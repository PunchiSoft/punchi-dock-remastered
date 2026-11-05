/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Opens and closes the two large overlays repeatedly and records the private
// anonymous memory of this process after every cycle. A leak shows up as a
// series that keeps rising instead of oscillating around a stable value.

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QEvent>
#include <QFile>
#include <QFileInfo>
#include <QIcon>
#include <QJSValue>
#include <QQuickItem>
#include <QHash>
#include <QQuickWindow>
#include <QSet>
#include <QTest>
#include <QElapsedTimer>
#include <QThread>

#include <KPackage/Package>
#include <KPackage/PackageLoader>

#include <Plasma/Applet>
#include <Plasma/Containment>
#include <Plasma/Corona>
#include <Plasma/PluginLoader>
#include <Plasma/Theme>
#include <PlasmaQuick/AppletQuickItem>

#include <algorithm>
#include <memory>

namespace
{
constexpr auto s_pluginId = "org.kde.plasma.punchi-dock-remastered";
// 25 cycles with a ceiling that leaves room for the allocator to keep freed
// blocks. A real leak of a few hundred kilobytes per cycle already crosses it.
// Valgrind or a manual bisection can lower it through the environment.
constexpr int s_defaultCycleCount = 25;
constexpr double s_growthLimitMb = 6.0;
constexpr int s_objectGrowthLimit = 50;

void drainDeferredEvents()
{
    for (int iteration = 0; iteration < 10; ++iteration) {
        QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
        QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
    }
}

void settle(int milliseconds)
{
    QElapsedTimer timer;
    timer.start();
    while (timer.elapsed() < milliseconds) {
        QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
        QThread::msleep(5);
    }
}

double privateAnonymousMb()
{
    // /proc files report a size of zero, so atEnd() is true from the start and
    // the whole file must be read in one go.
    QFile rollup(QStringLiteral("/proc/self/smaps_rollup"));
    if (!rollup.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning("smaps_rollup open failed: %s", qPrintable(rollup.errorString()));
        return -1.0;
    }
    const QByteArray contents = rollup.readAll();
    const QList<QByteArray> lines = contents.split('\n');
    for (const QByteArray &line : lines) {
        if (!line.startsWith("Pss_Anon:")) {
            continue;
        }
        const QList<QByteArray> fields = line.simplified().split(' ');
        if (fields.size() < 2) {
            break;
        }
        return fields.at(1).toDouble() / 1024.0;
    }
    qWarning("smaps_rollup has no usable Pss_Anon line (%lld bytes read)",
             static_cast<long long>(contents.size()));
    return -1.0;
}

int countItems(QQuickItem *item)
{
    if (!item) {
        return 0;
    }
    int total = 1;
    const auto children = item->childItems();
    for (QQuickItem *child : children) {
        total += countItems(child);
    }
    return total;
}

void censusObjects(QObject *object, QHash<QString, int> *counts)
{
    if (!object) {
        return;
    }
    const QString name = QString::fromLatin1(object->metaObject()->className());
    (*counts)[name] += 1;
    const auto children = object->children();
    for (QObject *child : children) {
        censusObjects(child, counts);
    }
}

int censusTotal(const QHash<QString, int> &counts)
{
    int total = 0;
    for (auto it = counts.cbegin(); it != counts.cend(); ++it) {
        total += it.value();
    }
    return total;
}

QString censusDelta(const QHash<QString, int> &first, const QHash<QString, int> &last)
{
    QStringList parts;
    QSet<QString> names;
    for (auto it = first.cbegin(); it != first.cend(); ++it) {
        names.insert(it.key());
    }
    for (auto it = last.cbegin(); it != last.cend(); ++it) {
        names.insert(it.key());
    }
    for (const QString &name : names) {
        const int delta = last.value(name) - first.value(name);
        if (delta != 0) {
            parts.append(QStringLiteral("%1 %+2").arg(name).arg(delta));
        }
    }
    std::sort(parts.begin(), parts.end());
    return parts.isEmpty() ? QStringLiteral("none") : parts.join(QStringLiteral(", "));
}

double median(QList<double> values)
{
    if (values.isEmpty()) {
        return 0.0;
    }
    std::sort(values.begin(), values.end());
    const int middle = values.size() / 2;
    if (values.size() % 2) {
        return values.at(middle);
    }
    return (values.at(middle - 1) + values.at(middle)) / 2.0;
}

QString formatSeries(const QList<double> &values)
{
    QStringList parts;
    for (int index = 0; index < values.size(); ++index) {
        parts.append(QStringLiteral("%1:%2").arg(index + 1).arg(values.at(index), 0, 'f', 1));
    }
    return parts.join(QLatin1Char(' '));
}

bool copyFile(const QString &sourcePath, const QString &destinationPath, QString *error)
{
    const QFileInfo sourceInfo(sourcePath);
    if (!sourceInfo.isFile() || sourceInfo.size() <= 0) {
        *error = QStringLiteral("Required source file is missing or empty: %1").arg(sourcePath);
        return false;
    }
    if (!QDir().mkpath(QFileInfo(destinationPath).absolutePath())) {
        *error = QStringLiteral("Could not create destination directory for: %1").arg(destinationPath);
        return false;
    }
    if (!QFile::copy(sourcePath, destinationPath)) {
        *error = QStringLiteral("Could not copy %1 to %2").arg(sourcePath, destinationPath);
        return false;
    }
    return true;
}

bool writeFile(const QString &destinationPath, const QByteArray &contents)
{
    if (!QDir().mkpath(QFileInfo(destinationPath).absolutePath())) {
        return false;
    }
    QFile destination(destinationPath);
    if (!destination.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return false;
    }
    return destination.write(contents) == contents.size();
}

bool copyPackageContents(const QString &sourcePath, const QString &destinationPath, QString *error)
{
    const QDir sourceDirectory(sourcePath);
    if (!sourceDirectory.exists()) {
        *error = QStringLiteral("Package source directory does not exist: %1").arg(sourcePath);
        return false;
    }

    // The working tree can hold an untracked copy of the native module that is
    // older than the sources. It is always replaced by the freshly built one,
    // so it must not be copied first.
    const QSet<QString> generatedModuleFiles{
        QStringLiteral("ui/org/punchi/dock/libpunchidockintegration.so"),
        QStringLiteral("ui/org/punchi/dock/libpunchidockintegrationplugin.so"),
        QStringLiteral("ui/org/punchi/dock/punchidockintegration.qmltypes"),
        QStringLiteral("ui/org/punchi/dock/qmldir"),
    };

    QDirIterator iterator(sourcePath,
                          QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot,
                          QDirIterator::Subdirectories);
    while (iterator.hasNext()) {
        iterator.next();
        const QString relativePath = sourceDirectory.relativeFilePath(iterator.filePath());
        if (generatedModuleFiles.contains(relativePath)) {
            continue;
        }

        const QString destination = QDir(destinationPath).filePath(relativePath);
        if (iterator.fileInfo().isDir()) {
            if (!QDir().mkpath(destination)) {
                *error = QStringLiteral("Could not create package directory: %1").arg(destination);
                return false;
            }
            continue;
        }

        if (!copyFile(iterator.filePath(), destination, error)) {
            return false;
        }
    }

    return true;
}

class TestCorona : public Plasma::Corona
{
    Q_OBJECT

public:
    explicit TestCorona(QObject *parent = nullptr)
        : Plasma::Corona(parent)
    {
    }

