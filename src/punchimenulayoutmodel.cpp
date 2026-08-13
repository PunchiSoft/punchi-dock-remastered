// SPDX-License-Identifier: GPL-3.0-or-later

#include "punchimenulayoutmodel.h"

#include "punchimenulayoutdocument.h"

#include <QCollator>
#include <QMetaType>
#include <QSet>

#include <algorithm>

namespace
{
constexpr auto applicationNodeType = "application";
constexpr auto folderNodeType = "folder";
constexpr qsizetype maximumApplicationNameLength = 256;
constexpr qsizetype maximumApplicationIconLength = 512;
constexpr qsizetype maximumFolderPreviewIcons = 4;
constexpr qsizetype maximumInputEntriesToInspect
    = PunchiMenuLayoutDocument::MaximumApplicationReferences * 4;

QString identityKey(const QString &value)
{
    return value;
}

bool isRestrictedDisplayCodePoint(uint codePoint)
{
    return codePoint < 0x20 || (codePoint >= 0x7f && codePoint <= 0x9f)
        || codePoint == 0x200e || codePoint == 0x200f
        || (codePoint >= 0x202a && codePoint <= 0x202e)
        || (codePoint >= 0x2066 && codePoint <= 0x2069)
        || codePoint == 0x2028 || codePoint == 0x2029
        || codePoint == 0xfeff;
}

QString boundedDisplayText(
    const QVariant &value, qsizetype maximumLength, const QString &fallback = {})
{
    QString result;
    const QString requested = value.toString();
    result.reserve(std::min(requested.size(), maximumLength));
    const qsizetype inputLimit = std::min(requested.size(), maximumLength * 8);
    qsizetype offset = 0;
    while (offset < inputLimit && result.size() < maximumLength) {
        const QChar first = requested.at(offset++);
        uint codePoint = first.unicode();
        if (first.isHighSurrogate()) {
            if (offset >= inputLimit || !requested.at(offset).isLowSurrogate()) {
                continue;
            }
            codePoint = QChar::surrogateToUcs4(
                first.unicode(), requested.at(offset++).unicode());
        } else if (first.isLowSurrogate()) {
            continue;
        }
        if (isRestrictedDisplayCodePoint(codePoint)) {
            continue;
        }
        const char32_t scalar = static_cast<char32_t>(codePoint);
        const QString character = QString::fromUcs4(&scalar, 1);
        if (result.size() + character.size() > maximumLength) {
            break;
        }
        result.append(character);
    }
    result = result.trimmed();
    return result.isEmpty() ? fallback : result;
}

QVariant mappedApplicationValue(
    const QVariantMap &application, const char *primaryKey, const char *legacyKey)
{
    const QString primary = QString::fromLatin1(primaryKey);
    if (application.contains(primary)) {
        return application.value(primary);
    }
    return application.value(QString::fromLatin1(legacyKey));
}

QVariantMap applicationRow(const QVariantMap &application)
{
    QVariantMap row = application;
    row.insert(QStringLiteral("nodeType"),
        QString::fromLatin1(applicationNodeType));
    const QString nodeId = QString(QStringLiteral("application:")
        + application.value(QStringLiteral("storageId")).toString());
    row.insert(QStringLiteral("nodeId"), nodeId);
    row.insert(QStringLiteral("appStorageId"),
        application.value(QStringLiteral("storageId")));
    row.insert(QStringLiteral("appName"),
        application.value(QStringLiteral("name")));
    row.insert(QStringLiteral("appIcon"),
        application.value(QStringLiteral("icon")));
    row.insert(QStringLiteral("appHidden"),
        application.value(QStringLiteral("hidden"), false));
    return row;
}

QString nodeDisplayLabel(const QVariantMap &node)
{
    return node.value(node.value(QStringLiteral("nodeType")).toString()
                == QLatin1String(folderNodeType)
            ? QStringLiteral("folderLabel")
            : QStringLiteral("appName"))
        .toString();
}
}

PunchiMenuLayoutModel::PunchiMenuLayoutModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_layoutDocument(PunchiMenuLayoutDocument::emptyDocument())
{
    rebuildNodes();
}

int PunchiMenuLayoutModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_nodes.size();
}

QVariant PunchiMenuLayoutModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_nodes.size()) {
        return {};
    }

    const QVariantMap node = m_nodes.at(index.row()).toMap();
    switch (role) {
    case Qt::DisplayRole:
        return node.value(node.value(QStringLiteral("nodeType")).toString()
                    == QLatin1String(folderNodeType)
                ? QStringLiteral("folderLabel")
                : QStringLiteral("appName"));
    case NodeTypeRole:
        return node.value(QStringLiteral("nodeType"));
    case NodeIdRole:
        return node.value(QStringLiteral("nodeId"));
    case AppStorageIdRole:
        return node.value(QStringLiteral("appStorageId"));
    case AppNameRole:
        return node.value(QStringLiteral("appName"));
    case AppIconRole:
        return node.value(QStringLiteral("appIcon"));
    case AppHiddenRole:
        return node.value(QStringLiteral("appHidden"));
    case FolderIdRole:
        return node.value(QStringLiteral("folderId"));
    case FolderLabelRole:
        return node.value(QStringLiteral("folderLabel"));
    case FolderMembersRole:
        return node.value(QStringLiteral("folderMembers"));
    case FolderMemberCountRole:
        return node.value(QStringLiteral("folderMemberCount"));
    case FolderPreviewIconsRole:
        return node.value(QStringLiteral("folderPreviewIcons"));
    default:
        return {};
    }
}

QHash<int, QByteArray> PunchiMenuLayoutModel::roleNames() const
{
    return {
        {NodeTypeRole, QByteArrayLiteral("nodeType")},
        {NodeIdRole, QByteArrayLiteral("nodeId")},
        {AppStorageIdRole, QByteArrayLiteral("appStorageId")},
        {AppNameRole, QByteArrayLiteral("appName")},
        {AppIconRole, QByteArrayLiteral("appIcon")},
        {AppHiddenRole, QByteArrayLiteral("appHidden")},
        {FolderIdRole, QByteArrayLiteral("folderId")},
        {FolderLabelRole, QByteArrayLiteral("folderLabel")},
        {FolderMembersRole, QByteArrayLiteral("folderMembers")},
        {FolderMemberCountRole, QByteArrayLiteral("folderMemberCount")},
        {FolderPreviewIconsRole, QByteArrayLiteral("folderPreviewIcons")},
    };
}

QVariantList PunchiMenuLayoutModel::applications() const
{
    return m_applications;
}

void PunchiMenuLayoutModel::setApplications(const QVariantList &applications)
{
    const QVariantList normalized = normalizedApplications(applications);
    if (m_applications == normalized) {
        return;
    }

    m_applications = normalized;
    rebuildNodes();
    Q_EMIT applicationsChanged();
}

QVariantMap PunchiMenuLayoutModel::layoutDocument() const
{
    return m_layoutDocument;
}

void PunchiMenuLayoutModel::setLayoutDocument(const QVariantMap &document)
{
    const PunchiMenuLayoutDocument::Result normalized
        = PunchiMenuLayoutDocument::sanitize(document);
    if (!normalized.success) {
        setLastErrorCode(normalized.errorCode);
        Q_EMIT validationFailed(normalized.errorCode);
        return;
    }

    setLastErrorCode({});
    if (m_layoutDocument == normalized.document) {
        return;
    }

    m_layoutDocument = normalized.document;
    rebuildNodes();
    Q_EMIT layoutDocumentChanged();
}

QStringList PunchiMenuLayoutModel::hiddenApplicationIds() const
{
    return m_hiddenApplicationIds;
}

