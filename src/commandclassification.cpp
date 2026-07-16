// SPDX-License-Identifier: GPL-3.0-or-later

#include "commandclassification.h"

#include <KShell>

bool CommandClassification::canResolveToDesktopService(const QString &command)
{
    KShell::Errors error = KShell::NoError;
    const QStringList arguments = KShell::splitArgs(command.trimmed(), KShell::AbortOnMeta, &error);
    return error == KShell::NoError && arguments.size() == 1 && !arguments.constFirst().isEmpty();
}
