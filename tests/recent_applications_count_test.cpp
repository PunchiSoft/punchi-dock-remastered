// SPDX-License-Identifier: GPL-3.0-or-later
#include "recentapplicationsmodel.h"
#include <QAbstractItemModelTester>
#include <QCoreApplication>
#include <QSignalSpy>
#include <QStandardItemModel>
#include <iostream>

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    bool passed = true;
    const auto check = [&](bool result, const char *message) {
        if (!result) { std::cerr << "FAILED: " << message << '\n'; passed = false; }
    };
    constexpr int storageRole = Qt::UserRole + 1;
    QStandardItemModel source;
    source.setItemRoleNames({{storageRole, "storageId"}});
    for (int i = 0; i < 30; ++i) {
        auto *row = new QStandardItem;
        row->setData(QStringLiteral("org.example.Count%1.desktop").arg(i), storageRole);
        source.appendRow(row);
    }
    RecentApplicationsModel model;
    QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::Fatal);
    QSignalSpy changes(&model, &RecentApplicationsModel::maximumItemsChanged);
    model.setSourceModel(&source);
    check(model.maximumItems() == 3 && model.count() == 0, "The default limit is three and disabled selection is empty");
    model.setEnabled(true);
    check(model.count() == 3, "Default selection preserves three items");
    model.setMaximumItems(8);
    check(model.count() == 8 && changes.count() == 1, "Increasing the limit immediately admits more rows");
    model.setExcludedStorageIds({QStringLiteral("org.example.Count0.desktop"), QStringLiteral("org.example.Count1")});
    check(model.count() == 8 && model.get(0).value(QStringLiteral("storageId")).toString() == QLatin1String("org.example.Count2.desktop"),
        "Exclusions apply before the configurable limit");
    model.setMaximumItems(1);
    check(model.count() == 1, "Reducing the limit removes extra rows immediately");
    source.removeRow(2);
    check(model.count() == 1 && model.get(0).value(QStringLiteral("storageId")).toString() == QLatin1String("org.example.Count3.desktop"),
        "A removal replenishes from the next eligible candidate");
    model.setMaximumItems(1000);
    check(model.maximumItems() == 20 && model.count() == 20, "Oversized configuration is bounded to twenty");
    const int notifications = changes.count();
    model.setMaximumItems(21);
    check(changes.count() == notifications, "An unchanged effective limit emits no redundant notification");
    model.setMaximumItems(-10);
    check(model.maximumItems() == 1 && model.count() == 1, "Invalid negative configuration is bounded to one");
    model.setEnabled(false);
    model.setMaximumItems(7);
    check(model.count() == 0, "Changing the quantity does not enable history");
    model.setEnabled(true);
    check(model.count() == 7, "Re-enabling preserves the configured limit");
    model.setSourceModel(nullptr);
    check(model.count() == 0, "An absent provider remains safe at any quantity");
    if (passed) { std::cout << "Recent applications count model: PASS\n"; }
    return passed ? 0 : 1;
}
