// SPDX-License-Identifier: GPL-3.0-or-later
#include "folderpopupentriesmodel.h"
#include <QAbstractItemModelTester>
#include <QSignalSpy>
#include <QStandardItemModel>
#include <QtTest>

class FolderPopupEntriesModelTest : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void init() { QTest::failOnWarning(QRegularExpression(QStringLiteral(".?"))); }
    void entriesAndFinalAction()
    {
        FolderPopupEntriesModel model;
        QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
        QCOMPARE(model.count(), 0);
        model.setAppendOpenLocation(true);
        QCOMPARE(model.count(), 1);
        QVERIFY(row(model, 0).value(QStringLiteral("_punchiOpenLocationAction")).toBool());
        const QVariantList entries{QVariantMap{{QStringLiteral("name"), QStringLiteral("First")}}};
        model.setEntries(entries);
        QCOMPARE(model.count(), 2);
        QCOMPARE(row(model, 0).value(QStringLiteral("name")).toString(), QStringLiteral("First"));
        QVERIFY(row(model, 1).value(QStringLiteral("_punchiOpenLocationAction")).toBool());
        QCOMPARE(model.entries(), entries);
        model.setAppendOpenLocation(false);
        QCOMPARE(model.count(), 1);
        QVERIFY(!model.data(model.index(1, 0), Qt::UserRole + 1).isValid());
        model.setEntries({});
        QCOMPARE(model.count(), 0);
    }
    void nativeRowsRemainReactive()
    {
        constexpr int sourceRole = Qt::UserRole + 12;
        auto source = std::make_unique<QStandardItemModel>();
        source->setItemRoleNames({{sourceRole, "modelData"}});
        FolderPopupEntriesModel model;
        QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
        model.setAppendOpenLocation(true);
        model.setSourceModel(source.get());
        QCOMPARE(model.sourceModel(), source.get());
        QCOMPARE(model.count(), 1);
        auto *first = new QStandardItem;
        first->setData(QVariantMap{{QStringLiteral("name"), QStringLiteral("First")}}, sourceRole);
        source->appendRow(first);
        QCOMPARE(model.count(), 2);
        QCOMPARE(row(model, 0).value(QStringLiteral("name")).toString(), QStringLiteral("First"));
        auto *second = new QStandardItem;
        second->setData(QVariantMap{{QStringLiteral("name"), QStringLiteral("Second")}}, sourceRole);
        source->insertRow(0, second);
        QCOMPARE(model.count(), 3);
        QVERIFY(row(model, 2).value(QStringLiteral("_punchiOpenLocationAction")).toBool());
        QSignalSpy changed(&model, &QAbstractItemModel::dataChanged);
        second->setData(QVariantMap{{QStringLiteral("name"), QStringLiteral("Updated")}}, sourceRole);
        QCOMPARE(changed.count(), 1);
        QCOMPARE(row(model, 0).value(QStringLiteral("name")).toString(), QStringLiteral("Updated"));
        source->removeRow(1);
        QCOMPARE(model.count(), 2);
        source->clear();
        QCOMPARE(model.count(), 1);
        QVERIFY(row(model, 0).value(QStringLiteral("_punchiOpenLocationAction")).toBool());
        QSignalSpy destroyed(&model, &FolderPopupEntriesModel::sourceModelChanged);
        source.reset();
        QCOMPARE(destroyed.count(), 1);
        QVERIFY(!model.sourceModel());
        QCOMPARE(model.count(), 1);
        model.setAppendOpenLocation(false);
        QCOMPARE(model.count(), 0);
    }
private:
    static QVariantMap row(const FolderPopupEntriesModel &model, int index)
    {
        return model.data(model.index(index, 0), Qt::UserRole + 1).toMap();
    }
};

QTEST_GUILESS_MAIN(FolderPopupEntriesModelTest)
#include "folder_popup_entries_model_test.moc"
