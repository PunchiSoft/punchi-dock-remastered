// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockthemerepository.h"

#include <QCoreApplication>
#include <KJob>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QSignalSpy>
#include <QStandardPaths>
#include <QTest>

class NativeTrashRepository : public DockThemeRepository
{
protected:
    KJob *createTrashJob(const QUrl &url) override {
        KJob *job = DockThemeRepository::createTrashJob(url);
        QObject::connect(job, &KJob::result, this, [](KJob *result) {
            if (result->error()) {
                qCritical("KIO test error: %s", qPrintable(result->errorString()));
            }
        });
        return job;
    }
};

// The runner supplies isolated XDG directories before starting D-Bus/KIO.
int main(int argc, char **argv)
{
    QCoreApplication application(argc, argv);
    if (!qEnvironmentVariableIsSet("PUNCHI_ISOLATED_TRASH_TEST")) {
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    const QString dataRoot = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    const QString source = QDir(dataRoot).filePath(QStringLiteral("source.json"));
    QFile file(source);
    const QByteArray theme = R"({"schemaVersion":1,"metadata":{"name":"Recoverable Theme"},"renderer":"flat","surface":{"color":"#20242a","radius":18}})";
    if (!file.open(QIODevice::WriteOnly) || file.write(theme) != theme.size()) {
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    file.close();
    NativeTrashRepository repository;
    const QString id = repository.importTheme(QUrl::fromLocalFile(source));
    if (id.isEmpty()) {
        qCritical("Theme fixture was rejected");
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    const QString library = QDir(dataRoot).filePath(QStringLiteral("punchi-dock-remastered/themes"));
    const QString unrelated = QDir(library).filePath(QStringLiteral("unrelated.json"));
    QFile other(unrelated);
    if (!other.open(QIODevice::WriteOnly) || other.write("{\"keep\":true}") < 0) {
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    other.close();
    if (repository.prepareRemoval().value(QStringLiteral("count")).toInt() != 1) {
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    QSignalSpy finished(&repository, &DockThemeRepository::removalFinished);
    if (!repository.confirmRemoval() || !finished.wait(15000)
        || finished.first().at(0).toInt() != 1 || finished.first().at(1).toInt() != 0) {
        qCritical("KIO could not trash the isolated theme");
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    // Check the real desktop Trash payload and recovery metadata, not only
    // absence from the library. The user's Trash is never used by this test.
    const QString trashRoot = QDir(dataRoot).filePath(QStringLiteral("Trash"));
    QDirIterator trashed(QDir(trashRoot).filePath(QStringLiteral("files")),
        {id + QStringLiteral(".json*")}, QDir::Files);
    if (!trashed.hasNext()) {
        qCritical("Recoverable payload is missing from the isolated Trash");
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    QFile payload(trashed.next());
    if (!payload.open(QIODevice::ReadOnly) || payload.readAll().isEmpty()) {
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    const QString infoPath = QDir(trashRoot).filePath(QStringLiteral("info/")
        + QFileInfo(payload).fileName() + QStringLiteral(".trashinfo"));
    QFile metadata(infoPath);
    if (!metadata.open(QIODevice::ReadOnly) || !metadata.readAll().contains("Path=")) {
        qCritical("Trash recovery metadata is missing");
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    if (!QFile::exists(unrelated) || !QFile::exists(source) || repository.valid()
        || !repository.availableThemes().isEmpty()) {
        qCritical("Isolated Trash assertion failed at line %d", __LINE__);
        return 1;
    }
    return 0;
}
