// SPDX-License-Identifier: GPL-3.0-or-later

#include "recentapplicationsadapter.h"
#include "recentapplicationsmodel.h"
#include <KService>
#include <KSycoca>
#include <QAbstractItemModelTester>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QStandardItemModel>
#include <QStandardPaths>
#include <QTest>

class RecentApplicationsAdapterTest : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void init() { QTest::failOnWarning(); }
    void initTestCase()
    {
        const QString applications = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
        QVERIFY(QDir().mkpath(applications));
        for (const auto &id : {"Visible", "NoDisplay", "Hidden"}) {
            QFile file(applications + QStringLiteral("/org.example.") + QString::fromLatin1(id) + QStringLiteral(".desktop"));
            QVERIFY(file.open(QIODevice::WriteOnly));
            QByteArray entry = "[Desktop Entry]\nType=Application\nName=Example App\nIcon=system-run\nExec=/bin/true\n";
            if (QByteArray(id) == "NoDisplay") { entry += "NoDisplay=true\n"; }
            if (QByteArray(id) == "Hidden") { entry += "Hidden=true\n"; }
            QCOMPARE(file.write(entry), entry.size());
        }
        const QString builder = QStandardPaths::findExecutable(QStringLiteral("kbuildsycoca6"));
        QVERIFY(!builder.isEmpty());
        QProcess process;
        process.start(builder, {QStringLiteral("--noincremental")});
        QVERIFY(process.waitForFinished(10000));
        QCOMPARE(process.exitCode(), 0);
    }
    void resourceResolutionRejectsCommandsPathsAndHiddenApplications()
    {
        for (const auto &resource : {"", "file:///tmp/app.desktop", "https://example.invalid/app.desktop", "applications:../app.desktop",
                 "applications:/bin/true", "applications:app\n.desktop", "applications:org.example.Missing.desktop",
                 "applications:org.example.Hidden.desktop", "applications:org.example.NoDisplay.desktop"}) {
            QVERIFY(RecentApplicationsAdapter::resolveResource(QString::fromLatin1(resource)).isEmpty());
        }
        const auto app = RecentApplicationsAdapter::resolveResource(QStringLiteral("applications:org.example.Visible.desktop"));
        QCOMPARE(app.value(QStringLiteral("storageId")).toString(), QStringLiteral("org.example.Visible.desktop"));
        QCOMPARE(app.value(QStringLiteral("name")).toString(), QStringLiteral("Example App"));
        QCOMPARE(app.value(QStringLiteral("icon")).toString(), QStringLiteral("system-run"));
        QCOMPARE(RecentApplicationsAdapter::resolveResource(QStringLiteral("applications:org.example.Visible")), app);
    }
    void providerLifecycleAndCanonicalSelection()
    {
        RecentApplicationsAdapter adapter;
        QAbstractItemModelTester tester(&adapter, QAbstractItemModelTester::FailureReportingMode::Fatal);
        QVERIFY(!adapter.enabled());
        QVERIFY(!adapter.sourceModel());
        adapter.recordAccess(QStringLiteral("org.example.Visible.desktop"));
        QVERIFY(!adapter.sourceModel());
        adapter.setEnabled(true);
        QTest::qWait(20);
        QVERIFY(!adapter.available());
        QVERIFY(!adapter.sourceModel());
        QStandardItemModel provider;
        provider.setItemRoleNames({{Qt::UserRole, "resource"}});
        for (const auto &resource : {"applications:org.example.Missing.desktop", "applications:org.example.Visible.desktop", "applications:org.example.Visible"}) {
            auto *row = new QStandardItem;
            row->setData(QString::fromLatin1(resource), Qt::UserRole);
            provider.appendRow(row);
        }
        adapter.setSourceModel(&provider);
        RecentApplicationsModel selection;
        selection.setSourceModel(&adapter);
        selection.setEnabled(true);
        QCOMPARE(selection.count(), 1);
        QCOMPARE(selection.get(0).value(QStringLiteral("storageId")).toString(), QStringLiteral("org.example.Visible.desktop"));
        selection.setExcludedStorageIds({QStringLiteral("org.example.Visible")});
        QCOMPARE(selection.count(), 0);
        selection.setExcludedStorageIds({});
        QCOMPARE(selection.count(), 1);
        KSycoca::self()->databaseChanged();
        QCOMPARE(selection.count(), 1);
        adapter.setEnabled(false);
        QVERIFY(!adapter.sourceModel());
        QCOMPARE(selection.count(), 0);
        adapter.setEnabled(true);
        QVERIFY(!adapter.sourceModel());
        adapter.setEnabled(false);
        QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
    }
};

int main(int argc, char **argv)
{
    const QString root = QFile::decodeName(qgetenv("PUNCHI_TEST_ENVIRONMENT_ROOT"));
    if (root.isEmpty() || !QDir(root).exists()) { return 1; }
    for (const auto &variable : {"XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR"}) {
        const QString path = root + QLatin1Char('/') + QString::fromLatin1(variable);
        if (!QDir().mkpath(path)) { return 1; }
        if (!QFile::setPermissions(path, QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner)) { return 1; }
        qputenv(variable, QFile::encodeName(path));
    }
    qputenv("XDG_DATA_DIRS", QFile::encodeName(root + QStringLiteral("/XDG_DATA_HOME")));
    qputenv("XDG_CONFIG_DIRS", QFile::encodeName(root + QStringLiteral("/XDG_CONFIG_HOME")));
    QCoreApplication application(argc, argv);
    RecentApplicationsAdapterTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "recentapplicationsadapter_test.moc"