void PunchiMenuLayoutModel::setHiddenApplicationIds(
    const QStringList &storageIds)
{
    QStringList normalized;
    QSet<QString> seen;
    normalized.reserve(std::min(storageIds.size(),
        qsizetype(PunchiMenuLayoutDocument::MaximumApplicationReferences)));
    const qsizetype inputLimit
        = std::min(storageIds.size(), maximumInputEntriesToInspect);
    for (qsizetype index = 0; index < inputLimit; ++index) {
        const QString &requestedStorageId = storageIds.at(index);
        const QString storageId
            = PunchiMenuLayoutDocument::normalizedStorageId(requestedStorageId);
        const QString key = identityKey(storageId);
        if (storageId.isEmpty() || seen.contains(key)) {
            continue;
        }
        seen.insert(key);
        normalized.append(storageId);
        if (normalized.size()
            >= PunchiMenuLayoutDocument::MaximumApplicationReferences) {
            break;
        }
    }

    if (m_hiddenApplicationIds == normalized) {
        return;
    }
    m_hiddenApplicationIds = normalized;
    rebuildNodes();
    Q_EMIT hiddenApplicationIdsChanged();
}

bool PunchiMenuLayoutModel::revealHiddenApplications() const
{
    return m_revealHiddenApplications;
}

void PunchiMenuLayoutModel::setRevealHiddenApplications(bool reveal)
{
    if (m_revealHiddenApplications == reveal) {
        return;
    }
    m_revealHiddenApplications = reveal;
    rebuildNodes();
    Q_EMIT revealHiddenApplicationsChanged();
}

bool PunchiMenuLayoutModel::alphabeticalSortingEnabled() const
{
    return m_alphabeticalSortingEnabled;
}

void PunchiMenuLayoutModel::setAlphabeticalSortingEnabled(bool enabled)
{
    if (m_alphabeticalSortingEnabled == enabled) {
        return;
    }

    m_alphabeticalSortingEnabled = enabled;
    rebuildNodes();
    Q_EMIT alphabeticalSortingEnabledChanged();
}

QVariantMap PunchiMenuLayoutModel::effectiveLayoutDocument() const
{
    return m_effectiveLayoutDocument;
}

QVariantList PunchiMenuLayoutModel::nodes() const
{
    return m_nodes;
}

int PunchiMenuLayoutModel::folderChoiceCount() const
{
    return folderChoices().size();
}

QString PunchiMenuLayoutModel::lastErrorCode() const
{
    return m_lastErrorCode;
}

int PunchiMenuLayoutModel::indexForNodeId(const QString &nodeId) const
{
    for (int index = 0; index < m_nodes.size(); ++index) {
        if (m_nodes.at(index).toMap().value(QStringLiteral("nodeId")).toString()
            == nodeId) {
            return index;
        }
    }
    return -1;
}

int PunchiMenuLayoutModel::indexForFolder(const QString &folderId) const
{
    const QString normalizedId
        = PunchiMenuLayoutDocument::normalizedFolderId(folderId);
    if (normalizedId.isEmpty()) {
        return -1;
    }
    return indexForNodeId(QStringLiteral("folder:") + normalizedId);
}

