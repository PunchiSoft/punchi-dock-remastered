// SPDX-License-Identifier: GPL-3.0-or-later

#include "punchimenulayoutcontroller.h"

#include "punchimenulayoutdocument.h"

#include <QSet>
#include <QUuid>

#include <algorithm>

namespace
{
constexpr qsizetype maximumInputEntriesToInspect
    = PunchiMenuLayoutDocument::MaximumApplicationReferences * 4;
constexpr int maximumUuidAttempts = 8;
constexpr qsizetype maximumErrorCodeLength = 128;

QString newUuid()
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QString normalizedErrorCode(const QString &requestedErrorCode)
{
    const QString errorCode = requestedErrorCode.trimmed();
    if (errorCode.isEmpty() || errorCode.size() > maximumErrorCodeLength) {
        return QStringLiteral("persist-failed");
    }

    const bool valid = std::all_of(
        errorCode.cbegin(), errorCode.cend(), [](QChar character) {
            const ushort codePoint = character.unicode();
            return (codePoint >= '0' && codePoint <= '9')
                || (codePoint >= 'A' && codePoint <= 'Z')
                || (codePoint >= 'a' && codePoint <= 'z')
                || character == QLatin1Char('-')
                || character == QLatin1Char('_')
                || character == QLatin1Char('.');
        });
    return valid ? errorCode : QStringLiteral("persist-failed");
}
}

PunchiMenuLayoutController::PunchiMenuLayoutController(QObject *parent)
    : QObject(parent)
    , m_layoutDocument(PunchiMenuLayoutDocument::emptyDocument())
{
}

QVariantMap PunchiMenuLayoutController::layoutDocument() const
{
    return m_layoutDocument;
}

void PunchiMenuLayoutController::setLayoutDocument(
    const QVariantMap &document)
{
    const PunchiMenuLayoutDocument::Result normalized
        = PunchiMenuLayoutDocument::sanitize(document);
    if (!normalized.success) {
        setLastErrorCode(normalized.errorCode);
        Q_EMIT validationFailed(normalized.errorCode);
        return;
    }

    if (m_transactionPending) {
        if (normalized.document == m_layoutDocument
            || normalized.document == m_pendingDocument) {
            setLastErrorCode({});
            return;
        }
        setLastErrorCode(QStringLiteral("transaction-active"));
        Q_EMIT validationFailed(QStringLiteral("transaction-active"));
        return;
    }

    setLastErrorCode({});
    if (m_layoutDocument == normalized.document) {
        return;
    }

    const bool undoWasAvailable = canUndo();
    m_layoutDocument = normalized.document;
    m_undoSnapshot.clear();
    m_hasUndoSnapshot = false;
    ++m_revision;

    Q_EMIT layoutDocumentChanged();
    Q_EMIT revisionChanged();
    if (undoWasAvailable != canUndo()) {
        Q_EMIT canUndoChanged();
    }
}

QStringList PunchiMenuLayoutController::applicationStorageIds() const
{
    return m_applicationStorageIds;
}

void PunchiMenuLayoutController::setApplicationStorageIds(
    const QStringList &storageIds)
{
    QStringList normalized;
    QSet<QString> seen;
    normalized.reserve(std::min(storageIds.size(),
        qsizetype(PunchiMenuLayoutDocument::MaximumApplicationReferences)));

    const qsizetype inputLimit
        = std::min(storageIds.size(), maximumInputEntriesToInspect);
    for (qsizetype index = 0; index < inputLimit; ++index) {
        const QString storageId
            = PunchiMenuLayoutDocument::normalizedStorageId(
                storageIds.at(index));
        if (storageId.isEmpty() || seen.contains(storageId)) {
            continue;
        }
        seen.insert(storageId);
        normalized.append(storageId);
        if (normalized.size()
            >= PunchiMenuLayoutDocument::MaximumApplicationReferences) {
            break;
        }
    }

    if (m_applicationStorageIds == normalized) {
        return;
    }
    m_applicationStorageIds = normalized;
    Q_EMIT applicationStorageIdsChanged();
}

bool PunchiMenuLayoutController::transactionPending() const
{
    return m_transactionPending;
}

QString PunchiMenuLayoutController::pendingTransactionId() const
{
    return m_pendingTransactionId;
}

bool PunchiMenuLayoutController::canUndo() const
{
    return m_hasUndoSnapshot && !m_transactionPending;
}

QString PunchiMenuLayoutController::lastErrorCode() const
{
    return m_lastErrorCode;
}

