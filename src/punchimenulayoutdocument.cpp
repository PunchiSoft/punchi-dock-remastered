// SPDX-License-Identifier: GPL-3.0-or-later

#include "punchimenulayoutdocument.h"

#include <QMetaType>
#include <QSet>

#include <algorithm>
#include <functional>
#include <utility>

namespace
{
constexpr auto versionKey = "version";
constexpr auto nodesKey = "nodes";
constexpr auto typeKey = "type";
constexpr auto applicationType = "application";
constexpr auto folderType = "folder";
constexpr auto storageIdKey = "storageId";
constexpr auto folderIdKey = "folderId";
constexpr auto labelKey = "label";
constexpr auto membersKey = "members";

bool isVariantList(const QVariant &value)
{
    return value.metaType().id() == QMetaType::QVariantList;
}

bool isVariantMap(const QVariant &value)
{
    return value.metaType().id() == QMetaType::QVariantMap;
}

bool isRestrictedCodePoint(uint codePoint)
{
    return codePoint < 0x20 || (codePoint >= 0x7f && codePoint <= 0x9f)
        || codePoint == 0x200e || codePoint == 0x200f
        || (codePoint >= 0x202a && codePoint <= 0x202e)
        || (codePoint >= 0x2066 && codePoint <= 0x2069)
        || codePoint == 0x2028 || codePoint == 0x2029
        || codePoint == 0xfeff;
}

bool containsRestrictedCharacters(const QString &value)
{
    const QList<uint> codePoints = value.toUcs4();
    return std::any_of(codePoints.cbegin(), codePoints.cend(), [](uint codePoint) {
        return isRestrictedCodePoint(codePoint);
    });
}

bool isAllowedFolderId(const QString &value)
{
    const auto isAsciiLetterOrNumber = [](QChar character) {
        const ushort codePoint = character.unicode();
        return (codePoint >= '0' && codePoint <= '9')
            || (codePoint >= 'A' && codePoint <= 'Z')
            || (codePoint >= 'a' && codePoint <= 'z');
    };
    if (value.isEmpty() || !isAsciiLetterOrNumber(value.at(0))) {
        return false;
    }
    return std::all_of(value.cbegin(), value.cend(), [&](QChar character) {
        return isAsciiLetterOrNumber(character) || character == QLatin1Char('-')
            || character == QLatin1Char('_') || character == QLatin1Char('.');
    });
}

bool isSupportedVersionValue(const QVariant &value)
{
    switch (value.metaType().id()) {
    case QMetaType::Int:
    case QMetaType::UInt:
    case QMetaType::LongLong:
    case QMetaType::ULongLong:
    case QMetaType::Double:
    case QMetaType::Float:
        return value.toDouble() == PunchiMenuLayoutDocument::CurrentVersion;
    default:
        return false;
    }
}

QString identityKey(const QString &value)
{
    return value;
}

QVariantMap applicationNode(const QString &storageId)
{
    return {
        {QString::fromLatin1(typeKey), QString::fromLatin1(applicationType)},
        {QString::fromLatin1(storageIdKey), storageId},
    };
}

QVariantMap folderNode(
    const QString &folderId, const QString &label, const QVariantList &members)
{
    return {
        {QString::fromLatin1(typeKey), QString::fromLatin1(folderType)},
        {QString::fromLatin1(folderIdKey), folderId},
        {QString::fromLatin1(labelKey), label},
        {QString::fromLatin1(membersKey), members},
    };
}

int standaloneApplicationIndex(const QVariantList &nodes, const QString &storageId)
{
    const QString requestedKey = identityKey(storageId);
    for (int index = 0; index < nodes.size(); ++index) {
        const QVariantMap node = nodes.at(index).toMap();
        if (node.value(QString::fromLatin1(typeKey)).toString()
                == QLatin1String(applicationType)
            && identityKey(node.value(QString::fromLatin1(storageIdKey)).toString())
                == requestedKey) {
            return index;
        }
    }
    return -1;
}

int folderIndex(const QVariantList &nodes, const QString &folderId)
{
    const QString requestedKey = identityKey(folderId);
    for (int index = 0; index < nodes.size(); ++index) {
        const QVariantMap node = nodes.at(index).toMap();
        if (node.value(QString::fromLatin1(typeKey)).toString()
                == QLatin1String(folderType)
            && identityKey(node.value(QString::fromLatin1(folderIdKey)).toString())
                == requestedKey) {
            return index;
        }
    }
    return -1;
}

QString nodeId(const QVariantMap &node)
{
    const QString type = node.value(QString::fromLatin1(typeKey)).toString();
    if (type == QLatin1String(applicationType)) {
        const QString storageId = PunchiMenuLayoutDocument::normalizedStorageId(
            node.value(QString::fromLatin1(storageIdKey)));
        return storageId.isEmpty() ? QString{}
                                   : QStringLiteral("application:") + storageId;
    }
    if (type == QLatin1String(folderType)) {
        const QString folderId = PunchiMenuLayoutDocument::normalizedFolderId(
            node.value(QString::fromLatin1(folderIdKey)));
        return folderId.isEmpty() ? QString{}
                                  : QStringLiteral("folder:") + folderId;
    }
    return {};
}

int nodeIndex(const QVariantList &nodes, const QString &requestedNodeId)
{
    for (int index = 0; index < nodes.size(); ++index) {
        if (nodeId(nodes.at(index).toMap()) == requestedNodeId) {
            return index;
        }
    }
    return -1;
}
}

