// SPDX-License-Identifier: GPL-3.0-or-later

#include "punchimenulayoutdocument.h"
#include "punchimenulayoutmodel.h"

#include <QCoreApplication>
#include <QJSEngine>

#include <iostream>

namespace
{
bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
    }
    return condition;
}

QVariantMap application(
    const QString &storageId,
    const QString &name = {},
    const QString &icon = {})
{
    return {
        {QStringLiteral("storageId"), storageId},
        {QStringLiteral("name"), name.isEmpty() ? storageId : name},
        {QStringLiteral("icon"), icon.isEmpty()
                ? QStringLiteral("application-x-executable")
                : icon},
    };
}

QVariantMap applicationNode(const QString &storageId)
{
    return {
        {QStringLiteral("type"), QStringLiteral("application")},
        {QStringLiteral("storageId"), storageId},
    };
}

QVariantMap folderNode(
    const QString &folderId,
    const QString &label,
    const QVariantList &members)
{
    return {
        {QStringLiteral("type"), QStringLiteral("folder")},
        {QStringLiteral("folderId"), folderId},
        {QStringLiteral("label"), label},
        {QStringLiteral("members"), members},
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

bool hasValidSurrogatePairs(const QString &value)
{
    for (qsizetype index = 0; index < value.size(); ++index) {
        const QChar character = value.at(index);
        if (character.isHighSurrogate()) {
            if (index + 1 >= value.size()
                || !value.at(index + 1).isLowSurrogate()) {
                return false;
            }
            ++index;
        } else if (character.isLowSurrogate()) {
            return false;
        }
    }
    return true;
}
}

int main(int argc, char **argv)
{
    QCoreApplication applicationInstance(argc, argv);
    Q_UNUSED(applicationInstance)

    bool passed = true;

    const auto absent = PunchiMenuLayoutDocument::sanitize(QVariant{});
    passed &= expect(absent.success && documentNodes(absent.document).isEmpty(),
        "an absent document migrates to an empty version-one document");

    const auto explicitEmptyObject
        = PunchiMenuLayoutDocument::sanitize(QVariantMap{});
    passed &= expect(!explicitEmptyObject.success
            && explicitEmptyObject.errorCode
                == QStringLiteral("unsupported-version"),
        "an explicit empty object is rejected instead of masking invalid persisted state");

    const auto wrongOuterType = PunchiMenuLayoutDocument::sanitize(
        QVariant::fromValue(QVariantList{}));
    passed &= expect(!wrongOuterType.success
            && wrongOuterType.errorCode == QStringLiteral("invalid-document"),
        "a non-object document is rejected before conversion");

    const auto stringVersion = PunchiMenuLayoutDocument::sanitize(QVariantMap{
        {QStringLiteral("version"), QStringLiteral("1")},
        {QStringLiteral("nodes"), QVariantList{}},
    });
    passed &= expect(!stringVersion.success
            && stringVersion.errorCode == QStringLiteral("unsupported-version"),
        "a string schema version is rejected");

    const auto jsonNumberVersion = PunchiMenuLayoutDocument::sanitize(QVariantMap{
        {QStringLiteral("version"), 1.0},
        {QStringLiteral("nodes"), QVariantList{}},
    });
    passed &= expect(jsonNumberVersion.success,
        "an integral JSON number is accepted as schema version one");

    const auto duplicate = PunchiMenuLayoutDocument::sanitize(document({
        applicationNode(QStringLiteral("org.example.Editor.desktop")),
        folderNode(QStringLiteral("work"), QStringLiteral("Work"), {
            QStringLiteral("org.example.Editor.desktop"),
            QStringLiteral("org.example.Terminal.desktop"),
        }),
    }));
    passed &= expect(!duplicate.success
            && duplicate.errorCode == QStringLiteral("duplicate-application"),
        "application identities are unique across standalone and folder nodes");

    const auto caseDistinct = PunchiMenuLayoutDocument::sanitize(document({
        applicationNode(QStringLiteral("org.example.Editor.desktop")),
        applicationNode(QStringLiteral("ORG.EXAMPLE.EDITOR.DESKTOP")),
    }));
    passed &= expect(caseDistinct.success
            && documentNodes(caseDistinct.document).size() == 2,
        "case-distinct desktop storage identifiers remain separate on Linux");

    const auto invalidFolderId = PunchiMenuLayoutDocument::sanitize(document({
        folderNode(QStringLiteral("../folder"), QStringLiteral("Work"), {
            QStringLiteral("org.example.Editor.desktop"),
            QStringLiteral("org.example.Terminal.desktop"),
        }),
    }));
    passed &= expect(!invalidFolderId.success
            && invalidFolderId.errorCode == QStringLiteral("invalid-folder"),
        "folder identifiers reject path-like values");
    passed &= expect(
        PunchiMenuLayoutDocument::normalizedFolderId(QStringLiteral("fólder"))
            .isEmpty(),
        "internal folder identifiers are restricted to a portable ASCII form");

    const auto invalidMemberType = PunchiMenuLayoutDocument::sanitize(document({
        folderNode(QStringLiteral("typed"), QStringLiteral("Typed"), {
            42,
            QStringLiteral("org.example.Terminal.desktop"),
        }),
    }));
    passed &= expect(!invalidMemberType.success
            && invalidMemberType.errorCode == QStringLiteral("invalid-storage-id"),
        "non-string application identities are rejected instead of coerced");

    QString emojiLabel;
    for (int index = 0; index < 81; ++index) {
        emojiLabel.append(QString::fromUtf8("🦎"));
    }
    const QString normalizedEmoji
        = PunchiMenuLayoutDocument::normalizedFolderLabel(emojiLabel);
    passed &= expect(normalizedEmoji.toUcs4().size()
            <= PunchiMenuLayoutDocument::MaximumFolderLabelLength,
        "folder labels are bounded by Unicode code points");
    passed &= expect(hasValidSurrogatePairs(normalizedEmoji),
        "folder labels never end in a split UTF-16 surrogate pair");

    const QString controlledLabel = QStringLiteral("Work\n")
        + QChar(0x202e) + QStringLiteral("Tools");
    passed &= expect(
        PunchiMenuLayoutDocument::normalizedFolderLabel(controlledLabel)
            == QStringLiteral("Work Tools"),
        "line breaks collapse and bidirectional controls are removed from labels");

    QVariantList tooManyMembers;
    for (int index = 0;
         index <= PunchiMenuLayoutDocument::MaximumFolderMembers; ++index) {
        tooManyMembers.append(QStringLiteral("org.example.App%1.desktop").arg(index));
    }
    const auto oversizedFolder = PunchiMenuLayoutDocument::sanitize(document({
        folderNode(QStringLiteral("oversized"), QStringLiteral("Oversized"),
            tooManyMembers),
    }));
    passed &= expect(!oversizedFolder.success
            && oversizedFolder.errorCode
                == QStringLiteral("invalid-folder-member-count"),
        "folder member limits are enforced");

    QVariantList tooManyFolders;
    for (int index = 0;
         index <= PunchiMenuLayoutDocument::MaximumFolders; ++index) {
        tooManyFolders.append(folderNode(
            QStringLiteral("folder-%1").arg(index),
            QStringLiteral("Folder %1").arg(index),
            {
                QStringLiteral("org.example.Folder%1A.desktop").arg(index),
                QStringLiteral("org.example.Folder%1B.desktop").arg(index),
            }));
    }
    const auto oversizedFolderCount
        = PunchiMenuLayoutDocument::sanitize(document(tooManyFolders));
    passed &= expect(!oversizedFolderCount.success
            && oversizedFolderCount.errorCode == QStringLiteral("too-many-folders"),
        "the global folder count limit is enforced");

    QVariantList tooManyApplicationReferences;
    for (int index = 0;
         index <= PunchiMenuLayoutDocument::MaximumApplicationReferences;
         ++index) {
        tooManyApplicationReferences.append(applicationNode(
            QStringLiteral("org.example.Reference%1.desktop").arg(index)));
    }
    const auto oversizedReferenceCount = PunchiMenuLayoutDocument::sanitize(
        document(tooManyApplicationReferences));
    passed &= expect(!oversizedReferenceCount.success
            && oversizedReferenceCount.errorCode
                == QStringLiteral("too-many-application-references"),
        "the global application reference limit is enforced");

    const QVariantMap emptyDocument = PunchiMenuLayoutDocument::emptyDocument();
    const auto seeded = PunchiMenuLayoutDocument::seedApplications(emptyDocument, {
        QStringLiteral("org.example.One.desktop"),
        QStringLiteral("org.example.Two.desktop"),
        QStringLiteral("org.example.Three.desktop"),
        QStringLiteral("org.example.One.desktop"),
    });
    passed &= expect(seeded.success && documentNodes(seeded.document).size() == 3,
        "catalog seeding appends each application identity once");

    const QVariantMap beforeCreate = seeded.document;
    const auto created = PunchiMenuLayoutDocument::createFolder(
        beforeCreate,
        QStringLiteral("org.example.One.desktop"),
        QStringLiteral("org.example.Two.desktop"),
        QStringLiteral("folder-1"),
        QStringLiteral("Work"));
    passed &= expect(created.success && documentNodes(created.document).size() == 2,
        "creating a folder replaces two standalone applications with one node");
    passed &= expect(beforeCreate == seeded.document
            && documentNodes(beforeCreate).size() == 3,
        "folder proposals do not mutate their source document");

    const QVariantList createdNodes = documentNodes(created.document);
    passed &= expect(createdNodes.constFirst().toMap()
                .value(QStringLiteral("type")).toString()
            == QStringLiteral("folder"),
        "a new folder occupies the earliest source application position");

    const QStringList batchStorageIds{
        QStringLiteral("org.example.BatchA.desktop"),
        QStringLiteral("org.example.BatchB.desktop"),
        QStringLiteral("org.example.BatchC.desktop"),
        QStringLiteral("org.example.BatchD.desktop"),
        QStringLiteral("org.example.BatchE.desktop"),
    };
    const auto batchSeeded = PunchiMenuLayoutDocument::seedApplications(
        emptyDocument, batchStorageIds);
    const auto batchCreated = PunchiMenuLayoutDocument::createFolder(
        batchSeeded.document,
        QStringList{
            batchStorageIds.at(3),
            batchStorageIds.at(1),
            batchStorageIds.at(2),
        },
        QStringLiteral("batch-folder"),
        QStringLiteral("Batch"));
    const QVariantList batchNodes = documentNodes(batchCreated.document);
    const QVariantList batchMembers
        = batchNodes.at(1).toMap().value(QStringLiteral("members")).toList();
    passed &= expect(batchCreated.success && batchNodes.size() == 3
            && batchNodes.at(0).toMap()
                    .value(QStringLiteral("storageId")).toString()
                == batchStorageIds.at(0)
            && batchNodes.at(1).toMap()
                    .value(QStringLiteral("type")).toString()
                == QStringLiteral("folder")
            && batchNodes.at(2).toMap()
                    .value(QStringLiteral("storageId")).toString()
                == batchStorageIds.at(4),
        "batch creation replaces all selected nodes at the earliest source position");
    passed &= expect(batchMembers.size() == 3
            && batchMembers.at(0).toString() == batchStorageIds.at(3)
            && batchMembers.at(1).toString() == batchStorageIds.at(1)
            && batchMembers.at(2).toString() == batchStorageIds.at(2),
        "batch creation preserves the caller's exact member order");

    const QVariantMap beforeRejectedBatches = batchSeeded.document;
    const auto tooSmallBatch = PunchiMenuLayoutDocument::createFolder(
        batchSeeded.document,
        QStringList{batchStorageIds.constFirst()},
        QStringLiteral("too-small"),
        QStringLiteral("Too small"));
    const auto duplicateBatch = PunchiMenuLayoutDocument::createFolder(
        batchSeeded.document,
        QStringList{batchStorageIds.constFirst(), batchStorageIds.constFirst()},
        QStringLiteral("duplicate-batch"),
        QStringLiteral("Duplicate"));
    const auto unavailableBatch = PunchiMenuLayoutDocument::createFolder(
        batchSeeded.document,
        QStringList{
            batchStorageIds.constFirst(),
            QStringLiteral("org.example.Unavailable.desktop"),
        },
        QStringLiteral("unavailable-batch"),
        QStringLiteral("Unavailable"));
    QStringList oversizedBatch;
    for (int index = 0;
         index <= PunchiMenuLayoutDocument::MaximumFolderMembers; ++index) {
        oversizedBatch.append(
            QStringLiteral("org.example.BatchLimit%1.desktop").arg(index));
    }
    const auto rejectedOversizedBatch
        = PunchiMenuLayoutDocument::createFolder(
            batchSeeded.document,
            oversizedBatch,
            QStringLiteral("oversized-batch"),
            QStringLiteral("Oversized"));
    passed &= expect(!tooSmallBatch.success
            && tooSmallBatch.errorCode
                == QStringLiteral("invalid-create-folder-request")
            && !duplicateBatch.success
            && duplicateBatch.errorCode
                == QStringLiteral("invalid-create-folder-request")
            && !unavailableBatch.success
            && unavailableBatch.errorCode
                == QStringLiteral("application-not-standalone")
            && !rejectedOversizedBatch.success
            && rejectedOversizedBatch.errorCode
                == QStringLiteral("invalid-create-folder-request")
            && batchSeeded.document == beforeRejectedBatches,
        "invalid batch requests are rejected atomically without partial mutation");

    QStringList maximumBatch;
    for (int index = 0;
         index < PunchiMenuLayoutDocument::MaximumFolderMembers; ++index) {
        maximumBatch.append(
            QStringLiteral("org.example.Maximum%1.desktop").arg(index));
    }
    const auto maximumBatchSeeded
        = PunchiMenuLayoutDocument::seedApplications(
            emptyDocument, maximumBatch);
    const auto maximumBatchCreated
        = PunchiMenuLayoutDocument::createFolder(
            maximumBatchSeeded.document,
            maximumBatch,
            QStringLiteral("maximum-batch"),
            QStringLiteral("Maximum"));
    passed &= expect(maximumBatchCreated.success
            && documentNodes(maximumBatchCreated.document).size() == 1
            && documentNodes(maximumBatchCreated.document).constFirst().toMap()
                    .value(QStringLiteral("members")).toList().size()
                == PunchiMenuLayoutDocument::MaximumFolderMembers,
        "batch creation accepts the documented maximum member count");

    const auto added = PunchiMenuLayoutDocument::addApplicationToFolder(
        created.document,
        QStringLiteral("org.example.Three.desktop"),
        QStringLiteral("folder-1"));
    passed &= expect(added.success
            && documentNodes(added.document).constFirst().toMap()
                    .value(QStringLiteral("members")).toList().size() == 3,
        "a standalone application can be proposed for an existing folder");

    const auto renamed = PunchiMenuLayoutDocument::renameFolder(
        added.document, QStringLiteral("folder-1"),
        QStringLiteral("Work\nTools"));
    passed &= expect(renamed.success
            && documentNodes(renamed.document).constFirst().toMap()
                    .value(QStringLiteral("label")).toString()
                == QStringLiteral("Work Tools"),
        "renaming a folder stores the sanitized one-line label");

    const auto removed = PunchiMenuLayoutDocument::removeApplicationFromFolder(
        renamed.document,
        QStringLiteral("org.example.Two.desktop"),
        QStringLiteral("folder-1"));
    passed &= expect(removed.success && documentNodes(removed.document).size() == 2,
        "removing from a three-member folder keeps the folder and releases the app");

    const auto dissolvedByRemoval
        = PunchiMenuLayoutDocument::removeApplicationFromFolder(
            created.document,
            QStringLiteral("org.example.One.desktop"),
            QStringLiteral("folder-1"));
    const QVariantList dissolvedNodes = documentNodes(dissolvedByRemoval.document);
    passed &= expect(dissolvedByRemoval.success && dissolvedNodes.size() == 3,
        "removing from a two-member folder produces standalone applications");
    passed &= expect(dissolvedNodes.at(0).toMap()
                    .value(QStringLiteral("storageId")).toString()
                == QStringLiteral("org.example.One.desktop")
            && dissolvedNodes.at(1).toMap()
                    .value(QStringLiteral("storageId")).toString()
                == QStringLiteral("org.example.Two.desktop"),
        "automatic dissolution preserves the original member order");

    const auto explicitlyDissolved = PunchiMenuLayoutDocument::dissolveFolder(
        created.document, QStringLiteral("folder-1"));
    passed &= expect(explicitlyDissolved.success
            && documentNodes(explicitlyDissolved.document).size() == 3,
        "explicit dissolution restores every member as a standalone node");

    const QVariantMap beforeFailedProposal = created.document;
    const auto failedProposal = PunchiMenuLayoutDocument::createFolder(
        created.document,
        QStringLiteral("org.example.One.desktop"),
        QStringLiteral("org.example.Three.desktop"),
        QStringLiteral("folder-2"),
        QStringLiteral("Invalid"));
    passed &= expect(!failedProposal.success
            && failedProposal.errorCode
                == QStringLiteral("application-not-standalone")
            && created.document == beforeFailedProposal,
        "a rejected proposal leaves the confirmed source document unchanged");

    const auto movedToFront = PunchiMenuLayoutDocument::moveNode(
        seeded.document,
        QStringLiteral("application:org.example.Three.desktop"),
        QStringLiteral("application:org.example.One.desktop"));
    const QVariantList movedToFrontNodes = documentNodes(movedToFront.document);
    passed &= expect(movedToFront.success
            && movedToFrontNodes.constFirst().toMap()
                    .value(QStringLiteral("storageId")).toString()
                == QStringLiteral("org.example.Three.desktop")
            && seeded.document == beforeCreate,
        "moving a node is pure and inserts it before the requested stable node");

    const auto movedToEnd = PunchiMenuLayoutDocument::moveNode(
        created.document, QStringLiteral("folder:folder-1"), {});
    const QVariantList movedToEndNodes = documentNodes(movedToEnd.document);
    passed &= expect(movedToEnd.success
            && movedToEndNodes.constLast().toMap()
                    .value(QStringLiteral("folderId")).toString()
                == QStringLiteral("folder-1"),
        "moving a folder keeps the complete node and supports insertion at the end");

    const auto missingMoveTarget = PunchiMenuLayoutDocument::moveNode(
        seeded.document,
        QStringLiteral("application:org.example.One.desktop"),
        QStringLiteral("application:org.example.Missing.desktop"));
    passed &= expect(!missingMoveTarget.success
            && missingMoveTarget.errorCode
                == QStringLiteral("move-target-not-found")
            && seeded.document == beforeCreate,
        "a rejected move leaves the confirmed source document unchanged");

    PunchiMenuLayoutModel model;
    QVariantMap firstCatalogApplication = application(
        QStringLiteral("org.example.One.desktop"),
        QStringLiteral("One"),
        QStringLiteral("one"));
    firstCatalogApplication.insert(
        QStringLiteral("command"), QStringLiteral("untrusted --argument"));
    firstCatalogApplication.insert(
        QStringLiteral("appCommand"), QStringLiteral("legacy --argument"));
    model.setApplications({
        firstCatalogApplication,
        application(QStringLiteral("org.example.Two.desktop"),
            QStringLiteral("Two"), QStringLiteral("two")),
        application(QStringLiteral("org.example.Three.desktop"),
            QStringLiteral("Three"), QStringLiteral("three")),
    });
    passed &= expect(model.rowCount() == 3,
        "an empty layout projects the live catalog in stable order");
    passed &= expect(!model.applications().constFirst().toMap().contains(
                         QStringLiteral("command"))
            && !model.applications().constFirst().toMap().contains(
                QStringLiteral("appCommand")),
        "the normalized catalog never retains application commands");

    model.setLayoutDocument(created.document);
    passed &= expect(model.rowCount() == 2
            && model.data(model.index(0, 0), PunchiMenuLayoutModel::NodeTypeRole)
                == QStringLiteral("folder"),
        "the model projects a folder and the remaining standalone application");
    passed &= expect(model.data(model.index(0, 0),
                         PunchiMenuLayoutModel::FolderMemberCountRole).toInt() == 2
            && model.data(model.index(0, 0),
                         PunchiMenuLayoutModel::FolderPreviewIconsRole)
                    .toList().size() == 2,
        "folder roles expose resolved members and preview icons");
    passed &= expect(model.indexForFolder(QStringLiteral("folder-1")) == 0
            && model.indexForNodeId(QStringLiteral("folder:folder-1")) == 0,
        "stable node lookup supports focus restoration after delegate recycling");
    const QVariantMap folderPlacement = model.applicationPlacement(
        QStringLiteral("org.example.One.desktop"));
    const QVariantMap standalonePlacement = model.applicationPlacement(
        QStringLiteral("org.example.Three.desktop"));
    const QVariantMap mismatchedPlacement = model.applicationPlacement(
        QStringLiteral("ORG.EXAMPLE.ONE.DESKTOP"));
    passed &= expect(folderPlacement.value(QStringLiteral("found")).toBool()
            && folderPlacement.value(QStringLiteral("available")).toBool()
            && folderPlacement.value(QStringLiteral("visible")).toBool()
            && folderPlacement.value(QStringLiteral("placement")).toString()
                == QStringLiteral("folder")
            && folderPlacement.value(QStringLiteral("folderId")).toString()
                == QStringLiteral("folder-1")
            && standalonePlacement.value(QStringLiteral("placement")).toString()
                == QStringLiteral("standalone")
            && !mismatchedPlacement.value(QStringLiteral("found")).toBool(),
        "placement queries resolve exact-case standalone and folder identities");
    const QVariantMap initialFolderInfo
        = model.folderInfo(QStringLiteral("folder-1"));
    const QVariantMap mismatchedFolderInfo
        = model.folderInfo(QStringLiteral("FOLDER-1"));
    const QVariantList initialFolderChoices = model.folderChoices();
    passed &= expect(initialFolderInfo.value(QStringLiteral("found")).toBool()
            && initialFolderInfo.value(QStringLiteral("visible")).toBool()
            && initialFolderInfo.value(
                   QStringLiteral("storedMemberCount")).toInt() == 2
            && initialFolderInfo.value(
                   QStringLiteral("visibleMemberCount")).toInt() == 2
            && initialFolderInfo.value(QStringLiteral("members")).toList().size()
                == 2
            && initialFolderInfo.value(
                   QStringLiteral("previewIcons")).toList().size() == 2
            && initialFolderInfo.value(
                   QStringLiteral("canAcceptMembers")).toBool()
            && !mismatchedFolderInfo.value(
                    QStringLiteral("found")).toBool()
            && initialFolderChoices.size() == 1
            && model.folderChoiceCount() == 1
            && initialFolderChoices.constFirst().toMap()
                    .value(QStringLiteral("label")).toString()
                == QStringLiteral("Work"),
        "folder queries expose bounded resolved data without requiring JSON scans");
    const QVariantMap firstResolvedMember
        = initialFolderInfo.value(QStringLiteral("members"))
              .toList().constFirst().toMap();
    passed &= expect(!firstResolvedMember.contains(QStringLiteral("appCommand"))
            && !firstResolvedMember.contains(QStringLiteral("command")),
        "resolved folder members do not expose or retain application commands");

    model.setHiddenApplicationIds({
        QStringLiteral("org.example.One.desktop"),
    });
    passed &= expect(model.rowCount() == 2
            && model.data(model.index(0, 0),
                         PunchiMenuLayoutModel::FolderMemberCountRole).toInt() == 1,
        "hidden applications are excluded from folder contents and previews");
    const QVariantMap partiallyHiddenInfo
        = model.folderInfo(QStringLiteral("folder-1"));
    passed &= expect(partiallyHiddenInfo.value(
                         QStringLiteral("storedMemberCount")).toInt() == 2
            && partiallyHiddenInfo.value(
                   QStringLiteral("visibleMemberCount")).toInt() == 1
            && !model.applicationPlacement(
                         QStringLiteral("org.example.One.desktop"))
                    .value(QStringLiteral("visible")).toBool(),
        "folder queries distinguish persisted members from currently visible members");

    model.setHiddenApplicationIds({
        QStringLiteral("org.example.One.desktop"),
        QStringLiteral("org.example.Two.desktop"),
    });
    passed &= expect(model.rowCount() == 1
            && model.data(model.index(0, 0), PunchiMenuLayoutModel::NodeTypeRole)
                == QStringLiteral("application"),
        "a folder with no visible members is omitted at runtime");
    const QVariantMap fullyHiddenInfo
        = model.folderInfo(QStringLiteral("folder-1"));
    passed &= expect(fullyHiddenInfo.value(QStringLiteral("found")).toBool()
            && !fullyHiddenInfo.value(QStringLiteral("visible")).toBool()
            && fullyHiddenInfo.value(
                   QStringLiteral("storedMemberCount")).toInt() == 2
            && fullyHiddenInfo.value(
                   QStringLiteral("visibleMemberCount")).toInt() == 0
            && model.folderChoices().isEmpty()
            && model.folderChoiceCount() == 0,
        "an invisible folder remains queryable but is omitted from target choices");

    model.setRevealHiddenApplications(true);
    passed &= expect(model.rowCount() == 2
            && model.data(model.index(0, 0),
                         PunchiMenuLayoutModel::FolderMemberCountRole).toInt() == 2,
        "revealing hidden applications restores their folder and preview count");
    const QVariantList revealedMembers = model.data(model.index(0, 0),
        PunchiMenuLayoutModel::FolderMembersRole).toList();
    passed &= expect(revealedMembers.constFirst().toMap()
                .value(QStringLiteral("hidden")).toBool(),
        "resolved folder members retain hidden state for the existing indicator");
    passed &= expect(revealedMembers.constFirst().toMap()
                    .value(QStringLiteral("appStorageId")).toString()
                == QStringLiteral("org.example.One.desktop")
            && !revealedMembers.constFirst().toMap()
                    .value(QStringLiteral("appName")).toString().isEmpty(),
        "resolved members use the same application role contract as grid nodes");

    model.setRevealHiddenApplications(false);
    model.setHiddenApplicationIds({});
    model.setApplications({
        application(QStringLiteral("org.example.One.desktop"),
            QStringLiteral("One"), QStringLiteral("one")),
        application(QStringLiteral("org.example.Three.desktop"),
            QStringLiteral("Three"), QStringLiteral("three")),
    });
    passed &= expect(model.rowCount() == 2
            && model.data(model.index(0, 0),
                         PunchiMenuLayoutModel::FolderMemberCountRole).toInt() == 1
            && documentNodes(model.layoutDocument()).constFirst().toMap()
                    .value(QStringLiteral("members")).toList().size() == 2,
        "missing applications are omitted without destructively rewriting folders");
    const QVariantMap missingMemberInfo
        = model.folderInfo(QStringLiteral("folder-1"));
    const QVariantMap missingMemberPlacement = model.applicationPlacement(
        QStringLiteral("org.example.Two.desktop"));
    passed &= expect(missingMemberInfo.value(
                         QStringLiteral("storedMemberCount")).toInt() == 2
            && missingMemberInfo.value(
                   QStringLiteral("visibleMemberCount")).toInt() == 1
            && missingMemberPlacement.value(QStringLiteral("found")).toBool()
            && !missingMemberPlacement.value(
                   QStringLiteral("available")).toBool()
            && !missingMemberPlacement.value(QStringLiteral("visible")).toBool(),
        "queries retain persisted placement while marking unavailable members safely");

    const QVariantMap lastValidDocument = model.layoutDocument();
    model.setLayoutDocument(QVariantMap{
        {QStringLiteral("version"), 99},
        {QStringLiteral("nodes"), QVariantList{}},
    });
    passed &= expect(model.layoutDocument() == lastValidDocument
            && model.lastErrorCode() == QStringLiteral("unsupported-version"),
        "an invalid replacement preserves the last valid layout document");

    passed &= expect(model.roleNames().value(PunchiMenuLayoutModel::NodeIdRole)
                == QByteArrayLiteral("nodeId")
            && model.roleNames().value(
                   PunchiMenuLayoutModel::FolderMembersRole)
                == QByteArrayLiteral("folderMembers")
            && !model.roleNames().values().contains(
                QByteArrayLiteral("appCommand")),
        "the QML role contract exposes stable data without command-bearing roles");

    PunchiMenuLayoutModel alphabeticalModel;
    alphabeticalModel.setApplications({
        application(QStringLiteral("org.example.Zulu.desktop"),
            QStringLiteral("Zulu"), QStringLiteral("zulu")),
        application(QStringLiteral("org.example.Alpha.desktop"),
            QStringLiteral("Alpha"), QStringLiteral("alpha")),
        application(QStringLiteral("org.example.Bravo.desktop"),
            QStringLiteral("Bravo"), QStringLiteral("bravo")),
        application(QStringLiteral("org.example.Echo.desktop"),
            QStringLiteral("Echo"), QStringLiteral("echo")),
    });
    alphabeticalModel.setLayoutDocument(document({
        applicationNode(QStringLiteral("org.example.Zulu.desktop")),
        folderNode(QStringLiteral("folder-alpha"),
            QStringLiteral("Alpha Folder"), {
                QStringLiteral("org.example.Alpha.desktop"),
                QStringLiteral("org.example.Echo.desktop"),
            }),
        applicationNode(QStringLiteral("org.example.Bravo.desktop")),
    }));
    const QVariantMap alphabeticalSourceDocument
        = alphabeticalModel.effectiveLayoutDocument();
    alphabeticalModel.setAlphabeticalSortingEnabled(true);
    passed &= expect(alphabeticalModel.alphabeticalSortingEnabled()
            && alphabeticalModel.data(alphabeticalModel.index(0, 0),
                   Qt::DisplayRole).toString()
                == QStringLiteral("Alpha Folder")
            && alphabeticalModel.data(alphabeticalModel.index(1, 0),
                   Qt::DisplayRole).toString()
                == QStringLiteral("Bravo")
            && alphabeticalModel.data(alphabeticalModel.index(2, 0),
                   Qt::DisplayRole).toString()
                == QStringLiteral("Zulu")
            && alphabeticalModel.effectiveLayoutDocument()
                == alphabeticalSourceDocument,
        "alphabetical sorting changes only the visible projection and includes folders");
    alphabeticalModel.setAlphabeticalSortingEnabled(false);
    passed &= expect(alphabeticalModel.data(alphabeticalModel.index(0, 0),
                   Qt::DisplayRole).toString()
                == QStringLiteral("Zulu")
            && alphabeticalModel.data(alphabeticalModel.index(1, 0),
                   Qt::DisplayRole).toString()
                == QStringLiteral("Alpha Folder"),
        "disabling alphabetical sorting restores the persisted manual order");

    PunchiMenuLayoutModel categoryModel;
    QVariantMap browserApplication = application(
        QStringLiteral("org.example.Browser.desktop"),
        QStringLiteral("Zulu Browser"), QStringLiteral("browser"));
    browserApplication.insert(QStringLiteral("categories"),
        QStringList{QStringLiteral("Network"),
            QStringLiteral("WebBrowser")});
    QVariantMap mailApplication = application(
        QStringLiteral("org.example.Mail.desktop"),
        QStringLiteral("Alpha Mail"), QStringLiteral("mail"));
    mailApplication.insert(QStringLiteral("categories"),
        QStringList{QStringLiteral("Network"), QStringLiteral("Email")});
    QVariantMap graphicsApplication = application(
        QStringLiteral("org.example.Graphics.desktop"),
        QStringLiteral("Graphics"), QStringLiteral("graphics"));
    graphicsApplication.insert(QStringLiteral("categories"),
        QVariantList{QStringLiteral("X-Flatpak"),
            QStringLiteral("Graphics")});
    QVariantMap uncategorizedApplication = application(
        QStringLiteral("org.example.Custom.desktop"),
        QStringLiteral("Custom"), QStringLiteral("custom"));
    uncategorizedApplication.insert(QStringLiteral("categories"),
        QStringList{QStringLiteral("X-Custom")});
    categoryModel.setApplications({browserApplication, mailApplication,
        graphicsApplication, uncategorizedApplication});
    const QVariantList categoryGroups = categoryModel.categoryGroups();
    const QVariantList networkMembers = categoryGroups.constFirst().toMap()
        .value(QStringLiteral("members")).toList();
    passed &= expect(categoryGroups.size() == 3
            && categoryGroups.constFirst().toMap()
                    .value(QStringLiteral("categoryId")).toString()
                == QStringLiteral("Network")
            && networkMembers.size() == 2
            && networkMembers.constFirst().toMap()
                    .value(QStringLiteral("appName")).toString()
                == QStringLiteral("Alpha Mail")
            && categoryGroups.constLast().toMap()
                    .value(QStringLiteral("categoryId")).toString()
                == QStringLiteral("Other"),
        "category groups follow KDE order and alphabetize their applications");
    passed &= expect(categoryGroups.at(1).toMap()
                    .value(QStringLiteral("categoryId")).toString()
                == QStringLiteral("Graphics")
            && categoryGroups.at(1).toMap()
                    .value(QStringLiteral("memberCount")).toInt() == 1,
        "QML-style category arrays preserve package-specific metadata and KDE grouping");
    QJSEngine qmlEngine;
    QVariantMap qmlApplication = application(
        QStringLiteral("org.example.Qml.desktop"),
        QStringLiteral("QML Browser"), QStringLiteral("browser"));
    qmlApplication.insert(QStringLiteral("categories"), QVariant::fromValue(
        qmlEngine.evaluate(QStringLiteral("['Network', 'WebBrowser']"))));
    PunchiMenuLayoutModel qmlCategoryModel;
    qmlCategoryModel.setApplications({qmlApplication});
    passed &= expect(qmlCategoryModel.categoryGroups().size() == 1
            && qmlCategoryModel.categoryGroups().constFirst().toMap()
                    .value(QStringLiteral("categoryId")).toString()
                == QStringLiteral("Network"),
        "QJSValue category arrays survive the QML-to-model boundary");
    categoryModel.setLayoutDocument(document({
        folderNode(QStringLiteral("network-folder"),
            QStringLiteral("Network tools"), {
                QStringLiteral("org.example.Browser.desktop"),
                QStringLiteral("org.example.Mail.desktop"),
            }),
        applicationNode(QStringLiteral("org.example.Graphics.desktop")),
        applicationNode(QStringLiteral("org.example.Custom.desktop")),
    }));
    const QVariantList categoryGroupsWithFolder
        = categoryModel.categoryGroups();
    passed &= expect(categoryModel.data(categoryModel.index(0, 0),
                         PunchiMenuLayoutModel::NodeTypeRole).toString()
                == QStringLiteral("folder")
            && categoryGroupsWithFolder.size() == 2
            && categoryGroupsWithFolder.constFirst().toMap()
                    .value(QStringLiteral("categoryId")).toString()
                == QStringLiteral("Graphics"),
        "applications in user folders remain separate from category sections");

    QVariantList capacityMembers;
    for (int index = 0;
         index < PunchiMenuLayoutDocument::MaximumFolderMembers; ++index) {
        capacityMembers.append(
            QStringLiteral("org.example.Capacity%1.desktop").arg(index));
    }
    PunchiMenuLayoutModel capacityModel;
    capacityModel.setApplications({
        application(capacityMembers.constFirst().toString()),
    });
    capacityModel.setLayoutDocument(document({
        folderNode(QStringLiteral("capacity-folder"),
            QStringLiteral("Capacity"), capacityMembers),
    }));
    const QVariantMap capacityInfo
        = capacityModel.folderInfo(QStringLiteral("capacity-folder"));
    passed &= expect(capacityInfo.value(
                         QStringLiteral("storedMemberCount")).toInt()
                == PunchiMenuLayoutDocument::MaximumFolderMembers
            && capacityInfo.value(
                   QStringLiteral("visibleMemberCount")).toInt() == 1
            && !capacityInfo.value(
                    QStringLiteral("canAcceptMembers")).toBool()
            && capacityModel.folderChoices().size() == 1
            && capacityModel.folderChoiceCount() == 1
            && !capacityModel.folderChoices().constFirst().toMap()
                    .value(QStringLiteral("canAcceptMembers")).toBool(),
        "folder choices use persisted counts when enforcing member capacity");

    PunchiMenuLayoutModel caseSensitiveModel;
    caseSensitiveModel.setApplications({
        application(QStringLiteral("org.example.Case.desktop"),
            QStringLiteral("Lower case"), QStringLiteral("lower")),
        application(QStringLiteral("ORG.EXAMPLE.CASE.DESKTOP"),
            QStringLiteral("Upper case"), QStringLiteral("upper")),
    });
    passed &= expect(caseSensitiveModel.rowCount() == 2,
        "the live catalog preserves case-distinct desktop storage identifiers");
    caseSensitiveModel.setHiddenApplicationIds({
        QStringLiteral("org.example.Case.desktop"),
    });
    passed &= expect(caseSensitiveModel.rowCount() == 1
            && caseSensitiveModel.data(caseSensitiveModel.index(0, 0),
                   PunchiMenuLayoutModel::AppStorageIdRole).toString()
                == QStringLiteral("ORG.EXAMPLE.CASE.DESKTOP"),
        "hiding one exact storage identity does not hide a case-distinct app");

    PunchiMenuLayoutModel signalOrderModel;
    bool applicationsHandlerObservedRebuiltState = false;
    QObject::connect(&signalOrderModel,
        &PunchiMenuLayoutModel::applicationsChanged,
        [&]() {
            applicationsHandlerObservedRebuiltState
                = signalOrderModel.rowCount() == 1
                && signalOrderModel.nodes().size() == 1;
        });
    signalOrderModel.setApplications({
        application(QStringLiteral("org.example.Signal.desktop")),
    });
    passed &= expect(applicationsHandlerObservedRebuiltState,
        "source property handlers observe already-rebuilt derived state");

    signalOrderModel.setApplications({
        application(QStringLiteral("org.example.One.desktop")),
        application(QStringLiteral("org.example.Two.desktop")),
        application(QStringLiteral("org.example.Three.desktop")),
    });
    bool layoutHandlerObservedRebuiltState = false;
    QObject::connect(&signalOrderModel,
        &PunchiMenuLayoutModel::layoutDocumentChanged,
        [&]() {
            layoutHandlerObservedRebuiltState
                = signalOrderModel.rowCount() == 2
                && signalOrderModel.data(signalOrderModel.index(0, 0),
                       PunchiMenuLayoutModel::NodeTypeRole).toString()
                    == QStringLiteral("folder");
        });
    signalOrderModel.setLayoutDocument(created.document);
    passed &= expect(layoutHandlerObservedRebuiltState,
        "layout property handlers observe the reconciled model state");

    return passed ? 0 : 1;
}