    int numScreens() const override
    {
        return 1;
    }

    QRect screenGeometry(int screen) const override
    {
        return screen == 0 ? QRect(0, 0, 1920, 1080) : QRect();
    }
};
}

class MemoryCycleTest : public QObject
{
    Q_OBJECT

public:
    explicit MemoryCycleTest(QString environmentRoot)
        : m_environmentRoot(std::move(environmentRoot))
    {
    }

private Q_SLOTS:
    void initTestCase()
    {
        const QString sourceRoot = QStringLiteral(PUNCHI_PROJECT_SOURCE_DIR);
        m_packageRoot = QDir(m_environmentRoot)
                            .filePath(QStringLiteral("data/plasma/plasmoids/%1")
                                          .arg(QString::fromLatin1(s_pluginId)));

        QString error;
        QVERIFY2(QDir().mkpath(m_packageRoot),
                 qPrintable(QStringLiteral("Could not create %1").arg(m_packageRoot)));
        QVERIFY2(copyFile(QDir(sourceRoot).filePath(QStringLiteral("metadata.json")),
                          QDir(m_packageRoot).filePath(QStringLiteral("metadata.json")),
                          &error),
                 qPrintable(error));
        QVERIFY2(copyPackageContents(QDir(sourceRoot).filePath(QStringLiteral("contents")),
                                     QDir(m_packageRoot).filePath(QStringLiteral("contents")),
                                     &error),
                 qPrintable(error));

        const QString moduleRoot =
            QDir(m_packageRoot).filePath(QStringLiteral("contents/ui/org/punchi/dock"));
        const QList<QPair<QString, QString>> generatedFiles{
            {QStringLiteral(PUNCHI_INTEGRATION_LIBRARY), QStringLiteral("libpunchidockintegration.so")},
            {QStringLiteral(PUNCHI_INTEGRATION_PLUGIN), QStringLiteral("libpunchidockintegrationplugin.so")},
            {QStringLiteral(PUNCHI_INTEGRATION_QMLDIR), QStringLiteral("qmldir")},
            {QStringLiteral(PUNCHI_INTEGRATION_QMLTYPES), QStringLiteral("punchidockintegration.qmltypes")},
        };
        for (const auto &[source, fileName] : generatedFiles) {
            QVERIFY2(copyFile(source, QDir(moduleRoot).filePath(fileName), &error), qPrintable(error));
        }

        m_corona = std::make_unique<TestCorona>();
        KPackage::Package shellPackage =
            KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/Shell"));
        shellPackage.setPath(QStringLiteral("org.kde.plasma.desktop"));
        QVERIFY2(shellPackage.isValid(), "The system Plasma shell package is unavailable");
        m_corona->setKPackage(shellPackage);
        m_containment = m_corona->createContainment(QStringLiteral("null"));
        QVERIFY2(m_containment, "Could not create the isolated test containment");
        m_containment->setFormFactor(Plasma::Types::Horizontal);
        m_containment->setLocation(Plasma::Types::BottomEdge);
    }

