// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class PunchiMenuLayoutDocument final
{
public:
    static constexpr int CurrentVersion = 1;
    static constexpr int MaximumFolders = 128;
    static constexpr int MaximumFolderMembers = 128;
    static constexpr int MaximumApplicationReferences = 1024;
    static constexpr int MaximumNodes = MaximumApplicationReferences + MaximumFolders;
    static constexpr int MaximumStorageIdLength = 512;
    static constexpr int MaximumFolderIdLength = 128;
    static constexpr int MaximumFolderLabelLength = 80;

    struct Result {
        bool success = false;
        QString errorCode;
        QVariantMap document;

        [[nodiscard]] QVariantMap toVariantMap() const;
    };

    [[nodiscard]] static QVariantMap emptyDocument();
    [[nodiscard]] static Result sanitize(const QVariant &document);
    [[nodiscard]] static Result sanitize(const QVariantMap &document);
    [[nodiscard]] static Result seedApplications(
        const QVariantMap &document, const QStringList &storageIds);
    [[nodiscard]] static Result createFolder(
        const QVariantMap &document,
        const QString &firstStorageId,
        const QString &secondStorageId,
        const QString &folderId,
        const QString &label);
    [[nodiscard]] static Result createFolder(
        const QVariantMap &document,
        const QStringList &storageIds,
        const QString &folderId,
        const QString &label);
    [[nodiscard]] static Result addApplicationToFolder(
        const QVariantMap &document,
        const QString &storageId,
        const QString &folderId);
    [[nodiscard]] static Result removeApplicationFromFolder(
        const QVariantMap &document,
        const QString &storageId,
        const QString &folderId);
    [[nodiscard]] static Result renameFolder(
        const QVariantMap &document,
        const QString &folderId,
        const QString &label);
    [[nodiscard]] static Result dissolveFolder(
        const QVariantMap &document, const QString &folderId);
    [[nodiscard]] static Result moveNode(
        const QVariantMap &document,
        const QString &sourceNodeId,
        const QString &beforeNodeId);

    [[nodiscard]] static QString normalizedStorageId(const QVariant &value);
    [[nodiscard]] static QString normalizedFolderId(const QVariant &value);
    [[nodiscard]] static QString normalizedFolderLabel(const QVariant &value);

private:
    [[nodiscard]] static Result failure(const QString &errorCode);
    [[nodiscard]] static Result success(const QVariantMap &document);
};