qulonglong PunchiMenuLayoutController::revision() const
{
    return m_revision;
}

QVariantMap PunchiMenuLayoutController::requestCreateFolder(
    const QString &firstStorageId,
    const QString &secondStorageId,
    const QString &label)
{
    return requestCreateFolderFromApplications(
        QStringList{firstStorageId, secondStorageId}, label);
}

QVariantMap PunchiMenuLayoutController::requestCreateFolderFromApplications(
    const QStringList &storageIds,
    const QString &label)
{
    if (m_transactionPending) {
        return rejectOperation(CreateFolder,
            QStringLiteral("transaction-active"));
    }

    bool baseSucceeded = false;
    const QVariantMap baseDocument
        = operationBaseDocument(CreateFolder, &baseSucceeded);
    if (!baseSucceeded) {
        return requestResult(false, CreateFolder, {}, {}, m_lastErrorCode);
    }

    for (int attempt = 0; attempt < maximumUuidAttempts; ++attempt) {
        const QString folderId = newUuid();
        const PunchiMenuLayoutDocument::Result proposal
            = PunchiMenuLayoutDocument::createFolder(
                baseDocument,
                storageIds,
                folderId,
                label);
        if (proposal.success) {
            return beginTransaction(
                CreateFolder, folderId, m_layoutDocument, proposal.document);
        }
        if (proposal.errorCode != QLatin1String("duplicate-folder")) {
            return rejectOperation(CreateFolder, proposal.errorCode);
        }
    }

    return rejectOperation(CreateFolder,
        QStringLiteral("identifier-generation-failed"));
}

QVariantMap PunchiMenuLayoutController::requestAddApplicationToFolder(
    const QString &storageId, const QString &folderId)
{
    if (m_transactionPending) {
        return rejectOperation(AddToFolder,
            QStringLiteral("transaction-active"));
    }
    bool baseSucceeded = false;
    const QVariantMap baseDocument
        = operationBaseDocument(AddToFolder, &baseSucceeded);
    if (!baseSucceeded) {
        return requestResult(false, AddToFolder, {}, {}, m_lastErrorCode);
    }
    const PunchiMenuLayoutDocument::Result proposal
        = PunchiMenuLayoutDocument::addApplicationToFolder(
            baseDocument, storageId, folderId);
    if (!proposal.success) {
        return rejectOperation(AddToFolder, proposal.errorCode);
    }
    return beginTransaction(AddToFolder,
        PunchiMenuLayoutDocument::normalizedFolderId(folderId),
        m_layoutDocument,
        proposal.document);
}

QVariantMap PunchiMenuLayoutController::requestRemoveApplicationFromFolder(
    const QString &storageId,
    const QString &folderId,
    bool confirmation)
{
    if (m_transactionPending) {
        return rejectOperation(RemoveFromFolder,
            QStringLiteral("transaction-active"));
    }
    bool baseSucceeded = false;
    const QVariantMap baseDocument
        = operationBaseDocument(RemoveFromFolder, &baseSucceeded);
    if (!baseSucceeded) {
        return requestResult(
            false, RemoveFromFolder, {}, {}, m_lastErrorCode);
    }
    const PunchiMenuLayoutDocument::Result proposal
        = PunchiMenuLayoutDocument::removeApplicationFromFolder(
            baseDocument, storageId, folderId);
    if (!proposal.success) {
        return rejectOperation(RemoveFromFolder, proposal.errorCode);
    }

    const QString normalizedFolderId
        = PunchiMenuLayoutDocument::normalizedFolderId(folderId);
    const QVariantList nodes
        = baseDocument.value(QStringLiteral("nodes")).toList();
    for (const QVariant &nodeValue : nodes) {
        const QVariantMap node = nodeValue.toMap();
        if (node.value(QStringLiteral("type")).toString()
                == QLatin1String("folder")
            && node.value(QStringLiteral("folderId")).toString()
                == normalizedFolderId
            && node.value(QStringLiteral("members")).toList().size() == 2
            && !confirmation) {
            return rejectOperation(RemoveFromFolder,
                QStringLiteral("confirmation-required"));
        }
    }
    return beginTransaction(RemoveFromFolder,
        normalizedFolderId,
        m_layoutDocument,
        proposal.document);
}