QVariantMap PunchiMenuLayoutModel::applicationPlacement(
    const QString &storageId) const
{
    const QString normalizedId
        = PunchiMenuLayoutDocument::normalizedStorageId(storageId);
    QVariantMap result{
        {QStringLiteral("found"), false},
        {QStringLiteral("available"), false},
        {QStringLiteral("visible"), false},
        {QStringLiteral("storageId"), normalizedId},
        {QStringLiteral("placement"), QStringLiteral("missing")},
        {QStringLiteral("nodeId"), QString{}},
        {QStringLiteral("folderId"), QString{}},
    };
    if (normalizedId.isEmpty()) {
        return result;
    }

    for (const QVariant &applicationValue : m_applications) {
        if (applicationValue.toMap().value(QStringLiteral("storageId")).toString()
            == normalizedId) {
            result.insert(QStringLiteral("available"), true);
            break;
        }
    }

    const QVariantList documentNodes
        = m_effectiveLayoutDocument.value(QStringLiteral("nodes")).toList();
    for (const QVariant &nodeValue : documentNodes) {
        const QVariantMap node = nodeValue.toMap();
        if (node.value(QStringLiteral("type")).toString()
            == QLatin1String(applicationNodeType)) {
            if (node.value(QStringLiteral("storageId")).toString()
                != normalizedId) {
                continue;
            }
            const QString nodeId
                = QStringLiteral("application:") + normalizedId;
            result.insert(QStringLiteral("found"), true);
            result.insert(QStringLiteral("placement"),
                QStringLiteral("standalone"));
            result.insert(QStringLiteral("nodeId"), nodeId);
            result.insert(QStringLiteral("visible"),
                indexForNodeId(nodeId) >= 0);
            return result;
        }

        const QVariantList members
            = node.value(QStringLiteral("members")).toList();
        for (const QVariant &memberValue : members) {
            if (memberValue.toString() != normalizedId) {
                continue;
            }
            const QString folderId
                = node.value(QStringLiteral("folderId")).toString();
            const QString nodeId = QStringLiteral("folder:") + folderId;
            bool memberVisible = false;
            const int folderRow = indexForNodeId(nodeId);
            if (folderRow >= 0) {
                const QVariantList visibleMembers = m_nodes.at(folderRow)
                                                        .toMap()
                                                        .value(QStringLiteral(
                                                            "folderMembers"))
                                                        .toList();
                for (const QVariant &visibleMemberValue : visibleMembers) {
                    if (visibleMemberValue.toMap()
                            .value(QStringLiteral("appStorageId"))
                            .toString()
                        == normalizedId) {
                        memberVisible = true;
                        break;
                    }
                }
            }
            result.insert(QStringLiteral("found"), true);
            result.insert(QStringLiteral("placement"),
                QStringLiteral("folder"));
            result.insert(QStringLiteral("nodeId"), nodeId);
            result.insert(QStringLiteral("folderId"), folderId);
            result.insert(QStringLiteral("visible"), memberVisible);
            return result;
        }
    }

    return result;
}

QVariantMap PunchiMenuLayoutModel::folderInfo(const QString &folderId) const
{
    const QString normalizedId
        = PunchiMenuLayoutDocument::normalizedFolderId(folderId);
    const QString nodeId = normalizedId.isEmpty()
        ? QString{}
        : QStringLiteral("folder:") + normalizedId;
    QVariantMap result{
        {QStringLiteral("found"), false},
        {QStringLiteral("folderId"), normalizedId},
        {QStringLiteral("nodeId"), nodeId},
        {QStringLiteral("label"), QString{}},
        {QStringLiteral("visible"), false},
        {QStringLiteral("storedMemberCount"), 0},
        {QStringLiteral("visibleMemberCount"), 0},
        {QStringLiteral("members"), QVariantList{}},
        {QStringLiteral("previewIcons"), QVariantList{}},
        {QStringLiteral("canAcceptMembers"), false},
    };
    if (normalizedId.isEmpty()) {
        return result;
    }

    const QVariantList documentNodes
        = m_effectiveLayoutDocument.value(QStringLiteral("nodes")).toList();
    QVariantMap folderNode;
    for (const QVariant &nodeValue : documentNodes) {
        const QVariantMap node = nodeValue.toMap();
        if (node.value(QStringLiteral("type")).toString()
                == QLatin1String(folderNodeType)
            && node.value(QStringLiteral("folderId")).toString()
                == normalizedId) {
            folderNode = node;
            break;
        }
    }
    if (folderNode.isEmpty()) {
        return result;
    }

    const int storedMemberCount
        = folderNode.value(QStringLiteral("members")).toList().size();
    result.insert(QStringLiteral("found"), true);
    result.insert(QStringLiteral("label"),
        folderNode.value(QStringLiteral("label")));
    result.insert(QStringLiteral("storedMemberCount"), storedMemberCount);
    result.insert(QStringLiteral("canAcceptMembers"),
        storedMemberCount < PunchiMenuLayoutDocument::MaximumFolderMembers);

    const int row = indexForNodeId(nodeId);
    if (row < 0) {
        return result;
    }

    const QVariantMap visibleFolder = m_nodes.at(row).toMap();
    const QVariantList members
        = visibleFolder.value(QStringLiteral("folderMembers")).toList();
    result.insert(QStringLiteral("visible"), true);
    result.insert(QStringLiteral("visibleMemberCount"), members.size());
    result.insert(QStringLiteral("members"), members);
    result.insert(QStringLiteral("previewIcons"),
        visibleFolder.value(QStringLiteral("folderPreviewIcons")));
    return result;
}

