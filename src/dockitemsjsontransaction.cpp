// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockitemsjsontransaction.h"

#include "punchimenulayoutdocument.h"

#include <KConfig>
#include <KConfigGroup>
#include <KCoreConfigSkeleton>

#include <QByteArray>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>

namespace
{
constexpr auto DockItemsJsonEntry = "dockItemsJson";
constexpr auto PunchiMenuType = "punchimenu";
constexpr auto ApplicationLayoutEntry = "applicationLayout";

QString valueFromConfig(
    KConfig *config, const KConfigSkeletonItem *item)
{
    if (!config || !item) {
        return {};
    }
    const KConfigGroup group(config, item->group());
    return group.readEntry(item->key(), item->getDefault().toString());
}

QString durableValue(
    const KConfig *sourceConfig, const KConfigSkeletonItem *item)
{
    if (!sourceConfig || !item || sourceConfig->name().isEmpty()) {
        return {};
    }
    KConfig durableConfig(
        sourceConfig->name(), KConfig::SimpleConfig,
        sourceConfig->locationType());
    return valueFromConfig(&durableConfig, item);
}

bool hasCanonicalPunchiMenuLayouts(const QJsonArray &items)
{
    for (const QJsonValue &value : items) {
        if (!value.isObject()) {
            continue;
        }
        const QJsonObject item = value.toObject();
        if (item.value(QStringLiteral("type")).toString()
                != QLatin1String(PunchiMenuType)
            || !item.contains(QString::fromLatin1(ApplicationLayoutEntry))) {
            continue;
        }

        const QJsonValue layoutValue = item.value(
            QString::fromLatin1(ApplicationLayoutEntry));
        if (!layoutValue.isObject()) {
            return false;
        }
        const QJsonObject requestedLayout = layoutValue.toObject();
        const PunchiMenuLayoutDocument::Result normalized
            = PunchiMenuLayoutDocument::sanitize(
                requestedLayout.toVariantMap());
        if (!normalized.success
            || QJsonObject::fromVariantMap(normalized.document)
                != requestedLayout) {
            return false;
        }
    }
    return true;
}

DockItemsJsonTransaction::Result validateCandidate(const QString &candidate)
{
    if (candidate.size() > DockItemsJsonTransaction::MaximumJsonBytes) {
        return {
            false,
            QStringLiteral("json-too-large"),
            {},
            false,
            false,
        };
    }

    const QByteArray utf8 = candidate.toUtf8();
    if (utf8.size() > DockItemsJsonTransaction::MaximumJsonBytes) {
        return {
            false,
            QStringLiteral("json-too-large"),
            {},
            false,
            false,
        };
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(utf8, &parseError);
    if (parseError.error != QJsonParseError::NoError || document.isNull()) {
        return {
            false,
            QStringLiteral("invalid-json"),
            {},
            false,
            false,
        };
    }
    if (!document.isArray()) {
        return {
            false,
            QStringLiteral("root-not-array"),
            {},
            false,
            false,
        };
    }
    const QJsonArray items = document.array();
    if (items.size() > DockItemsJsonTransaction::MaximumItemCount) {
        return {
            false,
            QStringLiteral("too-many-items"),
            {},
            false,
            false,
        };
    }
    if (!hasCanonicalPunchiMenuLayouts(items)) {
        return {
            false,
            QStringLiteral("invalid-application-layout"),
            {},
            false,
            false,
        };
    }

    return {
        true,
        {},
        candidate,
        false,
        false,
    };
}
}

QVariantMap DockItemsJsonTransaction::Result::toVariantMap() const
{
    return {
        {QStringLiteral("success"), success},
        {QStringLiteral("errorCode"), errorCode},
        {QStringLiteral("currentJson"), currentJson},
        {QStringLiteral("changed"), changed},
        {QStringLiteral("rolledBack"), rolledBack},
    };
}

DockItemsJsonTransaction::Result DockItemsJsonTransaction::commit(
    KCoreConfigSkeleton *configuration,
    State &state,
    const QString &expectedRaw,
    const QString &nextRaw,
    SyncFunction syncFunction)
{
    if (!configuration) {
        return failure(QStringLiteral("configuration-unavailable"));
    }

    KConfigSkeletonItem *const item = configuration->findItem(
        QString::fromLatin1(DockItemsJsonEntry));
    if (!item) {
        return failure(QStringLiteral("entry-unavailable"));
    }

    KConfig *const sourceConfig = configuration->config();
    if (!sourceConfig || sourceConfig->name().isEmpty()) {
        return failure(QStringLiteral("configuration-unavailable"));
    }

    const QString previous = item->property().toString();
    if (item->isImmutable()) {
        return failure(QStringLiteral("entry-immutable"), previous);
    }
    if (previous != expectedRaw) {
        return failure(QStringLiteral("conflict"), previous);
    }

    if (nextRaw.size() > MaximumJsonBytes) {
        return failure(QStringLiteral("json-too-large"), previous);
    }
    const QString candidate = nextRaw.trimmed().isEmpty()
        ? QStringLiteral("[]")
        : nextRaw;
    Result validation = validateCandidate(candidate);
    if (!validation.success) {
        validation.currentJson = previous;
        return validation;
    }
    const QString cached = valueFromConfig(sourceConfig, item);
    const QString durable = durableValue(sourceConfig, item);
    if (!state.initialized) {
        state.knownDurable = cached;
        state.initialized = true;
    }
    if (durable != expectedRaw
        && (!item->isSaveNeeded() || durable != state.knownDurable)) {
        return failure(QStringLiteral("conflict"), durable);
    }
    if (previous == candidate && durable == candidate) {
        KConfig durableConfig(
            sourceConfig->name(), KConfig::SimpleConfig,
            sourceConfig->locationType());
        item->readConfig(&durableConfig);
        state.knownDurable = candidate;
        return {
            true,
            {},
            previous,
            false,
            false,
        };
    }

    KConfig isolatedConfig(
        sourceConfig->name(), KConfig::SimpleConfig,
        sourceConfig->locationType());
    KConfigGroup isolatedGroup(&isolatedConfig, item->group());
    const QString key = item->key();
    const QString defaultValue = item->getDefault().toString();
    if (candidate == defaultValue && !isolatedGroup.hasDefault(key)) {
        isolatedGroup.revertToDefault(key, item->writeFlags());
    } else {
        isolatedGroup.writeEntry(key, candidate, item->writeFlags());
    }

    if (syncFunction) {
        (void)syncFunction(isolatedConfig);
    } else {
        (void)isolatedConfig.sync();
    }

    isolatedConfig.markAsClean();
    const QString recovered = durableValue(sourceConfig, item);
    if (recovered == candidate) {
        item->readConfig(&isolatedConfig);
        state.knownDurable = candidate;
        Q_EMIT configuration->configChanged();
        return {
            true,
            {},
            candidate,
            true,
            false,
        };
    }
    return failure(QStringLiteral("persistence-failed"), recovered,
        recovered != expectedRaw, false);
}

DockItemsJsonTransaction::Result DockItemsJsonTransaction::reconcile(
    KCoreConfigSkeleton *configuration,
    State &state,
    const QString &expectedDurable)
{
    if (!configuration) {
        return failure(QStringLiteral("configuration-unavailable"));
    }
    KConfigSkeletonItem *const item = configuration->findItem(
        QString::fromLatin1(DockItemsJsonEntry));
    KConfig *const sourceConfig = configuration->config();
    if (!item || !sourceConfig || sourceConfig->name().isEmpty()) {
        return failure(item ? QStringLiteral("configuration-unavailable")
                            : QStringLiteral("entry-unavailable"));
    }

    KConfig durableConfig(
        sourceConfig->name(), KConfig::SimpleConfig,
        sourceConfig->locationType());
    const QString durable = valueFromConfig(&durableConfig, item);
    if (durable != expectedDurable) {
        return failure(QStringLiteral("conflict"), durable);
    }

    const QString candidate = durable.trimmed().isEmpty()
        ? QStringLiteral("[]")
        : durable;
    Result validation = validateCandidate(candidate);
    if (!validation.success) {
        validation.currentJson = durable;
        return validation;
    }

    const QString previous = item->property().toString();
    item->readConfig(&durableConfig);
    state.knownDurable = durable;
    state.initialized = true;
    Q_EMIT configuration->configChanged();
    return {
        true,
        {},
        durable,
        previous != durable,
        false,
    };
}

DockItemsJsonTransaction::Result DockItemsJsonTransaction::failure(
    const QString &errorCode,
    const QString &currentJson,
    bool changed,
    bool rolledBack)
{
    return {
        false,
        errorCode,
        currentJson,
        changed,
        rolledBack,
    };
}
