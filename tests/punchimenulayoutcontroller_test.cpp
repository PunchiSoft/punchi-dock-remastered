// SPDX-License-Identifier: GPL-3.0-or-later

#include "punchimenulayoutcontroller.h"
#include "punchimenulayoutdocument.h"

#include <QCoreApplication>
#include <QUuid>

#include <iostream>

namespace
{
constexpr auto firstApplicationId = "org.example.One.desktop";
constexpr auto secondApplicationId = "org.example.Two.desktop";
constexpr auto thirdApplicationId = "org.example.Three.desktop";
constexpr auto fourthApplicationId = "org.example.Four.desktop";

bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
    }
    return condition;
}

QVariantMap applicationNode(const QString &storageId)
{
    return {
        {QStringLiteral("type"), QStringLiteral("application")},
        {QStringLiteral("storageId"), storageId},
    };
}

QVariantMap document(const QVariantList &nodes)
{
    return {
        {QStringLiteral("version"), 1},
        {QStringLiteral("nodes"), nodes},
    };
}

QVariantList documentNodes(const QVariantMap &value)
{
    return value.value(QStringLiteral("nodes")).toList();
}

QString firstFolderId(const QVariantMap &value)
{
    const QVariantList nodes = documentNodes(value);
    for (const QVariant &nodeValue : nodes) {
        const QVariantMap node = nodeValue.toMap();
        if (node.value(QStringLiteral("type")).toString()
            == QLatin1String("folder")) {
            return node.value(QStringLiteral("folderId")).toString();
        }
    }
    return {};
}

QString firstFolderLabel(const QVariantMap &value)
{
    const QVariantList nodes = documentNodes(value);
    for (const QVariant &nodeValue : nodes) {
        const QVariantMap node = nodeValue.toMap();
        if (node.value(QStringLiteral("type")).toString()
            == QLatin1String("folder")) {
            return node.value(QStringLiteral("label")).toString();
        }
    }
    return {};
}

int firstFolderMemberCount(const QVariantMap &value)
{
    const QVariantList nodes = documentNodes(value);
    for (const QVariant &nodeValue : nodes) {
        const QVariantMap node = nodeValue.toMap();
        if (node.value(QStringLiteral("type")).toString()
            == QLatin1String("folder")) {
            return node.value(QStringLiteral("members")).toList().size();
        }
    }
    return 0;
}

bool isUuidWithoutBraces(const QString &value)
{
    return !value.isEmpty() && !value.contains(QLatin1Char('{'))
        && !value.contains(QLatin1Char('}'))
        && !QUuid::fromString(value).isNull();
}
}