QVariantList PunchiMenuLayoutModel::folderChoices() const
{
    QVariantList result;
    const QVariantList documentNodes
        = m_effectiveLayoutDocument.value(QStringLiteral("nodes")).toList();
    for (const QVariant &nodeValue : documentNodes) {
        const QVariantMap node = nodeValue.toMap();
        if (node.value(QStringLiteral("type")).toString()
            != QLatin1String(folderNodeType)) {
            continue;
        }
        const QVariantMap info = folderInfo(
            node.value(QStringLiteral("folderId")).toString());
        if (!info.value(QStringLiteral("visible")).toBool()) {
            continue;
        }
        result.append(QVariantMap{
            {QStringLiteral("folderId"),
                info.value(QStringLiteral("folderId"))},
            {QStringLiteral("nodeId"),
                info.value(QStringLiteral("nodeId"))},
            {QStringLiteral("label"), info.value(QStringLiteral("label"))},
            {QStringLiteral("storedMemberCount"),
                info.value(QStringLiteral("storedMemberCount"))},
            {QStringLiteral("visibleMemberCount"),
                info.value(QStringLiteral("visibleMemberCount"))},
            {QStringLiteral("canAcceptMembers"),
                info.value(QStringLiteral("canAcceptMembers"))},
        });
    }
    return result;
}

QVariantList PunchiMenuLayoutModel::normalizedApplications(
    const QVariantList &applications)
{
    QVariantList result;
    result.reserve(std::min(applications.size(),
        qsizetype(PunchiMenuLayoutDocument::MaximumApplicationReferences)));
    QSet<QString> seen;

    const qsizetype inputLimit
        = std::min(applications.size(), maximumInputEntriesToInspect);
    for (qsizetype index = 0; index < inputLimit; ++index) {
        const QVariant &applicationValue = applications.at(index);
        if (applicationValue.metaType().id() != QMetaType::QVariantMap) {
            continue;
        }

        const QVariantMap requested = applicationValue.toMap();
        const QString storageId = PunchiMenuLayoutDocument::normalizedStorageId(
            mappedApplicationValue(requested, "storageId", "appStorageId"));
        const QString key = identityKey(storageId);
        if (storageId.isEmpty() || seen.contains(key)) {
            continue;
        }

        const QString name = boundedDisplayText(
            mappedApplicationValue(requested, "name", "appName"),
            maximumApplicationNameLength, storageId);
        const QString icon = boundedDisplayText(
            mappedApplicationValue(requested, "icon", "appIcon"),
            maximumApplicationIconLength,
            QStringLiteral("application-x-executable"));
        seen.insert(key);
        result.append(QVariantMap{
            {QStringLiteral("storageId"), storageId},
            {QStringLiteral("name"), name},
            {QStringLiteral("icon"), icon},
        });
        if (result.size()
            >= PunchiMenuLayoutDocument::MaximumApplicationReferences) {
            break;
        }
    }

    return result;
}

QStringList PunchiMenuLayoutModel::applicationStorageIds() const
{
    QStringList result;
    result.reserve(m_applications.size());
    for (const QVariant &applicationValue : m_applications) {
        result.append(applicationValue.toMap()
                          .value(QStringLiteral("storageId"))
                          .toString());
    }
    return result;
}

