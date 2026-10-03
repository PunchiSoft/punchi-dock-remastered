// SPDX-License-Identifier: GPL-3.0-or-later

#include "decorationbuttonprovider.h"

#include <KConfigGroup>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QXmlStreamReader>

namespace
{
constexpr qint64 maximumSvgBytes = 2 * 1024 * 1024;

bool isButtonSvg(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly) || file.size() <= 0 || file.size() > maximumSvgBytes) {
        return false;
    }
    QXmlStreamReader xml(file.read(maximumSvgBytes + 1));
    bool svg = false;
    bool activeCenter = false;
    while (!xml.atEnd()) {
        xml.readNext();
        if (xml.isStartElement()) {
            if (!svg) {
                if (xml.name() != QLatin1String("svg")) {
                    return false;
                }
                svg = true;
            }
            activeCenter |= xml.attributes().value(QLatin1String("id")) == QLatin1String("active-center");
        }
    }
    return svg && activeCenter && !xml.hasError();
}

void addExistingPath(QStringList &paths, const QString &path)
{
    if (!path.isEmpty() && QFileInfo::exists(path) && !paths.contains(path)) {
        paths.append(path);
    }
}
}

DecorationButtonProvider::DecorationButtonProvider(QObject *parent)
    : QObject(parent)
    , m_config(KSharedConfig::openConfig(QStringLiteral("kwinrc")))
    , m_configWatcher(KConfigWatcher::create(m_config))
{
    connect(m_configWatcher.data(), &KConfigWatcher::configChanged, this,
        [this](const KConfigGroup &group, const QByteArrayList &) {
            if (group.name() == QLatin1String("org.kde.kdecoration2")) {
                refresh();
            }
        });
    connect(&m_files, &QFileSystemWatcher::fileChanged, this, &DecorationButtonProvider::refresh);
    connect(&m_files, &QFileSystemWatcher::directoryChanged, this, &DecorationButtonProvider::refresh);
    refresh();
}

void DecorationButtonProvider::refresh()
{
    m_config->reparseConfiguration();
    const KConfigGroup decoration(m_config, QStringLiteral("org.kde.kdecoration2"));
    const QString plugin = decoration.readEntry("library", QString());
    const QString theme = decoration.readEntry("theme", QString());
    const QString prefix = QStringLiteral("__aurorae__svg__");
    QString themeName;
    QString imagePath;
    QSizeF buttonSize(16, 16);
    QStringList watchPaths;

    // Watching the containing directory also observes atomic replacement of kwinrc.
    for (const QString &directory : QStandardPaths::standardLocations(QStandardPaths::ConfigLocation)) {
        addExistingPath(watchPaths, directory + QStringLiteral("/kwinrc"));
    }
    addExistingPath(watchPaths, QStandardPaths::writableLocation(QStandardPaths::ConfigLocation));

    if ((plugin == QLatin1String("org.kde.kwin.aurorae.v2")
            || plugin == QLatin1String("org.kde.kwin.aurorae")) && theme.startsWith(prefix)) {
        themeName = theme.mid(prefix.size());
        // Theme identifiers must name one installed directory, never an arbitrary path.
        if (themeName.isEmpty() || themeName == QLatin1String(".") || themeName == QLatin1String("..")
            || themeName.contains(QLatin1Char('/')) || themeName.contains(QLatin1Char('\\'))) {
            themeName.clear();
        } else {
            const QString relativeDirectory = QStringLiteral("aurorae/themes/") + themeName;
            const QString directory = QStandardPaths::locate(QStandardPaths::GenericDataLocation,
                relativeDirectory, QStandardPaths::LocateDirectory);
            if (!directory.isEmpty()) {
                const QString canonicalDirectory = QFileInfo(directory).canonicalFilePath();
                const QString closePath = directory + QStringLiteral("/close.svg");
                const QString canonicalClosePath = QFileInfo(closePath).canonicalFilePath();
                const QString rcPath = directory + QLatin1Char('/') + themeName + QStringLiteral("rc");
                addExistingPath(watchPaths, directory);
                addExistingPath(watchPaths, closePath);
                addExistingPath(watchPaths, rcPath);
                if (!canonicalDirectory.isEmpty()
                    && canonicalClosePath.startsWith(canonicalDirectory + QLatin1Char('/'))
                    && isButtonSvg(canonicalClosePath)) {
                    imagePath = canonicalClosePath;
                    KConfig themeConfig(rcPath, KConfig::SimpleConfig);
                    const KConfigGroup layout(&themeConfig, QStringLiteral("Layout"));
                    buttonSize = QSizeF(qBound(8, layout.readEntry("ButtonWidth", 16), 64),
                        qBound(8, layout.readEntry("ButtonHeight", 16), 64));
                }
            }
        }
    }

    // Re-arm file watches after replacements and stop following the previous theme.
    const QStringList oldPaths = m_files.files() + m_files.directories();
    if (!oldPaths.isEmpty()) {
        m_files.removePaths(oldPaths);
    }
    if (!watchPaths.isEmpty()) {
        m_files.addPaths(watchPaths);
    }
    if (m_closeButtonPath == imagePath && m_themeName == themeName && m_buttonSize == buttonSize) {
        return;
    }
    m_closeButtonPath = imagePath;
    m_themeName = themeName;
    m_buttonSize = buttonSize;
    Q_EMIT appearanceChanged();
}
