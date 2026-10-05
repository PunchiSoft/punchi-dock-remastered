// SPDX-License-Identifier: GPL-3.0-or-later
#include "popupappearancedefaults.h"
#include <KConfigGroup>
#include <KConfigLoader>
#include <KConfigPropertyMap>
#include <KSharedConfig>
#include <QCoreApplication>
#include <QFile>
#include <QTemporaryDir>
#include <QTest>

class PopupAppearanceDefaultsTest : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void defaultProfile_data()
    {
        QTest::addColumn<QVersionNumber>("version");
        QTest::addColumn<int>("opacity");
        QTest::addColumn<bool>("blur");
        QTest::newRow("qt66") << QVersionNumber(6, 6, 0) << 75 << true;
        QTest::newRow("qt68") << QVersionNumber(6, 8, 2) << 100 << false;
        QTest::newRow("qt69") << QVersionNumber(6, 9, 0) << 75 << true;
        QTest::newRow("qt611") << QVersionNumber(6, 11, 2) << 75 << true;
    }
    void defaultProfile()
    {
        QFETCH(QVersionNumber, version);
        QFETCH(int, opacity);
        QFETCH(bool, blur);
        QTemporaryDir temporary;
        QVERIFY(temporary.isValid());
        auto config = KSharedConfig::openConfig(temporary.filePath(QStringLiteral("preferences")), KConfig::SimpleConfig);
        QFile schema(QStringLiteral(PUNCHI_PROJECT_SOURCE_DIR "/contents/config/main.xml"));
        KConfigLoader loader(config, &schema);
        loader.load();
        KConfigPropertyMap map(&loader);
        PopupAppearanceDefaults::apply(&loader, &map, version);
        for (const QString &key : {QStringLiteral("folderPopupBackgroundOpacityPercent"),
                                  QStringLiteral("windowPreviewBackgroundOpacityPercent"),
                                  QStringLiteral("mediaCardBackgroundOpacityPercent")}) {
            QCOMPARE(map.value(key).toInt(), opacity);
            QCOMPARE(map.value(key + QStringLiteral("Default")).toInt(), opacity);
            QCOMPARE(static_cast<KCoreConfigSkeleton &>(loader).findItem(key)->getDefault().toInt(), opacity);
        }
        QCOMPARE(map.value(QStringLiteral("contextMenuBackgroundOpacityPercent")).toInt(), 100);
        QCOMPARE(map.value(QStringLiteral("contextMenuBackgroundBlurEnabled")).toBool(), false);
        QCOMPARE(map.value(QStringLiteral("popupBackgroundBlurEnabled")).toBool(), blur);
        QCOMPARE(map.value(QStringLiteral("popupBackgroundBlurEnabledDefault")).toBool(), blur);
        // A reload reads the XML again; the runtime adapter reapplies the profile.
        loader.load();
        PopupAppearanceDefaults::apply(&loader, &map, version);
        QCOMPARE(map.value(QStringLiteral("folderPopupBackgroundOpacityPercent")).toInt(), opacity);
        QVERIFY(!QFile::exists(config->name()));
    }
    void savedChoicesSurviveLegacyDefaults()
    {
        QTemporaryDir temporary;
        QVERIFY(temporary.isValid());
        auto config = KSharedConfig::openConfig(temporary.filePath(QStringLiteral("preferences")), KConfig::SimpleConfig);
        KConfigGroup appearance(config, QStringLiteral("Appearance"));
        appearance.writeEntry("folderPopupBackgroundOpacityPercent", 75);
        appearance.writeEntry("popupBackgroundBlurEnabled", true);
        KConfigGroup windows(config, QStringLiteral("Windows"));
        windows.writeEntry("windowPreviewBackgroundOpacityPercent", 65);
        QVERIFY(config->sync());
        QFile schema(QStringLiteral(PUNCHI_PROJECT_SOURCE_DIR "/contents/config/main.xml"));
        KConfigLoader loader(config, &schema);
        loader.load();
        KConfigPropertyMap map(&loader);
        PopupAppearanceDefaults::apply(&loader, &map, QVersionNumber(6, 8, 2));
        QCOMPARE(map.value(QStringLiteral("folderPopupBackgroundOpacityPercent")).toInt(), 75);
        QCOMPARE(map.value(QStringLiteral("windowPreviewBackgroundOpacityPercent")).toInt(), 65);
        QCOMPARE(map.value(QStringLiteral("popupBackgroundBlurEnabled")).toBool(), true);
        QCOMPARE(map.value(QStringLiteral("folderPopupBackgroundOpacityPercentDefault")).toInt(), 100);
        QCOMPARE(map.value(QStringLiteral("popupBackgroundBlurEnabledDefault")).toBool(), false);
        QCOMPARE(appearance.readEntry("folderPopupBackgroundOpacityPercent", 0), 75);
        QCOMPARE(windows.readEntry("windowPreviewBackgroundOpacityPercent", 0), 65);
        // Restoring defaults uses the version-specific values, then persists them.
        loader.setDefaults();
        QCOMPARE(static_cast<KCoreConfigSkeleton &>(loader).findItem(QStringLiteral("folderPopupBackgroundOpacityPercent"))->property().toInt(), 100);
        QCOMPARE(static_cast<KCoreConfigSkeleton &>(loader).findItem(QStringLiteral("popupBackgroundBlurEnabled"))->property().toBool(), false);
        QVERIFY(loader.save());
        loader.load();
        PopupAppearanceDefaults::apply(&loader, &map, QVersionNumber(6, 8, 2));
        QCOMPARE(map.value(QStringLiteral("folderPopupBackgroundOpacityPercent")).toInt(), 100);
        QCOMPARE(map.value(QStringLiteral("popupBackgroundBlurEnabled")).toBool(), false);
    }
};

int main(int argc, char **argv)
{
    QCoreApplication application(argc, argv);
    PopupAppearanceDefaultsTest test;
    return QTest::qExec(&test, argc, argv);
}
#include "popup_appearance_defaults_test.moc"