void PunchiMenuLayoutModel::rebuildNodes()
{
    PunchiMenuLayoutDocument::Result effective
        = PunchiMenuLayoutDocument::seedApplications(
            m_layoutDocument, applicationStorageIds());
    if (!effective.success) {
        effective = PunchiMenuLayoutDocument::seedApplications(
            PunchiMenuLayoutDocument::emptyDocument(),
            applicationStorageIds());
    }

    QHash<QString, QVariantMap> applicationsById;
    applicationsById.reserve(m_applications.size());
    QSet<QString> hiddenKeys;
    for (const QString &storageId : m_hiddenApplicationIds) {
        hiddenKeys.insert(identityKey(storageId));
    }
    for (const QVariant &applicationValue : m_applications) {
        QVariantMap application = applicationValue.toMap();
        const QString key = identityKey(
            application.value(QStringLiteral("storageId")).toString());
        const bool hidden = hiddenKeys.contains(key);
        if (hidden && !m_revealHiddenApplications) {
            continue;
        }
        application.insert(QStringLiteral("hidden"), hidden);
        applicationsById.insert(key, application);
    }

    QVariantList rebuiltNodes;
    const QVariantList documentNodes
        = effective.document.value(QStringLiteral("nodes")).toList();
    rebuiltNodes.reserve(documentNodes.size());
    for (const QVariant &nodeValue : documentNodes) {
        const QVariantMap node = nodeValue.toMap();
        const QString nodeType = node.value(QStringLiteral("type")).toString();
        if (nodeType == QLatin1String(applicationNodeType)) {
            const QString key = identityKey(
                node.value(QStringLiteral("storageId")).toString());
            const auto application = applicationsById.constFind(key);
            if (application != applicationsById.cend()) {
                rebuiltNodes.append(applicationRow(application.value()));
            }
            continue;
        }

        QVariantList resolvedMembers;
        QVariantList previewIcons;
        const QVariantList memberIds
            = node.value(QStringLiteral("members")).toList();
        resolvedMembers.reserve(memberIds.size());
        for (const QVariant &memberValue : memberIds) {
            const auto application = applicationsById.constFind(
                identityKey(memberValue.toString()));
            if (application == applicationsById.cend()) {
                continue;
            }
            resolvedMembers.append(applicationRow(application.value()));
            if (previewIcons.size() < maximumFolderPreviewIcons) {
                previewIcons.append(
                    application.value().value(QStringLiteral("icon")));
            }
        }
        if (resolvedMembers.isEmpty()) {
            continue;
        }

        const QString folderNodeId = QString(QStringLiteral("folder:")
            + node.value(QStringLiteral("folderId")).toString());
        rebuiltNodes.append(QVariantMap{
            {QStringLiteral("nodeType"), QString::fromLatin1(folderNodeType)},
            {QStringLiteral("nodeId"), folderNodeId},
            {QStringLiteral("folderId"),
                node.value(QStringLiteral("folderId"))},
            {QStringLiteral("folderLabel"),
                node.value(QStringLiteral("label"))},
            {QStringLiteral("folderMembers"), resolvedMembers},
            {QStringLiteral("folderMemberCount"), resolvedMembers.size()},
            {QStringLiteral("folderPreviewIcons"), previewIcons},
        });
    }

    if (m_alphabeticalSortingEnabled) {
        QCollator collator;
        collator.setCaseSensitivity(Qt::CaseInsensitive);
        collator.setNumericMode(true);
        std::stable_sort(rebuiltNodes.begin(), rebuiltNodes.end(),
            [&collator](const QVariant &leftValue,
                const QVariant &rightValue) {
                const QVariantMap left = leftValue.toMap();
                const QVariantMap right = rightValue.toMap();
                const int labelOrder = collator.compare(
                    nodeDisplayLabel(left), nodeDisplayLabel(right));
                if (labelOrder != 0) {
                    return labelOrder < 0;
                }
                return left.value(QStringLiteral("nodeId")).toString()
                    < right.value(QStringLiteral("nodeId")).toString();
            });
    }

    beginResetModel();
    m_effectiveLayoutDocument = effective.document;
    m_nodes = rebuiltNodes;
    endResetModel();
    Q_EMIT nodesChanged();
}

void PunchiMenuLayoutModel::setLastErrorCode(const QString &errorCode)
{
    if (m_lastErrorCode == errorCode) {
        return;
    }
    m_lastErrorCode = errorCode;
    Q_EMIT lastErrorCodeChanged();
}