    void overlaysDoNotAccumulateMemory()
    {
        const int cycleCount = qEnvironmentVariableIntValue("PUNCHI_MEMORY_CYCLE_COUNT") > 0
            ? qEnvironmentVariableIntValue("PUNCHI_MEMORY_CYCLE_COUNT")
            : s_defaultCycleCount;
        QQuickWindow hostWindow;
        QObject *root = createApplet(rootWindow(hostWindow));
        QVERIFY2(root != nullptr, "The applet root object was not created");

        // The first cycles build caches and warm the QML engine; the series
        // starts after them so a legitimate ramp is not reported as a leak.
        QList<double> series;
        QList<int> itemCounts;
        for (int cycle = 0; cycle < cycleCount; ++cycle) {
            openAndClose(root, QStringLiteral("toggleControlCenter"),
                         QStringLiteral("controlCenterDialogInstance"),
                         QStringLiteral("controlCenterFullscreenDialog"));
            openAndClose(root, QStringLiteral("togglePunchiMenu"),
                         QStringLiteral("punchiMenuDialogInstance"),
                         QString());
            settle(150);

            const double anon = privateAnonymousMb();
            QVERIFY2(anon >= 0.0, "Could not read Pss_Anon from /proc/self/smaps_rollup");
            series.append(anon);
            itemCounts.append(countItems(hostWindow.contentItem()));
        }

        qInfo("memory-cycle series (MB): %s", qPrintable(formatSeries(series)));
        qInfo("memory-cycle item counts: %s",
              qPrintable([&itemCounts]() {
                  QStringList parts;
                  for (int index = 0; index < itemCounts.size(); ++index) {
                      parts.append(QStringLiteral("%1:%2").arg(index + 1).arg(itemCounts.at(index)));
                  }
                  return parts.join(QLatin1Char(' '));
              }()));

        const int warmup = std::min<int>(5, static_cast<int>(series.size()));
        const double warmMedian = median(series.mid(warmup, 5));
        const double finalMedian = median(series.mid(series.size() - 5));
        const double growth = finalMedian - warmMedian;
        qInfo("memory-cycle growth from warm-up to the last cycles: %.1f MB", growth);

        QVERIFY2(growth <= s_growthLimitMb,
                 qPrintable(QStringLiteral("Overlay cycles kept growing: %.1f MB over %2 cycles "
                                           "exceeds the %.1f MB ceiling. Series: %3")
                                .arg(growth)
                                .arg(cycleCount)
                                .arg(s_growthLimitMb)
                                .arg(formatSeries(series))));

        const int warmIndex = std::min<int>(warmup, static_cast<int>(itemCounts.size()) - 1);
        const int warmItems = itemCounts.at(warmIndex);
        const int finalItems = itemCounts.last();
        qInfo("memory-cycle item growth: %d -> %d", warmItems, finalItems);
        QVERIFY2(finalItems - warmItems <= s_objectGrowthLimit,
                 qPrintable(QStringLiteral("Visual items kept accumulating: %1 -> %2")
                                .arg(warmItems)
                                .arg(finalItems)));
    }

