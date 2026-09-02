// SPDX-License-Identifier: GPL-2.0-or-later

#include "controlcenterthemeadapter.h"

#include <KConfigGroup>
#include <KPackage/PackageLoader>

#include <QEvent>
#include <QGuiApplication>
#include <QPalette>
#include <QProcess>
#include <QStandardPaths>

namespace
{
constexpr auto s_lightThemeFallback = "org.kde.breeze.desktop";
constexpr auto s_darkThemeFallback = "org.kde.breezedark.desktop";
}

ControlCenterThemeAdapter::ControlCenterThemeAdapter(QObject *parent)
    : QObject(parent)
    , m_config(KSharedConfig::openConfig())
    , m_configWatcher(KConfigWatcher::create(m_config))
    , m_process(new QProcess(this))
    , m_executablePath(QStandardPaths::findExecutable(QStringLiteral("plasma-apply-lookandfeel")))
{
    connect(m_configWatcher.data(), &KConfigWatcher::configChanged, this, [this](const KConfigGroup &group, const QByteArrayList &keys) {
        if (group.name() != QLatin1String("KDE")) {
            return;
        }

        if (keys.contains(QByteArrayLiteral("LookAndFeelPackage"))
            || keys.contains(QByteArrayLiteral("DefaultLightLookAndFeel"))
            || keys.contains(QByteArrayLiteral("DefaultDarkLookAndFeel"))) {
            refresh();
        }
    });
    connect(m_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this, [this]() {
        m_busy = false;
        refresh();
        Q_EMIT stateChanged();
    });
    connect(m_process, &QProcess::errorOccurred, this, [this]() {
        m_busy = false;
        m_executablePath = QStandardPaths::findExecutable(QStringLiteral("plasma-apply-lookandfeel"));
        refresh();
        Q_EMIT stateChanged();
    });
    qGuiApp->installEventFilter(this);
    refresh();
}

bool ControlCenterThemeAdapter::available() const
{
    return m_available;
}

bool ControlCenterThemeAdapter::darkMode() const
{
    return m_darkMode;
}

bool ControlCenterThemeAdapter::busy() const
{
    return m_busy;
}

QString ControlCenterThemeAdapter::lightThemeId() const
{
    return m_lightThemeId;
}

QString ControlCenterThemeAdapter::darkThemeId() const
{
    return m_darkThemeId;
}

bool ControlCenterThemeAdapter::toggleMode()
{
    if (!m_available) {
        return false;
    }
    if (m_busy) {
        return true;
    }

    const QString targetThemeId = m_darkMode ? m_lightThemeId : m_darkThemeId;
    m_busy = true;
    Q_EMIT stateChanged();
    m_process->start(m_executablePath, {QStringLiteral("--apply"), targetThemeId});
    return true;
}

bool ControlCenterThemeAdapter::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == qGuiApp && event->type() == QEvent::ApplicationPaletteChange) {
        refresh();
    }
    return QObject::eventFilter(watched, event);
}

void ControlCenterThemeAdapter::refresh()
{
    m_config->reparseConfiguration();
    const KConfigGroup group(m_config, QStringLiteral("KDE"));
    const QString lightThemeId = group.readEntry("DefaultLightLookAndFeel", QString::fromLatin1(s_lightThemeFallback));
    const QString darkThemeId = group.readEntry("DefaultDarkLookAndFeel", QString::fromLatin1(s_darkThemeFallback));
    const QString currentThemeId = group.readEntry("LookAndFeelPackage", lightThemeId);

    bool darkMode = false;
    if (currentThemeId == darkThemeId) {
        darkMode = true;
    } else if (currentThemeId != lightThemeId) {
        darkMode = qGuiApp->palette().color(QPalette::Window).lightnessF() < 0.5;
    }

    const bool available = !m_executablePath.isEmpty()
        && !lightThemeId.isEmpty() && !darkThemeId.isEmpty()
        && lightThemeId != darkThemeId && packageAvailable(lightThemeId) && packageAvailable(darkThemeId);

    if (m_lightThemeId == lightThemeId && m_darkThemeId == darkThemeId && m_available == available && m_darkMode == darkMode) {
        return;
    }

    m_lightThemeId = lightThemeId;
    m_darkThemeId = darkThemeId;
    m_available = available;
    m_darkMode = darkMode;
    Q_EMIT stateChanged();
}

bool ControlCenterThemeAdapter::packageAvailable(const QString &packageId) const
{
    KPackage::Package package = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/LookAndFeel"));
    package.setPath(packageId);
    return package.metadata().pluginId() == packageId;
}
