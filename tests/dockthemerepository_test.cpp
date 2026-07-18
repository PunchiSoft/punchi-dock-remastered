// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockthemerepository.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QTemporaryDir>

#include <algorithm>
#include <iostream>

namespace
{
bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
    }
    return condition;
}

QString findManagedThemePath(const QString &dataHome, const QString &themeId)
{
    QDirIterator iterator(
        QDir(dataHome).filePath(QStringLiteral("punchi-dock-remastered/themes")),
        {themeId + QStringLiteral(".json")},
        QDir::Files | QDir::NoDotAndDotDot,
        QDirIterator::Subdirectories);
    return iterator.hasNext() ? iterator.next() : QString();
}
}

int main(int argc, char **argv)
{
    QCoreApplication application(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("punchi-dock-theme-test"));

    QTemporaryDir temporaryDataHome;
    if (!temporaryDataHome.isValid()) {
        std::cerr << "FAILED: temporary data directory unavailable\n";
        return 1;
    }
    qputenv("XDG_DATA_HOME", temporaryDataHome.path().toUtf8());

    const QByteArray themeData = R"json(
{
  "schemaVersion": 1,
  "metadata": {
    "name": "External Test Theme"
  },
  "renderer": "flat",
  "surface": {
    "color": "#20242a",
    "radius": 18,
    "gradient": {
      "direction": "horizontal",
      "stops": [
        { "position": 0, "color": "#20242a" },
        { "position": 1, "color": "#ff101318" }
      ]
    }
  },
  "separator": {
    "style": "dot",
    "color": "#35cce0",
    "thickness": 14,
    "radius": 7
  }
}
)json";

    const QString sourcePath = QDir(temporaryDataHome.path()).filePath(QStringLiteral("downloaded-theme.json"));
    QFile sourceFile(sourcePath);
    if (!sourceFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || sourceFile.write(themeData) != themeData.size()) {
        std::cerr << "FAILED: source theme could not be created\n";
        return 1;
    }
    sourceFile.close();

    bool passed = true;
    DockThemeRepository importer;
    const QString themeId = importer.importTheme(QUrl::fromLocalFile(sourcePath));
    passed &= expect(themeId.size() == 16, "import returns a stable identifier");
    passed &= expect(importer.valid(), "imported theme is active");
    passed &= expect(importer.themeName() == QLatin1String("External Test Theme"),
        "imported metadata is available");
    passed &= expect(importer.theme().value(QStringLiteral("separator")).toMap()
        .value(QStringLiteral("style")).toString() == QLatin1String("dot"),
        "imported separator is available");

    const QString managedThemePath = findManagedThemePath(
        temporaryDataHome.path(), themeId);
    passed &= expect(QFile::exists(managedThemePath), "theme copied to managed external storage");
    passed &= expect(managedThemePath.contains(
        QStringLiteral("/themes/2d/external-test-theme/")),
        "new imports are organized by renderer and safe theme name");
    passed &= expect(!QFile::exists(QDir(temporaryDataHome.path())
        .filePath(QStringLiteral("punchi-dock/themes/%1.json").arg(themeId))),
        "legacy storage namespace remains untouched");
    passed &= expect(importer.availableThemes().size() == 1,
        "imported theme appears in the managed library");
    const QVariantMap libraryTheme = importer.availableThemes().constFirst().toMap();
    passed &= expect(libraryTheme.value(QStringLiteral("id")).toString() == themeId
        && libraryTheme.value(QStringLiteral("name")).toString() == QLatin1String("External Test Theme")
        && libraryTheme.value(QStringLiteral("renderer")).toString() == QLatin1String("flat"),
        "library exposes stable id, readable name and renderer");

    DockThemeRepository loader;
    loader.setThemeId(themeId);
    passed &= expect(loader.valid(), "managed theme reloads by identifier");
    passed &= expect(loader.themeName() == QLatin1String("External Test Theme"),
        "reloaded theme preserves metadata");
    passed &= expect(loader.theme().value(QStringLiteral("separator")).toMap()
        .value(QStringLiteral("thickness")).toDouble() == 14,
        "reloaded theme preserves separator");

    DockThemeRepository invalidLoader;
    invalidLoader.setThemeId(QStringLiteral("../../outside"));
    passed &= expect(!invalidLoader.valid()
        && invalidLoader.errorCode() == QLatin1String("invalidThemeId"),
        "path traversal identifier rejected");

    const QString invalidLibraryPath = QDir(temporaryDataHome.path())
        .filePath(QStringLiteral("punchi-dock-remastered/themes/not-managed.json"));
    QFile invalidLibraryFile(invalidLibraryPath);
    if (!invalidLibraryFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || invalidLibraryFile.write(themeData) != themeData.size()) {
        std::cerr << "FAILED: invalid library fixture could not be created\n";
        return 1;
    }
    invalidLibraryFile.close();

    int themesChangedCount = 0;
    QObject::connect(&loader, &DockThemeRepository::themesChanged,
        [&themesChangedCount]() {
            ++themesChangedCount;
        });
    loader.refreshThemes();
    passed &= expect(loader.availableThemes().size() == 1,
        "library ignores files without a managed identifier");
    passed &= expect(themesChangedCount == 0,
        "unchanged library does not emit a redundant notification");

    const QString secondManagedThemePath = QDir(temporaryDataHome.path())
        .filePath(QStringLiteral("punchi-dock-remastered/themes/0123456789abcdef.json"));
    QFile secondManagedThemeFile(secondManagedThemePath);
    if (!secondManagedThemeFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || secondManagedThemeFile.write(themeData) != themeData.size()) {
        std::cerr << "FAILED: second managed theme fixture could not be created\n";
        return 1;
    }
    secondManagedThemeFile.close();

    loader.refreshThemes();
    passed &= expect(loader.availableThemes().size() == 2,
        "library includes newly discovered managed themes");
    passed &= expect(themesChangedCount == 1,
        "library refresh notifies QML when its contents change");

    QTemporaryDir importDirectory;
    if (!importDirectory.isValid()) {
        std::cerr << "FAILED: batch import directory unavailable\n";
        return 1;
    }

    QFile validBatchTheme(QDir(importDirectory.path()).filePath(
        QStringLiteral("valid.json")));
    if (!validBatchTheme.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || validBatchTheme.write(themeData) != themeData.size()) {
        std::cerr << "FAILED: valid batch fixture could not be created\n";
        return 1;
    }
    validBatchTheme.close();

    const QString nestedDirectoryPath = QDir(importDirectory.path()).filePath(
        QStringLiteral("flat/blue"));
    if (!QDir().mkpath(nestedDirectoryPath)) {
        std::cerr << "FAILED: nested batch directory could not be created\n";
        return 1;
    }

    QByteArray secondThemeData = themeData;
    secondThemeData.replace("External Test Theme", "Second Batch Theme");
    QFile secondValidBatchTheme(QDir(nestedDirectoryPath).filePath(
        QStringLiteral("second-valid.JSON")));
    if (!secondValidBatchTheme.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || secondValidBatchTheme.write(secondThemeData) != secondThemeData.size()) {
        std::cerr << "FAILED: second valid batch fixture could not be created\n";
        return 1;
    }
    secondValidBatchTheme.close();

    const QString linkedDirectoryTarget = QDir(temporaryDataHome.path()).filePath(
        QStringLiteral("linked-theme-source"));
    if (!QDir().mkpath(linkedDirectoryTarget)) {
        std::cerr << "FAILED: linked batch directory could not be created\n";
        return 1;
    }
    QByteArray linkedThemeData = themeData;
    linkedThemeData.replace("External Test Theme", "Linked Theme");
    QFile linkedTheme(QDir(linkedDirectoryTarget).filePath(
        QStringLiteral("linked.json")));
    if (!linkedTheme.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || linkedTheme.write(linkedThemeData) != linkedThemeData.size()) {
        std::cerr << "FAILED: linked batch fixture could not be created\n";
        return 1;
    }
    linkedTheme.close();
    if (!QFile::link(linkedDirectoryTarget, QDir(importDirectory.path()).filePath(
            QStringLiteral("linked-directory")))) {
        std::cerr << "FAILED: linked batch directory could not be linked\n";
        return 1;
    }

    QFile invalidBatchTheme(QDir(importDirectory.path()).filePath(
        QStringLiteral("invalid.json")));
    if (!invalidBatchTheme.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || invalidBatchTheme.write("{invalid") <= 0) {
        std::cerr << "FAILED: invalid batch fixture could not be created\n";
        return 1;
    }
    invalidBatchTheme.close();

    QFile ignoredBatchFile(QDir(importDirectory.path()).filePath(
        QStringLiteral("notes.txt")));
    if (!ignoredBatchFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || ignoredBatchFile.write("not a theme") <= 0) {
        std::cerr << "FAILED: ignored batch fixture could not be created\n";
        return 1;
    }
    ignoredBatchFile.close();

    DockThemeRepository batchImporter;
    const QVariantMap batchResult = batchImporter.importThemeDirectory(
        QUrl::fromLocalFile(importDirectory.path()));
    passed &= expect(batchResult.value(QStringLiteral("candidateCount")).toInt() == 3,
        "batch import finds nested JSON files without following linked directories");
    passed &= expect(batchResult.value(QStringLiteral("importedCount")).toInt() == 1
        && batchResult.value(QStringLiteral("duplicateCount")).toInt() == 1,
        "batch import stores new themes and detects an already installed theme");
    passed &= expect(batchResult.value(QStringLiteral("rejectedCount")).toInt() == 1,
        "batch import rejects invalid JSON without aborting the folder");
    passed &= expect(batchResult.value(
        QStringLiteral("selectedThemeId")).toString().size() == 16,
        "batch import returns the first valid theme for immediate selection");
    const auto secondBatchThemeIterator = std::find_if(
        batchImporter.availableThemes().cbegin(),
        batchImporter.availableThemes().cend(),
        [](const QVariant &themeValue) {
            return themeValue.toMap().value(QStringLiteral("name")).toString()
                == QLatin1String("Second Batch Theme");
        });
    passed &= expect(secondBatchThemeIterator
        != batchImporter.availableThemes().cend(),
        "nested batch theme appears in the recursive managed library");
    if (secondBatchThemeIterator != batchImporter.availableThemes().cend()) {
        const QString secondBatchThemeId = secondBatchThemeIterator->toMap()
            .value(QStringLiteral("id")).toString();
        passed &= expect(findManagedThemePath(
            temporaryDataHome.path(), secondBatchThemeId).contains(
                QStringLiteral("/themes/2d/second-batch-theme/")),
            "batch imports preserve the managed theme hierarchy");
    }

    const QVariantMap invalidDirectoryResult = batchImporter.importThemeDirectory(
        QUrl::fromLocalFile(QDir(importDirectory.path()).filePath(
            QStringLiteral("missing"))));
    passed &= expect(invalidDirectoryResult.value(
        QStringLiteral("candidateCount")).toInt() == 0
        && batchImporter.errorCode() == QLatin1String("unreadableDirectory"),
        "batch import rejects an unavailable directory");

    const QString importedThemeDirectory = QFileInfo(managedThemePath).absolutePath();
    passed &= expect(importer.removeTheme(themeId),
        "managed theme can be removed by its validated identifier");
    passed &= expect(!QFile::exists(managedThemePath),
        "theme removal deletes the managed JSON file");
    passed &= expect(!QDir(importedThemeDirectory).exists(),
        "theme removal cleans its empty named directory");
    passed &= expect(!importer.valid() && importer.themeId().isEmpty(),
        "removing the active theme clears repository state");
    passed &= expect(std::none_of(
        importer.availableThemes().cbegin(),
        importer.availableThemes().cend(),
        [&themeId](const QVariant &themeValue) {
            return themeValue.toMap().value(QStringLiteral("id")).toString()
                == themeId;
        }),
        "removed theme disappears from the reactive library");

    passed &= expect(!importer.removeTheme(QStringLiteral("../../outside"))
        && importer.errorCode() == QLatin1String("invalidThemeId"),
        "theme removal rejects traversal identifiers");
    passed &= expect(!importer.removeTheme(QStringLiteral("ffffffffffffffff"))
        && importer.errorCode() == QLatin1String("themeNotFound"),
        "theme removal reports an unavailable managed identifier");

    const QString linkedThemeId = QStringLiteral("aaaaaaaaaaaaaaaa");
    const QString linkedManagedPath = QDir(temporaryDataHome.path()).filePath(
        QStringLiteral("punchi-dock-remastered/themes/%1.json").arg(linkedThemeId));
    if (!QFile::link(sourcePath, linkedManagedPath)) {
        std::cerr << "FAILED: managed theme symlink fixture could not be created\n";
        return 1;
    }
    passed &= expect(!importer.removeTheme(linkedThemeId)
        && importer.errorCode() == QLatin1String("themeNotFound")
        && QFile::exists(sourcePath),
        "theme removal ignores symlinks and preserves their targets");

    const QByteArray shapedThemeData = R"json(
{
  "schemaVersion": 2,
  "metadata": { "name": "Repository Wave" },
  "renderer": "shaped",
  "surface": { "color": "#d9273140" },
  "shape": {
    "preset": "wave",
    "depthRatio": 0.1,
    "repetitions": 5,
    "phase": 0
  }
}
)json";
    const QString shapedSourcePath = QDir(temporaryDataHome.path()).filePath(
        QStringLiteral("shaped-theme.json"));
    QFile shapedSourceFile(shapedSourcePath);
    if (!shapedSourceFile.open(QIODevice::WriteOnly | QIODevice::Truncate)
        || shapedSourceFile.write(shapedThemeData) != shapedThemeData.size()) {
        std::cerr << "FAILED: shaped theme fixture could not be created\n";
        return 1;
    }
    shapedSourceFile.close();

    DockThemeRepository shapedImporter;
    const QString shapedThemeId = shapedImporter.importTheme(
        QUrl::fromLocalFile(shapedSourcePath));
    const QString shapedManagedPath = findManagedThemePath(
        temporaryDataHome.path(), shapedThemeId);
    passed &= expect(shapedThemeId.size() == 16
        && shapedManagedPath.contains(
            QStringLiteral("/themes/shaped/repository-wave/")),
        "shaped imports use their own managed hierarchy");
    const QVariantList shapedThemes = shapedImporter.availableThemes();
    const auto shapedThemeIterator = std::find_if(
        shapedThemes.cbegin(),
        shapedThemes.cend(),
        [&shapedThemeId](const QVariant &themeValue) {
            return themeValue.toMap().value(QStringLiteral("id")).toString()
                == shapedThemeId;
        });
    passed &= expect(shapedThemeIterator != shapedThemes.cend(),
        "shaped theme appears in the managed library");
    if (shapedThemeIterator != shapedThemes.cend()) {
        const QString shapedDisplayName = shapedThemeIterator->toMap()
            .value(QStringLiteral("displayName")).toString();
        passed &= expect(shapedDisplayName.endsWith(QStringLiteral(" · Shaped")),
            "shaped theme is identified in the managed library");
    }

    return passed ? 0 : 1;
}