    // Idle use (no interaction at all) is where the 2026-11-04 audit measured a
    // slow rise. Memory alone cannot say what grows, so this slot also censuses
    // the QObject tree every sample and reports which classes gained instances.
    void idleUseDoesNotAccumulateObjects()
    {
        const int seconds = qEnvironmentVariableIntValue("PUNCHI_MEMORY_IDLE_SECONDS") > 0
            ? qEnvironmentVariableIntValue("PUNCHI_MEMORY_IDLE_SECONDS")
            : 45;
        QQuickWindow hostWindow;
        QObject *root = createApplet(hostWindow, 2002U);
        QVERIFY2(root != nullptr, "The applet root object was not created");

        // The applet builds several popups and menus lazily on first use. Wait
        // for that ramp before taking the baseline census, otherwise it looks
        // like 1400 leaked objects.
        settle(45000);
        QHash<QString, int> firstCensus;
        censusObjects(root, &firstCensus);
        const int firstItems = countItems(hostWindow.contentItem());
        const double firstAnon = privateAnonymousMb();
        QHash<QString, int> lastCensus = firstCensus;
        int lastItems = firstItems;
        double lastAnon = firstAnon;

        QElapsedTimer timer;
        timer.start();
        int nextReport = 60;
        while (timer.elapsed() / 1000 < seconds) {
            settle(1000);
            lastAnon = privateAnonymousMb();
            lastItems = countItems(hostWindow.contentItem());
            lastCensus.clear();
            censusObjects(root, &lastCensus);
            const int elapsed = timer.elapsed() / 1000;
            if (elapsed >= nextReport) {
                qInfo("idle t=%ds anon=%.1f MB items=%d objects=%d", elapsed, lastAnon,
                      lastItems, censusTotal(lastCensus));
                nextReport += 60;
            }
        }

        const int objectGrowth = censusTotal(lastCensus) - censusTotal(firstCensus);
        qInfo("idle result: %ds anon %.1f -> %.1f MB (%+.1f), items %d -> %d (%+d), "
              "objects %d -> %d (%+d)",
              seconds, firstAnon, lastAnon, lastAnon - firstAnon, firstItems, lastItems,
              lastItems - firstItems, censusTotal(firstCensus), censusTotal(lastCensus),
              objectGrowth);
        qInfo("idle object delta: %s", qPrintable(censusDelta(firstCensus, lastCensus)));

        QVERIFY2(objectGrowth <= s_objectGrowthLimit,
                 qPrintable(QStringLiteral("Idle use accumulated %1 QObjects over %2 s: %3")
                                .arg(objectGrowth)
                                .arg(seconds)
                                .arg(censusDelta(firstCensus, lastCensus))));
        QVERIFY2(lastItems - firstItems <= s_objectGrowthLimit,
                 qPrintable(QStringLiteral("Idle use accumulated %1 visual items over %2 s")
                                .arg(lastItems - firstItems)
                                .arg(seconds)));
    }

    void cleanupTestCase()
    {
        m_containment = nullptr;
        m_corona.reset();
        drainDeferredEvents();
    }

private:
    QQuickWindow &rootWindow(QQuickWindow &window)
    {
        window.resize(1920, 1080);
        window.show();
        return window;
    }

    QObject *createApplet(QQuickWindow &window, uint appletId = 2001U)
    {
        Plasma::Applet *applet =
            Plasma::PluginLoader::self()->loadApplet(QString::fromLatin1(s_pluginId), appletId);
        if (!applet) {
            return nullptr;
        }
        m_containment->addApplet(applet);
        PlasmaQuick::AppletQuickItem *item = PlasmaQuick::AppletQuickItem::itemForApplet(applet);
        if (!item) {
            return nullptr;
        }
        item->setParentItem(window.contentItem());
        window.show();
        settle(500);

        // The applet root is the object that owns togglePunchiMenu and
        // toggleControlCenter, not the AppletQuickItem wrapper.
        QObject *root = item;
        if (root->objectName() != QLatin1StringView("punchiDockRoot")) {
            root = item->findChild<QObject *>(QStringLiteral("punchiDockRoot"));
        }
        return root;
    }