QVariantMap PunchiMenuLayoutDocument::Result::toVariantMap() const
{
    return {
        {QStringLiteral("success"), success},
        {QStringLiteral("errorCode"), errorCode},
        {QStringLiteral("document"), document},
    };
}

QVariantMap PunchiMenuLayoutDocument::emptyDocument()
{
    return {
        {QString::fromLatin1(versionKey), CurrentVersion},
        {QString::fromLatin1(nodesKey), QVariantList{}},
    };
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::failure(
    const QString &errorCode)
{
    return {false, errorCode, {}};
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::success(
    const QVariantMap &document)
{
    return {true, {}, document};
}

QString PunchiMenuLayoutDocument::normalizedStorageId(const QVariant &value)
{
    if (value.metaType().id() != QMetaType::QString) {
        return {};
    }
    const QString storageId = value.toString().trimmed();
    if (storageId.isEmpty() || storageId.size() > MaximumStorageIdLength
        || containsRestrictedCharacters(storageId)) {
        return {};
    }
    return storageId;
}

QString PunchiMenuLayoutDocument::normalizedFolderId(const QVariant &value)
{
    if (value.metaType().id() != QMetaType::QString) {
        return {};
    }
    const QString folderId = value.toString().trimmed();
    if (folderId.isEmpty() || folderId.size() > MaximumFolderIdLength
        || containsRestrictedCharacters(folderId) || !isAllowedFolderId(folderId)) {
        return {};
    }
    return folderId;
}

QString PunchiMenuLayoutDocument::normalizedFolderLabel(const QVariant &value)
{
    if (value.metaType().id() != QMetaType::QString) {
        return {};
    }
    QString label;
    const QString requestedLabel = value.toString();
    label.reserve(std::min(requestedLabel.size(),
        qsizetype(MaximumFolderLabelLength * 2)));
    bool pendingSpace = false;
    int acceptedCodePoints = 0;
    qsizetype offset = 0;
    int inspectedCodePoints = 0;
    constexpr int maximumInspectedCodePoints = MaximumFolderLabelLength * 8;
    while (offset < requestedLabel.size()
        && inspectedCodePoints < maximumInspectedCodePoints
        && acceptedCodePoints < MaximumFolderLabelLength) {
        const QChar first = requestedLabel.at(offset++);
        uint codePoint = first.unicode();
        if (first.isHighSurrogate()) {
            if (offset >= requestedLabel.size()
                || !requestedLabel.at(offset).isLowSurrogate()) {
                ++inspectedCodePoints;
                continue;
            }
            codePoint = QChar::surrogateToUcs4(
                first.unicode(), requestedLabel.at(offset++).unicode());
        } else if (first.isLowSurrogate()) {
            ++inspectedCodePoints;
            continue;
        }
        ++inspectedCodePoints;
        if (isRestrictedCodePoint(codePoint)) {
            if (codePoint == '\t' || codePoint == '\n' || codePoint == '\r'
                || codePoint == 0x2028 || codePoint == 0x2029) {
                pendingSpace = !label.isEmpty();
            }
            continue;
        }
        if (QChar::isSpace(codePoint)) {
            pendingSpace = !label.isEmpty();
            continue;
        }
        if (pendingSpace && acceptedCodePoints < MaximumFolderLabelLength) {
            label.append(QLatin1Char(' '));
            ++acceptedCodePoints;
        }
        pendingSpace = false;
        if (acceptedCodePoints >= MaximumFolderLabelLength) {
            break;
        }
        const char32_t scalar = static_cast<char32_t>(codePoint);
        label.append(QString::fromUcs4(&scalar, 1));
        ++acceptedCodePoints;
    }
    return label.trimmed();
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::sanitize(
    const QVariant &document)
{
    if (!document.isValid() || document.isNull()) {
        return success(emptyDocument());
    }
    if (!isVariantMap(document)) {
        return failure(QStringLiteral("invalid-document"));
    }
    return sanitize(document.toMap());
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::sanitize(
    const QVariantMap &document)
{
    if (!isSupportedVersionValue(
            document.value(QString::fromLatin1(versionKey)))) {
        return failure(QStringLiteral("unsupported-version"));
    }

    const QVariant nodesValue = document.value(QString::fromLatin1(nodesKey));
    if (!isVariantList(nodesValue)) {
        return failure(QStringLiteral("invalid-nodes"));
    }

    const QVariantList requestedNodes = nodesValue.toList();
    if (requestedNodes.size() > MaximumNodes) {
        return failure(QStringLiteral("too-many-nodes"));
    }

    QVariantList normalizedNodes;
    normalizedNodes.reserve(requestedNodes.size());
    QSet<QString> applicationKeys;
    QSet<QString> folderKeys;
    int folderCount = 0;
    int applicationReferenceCount = 0;

    for (const QVariant &requestedNodeValue : requestedNodes) {
        if (!isVariantMap(requestedNodeValue)) {
            return failure(QStringLiteral("invalid-node"));
        }

        const QVariantMap requestedNode = requestedNodeValue.toMap();
        const QString type = requestedNode.value(QString::fromLatin1(typeKey))
                                 .toString()
                                 .trimmed();
        if (type == QLatin1String(applicationType)) {
            const QString storageId = normalizedStorageId(
                requestedNode.value(QString::fromLatin1(storageIdKey)));
            const QString key = identityKey(storageId);
            if (storageId.isEmpty()) {
                return failure(QStringLiteral("invalid-storage-id"));
            }
            if (applicationKeys.contains(key)) {
                return failure(QStringLiteral("duplicate-application"));
            }
            applicationKeys.insert(key);
            ++applicationReferenceCount;
            normalizedNodes.append(applicationNode(storageId));
        } else if (type == QLatin1String(folderType)) {
            if (++folderCount > MaximumFolders) {
                return failure(QStringLiteral("too-many-folders"));
            }

            const QString folderId = normalizedFolderId(
                requestedNode.value(QString::fromLatin1(folderIdKey)));
            const QString folderKey = identityKey(folderId);
            const QString label = normalizedFolderLabel(
                requestedNode.value(QString::fromLatin1(labelKey)));
            const QVariant membersValue = requestedNode.value(
                QString::fromLatin1(membersKey));
            if (folderId.isEmpty() || label.isEmpty()) {
                return failure(QStringLiteral("invalid-folder"));
            }
            if (folderKeys.contains(folderKey)) {
                return failure(QStringLiteral("duplicate-folder"));
            }
            if (!isVariantList(membersValue)) {
                return failure(QStringLiteral("invalid-folder-members"));
            }

            const QVariantList requestedMembers = membersValue.toList();
            if (requestedMembers.size() < 2
                || requestedMembers.size() > MaximumFolderMembers) {
                return failure(QStringLiteral("invalid-folder-member-count"));
            }

            QVariantList normalizedMembers;
            normalizedMembers.reserve(requestedMembers.size());
            for (const QVariant &memberValue : requestedMembers) {
                const QString storageId = normalizedStorageId(memberValue);
                const QString key = identityKey(storageId);
                if (storageId.isEmpty()) {
                    return failure(QStringLiteral("invalid-storage-id"));
                }
                if (applicationKeys.contains(key)) {
                    return failure(QStringLiteral("duplicate-application"));
                }
                applicationKeys.insert(key);
                normalizedMembers.append(storageId);
                ++applicationReferenceCount;
            }
            folderKeys.insert(folderKey);
            normalizedNodes.append(folderNode(folderId, label, normalizedMembers));
        } else {
            return failure(QStringLiteral("invalid-node-type"));
        }

        if (applicationReferenceCount > MaximumApplicationReferences) {
            return failure(QStringLiteral("too-many-application-references"));
        }
    }

    return success({
        {QString::fromLatin1(versionKey), CurrentVersion},
        {QString::fromLatin1(nodesKey), normalizedNodes},
    });
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::seedApplications(
    const QVariantMap &document, const QStringList &storageIds)
{
    const Result normalized = sanitize(document);
    if (!normalized.success) {
        return normalized;
    }

    QVariantList nodes = normalized.document.value(QString::fromLatin1(nodesKey))
                             .toList();
    QSet<QString> seen;
    for (const QVariant &nodeValue : std::as_const(nodes)) {
        const QVariantMap node = nodeValue.toMap();
        if (node.value(QString::fromLatin1(typeKey)).toString()
            == QLatin1String(applicationType)) {
            seen.insert(identityKey(
                node.value(QString::fromLatin1(storageIdKey)).toString()));
            continue;
        }
        const QVariantList members = node.value(QString::fromLatin1(membersKey))
                                         .toList();
        for (const QVariant &member : members) {
            seen.insert(identityKey(member.toString()));
        }
    }

    const qsizetype inputLimit = std::min(storageIds.size(),
        qsizetype(MaximumApplicationReferences * 4));
    for (qsizetype index = 0; index < inputLimit; ++index) {
        const QString &requestedStorageId = storageIds.at(index);
        const QString storageId = normalizedStorageId(requestedStorageId);
        const QString key = identityKey(storageId);
        if (storageId.isEmpty() || seen.contains(key)) {
            continue;
        }
        if (seen.size() >= MaximumApplicationReferences
            || nodes.size() >= MaximumNodes) {
            break;
        }
        seen.insert(key);
        nodes.append(applicationNode(storageId));
    }

    return sanitize({
        {QString::fromLatin1(versionKey), CurrentVersion},
        {QString::fromLatin1(nodesKey), nodes},
    });
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::createFolder(
    const QVariantMap &document,
    const QString &firstStorageId,
    const QString &secondStorageId,
    const QString &folderId,
    const QString &label)
{
    return createFolder(document,
        QStringList{firstStorageId, secondStorageId}, folderId, label);
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::createFolder(
    const QVariantMap &document,
    const QStringList &storageIds,
    const QString &folderId,
    const QString &label)
{
    const Result normalized = sanitize(document);
    if (!normalized.success) {
        return normalized;
    }

    const QString normalizedId = normalizedFolderId(folderId);
    const QString normalizedLabel = normalizedFolderLabel(label);
    if (storageIds.size() < 2 || storageIds.size() > MaximumFolderMembers
        || normalizedId.isEmpty() || normalizedLabel.isEmpty()) {
        return failure(QStringLiteral("invalid-create-folder-request"));
    }

    QVariantList nodes = normalized.document.value(QString::fromLatin1(nodesKey))
                             .toList();
    if (folderIndex(nodes, normalizedId) >= 0) {
        return failure(QStringLiteral("duplicate-folder"));
    }

    QVariantList members;
    members.reserve(storageIds.size());
    QList<int> sourceIndices;
    sourceIndices.reserve(storageIds.size());
    QSet<QString> selectedKeys;
    for (const QString &requestedStorageId : storageIds) {
        const QString storageId = normalizedStorageId(requestedStorageId);
        const QString key = identityKey(storageId);
        if (storageId.isEmpty() || selectedKeys.contains(key)) {
            return failure(QStringLiteral("invalid-create-folder-request"));
        }

        const int sourceIndex = standaloneApplicationIndex(nodes, storageId);
        if (sourceIndex < 0) {
            return failure(QStringLiteral("application-not-standalone"));
        }
        selectedKeys.insert(key);
        members.append(storageId);
        sourceIndices.append(sourceIndex);
    }

    const int insertionIndex
        = *std::min_element(sourceIndices.cbegin(), sourceIndices.cend());
    std::sort(sourceIndices.begin(), sourceIndices.end(), std::greater<int>());
    for (const int sourceIndex : std::as_const(sourceIndices)) {
        nodes.removeAt(sourceIndex);
    }
    nodes.insert(insertionIndex,
        folderNode(normalizedId, normalizedLabel, members));

    return sanitize({
        {QString::fromLatin1(versionKey), CurrentVersion},
        {QString::fromLatin1(nodesKey), nodes},
    });
}

PunchiMenuLayoutDocument::Result
PunchiMenuLayoutDocument::addApplicationToFolder(
    const QVariantMap &document,
    const QString &storageId,
    const QString &folderId)
{
    const Result normalized = sanitize(document);
    if (!normalized.success) {
        return normalized;
    }

    const QString applicationId = normalizedStorageId(storageId);
    const QString normalizedId = normalizedFolderId(folderId);
    QVariantList nodes = normalized.document.value(QString::fromLatin1(nodesKey))
                             .toList();
    int applicationIndex = standaloneApplicationIndex(nodes, applicationId);
    int targetFolderIndex = folderIndex(nodes, normalizedId);
    if (applicationIndex < 0 || targetFolderIndex < 0) {
        return failure(QStringLiteral("move-target-not-found"));
    }

    QVariantMap targetFolder = nodes.at(targetFolderIndex).toMap();
    QVariantList members = targetFolder.value(QString::fromLatin1(membersKey))
                               .toList();
    if (members.size() >= MaximumFolderMembers) {
        return failure(QStringLiteral("folder-member-limit"));
    }
    members.append(applicationId);
    targetFolder.insert(QString::fromLatin1(membersKey), members);

    nodes.removeAt(applicationIndex);
    if (applicationIndex < targetFolderIndex) {
        --targetFolderIndex;
    }
    nodes[targetFolderIndex] = targetFolder;

    return sanitize({
        {QString::fromLatin1(versionKey), CurrentVersion},
        {QString::fromLatin1(nodesKey), nodes},
    });
}

PunchiMenuLayoutDocument::Result
PunchiMenuLayoutDocument::removeApplicationFromFolder(
    const QVariantMap &document,
    const QString &storageId,
    const QString &folderId)
{
    const Result normalized = sanitize(document);
    if (!normalized.success) {
        return normalized;
    }

    const QString applicationId = normalizedStorageId(storageId);
    const QString normalizedId = normalizedFolderId(folderId);
    QVariantList nodes = normalized.document.value(QString::fromLatin1(nodesKey))
                             .toList();
    const int targetFolderIndex = folderIndex(nodes, normalizedId);
    if (targetFolderIndex < 0 || applicationId.isEmpty()) {
        return failure(QStringLiteral("folder-member-not-found"));
    }

    QVariantMap targetFolder = nodes.at(targetFolderIndex).toMap();
    QVariantList members = targetFolder.value(QString::fromLatin1(membersKey))
                               .toList();
    const QVariantList originalMembers = members;
    int memberIndex = -1;
    for (int index = 0; index < members.size(); ++index) {
        if (identityKey(members.at(index).toString())
            == identityKey(applicationId)) {
            memberIndex = index;
            break;
        }
    }
    if (memberIndex < 0) {
        return failure(QStringLiteral("folder-member-not-found"));
    }

    const QString removedStorageId = members.takeAt(memberIndex).toString();
    if (members.size() >= 2) {
        targetFolder.insert(QString::fromLatin1(membersKey), members);
        nodes[targetFolderIndex] = targetFolder;
        nodes.insert(targetFolderIndex + 1, applicationNode(removedStorageId));
    } else {
        nodes.removeAt(targetFolderIndex);
        for (int index = 0; index < originalMembers.size(); ++index) {
            nodes.insert(targetFolderIndex + index,
                applicationNode(originalMembers.at(index).toString()));
        }
    }

    return sanitize({
        {QString::fromLatin1(versionKey), CurrentVersion},
        {QString::fromLatin1(nodesKey), nodes},
    });
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::renameFolder(
    const QVariantMap &document,
    const QString &folderId,
    const QString &label)
{
    const Result normalized = sanitize(document);
    if (!normalized.success) {
        return normalized;
    }

    const QString normalizedId = normalizedFolderId(folderId);
    const QString normalizedLabel = normalizedFolderLabel(label);
    QVariantList nodes = normalized.document.value(QString::fromLatin1(nodesKey))
                             .toList();
    const int targetFolderIndex = folderIndex(nodes, normalizedId);
    if (targetFolderIndex < 0 || normalizedLabel.isEmpty()) {
        return failure(QStringLiteral("invalid-rename-folder-request"));
    }

    QVariantMap targetFolder = nodes.at(targetFolderIndex).toMap();
    targetFolder.insert(QString::fromLatin1(labelKey), normalizedLabel);
    nodes[targetFolderIndex] = targetFolder;
    return sanitize({
        {QString::fromLatin1(versionKey), CurrentVersion},
        {QString::fromLatin1(nodesKey), nodes},
    });
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::dissolveFolder(
    const QVariantMap &document, const QString &folderId)
{
    const Result normalized = sanitize(document);
    if (!normalized.success) {
        return normalized;
    }

    const QString normalizedId = normalizedFolderId(folderId);
    QVariantList nodes = normalized.document.value(QString::fromLatin1(nodesKey))
                             .toList();
    const int targetFolderIndex = folderIndex(nodes, normalizedId);
    if (targetFolderIndex < 0) {
        return failure(QStringLiteral("folder-not-found"));
    }

    const QVariantList members = nodes.at(targetFolderIndex)
                                     .toMap()
                                     .value(QString::fromLatin1(membersKey))
                                     .toList();
    nodes.removeAt(targetFolderIndex);
    for (int index = 0; index < members.size(); ++index) {
        nodes.insert(targetFolderIndex + index,
            applicationNode(members.at(index).toString()));
    }

    return sanitize({
        {QString::fromLatin1(versionKey), CurrentVersion},
        {QString::fromLatin1(nodesKey), nodes},
    });
}

PunchiMenuLayoutDocument::Result PunchiMenuLayoutDocument::moveNode(
    const QVariantMap &document,
    const QString &sourceNodeId,
    const QString &beforeNodeId)
{
    const Result normalized = sanitize(document);
    if (!normalized.success) {
        return normalized;
    }

    const QString requestedSourceId = sourceNodeId.trimmed();
    const QString requestedBeforeId = beforeNodeId.trimmed();
    QVariantList nodes = normalized.document.value(QString::fromLatin1(nodesKey))
                             .toList();
    const int sourceIndex = nodeIndex(nodes, requestedSourceId);
    if (requestedSourceId.isEmpty() || sourceIndex < 0) {
        return failure(QStringLiteral("move-source-not-found"));
    }
    if (requestedBeforeId == requestedSourceId) {
        return failure(QStringLiteral("no-change"));
    }

    int insertionIndex = nodes.size();
    if (!requestedBeforeId.isEmpty()) {
        insertionIndex = nodeIndex(nodes, requestedBeforeId);
        if (insertionIndex < 0) {
            return failure(QStringLiteral("move-target-not-found"));
        }
    }

    const QVariant sourceNode = nodes.takeAt(sourceIndex);
    if (sourceIndex < insertionIndex) {
        --insertionIndex;
    }
    nodes.insert(insertionIndex, sourceNode);

    return sanitize({
        {QString::fromLatin1(versionKey), CurrentVersion},
        {QString::fromLatin1(nodesKey), nodes},
    });
}
