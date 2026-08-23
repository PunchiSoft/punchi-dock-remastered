// SPDX-License-Identifier: GPL-3.0-or-later

#include "punchimenushortcutcontroller.h"

#include <KGlobalAccel>
#include <KLocalizedString>

#include <QAction>
#include <QIcon>
#include <QKeySequence>
#include <QVariant>

namespace
{
constexpr auto TranslationDomain = "plasma_applet_org.kde.plasma.punchi-dock-remastered";
constexpr auto ComponentName = "org.kde.plasma.punchi-dock-remastered";

QString canonicalShortcut(const QString &shortcut)
{
    const QString trimmedShortcut = shortcut.trimmed();
    if (trimmedShortcut.isEmpty()) {
        return QString();
    }

    QKeySequence sequence = QKeySequence::fromString(trimmedShortcut, QKeySequence::PortableText);
    if (sequence.isEmpty()) {
        sequence = QKeySequence::fromString(trimmedShortcut, QKeySequence::NativeText);
    }
    return sequence.toString(QKeySequence::PortableText);
}
}

PunchiMenuShortcutController::PunchiMenuShortcutController(QObject *parent)
    : QObject(parent)
{
}

PunchiMenuShortcutController::~PunchiMenuShortcutController() = default;

uint PunchiMenuShortcutController::instanceId() const
{
    return m_instanceId;
}

void PunchiMenuShortcutController::setInstanceId(uint instanceId)
{
    if (m_instanceId == instanceId) {
        return;
    }

    m_instanceId = instanceId;
    Q_EMIT instanceIdChanged();

    if (m_action) {
        m_action->deleteLater();
        m_action = nullptr;
        m_activeShortcut.clear();
        Q_EMIT activeShortcutChanged();
        updateRegistered(false);
    }
    if (!m_configuredShortcut.isEmpty()) {
        initializeAction();
    }
}

QString PunchiMenuShortcutController::configuredShortcut() const
{
    return m_configuredShortcut;
}

void PunchiMenuShortcutController::setConfiguredShortcut(const QString &shortcut)
{
    const QString normalizedShortcut = canonicalShortcut(shortcut);
    if (m_configuredShortcut == normalizedShortcut) {
        return;
    }

    m_configuredShortcut = normalizedShortcut;
    Q_EMIT configuredShortcutChanged();
    applyConfiguredShortcut();
}

QString PunchiMenuShortcutController::activeShortcut() const
{
    return m_activeShortcut;
}

bool PunchiMenuShortcutController::enabled() const
{
    return m_enabled;
}

void PunchiMenuShortcutController::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }

    m_enabled = enabled;
    if (m_action) {
        m_action->setEnabled(enabled);
    }
    Q_EMIT enabledChanged();
}

bool PunchiMenuShortcutController::registered() const
{
    return m_registered;
}

void PunchiMenuShortcutController::initializeAction()
{
    if (m_action || m_instanceId == 0) {
        return;
    }

    m_action = new QAction(this);
    m_action->setObjectName(QStringLiteral("toggle-punchimenu-%1").arg(m_instanceId));
    m_action->setProperty("componentName", QString::fromLatin1(ComponentName));
    m_action->setProperty("componentDisplayName", i18nd(TranslationDomain, "Punchi Dock Remastered"));
    m_action->setText(i18nd(TranslationDomain, "Open or close PunchiMenu"));
    m_action->setIcon(QIcon::fromTheme(QStringLiteral("start-here-kde")));
    m_action->setShortcutContext(Qt::ApplicationShortcut);
    m_action->setEnabled(m_enabled);

    connect(m_action, &QAction::triggered, this, &PunchiMenuShortcutController::activated);
    connect(KGlobalAccel::self(), &KGlobalAccel::globalShortcutChanged, this,
        [this](QAction *action, const QKeySequence &shortcut) {
            if (action != m_action) {
                return;
            }

            const QString nextShortcut = shortcut.toString(QKeySequence::PortableText);
            if (m_activeShortcut != nextShortcut) {
                m_activeShortcut = nextShortcut;
                Q_EMIT activeShortcutChanged();
            }
        });

    KGlobalAccel::self()->setDefaultShortcut(m_action, {}, KGlobalAccel::NoAutoloading);
    applyConfiguredShortcut();
}

void PunchiMenuShortcutController::applyConfiguredShortcut()
{
    if (!m_action && m_configuredShortcut.isEmpty()) {
        updateRegistered(false);
        return;
    }
    if (!m_action) {
        initializeAction();
    }
    if (!m_action) {
        return;
    }

    const QKeySequence requestedSequence = QKeySequence::fromString(
        m_configuredShortcut, QKeySequence::PortableText);
    const QList<QKeySequence> requestedShortcuts = requestedSequence.isEmpty()
        ? QList<QKeySequence>()
        : QList<QKeySequence>{requestedSequence};

    const bool registrationSucceeded = KGlobalAccel::self()->setShortcut(
        m_action, requestedShortcuts, KGlobalAccel::NoAutoloading);
    updateRegistered(registrationSucceeded);

    const QList<QKeySequence> activeShortcuts = KGlobalAccel::self()->shortcut(m_action);
    const QString nextShortcut = activeShortcuts.isEmpty()
        ? QString()
        : activeShortcuts.constFirst().toString(QKeySequence::PortableText);
    if (m_activeShortcut != nextShortcut) {
        m_activeShortcut = nextShortcut;
        Q_EMIT activeShortcutChanged();
    }

    if (!registrationSucceeded || nextShortcut != m_configuredShortcut) {
        Q_EMIT shortcutRegistrationFailed(m_configuredShortcut);
    }
}

void PunchiMenuShortcutController::updateRegistered(bool registered)
{
    if (m_registered == registered) {
        return;
    }
    m_registered = registered;
    Q_EMIT registeredChanged();
}
