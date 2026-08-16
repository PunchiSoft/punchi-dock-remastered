// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QString>
#include <QStringList>

namespace ApplicationCategoryClassifier
{
[[nodiscard]] QStringList orderedGroups();
[[nodiscard]] bool matches(
    const QStringList &serviceCategories, const QString &requestedGroup);
[[nodiscard]] QString primaryGroup(const QStringList &serviceCategories);
}
