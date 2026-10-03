// SPDX-License-Identifier: GPL-3.0-or-later
#include "decorationbuttonprovider.h"

#include <QDir>
#include <QFile>
#include <QSaveFile>
#include <QSignalSpy>
#include <QTest>

class DecorationButtonProviderTest : public QObject
{
    Q_OBJECT

private:
    QString m_root;

    bool writeFile(const QString &path, const QByteArray &contents)
    {
        QSaveFile file(path);
        return file.open(QIODevice::WriteOnly) && file.write(contents) == contents.size() && file.commit();
    }

    bool selectTheme(const QByteArray &theme, const QByteArray &plugin = "org.kde.kwin.aurorae.v2")
    {
        return writeFile(m_root + QStringLiteral("/config/kwinrc"), "[org.kde.kdecoration2]\nlibrary="
            + plugin + "\ntheme=__aurorae__svg__" + theme + '\n');
    }

private Q_SLOTS:
    void initTestCase()
    {
        m_root = qEnvironmentVariable("PUNCHI_TEST_ENVIRONMENT_ROOT");
        QVERIFY2(!m_root.isEmpty(), "Run through the disposable environment wrapper");
        for (const auto &entry : {std::pair("XDG_CONFIG_HOME", "/config"),
                 std::pair("XDG_DATA_HOME", "/data"), std::pair("XDG_CACHE_HOME", "/cache"),
                 std::pair("XDG_CONFIG_DIRS", "/system-config"), std::pair("XDG_DATA_DIRS", "/system-data")}) {
            const QString path = m_root + QString::fromLatin1(entry.second);
            QVERIFY(QDir().mkpath(path));
            qputenv(entry.first, path.toUtf8());
        }
        for (const QString &theme : {QStringLiteral("FixtureDark"), QStringLiteral("FixtureLight")}) {
            const QString directory = m_root + QStringLiteral("/data/aurorae/themes/") + theme;
            QVERIFY(QDir().mkpath(directory));
            QVERIFY(writeFile(directory + QStringLiteral("/close.svg"),
                "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\">"
                "<rect id=\"active-center\" width=\"16\" height=\"16\" fill=\"red\"/></svg>"));
            QVERIFY(writeFile(directory + QLatin1Char('/') + theme + QStringLiteral("rc"), "[Layout]\nButtonWidth=16\nButtonHeight=18\n"));
        }
    }

    void selectedThemeAndAtomicHotRefresh()
    {
        QVERIFY(selectTheme("FixtureDark"));
        DecorationButtonProvider provider;
        QCOMPARE(provider.themeName(), QStringLiteral("FixtureDark"));
        QVERIFY(provider.closeButtonPath().endsWith(QStringLiteral("/FixtureDark/close.svg")));
        QCOMPARE(provider.buttonSize(), QSizeF(16, 18));
        QSignalSpy changed(&provider, &DecorationButtonProvider::appearanceChanged);
        QVERIFY(selectTheme("FixtureLight"));
        QTRY_COMPARE(provider.themeName(), QStringLiteral("FixtureLight"));
        QVERIFY(provider.closeButtonPath().endsWith(QStringLiteral("/FixtureLight/close.svg")));
        QVERIFY(!changed.isEmpty());
        QVERIFY(selectTheme("FixtureLight", "org.kde.breeze"));
        QTRY_VERIFY(provider.closeButtonPath().isEmpty());
        QVERIFY(selectTheme("FixtureDark"));
        QTRY_VERIFY(provider.closeButtonPath().endsWith(QStringLiteral("/FixtureDark/close.svg")));
    }

    void traversalMissingAndMalformedResourcesFallBack()
    {
        for (const QByteArray &theme : {QByteArray("../FixtureDark"), QByteArray(".."), QByteArray("Missing")}) {
            QVERIFY(selectTheme(theme));
            DecorationButtonProvider provider;
            QVERIFY(provider.closeButtonPath().isEmpty());
        }
        const QString directory = m_root + QStringLiteral("/data/aurorae/themes/Invalid");
        QVERIFY(QDir().mkpath(directory));
        QVERIFY(selectTheme("Invalid"));
        for (const QByteArray &svg : {QByteArray("not an svg"), QByteArray("<svg><rect id=\"active-center\"/>")}) {
            QVERIFY(writeFile(directory + QStringLiteral("/close.svg"), svg));
            DecorationButtonProvider provider;
            QVERIFY(provider.closeButtonPath().isEmpty());
        }
        QVERIFY(writeFile(directory + QStringLiteral("/close.svg"), QByteArray(2 * 1024 * 1024 + 1, 'x')));
        DecorationButtonProvider provider;
        QVERIFY(provider.closeButtonPath().isEmpty());
    }

    void outsideSymlinkCannotBecomeAButton()
    {
        const QString directory = m_root + QStringLiteral("/data/aurorae/themes/Linked");
        QVERIFY(QDir().mkpath(directory));
        const QString source = m_root + QStringLiteral("/data/aurorae/themes/FixtureDark/close.svg");
        QVERIFY(QFile::link(source, directory + QStringLiteral("/close.svg")));
        QVERIFY(selectTheme("Linked"));
        DecorationButtonProvider provider;
        QVERIFY(provider.closeButtonPath().isEmpty());
    }
};

QTEST_GUILESS_MAIN(DecorationButtonProviderTest)
#include "decorationbuttonprovider_test.moc"
