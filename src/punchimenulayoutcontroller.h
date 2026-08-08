// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class PunchiMenuLayoutController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantMap layoutDocument READ layoutDocument WRITE setLayoutDocument NOTIFY layoutDocumentChanged)
    Q_PROPERTY(QStringList applicationStorageIds READ applicationStorageIds WRITE setApplicationStorageIds NOTIFY applicationStorageIdsChanged)
    Q_PROPERTY(bool transactionPending READ transactionPending NOTIFY transactionPendingChanged)
    Q_PROPERTY(QString pendingTransactionId READ pendingTransactionId NOTIFY transactionPendingChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY canUndoChanged)
    Q_PROPERTY(QString lastErrorCode READ lastErrorCode NOTIFY lastErrorCodeChanged)
    Q_PROPERTY(qulonglong revision READ revision NOTIFY revisionChanged)

public:
    enum Operation {
        NoOperation = 0,
        CreateFolder,
        AddToFolder,
        RemoveFromFolder,
        RenameFolder,
        DissolveFolder,
        MoveNode,
        Undo,
    };
    Q_ENUM(Operation)

    explicit PunchiMenuLayoutController(QObject *parent = nullptr);

    [[nodiscard]] QVariantMap layoutDocument() const;
    void setLayoutDocument(const QVariantMap &document);

    [[nodiscard]] QStringList applicationStorageIds() const;
    void setApplicationStorageIds(const QStringList &storageIds);

    [[nodiscard]] bool transactionPending() const;
    [[nodiscard]] QString pendingTransactionId() const;
    [[nodiscard]] bool canUndo() const;
    [[nodiscard]] QString lastErrorCode() const;
    [[nodiscard]] qulonglong revision() const;

    Q_INVOKABLE QVariantMap requestCreateFolder(
        const QString &firstStorageId,
        const QString &secondStorageId,
        const QString &label);
    Q_INVOKABLE QVariantMap requestCreateFolderFromApplications(
        const QStringList &storageIds,
        const QString &label);
    Q_INVOKABLE QVariantMap requestAddApplicationToFolder(
        const QString &storageId, const QString &folderId);
    Q_INVOKABLE QVariantMap requestRemoveApplicationFromFolder(
        const QString &storageId,
        const QString &folderId,
        bool confirmation = false);
    Q_INVOKABLE QVariantMap requestRenameFolder(
        const QString &folderId, const QString &label);
    Q_INVOKABLE QVariantMap requestDissolveFolder(
        const QString &folderId, bool confirmation = false);
    Q_INVOKABLE QVariantMap requestMoveNode(
        const QString &sourceNodeId, const QString &beforeNodeId = QString());
    Q_INVOKABLE QVariantMap requestUndo();

    Q_INVOKABLE bool confirmPersistence(const QString &transactionId);
    Q_INVOKABLE bool rejectPersistence(
        const QString &transactionId,
        const QString &errorCode = QStringLiteral("persist-failed"));
    Q_INVOKABLE void discardUndoHistory();

Q_SIGNALS:
    void layoutDocumentChanged();
    void applicationStorageIdsChanged();
    void transactionPendingChanged();
    void canUndoChanged();
    void lastErrorCodeChanged();
    void revisionChanged();
    void validationFailed(const QString &errorCode);
    void persistenceRequested(
        const QString &transactionId,
        const QVariantMap &document,
        PunchiMenuLayoutController::Operation operation,
        const QString &subjectId);
    void transactionCommitted(
        const QString &transactionId,
        PunchiMenuLayoutController::Operation operation,
        const QString &subjectId);
    void transactionFailed(
        const QString &transactionId,
        PunchiMenuLayoutController::Operation operation,
        const QString &errorCode);
    void operationRejected(
        PunchiMenuLayoutController::Operation operation,
        const QString &errorCode);

private:
    [[nodiscard]] QVariantMap requestResult(
        bool accepted,
        Operation operation,
        const QString &transactionId,
        const QString &subjectId,
        const QString &errorCode) const;
    [[nodiscard]] QVariantMap rejectOperation(
        Operation operation, const QString &errorCode);
    [[nodiscard]] QVariantMap beginTransaction(
        Operation operation,
        const QString &subjectId,
        const QVariantMap &beforeDocument,
        const QVariantMap &proposedDocument);
    [[nodiscard]] QVariantMap operationBaseDocument(
        Operation operation, bool *succeeded);
    void clearPendingState();
    void setLastErrorCode(const QString &errorCode);

    QVariantMap m_layoutDocument;
    QStringList m_applicationStorageIds;
    QVariantMap m_pendingBeforeDocument;
    QVariantMap m_pendingDocument;
    QVariantMap m_undoSnapshot;
    QString m_pendingTransactionId;
    QString m_pendingSubjectId;
    QString m_lastErrorCode;
    Operation m_pendingOperation = NoOperation;
    qulonglong m_revision = 0;
    bool m_transactionPending = false;
    bool m_hasUndoSnapshot = false;
    bool m_discardUndoOnCommit = false;
};