QVariantMap PunchiMenuLayoutController::requestRenameFolder(
    const QString &folderId, const QString &label)
{
    if (m_transactionPending) {
        return rejectOperation(RenameFolder,
            QStringLiteral("transaction-active"));
    }
    bool baseSucceeded = false;
    const QVariantMap baseDocument
        = operationBaseDocument(RenameFolder, &baseSucceeded);
    if (!baseSucceeded) {
        return requestResult(false, RenameFolder, {}, {}, m_lastErrorCode);
    }
    const PunchiMenuLayoutDocument::Result proposal
        = PunchiMenuLayoutDocument::renameFolder(
            baseDocument, folderId, label);
    if (!proposal.success) {
        return rejectOperation(RenameFolder, proposal.errorCode);
    }
    return beginTransaction(RenameFolder,
        PunchiMenuLayoutDocument::normalizedFolderId(folderId),
        m_layoutDocument,
        proposal.document);
}

QVariantMap PunchiMenuLayoutController::requestDissolveFolder(
    const QString &folderId, bool confirmation)
{
    if (m_transactionPending) {
        return rejectOperation(DissolveFolder,
            QStringLiteral("transaction-active"));
    }
    if (!confirmation) {
        return rejectOperation(DissolveFolder,
            QStringLiteral("confirmation-required"));
    }
    bool baseSucceeded = false;
    const QVariantMap baseDocument
        = operationBaseDocument(DissolveFolder, &baseSucceeded);
    if (!baseSucceeded) {
        return requestResult(false, DissolveFolder, {}, {}, m_lastErrorCode);
    }
    const PunchiMenuLayoutDocument::Result proposal
        = PunchiMenuLayoutDocument::dissolveFolder(baseDocument, folderId);
    if (!proposal.success) {
        return rejectOperation(DissolveFolder, proposal.errorCode);
    }
    return beginTransaction(DissolveFolder,
        PunchiMenuLayoutDocument::normalizedFolderId(folderId),
        m_layoutDocument,
        proposal.document);
}

QVariantMap PunchiMenuLayoutController::requestUndo()
{
    if (m_transactionPending) {
        return rejectOperation(Undo, QStringLiteral("transaction-active"));
    }
    if (!m_hasUndoSnapshot) {
        return rejectOperation(Undo, QStringLiteral("nothing-to-undo"));
    }

    const PunchiMenuLayoutDocument::Result current
        = PunchiMenuLayoutDocument::sanitize(m_layoutDocument);
    const PunchiMenuLayoutDocument::Result previous
        = PunchiMenuLayoutDocument::sanitize(m_undoSnapshot);
    if (!current.success || !previous.success) {
        return rejectOperation(Undo, QStringLiteral("invalid-undo-snapshot"));
    }
    return beginTransaction(
        Undo, {}, current.document, previous.document);
}

bool PunchiMenuLayoutController::confirmPersistence(
    const QString &transactionId)
{
    if (!m_transactionPending) {
        setLastErrorCode(QStringLiteral("transaction-not-pending"));
        return false;
    }
    if (transactionId != m_pendingTransactionId) {
        setLastErrorCode(QStringLiteral("transaction-mismatch"));
        return false;
    }

    const bool undoWasAvailable = canUndo();
    const QString committedTransactionId = m_pendingTransactionId;
    const QString committedSubjectId = m_pendingSubjectId;
    const Operation committedOperation = m_pendingOperation;
    const QVariantMap committedDocument = m_pendingDocument;
    const QVariantMap beforeDocument = m_pendingBeforeDocument;
    const bool discardUndo = m_discardUndoOnCommit;

    m_layoutDocument = committedDocument;
    if (committedOperation == Undo || discardUndo) {
        m_undoSnapshot.clear();
        m_hasUndoSnapshot = false;
    } else {
        m_undoSnapshot = beforeDocument;
        m_hasUndoSnapshot = true;
    }
    ++m_revision;
    clearPendingState();
    setLastErrorCode({});

    Q_EMIT layoutDocumentChanged();
    Q_EMIT revisionChanged();
    Q_EMIT transactionPendingChanged();
    if (undoWasAvailable != canUndo()) {
        Q_EMIT canUndoChanged();
    }
    Q_EMIT transactionCommitted(
        committedTransactionId, committedOperation, committedSubjectId);
    return true;
}

