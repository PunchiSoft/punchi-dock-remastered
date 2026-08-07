// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QAbstractListModel>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlregistration.h>

class PunchiMenuLayoutModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVariantList applications READ applications WRITE setApplications NOTIFY applicationsChanged)
    Q_PROPERTY(QVariantMap layoutDocument READ layoutDocument WRITE setLayoutDocument NOTIFY layoutDocumentChanged)
    Q_PROPERTY(QStringList hiddenApplicationIds READ hiddenApplicationIds WRITE setHiddenApplicationIds NOTIFY hiddenApplicationIdsChanged)
    Q_PROPERTY(bool revealHiddenApplications READ revealHiddenApplications WRITE setRevealHiddenApplications NOTIFY revealHiddenApplicationsChanged)
    Q_PROPERTY(QVariantMap effectiveLayoutDocument READ effectiveLayoutDocument NOTIFY nodesChanged)
    Q_PROPERTY(QVariantList nodes READ nodes NOTIFY nodesChanged)
    Q_PROPERTY(int folderChoiceCount READ folderChoiceCount NOTIFY nodesChanged)
    Q_PROPERTY(QString lastErrorCode READ lastErrorCode NOTIFY lastErrorCodeChanged)

public:
    enum Role {
        NodeTypeRole = Qt::UserRole + 1,
        NodeIdRole,
        AppStorageIdRole,
        AppNameRole,
        AppIconRole,
        AppHiddenRole,
        FolderIdRole,
        FolderLabelRole,
        FolderMembersRole,
        FolderMemberCountRole,
        FolderPreviewIconsRole,
    };
    Q_ENUM(Role)

    explicit PunchiMenuLayoutModel(QObject *parent = nullptr);

    [[nodiscard]] int rowCount(
        const QModelIndex &parent = QModelIndex()) const override;
    [[nodiscard]] QVariant data(
        const QModelIndex &index, int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    [[nodiscard]] QVariantList applications() const;
    void setApplications(const QVariantList &applications);

    [[nodiscard]] QVariantMap layoutDocument() const;
    void setLayoutDocument(const QVariantMap &document);

    [[nodiscard]] QStringList hiddenApplicationIds() const;
    void setHiddenApplicationIds(const QStringList &storageIds);

    [[nodiscard]] bool revealHiddenApplications() const;
    void setRevealHiddenApplications(bool reveal);

    [[nodiscard]] QVariantMap effectiveLayoutDocument() const;
    [[nodiscard]] QVariantList nodes() const;
    [[nodiscard]] int folderChoiceCount() const;
    [[nodiscard]] QString lastErrorCode() const;

    Q_INVOKABLE int indexForNodeId(const QString &nodeId) const;
    Q_INVOKABLE int indexForFolder(const QString &folderId) const;
    Q_INVOKABLE QVariantMap applicationPlacement(
        const QString &storageId) const;
    Q_INVOKABLE QVariantMap folderInfo(const QString &folderId) const;
    Q_INVOKABLE QVariantList folderChoices() const;

Q_SIGNALS:
    void applicationsChanged();
    void layoutDocumentChanged();
    void hiddenApplicationIdsChanged();
    void revealHiddenApplicationsChanged();
    void nodesChanged();
    void lastErrorCodeChanged();
    void validationFailed(const QString &errorCode);

private:
    [[nodiscard]] static QVariantList normalizedApplications(
        const QVariantList &applications);
    [[nodiscard]] QStringList applicationStorageIds() const;
    void rebuildNodes();
    void setLastErrorCode(const QString &errorCode);

    QVariantList m_applications;
    QVariantMap m_layoutDocument;
    QStringList m_hiddenApplicationIds;
    bool m_revealHiddenApplications = false;
    QVariantMap m_effectiveLayoutDocument;
    QVariantList m_nodes;
    QString m_lastErrorCode;
};
