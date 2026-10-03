// SPDX-License-Identifier: GPL-3.0-or-later

#include "recentapplicationsmodel.h"

#include <QAbstractItemModelTester>
#include <QCoreApplication>
#include <QPersistentModelIndex>
#include <QStandardItemModel>

#include <iostream>

namespace
{
enum SourceRole { StorageId = Qt::UserRole + 1, Name, Icon };

bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
    }
    return condition;
}

void setupSource(QStandardItemModel &source)
{
    source.setItemRoleNames({{StorageId, "storageId"}, {Name, "name"}, {Icon, "icon"}});
}

QStandardItem *item(const QVariant &storageId)
{
    auto *result = new QStandardItem;
    result->setData(storageId, StorageId);
    result->setData(QStringLiteral("Example application"), Name);
    result->setData(QStringLiteral("application-x-executable"), Icon);
    return result;
}

QStringList identities(const RecentApplicationsModel &model)
{
    QStringList result;
    for (const auto &value : model.items()) {
        result.append(value.toMap().value(QStringLiteral("storageId")).toString());
    }
    return result;
}
}

int main(int argc, char **argv)
{
    QCoreApplication application(argc, argv);
    bool passed = true;
    QStandardItemModel source;
    setupSource(source);
    source.appendRow(item(QStringLiteral("org.example.First.desktop")));
    source.appendRow(item(QStringLiteral("org.example.Second.desktop")));
    source.appendRow(item(QStringLiteral("org.example.Third.desktop")));
    source.appendRow(item(QStringLiteral("org.example.Fourth.desktop")));
    source.appendRow(item(QStringLiteral("org.example.Fifth.desktop")));

    RecentApplicationsModel model;
    model.setSourceModel(&source);
    QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::Fatal);
    passed &= expect(model.count() == 0, "recent applications are disabled by default");
    model.setEnabled(true);
    passed &= expect(model.count() == 3, "five candidates produce exactly three visible applications");
    passed &= expect(identities(model) == QStringList{
        QStringLiteral("org.example.First.desktop"),
        QStringLiteral("org.example.Second.desktop"),
        QStringLiteral("org.example.Third.desktop")},
        "source recency order is preserved");

    model.setExcludedStorageIds({QStringLiteral("applications:org.example.First.desktop"),
        QStringLiteral("org.example.Second")});
    passed &= expect(identities(model) == QStringList{
        QStringLiteral("org.example.Third.desktop"),
        QStringLiteral("org.example.Fourth.desktop"),
        QStringLiteral("org.example.Fifth.desktop")},
        "pinned and running exclusions are applied before the three-item limit");
    const QPersistentModelIndex thirdIndex(model.index(0, 0));
    model.setExcludedStorageIds({QStringLiteral("org.example.First.desktop"),
        QStringLiteral("org.example.Second.desktop"),
        QStringLiteral("org.example.Third.desktop")});
    passed &= expect(model.count() == 2 && !thirdIndex.isValid(),
        "launching a recent application removes its entry immediately");
    model.setExcludedStorageIds({QStringLiteral("org.example.First.desktop"),
        QStringLiteral("org.example.Second.desktop")});
    passed &= expect(model.get(0).value(QStringLiteral("storageId")).toString()
        == QStringLiteral("org.example.Third.desktop"),
        "closing the last window restores the candidate without changing its recency order");

    const QVariantMap descriptor = model.get(0);
    passed &= expect(descriptor.value(QStringLiteral("storageId")) == source.index(2, 0).data(StorageId)
        && descriptor.value(QStringLiteral("entryRole")) == QStringLiteral("recent")
        && descriptor.value(QStringLiteral("key")) == QStringLiteral("recent:org.example.Third.desktop"),
        "visual role is distinct while canonical application identity is retained");
    const int recentRole = model.roleNames().key("recentItem", -1);
    passed &= expect(recentRole > Icon && model.index(0, 0).data(recentRole).toMap() == descriptor,
        "QML delegates receive a recent descriptor without overwriting provider roles");
    passed &= expect(model.get(-1).isEmpty() && model.get(3).isEmpty(),
        "invalid row lookups are safe");

    model.setExcludedStorageIds({});
    source.removeRow(0);
    passed &= expect(identities(model) == QStringList{
        QStringLiteral("org.example.Second.desktop"),
        QStringLiteral("org.example.Third.desktop"),
        QStringLiteral("org.example.Fourth.desktop")},
        "removing a candidate fills the freed slot from previously filtered rows");
    source.insertRow(0, item(QStringLiteral("org.example.Fifth.desktop")));
    passed &= expect(model.count() == 3
        && identities(model).first() == QStringLiteral("org.example.Fifth.desktop"),
        "new recent source rows update selection reactively");
    source.insertRow(0, item(QStringLiteral("org.example.Fifth")));
    passed &= expect(model.count() == 3 && identities(model).at(1)
        == QStringLiteral("org.example.Second.desktop"),
        "duplicate application identities consume only one recent slot");
    source.insertRow(0, item(42));
    source.insertRow(0, item(QStringLiteral("../unsafe.desktop")));
    source.insertRow(0, item(QStringLiteral("org.example.\nInvalid.desktop")));
    source.insertRow(0, item(QStringLiteral(".desktop")));
    passed &= expect(model.count() == 3 && identities(model).first()
        == QStringLiteral("org.example.Fifth"),
        "invalid identities do not consume slots or become launchers");
    source.setData(source.index(4, 0), QStringLiteral("org.example.Latest.desktop"), StorageId);
    passed &= expect(identities(model).first() == QStringLiteral("org.example.Latest.desktop"),
        "identity changes invalidate hidden and visible candidate selection");

    QStandardItemModel caseSource;
    setupSource(caseSource);
    caseSource.appendRow(item(QStringLiteral("org.example.Editor.desktop")));
    caseSource.appendRow(item(QStringLiteral("org.example.editor.desktop")));
    caseSource.appendRow(item(QStringLiteral("org.example.Other.desktop")));
    model.setSourceModel(&caseSource);
    model.setExcludedStorageIds({QStringLiteral("org.example.Editor.desktop")});
    passed &= expect(model.count() == 2 && identities(model).first()
        == QStringLiteral("org.example.editor.desktop"),
        "case-distinct Linux application identities remain distinct");
    model.setEnabled(false);
    passed &= expect(model.count() == 0 && model.items().isEmpty(),
        "disabling recent applications removes every visible row");
    model.setEnabled(true);
    passed &= expect(model.count() == 2, "re-enabling restores selection without losing source data");
    model.setSourceModel(nullptr);
    passed &= expect(model.count() == 0 && model.get(0).isEmpty(), "an absent provider is safe");
    auto *temporarySource = new QStandardItemModel;
    setupSource(*temporarySource);
    temporarySource->appendRow(item(QStringLiteral("org.example.Temporary.desktop")));
    model.setSourceModel(temporarySource);
    passed &= expect(model.count() == 1, "a replacement provider can populate the model");
    delete temporarySource;
    passed &= expect(model.count() == 0, "destroying the provider clears the proxy safely");
    return passed ? 0 : 1;
}