bool PunchiMenuLayoutController::rejectPersistence(
    const QString &transactionId, const QString &errorCode)
{
    if (!m_transactionPending) {
        setLastErrorCode(QStringLiteral("transaction-not-pending"));
        return false;
    }
    if (transactionId != m_pendingTransactionId) {
        setLastErrorCode(QStringLiteral("transaction-mismatch"));
        return false;
    }

    const bool undoWasAvailable = canUndo();
    const QString failedTransactionId = m_pendingTransactionId;
    const Operation failedOperation = m_pendingOperation;
    const QString normalizedFailure = normalizedErrorCode(errorCode);
    clearPendingState();
    setLastErrorCode(normalizedFailure);

    Q_EMIT transactionPendingChanged();
    if (undoWasAvailable != canUndo()) {
        Q_EMIT canUndoChanged();
    }
    Q_EMIT transactionFailed(
        failedTransactionId, failedOperation, normalizedFailure);
    return true;
}

void PunchiMenuLayoutController::discardUndoHistory()
{
    const bool undoWasAvailable = canUndo();
    m_undoSnapshot.clear();
    m_hasUndoSnapshot = false;
    if (m_transactionPending) {
        m_discardUndoOnCommit = true;
    }
    if (undoWasAvailable != canUndo()) {
        Q_EMIT canUndoChanged();
    }
}

QVariantMap PunchiMenuLayoutController::requestResult(
    bool accepted,
    Operation operation,
    const QString &transactionId,
    const QString &subjectId,
    const QString &errorCode) const
{
    return {
        {QStringLiteral("accepted"), accepted},
        {QStringLiteral("transactionId"), transactionId},
        {QStringLiteral("operation"), static_cast<int>(operation)},
        {QStringLiteral("subjectId"), subjectId},
        {QStringLiteral("errorCode"), errorCode},
    };
}

QVariantMap PunchiMenuLayoutController::rejectOperation(
    Operation operation, const QString &errorCode)
{
    const QString normalized = normalizedErrorCode(errorCode);
    setLastErrorCode(normalized);
    Q_EMIT operationRejected(operation, normalized);
    return requestResult(false, operation, {}, {}, normalized);
}

QVariantMap PunchiMenuLayoutController::beginTransaction(
    Operation operation,
    const QString &subjectId,
    const QVariantMap &beforeDocument,
    const QVariantMap &proposedDocument)
{
    if (m_transactionPending) {
        return rejectOperation(operation, QStringLiteral("transaction-active"));
    }

    const PunchiMenuLayoutDocument::Result before
        = PunchiMenuLayoutDocument::sanitize(beforeDocument);
    const PunchiMenuLayoutDocument::Result proposal
        = PunchiMenuLayoutDocument::sanitize(proposedDocument);
    if (!before.success || !proposal.success) {
        return rejectOperation(operation,
            before.success ? proposal.errorCode : before.errorCode);
    }
    if (before.document == proposal.document) {
        return rejectOperation(operation, QStringLiteral("no-change"));
    }

    const bool undoWasAvailable = canUndo();
    const QString transactionId = newUuid();
    m_pendingBeforeDocument = before.document;
    m_pendingDocument = proposal.document;
    m_pendingTransactionId = transactionId;
    m_pendingSubjectId = subjectId;
    m_pendingOperation = operation;
    m_transactionPending = true;
    m_discardUndoOnCommit = false;
    setLastErrorCode({});

    const QVariantMap result
        = requestResult(true, operation, transactionId, subjectId, {});
    Q_EMIT transactionPendingChanged();
    if (undoWasAvailable != canUndo()) {
        Q_EMIT canUndoChanged();
    }
    Q_EMIT persistenceRequested(
        transactionId, proposal.document, operation, subjectId);
    return result;
}

QVariantMap PunchiMenuLayoutController::operationBaseDocument(
    Operation operation, bool *succeeded)
{
    const PunchiMenuLayoutDocument::Result base
        = PunchiMenuLayoutDocument::seedApplications(
            m_layoutDocument, m_applicationStorageIds);
    if (!base.success) {
        if (succeeded) {
            *succeeded = false;
        }
        (void)rejectOperation(operation, base.errorCode);
        return {};
    }
    if (succeeded) {
        *succeeded = true;
    }
    return base.document;
}

void PunchiMenuLayoutController::clearPendingState()
{
    m_pendingBeforeDocument.clear();
    m_pendingDocument.clear();
    m_pendingTransactionId.clear();
    m_pendingSubjectId.clear();
    m_pendingOperation = NoOperation;
    m_transactionPending = false;
    m_discardUndoOnCommit = false;
}

void PunchiMenuLayoutController::setLastErrorCode(
    const QString &errorCode)
{
    if (m_lastErrorCode == errorCode) {
        return;
    }
    m_lastErrorCode = errorCode;
    Q_EMIT lastErrorCodeChanged();
}