int main(int argc, char **argv)
{
    QCoreApplication application(argc, argv);
    Q_UNUSED(application)

    bool passed = true;

    PunchiMenuLayoutController validationController;
    const QVariantMap validDocument = document({
        applicationNode(QString::fromLatin1(firstApplicationId)),
        applicationNode(QString::fromLatin1(secondApplicationId)),
    });
    validationController.setLayoutDocument(validDocument);
    const qulonglong validRevision = validationController.revision();
    validationController.setLayoutDocument(QVariantMap{
        {QStringLiteral("version"), 99},
        {QStringLiteral("nodes"), QVariantList{}},
    });
    passed &= expect(validationController.layoutDocument() == validDocument
            && validationController.revision() == validRevision
            && validationController.lastErrorCode()
                == QStringLiteral("unsupported-version"),
        "an invalid external document preserves the last confirmed state");

    validationController.setApplicationStorageIds({
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(firstApplicationId),
        QStringLiteral("ORG.EXAMPLE.ONE.DESKTOP"),
        QStringLiteral("invalid\nidentity"),
    });
    passed &= expect(validationController.applicationStorageIds().size() == 2
            && validationController.applicationStorageIds().at(0)
                == QString::fromLatin1(firstApplicationId)
            && validationController.applicationStorageIds().at(1)
                == QStringLiteral("ORG.EXAMPLE.ONE.DESKTOP"),
        "catalog identities are bounded, deduplicated exactly, and case-sensitive");

    PunchiMenuLayoutController moveController;
    moveController.setApplicationStorageIds({
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
        QString::fromLatin1(thirdApplicationId),
    });
    QString moveTransactionId;
    QVariantMap moveProposal;
    PunchiMenuLayoutController::Operation moveOperation
        = PunchiMenuLayoutController::NoOperation;
    QObject::connect(&moveController,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &transactionId,
            const QVariantMap &proposedDocument,
            PunchiMenuLayoutController::Operation operation,
            const QString &) {
            moveTransactionId = transactionId;
            moveProposal = proposedDocument;
            moveOperation = operation;
        });
    const QVariantMap moveRequest = moveController.requestMoveNode(
        QStringLiteral("application:") + QString::fromLatin1(thirdApplicationId),
        QStringLiteral("application:") + QString::fromLatin1(firstApplicationId));
    passed &= expect(moveRequest.value(QStringLiteral("accepted")).toBool()
            && moveOperation == PunchiMenuLayoutController::MoveNode
            && documentNodes(moveProposal).constFirst().toMap()
                    .value(QStringLiteral("storageId")).toString()
                == QString::fromLatin1(thirdApplicationId)
            && moveController.confirmPersistence(moveTransactionId)
            && moveController.canUndo(),
        "a node move is proposed and committed through one transaction");
    const QVariantMap undoMove = moveController.requestUndo();
    passed &= expect(undoMove.value(QStringLiteral("accepted")).toBool()
            && moveController.confirmPersistence(moveTransactionId)
            && documentNodes(moveController.layoutDocument()).isEmpty(),
        "undo restores the exact unseeded layout that preceded a committed node move");

    PunchiMenuLayoutController firstUndoController;
    firstUndoController.setApplicationStorageIds({
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
    });
    QString firstUndoTransactionId;
    QVariantMap firstUndoRequestedDocument;
    QObject::connect(&firstUndoController,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &transactionId,
            const QVariantMap &proposedDocument,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            firstUndoTransactionId = transactionId;
            firstUndoRequestedDocument = proposedDocument;
        });
    const QVariantMap firstCreation = firstUndoController.requestCreateFolder(
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
        QStringLiteral("First"));
    passed &= expect(firstCreation.value(QStringLiteral("accepted")).toBool()
            && firstUndoController.confirmPersistence(firstUndoTransactionId)
            && firstUndoController.canUndo(),
        "the first confirmed creation records an undo snapshot");
    const QVariantMap firstUndo = firstUndoController.requestUndo();
    passed &= expect(firstUndo.value(QStringLiteral("accepted")).toBool()
            && documentNodes(firstUndoRequestedDocument).isEmpty()
            && firstUndoController.confirmPersistence(firstUndoTransactionId)
            && documentNodes(firstUndoController.layoutDocument()).isEmpty()
            && !firstUndoController.canUndo(),
        "undoing the first creation restores the exact empty confirmed document");

    PunchiMenuLayoutController batchController;
    batchController.setApplicationStorageIds({
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
        QString::fromLatin1(thirdApplicationId),
        QString::fromLatin1(fourthApplicationId),
    });
    int batchPersistenceRequests = 0;
    QString batchTransactionId;
    QVariantMap batchProposal;
    QObject::connect(&batchController,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &transactionId,
            const QVariantMap &proposedDocument,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            ++batchPersistenceRequests;
            batchTransactionId = transactionId;
            batchProposal = proposedDocument;
        });
    const QVariantMap batchRequest
        = batchController.requestCreateFolderFromApplications({
            QString::fromLatin1(fourthApplicationId),
            QString::fromLatin1(secondApplicationId),
            QString::fromLatin1(thirdApplicationId),
        }, QStringLiteral("Batch"));
    passed &= expect(batchRequest.value(QStringLiteral("accepted")).toBool()
            && batchPersistenceRequests == 1
            && firstFolderMemberCount(batchProposal) == 3
            && batchController.rejectPersistence(
                batchTransactionId, QStringLiteral("write-failed"))
            && documentNodes(batchController.layoutDocument()).isEmpty(),
        "a batch NACK preserves confirmed state after exactly one persistence request");
    const QVariantMap retriedBatchRequest
        = batchController.requestCreateFolderFromApplications({
            QString::fromLatin1(fourthApplicationId),
            QString::fromLatin1(secondApplicationId),
            QString::fromLatin1(thirdApplicationId),
        }, QStringLiteral("Batch"));
    passed &= expect(
        retriedBatchRequest.value(QStringLiteral("accepted")).toBool()
            && batchPersistenceRequests == 2
            && firstFolderMemberCount(batchProposal) == 3
            && batchController.confirmPersistence(batchTransactionId)
            && firstFolderMemberCount(batchController.layoutDocument()) == 3,
        "a retried batch commits through one proposal and one persistence request");
    const QVariantMap batchUndo = batchController.requestUndo();
    passed &= expect(batchUndo.value(QStringLiteral("accepted")).toBool()
            && batchPersistenceRequests == 3
            && batchController.confirmPersistence(batchTransactionId)
            && documentNodes(batchController.layoutDocument()).isEmpty()
            && !batchController.canUndo(),
        "batch creation is reverted by one atomic undo transaction");
    const qulonglong revisionBeforeInvalidBatch = batchController.revision();
    const QVariantMap invalidBatch
        = batchController.requestCreateFolderFromApplications({
            QString::fromLatin1(firstApplicationId),
        }, QStringLiteral("Invalid"));
    passed &= expect(!invalidBatch.value(QStringLiteral("accepted")).toBool()
            && invalidBatch.value(QStringLiteral("errorCode")).toString()
                == QStringLiteral("invalid-create-folder-request")
            && batchPersistenceRequests == 3
            && batchController.revision() == revisionBeforeInvalidBatch
            && !batchController.transactionPending(),
        "an invalid batch emits no persistence request and changes no state");

    QStringList maximumControllerBatch;
    for (int index = 0;
         index < PunchiMenuLayoutDocument::MaximumFolderMembers; ++index) {
        maximumControllerBatch.append(
            QStringLiteral("org.example.ControllerMaximum%1.desktop").arg(index));
    }
    PunchiMenuLayoutController maximumBatchController;
    maximumBatchController.setApplicationStorageIds(maximumControllerBatch);
    int maximumBatchPersistenceRequests = 0;
    QString maximumBatchTransactionId;
    QVariantMap maximumBatchProposal;
    QObject::connect(&maximumBatchController,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &transactionId,
            const QVariantMap &proposedDocument,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            ++maximumBatchPersistenceRequests;
            maximumBatchTransactionId = transactionId;
            maximumBatchProposal = proposedDocument;
        });
    const QVariantMap maximumBatchRequest
        = maximumBatchController.requestCreateFolderFromApplications(
            maximumControllerBatch, QStringLiteral("Maximum"));
    passed &= expect(
        maximumBatchRequest.value(QStringLiteral("accepted")).toBool()
            && maximumBatchPersistenceRequests == 1
            && firstFolderMemberCount(maximumBatchProposal)
                == PunchiMenuLayoutDocument::MaximumFolderMembers
            && maximumBatchController.confirmPersistence(
                maximumBatchTransactionId),
        "the controller commits the maximum batch through one persistence request");
    const QVariantMap maximumBatchUndo
        = maximumBatchController.requestUndo();
    passed &= expect(
        maximumBatchUndo.value(QStringLiteral("accepted")).toBool()
            && maximumBatchPersistenceRequests == 2
            && maximumBatchController.confirmPersistence(
                maximumBatchTransactionId)
            && documentNodes(
                   maximumBatchController.layoutDocument()).isEmpty(),
        "the maximum batch is reverted by one undo persistence request");

    PunchiMenuLayoutController folderActionController;
    folderActionController.setApplicationStorageIds({
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
        QString::fromLatin1(thirdApplicationId),
    });
    int folderActionPersistenceRequests = 0;
    QString folderActionTransactionId;
    QVariantMap folderActionProposal;
    QObject::connect(&folderActionController,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &transactionId,
            const QVariantMap &proposedDocument,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            ++folderActionPersistenceRequests;
            folderActionTransactionId = transactionId;
            folderActionProposal = proposedDocument;
        });

    const QVariantMap actionCreate = folderActionController.requestCreateFolder(
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
        QStringLiteral("Actions"));
    passed &= expect(actionCreate.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 1
            && folderActionController.confirmPersistence(
                folderActionTransactionId),
        "the action test fixture commits its initial two-member folder once");
    const QString actionFolderId
        = firstFolderId(folderActionController.layoutDocument());

    const QVariantMap failedAdd
        = folderActionController.requestAddApplicationToFolder(
            QString::fromLatin1(thirdApplicationId), actionFolderId);
    passed &= expect(failedAdd.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 2
            && firstFolderMemberCount(folderActionProposal) == 3
            && folderActionController.rejectPersistence(
                folderActionTransactionId, QStringLiteral("write-failed"))
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "a rejected add keeps the confirmed folder unchanged");
    const QVariantMap successfulAdd
        = folderActionController.requestAddApplicationToFolder(
            QString::fromLatin1(thirdApplicationId), actionFolderId);
    passed &= expect(successfulAdd.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 3
            && folderActionController.confirmPersistence(
                folderActionTransactionId)
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 3,
        "a confirmed add persists exactly once");
    const QVariantMap undoAdd = folderActionController.requestUndo();
    passed &= expect(undoAdd.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 4
            && folderActionController.confirmPersistence(
                folderActionTransactionId)
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "undo restores the folder that existed before the add");

    const QVariantMap addForRemoval
        = folderActionController.requestAddApplicationToFolder(
            QString::fromLatin1(thirdApplicationId), actionFolderId);
    passed &= expect(addForRemoval.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 5
            && folderActionController.confirmPersistence(
                folderActionTransactionId),
        "the removal fixture restores a three-member folder once");
    const QVariantMap nonDestructiveRemoval
        = folderActionController.requestRemoveApplicationFromFolder(
            QString::fromLatin1(thirdApplicationId), actionFolderId);
    passed &= expect(
        nonDestructiveRemoval.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 6
            && folderActionController.confirmPersistence(
                folderActionTransactionId)
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "removing from a three-member folder does not require confirmation");
    const QVariantMap undoNonDestructiveRemoval
        = folderActionController.requestUndo();
    passed &= expect(
        undoNonDestructiveRemoval.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 7
            && folderActionController.confirmPersistence(
                folderActionTransactionId)
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 3,
        "undo restores a non-destructively removed member");
    const QVariantMap prepareDestructiveRemoval
        = folderActionController.requestRemoveApplicationFromFolder(
            QString::fromLatin1(thirdApplicationId), actionFolderId);
    passed &= expect(
        prepareDestructiveRemoval.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 8
            && folderActionController.confirmPersistence(
                folderActionTransactionId)
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "the destructive-removal fixture returns to two members");

    const qulonglong revisionBeforeConfirmation
        = folderActionController.revision();
    const QVariantMap unconfirmedRemoval
        = folderActionController.requestRemoveApplicationFromFolder(
            QString::fromLatin1(firstApplicationId), actionFolderId);
    passed &= expect(
        !unconfirmedRemoval.value(QStringLiteral("accepted")).toBool()
            && unconfirmedRemoval.value(QStringLiteral("errorCode")).toString()
                == QStringLiteral("confirmation-required")
            && folderActionPersistenceRequests == 8
            && !folderActionController.transactionPending()
            && folderActionController.revision() == revisionBeforeConfirmation
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "removing from a two-member persisted folder requires confirmation without mutation");
    const QVariantMap rejectedDestructiveRemoval
        = folderActionController.requestRemoveApplicationFromFolder(
            QString::fromLatin1(firstApplicationId), actionFolderId, true);
    passed &= expect(
        rejectedDestructiveRemoval.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 9
            && firstFolderId(folderActionProposal).isEmpty()
            && folderActionController.rejectPersistence(
                folderActionTransactionId, QStringLiteral("write-failed"))
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "a rejected confirmed removal preserves the two-member folder");
    const QVariantMap committedDestructiveRemoval
        = folderActionController.requestRemoveApplicationFromFolder(
            QString::fromLatin1(firstApplicationId), actionFolderId, true);
    passed &= expect(
        committedDestructiveRemoval.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 10
            && folderActionController.confirmPersistence(
                folderActionTransactionId)
            && firstFolderId(folderActionController.layoutDocument()).isEmpty(),
        "a confirmed penultimate removal dissolves the folder in one commit");
    const QVariantMap undoDestructiveRemoval
        = folderActionController.requestUndo();
    passed &= expect(
        undoDestructiveRemoval.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 11
            && folderActionController.confirmPersistence(
                folderActionTransactionId)
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "undo restores a folder dissolved by member removal");

    const qulonglong revisionBeforeDissolveConfirmation
        = folderActionController.revision();
    const QVariantMap unconfirmedDissolve
        = folderActionController.requestDissolveFolder(actionFolderId);
    passed &= expect(
        !unconfirmedDissolve.value(QStringLiteral("accepted")).toBool()
            && unconfirmedDissolve.value(QStringLiteral("errorCode")).toString()
                == QStringLiteral("confirmation-required")
            && folderActionPersistenceRequests == 11
            && folderActionController.revision()
                == revisionBeforeDissolveConfirmation
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "explicit dissolution requires confirmation without persistence or mutation");
    const QVariantMap rejectedDissolve
        = folderActionController.requestDissolveFolder(actionFolderId, true);
    passed &= expect(rejectedDissolve.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 12
            && folderActionController.rejectPersistence(
                folderActionTransactionId, QStringLiteral("write-failed"))
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "a dissolution NACK leaves the confirmed folder intact");
    const QVariantMap committedDissolve
        = folderActionController.requestDissolveFolder(actionFolderId, true);
    passed &= expect(committedDissolve.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 13
            && folderActionController.confirmPersistence(
                folderActionTransactionId)
            && firstFolderId(folderActionController.layoutDocument()).isEmpty(),
        "a confirmed dissolution persists exactly once");
    const QVariantMap undoDissolve = folderActionController.requestUndo();
    passed &= expect(undoDissolve.value(QStringLiteral("accepted")).toBool()
            && folderActionPersistenceRequests == 14
            && folderActionController.confirmPersistence(
                folderActionTransactionId)
            && firstFolderMemberCount(
                   folderActionController.layoutDocument()) == 2,
        "undo restores an explicitly dissolved folder");

    PunchiMenuLayoutController controller;
    controller.setApplicationStorageIds({
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
        QString::fromLatin1(thirdApplicationId),
    });

    int persistenceRequestCount = 0;
    int committedCount = 0;
    int failedCount = 0;
    QString requestedTransactionId;
    QString requestedSubjectId;
    QVariantMap requestedDocument;
    PunchiMenuLayoutController::Operation requestedOperation
        = PunchiMenuLayoutController::NoOperation;
    QObject::connect(&controller,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &transactionId,
            const QVariantMap &proposedDocument,
            PunchiMenuLayoutController::Operation operation,
            const QString &subjectId) {
            ++persistenceRequestCount;
            requestedTransactionId = transactionId;
            requestedDocument = proposedDocument;
            requestedOperation = operation;
            requestedSubjectId = subjectId;
        });
    QObject::connect(&controller,
        &PunchiMenuLayoutController::transactionCommitted,
        [&](const QString &,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            ++committedCount;
        });
    QObject::connect(&controller,
        &PunchiMenuLayoutController::transactionFailed,
        [&](const QString &,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            ++failedCount;
        });

    const QVariantMap emptyDocument = controller.layoutDocument();
    const QVariantMap createRequest = controller.requestCreateFolder(
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
        QStringLiteral("Work"));
    passed &= expect(createRequest.value(QStringLiteral("accepted")).toBool()
            && persistenceRequestCount == 1
            && controller.transactionPending()
            && requestedTransactionId
                == createRequest.value(QStringLiteral("transactionId")).toString()
            && requestedOperation == PunchiMenuLayoutController::CreateFolder,
        "a valid create request enters the persistence handshake once");
    passed &= expect(isUuidWithoutBraces(requestedTransactionId)
            && isUuidWithoutBraces(requestedSubjectId)
            && requestedSubjectId
                == createRequest.value(QStringLiteral("subjectId")).toString(),
        "transaction and folder identities are controller-generated UUIDs");
    passed &= expect(controller.layoutDocument() == emptyDocument
            && controller.revision() == 0
            && !controller.canUndo(),
        "a proposal does not mutate confirmed state before persistence succeeds");
    passed &= expect(documentNodes(requestedDocument).size() == 2
            && firstFolderLabel(requestedDocument) == QStringLiteral("Work"),
        "the operation base seeds the live catalog before creating a folder");

    QVariantList alteredNodes = documentNodes(requestedDocument);
    QVariantMap alteredFolder = alteredNodes.constFirst().toMap();
    alteredFolder.insert(QStringLiteral("label"), QStringLiteral("Tampered"));
    alteredNodes[0] = alteredFolder;
    requestedDocument.insert(QStringLiteral("nodes"), alteredNodes);

    passed &= expect(controller.confirmPersistence(requestedTransactionId)
            && !controller.transactionPending()
            && controller.revision() == 1
            && controller.canUndo()
            && firstFolderLabel(controller.layoutDocument())
                == QStringLiteral("Work")
            && committedCount == 1,
        "ACK commits the internal canonical copy and creates one undo snapshot");
    const QString createdFolderId = firstFolderId(controller.layoutDocument());
    passed &= expect(!controller.confirmPersistence(requestedTransactionId)
            && controller.revision() == 1
            && committedCount == 1,
        "a duplicate ACK is idempotently rejected");

    const int requestsBeforeNoChange = persistenceRequestCount;
    const QVariantMap noChange = controller.requestRenameFolder(
        createdFolderId, QStringLiteral("Work"));
    passed &= expect(!noChange.value(QStringLiteral("accepted")).toBool()
            && noChange.value(QStringLiteral("errorCode")).toString()
                == QStringLiteral("no-change")
            && persistenceRequestCount == requestsBeforeNoChange
            && controller.canUndo(),
        "a no-op proposal does not write or replace undo history");

    const QVariantMap beforeFailedRename = controller.layoutDocument();
    const qulonglong revisionBeforeFailedRename = controller.revision();
    const QVariantMap renameRequest = controller.requestRenameFolder(
        createdFolderId, QStringLiteral("Tools"));
    const QString renameTransactionId
        = renameRequest.value(QStringLiteral("transactionId")).toString();
    passed &= expect(renameRequest.value(QStringLiteral("accepted")).toBool()
            && controller.transactionPending()
            && !controller.canUndo(),
        "an accepted transaction temporarily blocks the undo action");

    const int requestsBeforeBusyAttempt = persistenceRequestCount;
    const QVariantMap busyAttempt
        = controller.requestDissolveFolder(createdFolderId);
    passed &= expect(!busyAttempt.value(QStringLiteral("accepted")).toBool()
            && busyAttempt.value(QStringLiteral("errorCode")).toString()
                == QStringLiteral("transaction-active")
            && controller.pendingTransactionId() == renameTransactionId
            && persistenceRequestCount == requestsBeforeBusyAttempt,
        "a second operation cannot replace an in-flight transaction");
    passed &= expect(!controller.confirmPersistence(QStringLiteral("wrong-token"))
            && !controller.rejectPersistence(
                QStringLiteral("wrong-token"), QStringLiteral("write-failed"))
            && controller.transactionPending()
            && controller.layoutDocument() == beforeFailedRename,
        "a mismatched token cannot mutate or cancel the pending transaction");
    passed &= expect(controller.rejectPersistence(
                         renameTransactionId,
                         QStringLiteral("unsafe\nexternal error"))
            && !controller.transactionPending()
            && controller.layoutDocument() == beforeFailedRename
            && controller.revision() == revisionBeforeFailedRename
            && controller.canUndo()
            && controller.lastErrorCode() == QStringLiteral("persist-failed")
            && failedCount == 1,
        "NACK preserves the document, revision, and previous undo snapshot");

    const QVariantMap successfulRename = controller.requestRenameFolder(
        createdFolderId, QStringLiteral("Tools"));
    const QString successfulRenameId
        = successfulRename.value(QStringLiteral("transactionId")).toString();
    passed &= expect(successfulRename.value(QStringLiteral("accepted")).toBool()
            && controller.confirmPersistence(successfulRenameId)
            && firstFolderLabel(controller.layoutDocument())
                == QStringLiteral("Tools")
            && controller.canUndo(),
        "a later successful operation replaces the single undo snapshot");

    const QVariantMap undoRequest = controller.requestUndo();
    const QString failedUndoId
        = undoRequest.value(QStringLiteral("transactionId")).toString();
    passed &= expect(undoRequest.value(QStringLiteral("accepted")).toBool()
            && firstFolderLabel(requestedDocument) == QStringLiteral("Work")
            && controller.rejectPersistence(
                failedUndoId, QStringLiteral("write-failed"))
            && firstFolderLabel(controller.layoutDocument())
                == QStringLiteral("Tools")
            && controller.canUndo(),
        "a failed undo keeps both the current document and the undo snapshot");

    const QVariantMap retriedUndo = controller.requestUndo();
    const QString retriedUndoId
        = retriedUndo.value(QStringLiteral("transactionId")).toString();
    passed &= expect(retriedUndo.value(QStringLiteral("accepted")).toBool()
            && controller.confirmPersistence(retriedUndoId)
            && firstFolderLabel(controller.layoutDocument())
                == QStringLiteral("Work")
            && !controller.canUndo(),
        "a successful undo restores the exact prior snapshot without creating redo");

    PunchiMenuLayoutController reentrantController;
    reentrantController.setApplicationStorageIds({
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
    });
    bool reentrantAckSucceeded = false;
    QObject::connect(&reentrantController,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &transactionId,
            const QVariantMap &,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            reentrantAckSucceeded
                = reentrantController.confirmPersistence(transactionId);
        });
    const QVariantMap reentrantRequest
        = reentrantController.requestCreateFolder(
            QString::fromLatin1(firstApplicationId),
            QString::fromLatin1(secondApplicationId),
            QStringLiteral("Immediate"));
    passed &= expect(reentrantRequest.value(QStringLiteral("accepted")).toBool()
            && reentrantAckSucceeded
            && !reentrantController.transactionPending()
            && firstFolderLabel(reentrantController.layoutDocument())
                == QStringLiteral("Immediate")
            && reentrantController.canUndo(),
        "a synchronous persistence callback is reentrancy-safe");

    const QVariantMap reentrantCommittedDocument
        = reentrantController.layoutDocument();
    reentrantController.setLayoutDocument(reentrantCommittedDocument);
    passed &= expect(reentrantController.canUndo(),
        "an external echo of the committed document preserves undo history");
    reentrantController.setLayoutDocument(
        PunchiMenuLayoutDocument::emptyDocument());
    passed &= expect(!reentrantController.canUndo()
            && documentNodes(reentrantController.layoutDocument()).isEmpty(),
        "a distinct valid external replacement clears stale undo history");

    PunchiMenuLayoutController caseController;
    const QString lowerCaseId = QStringLiteral("org.example.Case.desktop");
    const QString upperCaseId = QStringLiteral("ORG.EXAMPLE.CASE.DESKTOP");
    caseController.setApplicationStorageIds({lowerCaseId, upperCaseId});
    QString caseTransactionId;
    QVariantMap caseProposal;
    QObject::connect(&caseController,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &transactionId,
            const QVariantMap &proposedDocument,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            caseTransactionId = transactionId;
            caseProposal = proposedDocument;
        });
    const QVariantMap caseRequest = caseController.requestCreateFolder(
        lowerCaseId, upperCaseId, QStringLiteral("Case"));
    const QVariantList caseMembers = documentNodes(caseProposal)
                                         .constFirst()
                                         .toMap()
                                         .value(QStringLiteral("members"))
                                         .toList();
    passed &= expect(caseRequest.value(QStringLiteral("accepted")).toBool()
            && caseMembers.size() == 2
            && caseMembers.at(0).toString() == lowerCaseId
            && caseMembers.at(1).toString() == upperCaseId
            && caseController.rejectPersistence(
                caseTransactionId, QStringLiteral("test-rejection")),
        "case-distinct Linux storage identities remain distinct in proposals");

    PunchiMenuLayoutController discardController;
    discardController.setApplicationStorageIds({
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
    });
    QString discardTransactionId;
    QObject::connect(&discardController,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &transactionId,
            const QVariantMap &,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            discardTransactionId = transactionId;
        });
    const QVariantMap discardRequest = discardController.requestCreateFolder(
        QString::fromLatin1(firstApplicationId),
        QString::fromLatin1(secondApplicationId),
        QStringLiteral("Discard"));
    discardController.discardUndoHistory();
    passed &= expect(discardRequest.value(QStringLiteral("accepted")).toBool()
            && discardController.confirmPersistence(discardTransactionId)
            && !discardController.canUndo(),
        "closing during persistence prevents undo history from resurfacing");

    PunchiMenuLayoutController invalidRequestController;
    int invalidPersistenceRequests = 0;
    QObject::connect(&invalidRequestController,
        &PunchiMenuLayoutController::persistenceRequested,
        [&](const QString &,
            const QVariantMap &,
            PunchiMenuLayoutController::Operation,
            const QString &) {
            ++invalidPersistenceRequests;
        });
    const QVariantMap invalidRequest
        = invalidRequestController.requestCreateFolder(
            QString::fromLatin1(firstApplicationId),
            QString::fromLatin1(secondApplicationId),
            QStringLiteral("Unavailable"));
    passed &= expect(!invalidRequest.value(QStringLiteral("accepted")).toBool()
            && invalidPersistenceRequests == 0
            && !invalidRequestController.transactionPending()
            && invalidRequestController.revision() == 0,
        "an invalid proposal emits no persistence request and mutates no state");

    return passed ? 0 : 1;
}
