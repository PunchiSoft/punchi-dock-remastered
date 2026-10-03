// SPDX-License-Identifier: GPL-3.0-or-later
#include "foldernavigationmodel.h"
#include "systemdiscovery.h"
#include "folderentryicon.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QMimeDatabase>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>
#include <QUrl>
#include <sys/stat.h>

class FolderEntryIconsTest : public QObject
{
    Q_OBJECT
private:
    static bool writeFile(const QString &path, const QByteArray &contents)
    {
        QFile file(path);
        return file.open(QIODevice::WriteOnly) && file.write(contents) == contents.size();
    }

    static QVariantMap findEntry(const QVariantList &entries, const QString &fileName)
    {
        for (const auto &entry : entries) {
            const auto row = entry.toMap();
            if (QUrl(row.value(QStringLiteral("url")).toString()).fileName() == fileName) {
                return row;
            }
        }
        return {};
    }

    static QVariantList modelEntries(const FolderNavigationModel &model)
    {
        QVariantList result;
        for (int i = 0; i < model.count(); ++i) {
            result.append(model.get(i));
        }
        return result;
    }

private Q_SLOTS:
    void init() { QTest::failOnWarning(QRegularExpression(QStringLiteral(".?"))); }

    void explicitIconAndMimeMetadata()
    {
        KIO::UDSEntry entry;
        entry.fastInsert(KIO::UDSEntry::UDS_NAME, QStringLiteral("clip.webm"));
        entry.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, S_IFREG);
        entry.fastInsert(KIO::UDSEntry::UDS_ICON_NAME, QStringLiteral("explicit-fixture-icon"));
        const QUrl url = QUrl::fromLocalFile(QStringLiteral("/nonexistent-fixture/clip.webm"));
        QCOMPARE(FolderEntryIcon::resolve(entry, url), QStringLiteral("explicit-fixture-icon"));
        entry.replace(KIO::UDSEntry::UDS_ICON_NAME, QString());
        entry.fastInsert(KIO::UDSEntry::UDS_MIME_TYPE, QStringLiteral("image/png"));
        QCOMPARE(FolderEntryIcon::resolve(entry, url), QMimeDatabase().mimeTypeForName(QStringLiteral("image/png")).iconName());
        entry.replace(KIO::UDSEntry::UDS_MIME_TYPE, QStringLiteral("invalid/fixture-format"));
        QCOMPARE(FolderEntryIcon::resolve(entry, url), QMimeDatabase().mimeTypeForName(QStringLiteral("video/webm")).iconName());
    }

    void fileFormats_data()
    {
        QTest::addColumn<QString>("fileName");
        QTest::addColumn<QString>("mimeType");
        QTest::newRow("video") << QStringLiteral("clip.webm") << QStringLiteral("video/webm");
        QTest::newRow("image") << QStringLiteral("picture.png") << QStringLiteral("image/png");
        QTest::newRow("pdf") << QStringLiteral("document.pdf") << QStringLiteral("application/pdf");
        QTest::newRow("audio") << QStringLiteral("sound.mp3") << QStringLiteral("audio/mpeg");
        QTest::newRow("archive") << QStringLiteral("archive.zip") << QStringLiteral("application/zip");
        QTest::newRow("text") << QStringLiteral("notes.txt") << QStringLiteral("text/plain");
        QTest::newRow("unknown") << QStringLiteral("unknown.punchiunknownformat") << QStringLiteral("application/octet-stream");
    }

    void fileFormats()
    {
        QFETCH(QString, fileName);
        QFETCH(QString, mimeType);
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        QVERIFY(QDir(directory.path()).mkdir(QStringLiteral("child")));
        // Deliberately misleading bytes: listing icons must not read file contents.
        QVERIFY(writeFile(directory.filePath(fileName), "Plain fixture bytes\n"));
        QVERIFY(writeFile(directory.filePath(QStringLiteral("child/") + fileName), "Plain fixture bytes\n"));
        const auto expected = QMimeDatabase().mimeTypeForName(mimeType).iconName();
        QVERIFY(!expected.isEmpty());

        SystemDiscovery discovery;
        QSignalSpy result(&discovery, &SystemDiscovery::folderEntriesReady);
        QSignalSpy errors(&discovery, &SystemDiscovery::operationFailed);
        discovery.requestFolderEntries(directory.path());
        QTRY_COMPARE_WITH_TIMEOUT(result.count(), 1, 5000);
        const auto initial = findEntry(result.at(0).at(0).toList(), fileName);
        QVERIFY(!initial.isEmpty());
        QCOMPARE(initial.value(QStringLiteral("icon")).toString(), expected);
        QCOMPARE(errors.count(), 0);

        FolderNavigationModel navigation;
        navigation.setRootPath(directory.path());
        navigation.setEnabled(true);
        QTRY_VERIFY_WITH_TIMEOUT(!navigation.loading(), 5000);
        QCOMPARE(navigation.error(), QString());
        QCOMPARE(findEntry(modelEntries(navigation), fileName).value(QStringLiteral("icon")).toString(), expected);
        navigation.setLocation(directory.filePath(QStringLiteral("child")));
        QTRY_VERIFY_WITH_TIMEOUT(!navigation.loading(), 5000);
        QCOMPARE(navigation.depth(), 1);
        QCOMPARE(findEntry(modelEntries(navigation), fileName).value(QStringLiteral("icon")).toString(), expected);
        navigation.setEnabled(false);
        QCOMPARE(navigation.count(), 0);
    }

    void folderAndLauncherIcons()
    {
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        const QString folder = directory.filePath(QStringLiteral("custom-folder"));
        QVERIFY(QDir().mkdir(folder));
        QVERIFY(writeFile(folder + QStringLiteral("/.directory"), "[Desktop Entry]\nIcon=folder-videos\n"));
        QVERIFY(writeFile(directory.filePath(QStringLiteral("launcher.desktop")),
            "[Desktop Entry]\nType=Application\nName=Fixture Launcher\nExec=/bin/false\nIcon=fixture-launcher-icon\n"));
        QVERIFY(QFile::setPermissions(directory.filePath(QStringLiteral("launcher.desktop")),
            QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner));

        SystemDiscovery discovery;
        QSignalSpy result(&discovery, &SystemDiscovery::folderEntriesReady);
        discovery.requestFolderEntries(directory.path());
        QTRY_COMPARE_WITH_TIMEOUT(result.count(), 1, 5000);
        const auto initial = result.at(0).at(0).toList();
        QCOMPARE(findEntry(initial, QStringLiteral("custom-folder")).value(QStringLiteral("icon")).toString(), QStringLiteral("folder-videos"));
        QCOMPARE(findEntry(initial, QStringLiteral("launcher.desktop")).value(QStringLiteral("icon")).toString(), QStringLiteral("fixture-launcher-icon"));

        FolderNavigationModel navigation;
        navigation.setRootPath(directory.path());
        navigation.setEnabled(true);
        QTRY_VERIFY_WITH_TIMEOUT(!navigation.loading(), 5000);
        const auto listed = modelEntries(navigation);
        QCOMPARE(findEntry(listed, QStringLiteral("custom-folder")).value(QStringLiteral("icon")).toString(), QStringLiteral("folder-videos"));
        QCOMPARE(findEntry(listed, QStringLiteral("launcher.desktop")).value(QStringLiteral("icon")).toString(), QStringLiteral("fixture-launcher-icon"));
        navigation.setEnabled(false);
    }
};

int main(int argc, char **argv)
{
    const QString root = qEnvironmentVariable("PUNCHI_TEST_ENVIRONMENT_ROOT");
    if (root.isEmpty()) {
        qCritical("A parent-owned isolated test environment is required.");
        return 2;
    }
    for (const auto &variable : {"XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR", "XDG_CONFIG_DIRS"}) {
        const QString path = root + QLatin1Char('/') + QString::fromLatin1(variable);
        QDir().mkpath(path);
        qputenv(variable, path.toUtf8());
    }
    qputenv("TMPDIR", root.toUtf8());
    QCoreApplication application(argc, argv);
    application.setApplicationName(QStringLiteral("punchi-icons-test"));
    FolderEntryIconsTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "folder_entry_icons_test.moc"