    void openAndClose(QObject *root, const QString &toggle, const QString &instanceProperty,
                      const QString &expectedObjectName)
    {
        if (!QMetaObject::invokeMethod(root, toggle.toUtf8().constData(),
                                       Q_ARG(QVariant, QVariant()))) {
            qWarning("Could not invoke %s", qPrintable(toggle));
            return;
        }
        settle(250);

        const QVariant dialogValue = root->property(instanceProperty.toUtf8().constData());
        QObject *dialog = qvariant_cast<QObject *>(dialogValue);
        if (!dialog && dialogValue.canConvert<QJSValue>()) {
            dialog = dialogValue.value<QJSValue>().toQObject();
        }
        if (!dialog) {
            qWarning("%s did not create its dialog", qPrintable(toggle));
            return;
        }
        if (!expectedObjectName.isEmpty()
            && dialog->objectName() != expectedObjectName) {
            qWarning("%s created an unexpected dialog: %s", qPrintable(toggle),
                     qPrintable(dialog->objectName()));
        }
        QMetaObject::invokeMethod(dialog, "closeImmediately");
        settle(250);
    }

    QString m_environmentRoot;
    QString m_packageRoot;
    std::unique_ptr<TestCorona> m_corona;
    Plasma::Containment *m_containment = nullptr;
};

int main(int argc, char **argv)
{
    const QByteArray encodedEnvironmentRoot = qgetenv("PUNCHI_TEST_ENVIRONMENT_ROOT");
    if (encodedEnvironmentRoot.isEmpty()) {
        qCritical("PUNCHI_TEST_ENVIRONMENT_ROOT must be provided by the cleanup wrapper");
        return 1;
    }
    const QString environmentRoot = QFile::decodeName(encodedEnvironmentRoot);
    if (!QFileInfo(environmentRoot).isDir()) {
        qCritical("PUNCHI_TEST_ENVIRONMENT_ROOT does not identify an existing directory");
        return 1;
    }

    const QList<QPair<QByteArray, QString>> isolatedLocations{
        {QByteArrayLiteral("XDG_DATA_HOME"), QStringLiteral("data")},
        {QByteArrayLiteral("XDG_CONFIG_HOME"), QStringLiteral("config")},
        {QByteArrayLiteral("XDG_CACHE_HOME"), QStringLiteral("cache")},
        {QByteArrayLiteral("XDG_RUNTIME_DIR"), QStringLiteral("runtime")},
    };
    for (const auto &[variable, directory] : isolatedLocations) {
        const QString path = QDir(environmentRoot).filePath(directory);
        if (!QDir().mkpath(path)) {
            return 1;
        }
        if (variable == QByteArrayLiteral("XDG_RUNTIME_DIR")
            && !QFile::setPermissions(path, QFileDevice::ReadOwner | QFileDevice::WriteOwner
                                                | QFileDevice::ExeOwner)) {
            return 1;
        }
        qputenv(variable.constData(), QFile::encodeName(path));
    }

    const QString configRoot = QDir(environmentRoot).filePath(QStringLiteral("config"));
    if (!writeFile(QDir(configRoot).filePath(QStringLiteral("plasmarc")),
                   QByteArrayLiteral("[Theme]\nname=default\n"))
        || !writeFile(QDir(configRoot).filePath(QStringLiteral("kdeglobals")),
                      QByteArrayLiteral("[Icons]\nTheme=breeze\n"))) {
        return 1;
    }

    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QT_QUICK_BACKEND", "software");

    QGuiApplication application(argc, argv);
    QIcon::setThemeName(QStringLiteral("breeze"));
    Plasma::Theme isolatedTheme;
    isolatedTheme.setThemeName(QStringLiteral("default"));
    if (isolatedTheme.themeName() != QLatin1StringView("default")) {
        return 1;
    }

    MemoryCycleTest test(environmentRoot);
    const int result = QTest::qExec(&test, argc, argv);
    return result;
}

#include "memory_cycle_test.moc"
