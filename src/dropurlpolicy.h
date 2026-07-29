// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QList>
#include <QString>
#include <QUrl>
#include <QVariantList>

namespace DropUrlPolicy
{
inline constexpr int maximumUrlCount = 64;
inline constexpr qsizetype maximumUrlBytes = 16 * 1024;
inline constexpr qsizetype maximumBatchBytes = 256 * 1024;

struct Result {
    QList<QUrl> urls;
    QString errorCode;

    [[nodiscard]] bool accepted() const
    {
        return errorCode.isEmpty() && !urls.isEmpty();
    }
};

[[nodiscard]] Result validate(const QVariantList &values);
}
