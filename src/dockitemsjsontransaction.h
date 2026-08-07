// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QString>
#include <QVariantMap>
#include <QtGlobal>

#include <functional>

class KConfig;
class KCoreConfigSkeleton;

class DockItemsJsonTransaction final
{
public:
    using SyncFunction = std::function<bool(KConfig &)>;

    static constexpr qsizetype MaximumJsonBytes = 1024 * 1024;
    static constexpr qsizetype MaximumItemCount = 512;

    struct Result {
        bool success = false;
        QString errorCode;
        QString currentJson;
        bool changed = false;
        bool rolledBack = false;

        [[nodiscard]] QVariantMap toVariantMap() const;
    };

    struct State {
        QString knownDurable;
        bool initialized = false;
    };

    [[nodiscard]] static Result commit(
        KCoreConfigSkeleton *configuration,
        State &state,
        const QString &expectedRaw,
        const QString &nextRaw,
        SyncFunction syncFunction = {});
    [[nodiscard]] static Result reconcile(
        KCoreConfigSkeleton *configuration,
        State &state,
        const QString &expectedDurable);

private:
    [[nodiscard]] static Result failure(
        const QString &errorCode,
        const QString &currentJson = QString(),
        bool changed = false,
        bool rolledBack = false);
};
