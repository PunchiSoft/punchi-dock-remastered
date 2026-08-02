// SPDX-License-Identifier: GPL-3.0-or-later

#include "sessionactionscontroller.h"

#include <sessionmanagement.h>

SessionActionsController::SessionActionsController(QObject *parent)
    : QObject(parent)
    , m_sessionManagement(new SessionManagement(this))
{
    connect(m_sessionManagement, &SessionManagement::stateChanged,
        this, &SessionActionsController::capabilitiesChanged);
    connect(m_sessionManagement, &SessionManagement::canLogoutChanged,
        this, &SessionActionsController::capabilitiesChanged);
    connect(m_sessionManagement, &SessionManagement::canRebootChanged,
        this, &SessionActionsController::capabilitiesChanged);
    connect(m_sessionManagement, &SessionManagement::canShutdownChanged,
        this, &SessionActionsController::capabilitiesChanged);
}

SessionActionsController::~SessionActionsController() = default;

bool SessionActionsController::canLogout() const
{
    return m_sessionManagement->canLogout();
}

bool SessionActionsController::canReboot() const
{
    return m_sessionManagement->canReboot();
}

bool SessionActionsController::canShutdown() const
{
    return m_sessionManagement->canShutdown();
}

void SessionActionsController::requestLogout()
{
    if (canLogout()) {
        m_sessionManagement->requestLogout(
            SessionManagement::ConfirmationMode::ForcePrompt);
    }
}

void SessionActionsController::requestReboot()
{
    if (canReboot()) {
        m_sessionManagement->requestReboot(
            SessionManagement::ConfirmationMode::ForcePrompt);
    }
}

void SessionActionsController::requestShutdown()
{
    if (canShutdown()) {
        m_sessionManagement->requestShutdown(
            SessionManagement::ConfirmationMode::ForcePrompt);
    }
}
