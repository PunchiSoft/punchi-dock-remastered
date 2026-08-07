// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockitemsjsontransaction.h"

#include <KConfig>
#include <KConfigGroup>
#include <KCoreConfigSkeleton>
#include <KSharedConfig>

#include <QCoreApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTemporaryDir>

#include <cstdlib>
#include <iostream>
#include <memory>
#include <utility>

namespace
{
class TestSkeleton final : public KCoreConfigSkeleton
{
public:
    TestSkeleton(const KSharedConfig::Ptr &configuration,
        QString &dockItemsJson, QString &otherSetting)
        : KCoreConfigSkeleton(configuration)
    {
        setCurrentGroup(QStringLiteral("General"));
        addItemString(QStringLiteral("dockItemsJson"), dockItemsJson,
            QStringLiteral("[]"));
        addItemString(QStringLiteral("otherSetting"), otherSetting,
            QStringLiteral("baseline"));
        load();
    }
};

class SkeletonFixture final
{
public:
    SkeletonFixture()
    {
        if (!directory.isValid()) {
            return;
        }
        configPath = directory.filePath(QStringLiteral("transactiontestrc"));
        configuration = KSharedConfig::openConfig(
            configPath, KConfig::SimpleConfig);
        skeleton = std::make_unique<TestSkeleton>(
            configuration, dockItemsJson, otherSetting);
    }

    [[nodiscard]] bool isValid() const
    {
        return directory.isValid() && configuration && skeleton;
    }

    [[nodiscard]] QString persistedValue(
        const QString &key, const QString &defaultValue) const
    {
        KConfig durableConfiguration(configPath, KConfig::SimpleConfig);
        const KConfigGroup group(
            &durableConfiguration, QStringLiteral("General"));
        return group.readEntry(key, defaultValue);
    }

    [[nodiscard]] QString persistedJson() const
    {
        return persistedValue(
            QStringLiteral("dockItemsJson"), QStringLiteral("[]"));
    }

    [[nodiscard]] QString persistedOtherSetting() const
    {
        return persistedValue(
            QStringLiteral("otherSetting"), QStringLiteral("baseline"));
    }

    [[nodiscard]] bool writeExternalJson(const QString &value) const
    {
        KConfig externalConfiguration(configPath, KConfig::SimpleConfig);
        KConfigGroup group(
            &externalConfiguration, QStringLiteral("General"));
        group.writeEntry(QStringLiteral("dockItemsJson"), value);
        return externalConfiguration.sync();
    }

    [[nodiscard]] KConfigSkeletonItem *dockItemsItem() const
    {
        return skeleton
            ? skeleton->findItem(QStringLiteral("dockItemsJson"))
            : nullptr;
    }

    [[nodiscard]] KConfigSkeletonItem *otherSettingItem() const
    {
        return skeleton
            ? skeleton->findItem(QStringLiteral("otherSetting"))
            : nullptr;
    }

    [[nodiscard]] DockItemsJsonTransaction::Result commit(
        const QString &expectedRaw,
        const QString &nextRaw,
        DockItemsJsonTransaction::SyncFunction syncFunction = {})
    {
        return DockItemsJsonTransaction::commit(
            skeleton.get(), transactionState,
            expectedRaw, nextRaw, std::move(syncFunction));
    }

    [[nodiscard]] DockItemsJsonTransaction::Result reconcile(
        const QString &expectedDurable)
    {
        return DockItemsJsonTransaction::reconcile(
            skeleton.get(), transactionState, expectedDurable);
    }

    QTemporaryDir directory;
    QString configPath;
    QString dockItemsJson;
    QString otherSetting;
    KSharedConfig::Ptr configuration;
    std::unique_ptr<TestSkeleton> skeleton;
    DockItemsJsonTransaction::State transactionState;
};

bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
    }
    return condition;
}

QString canonicalLayoutCandidate()
{
    return QStringLiteral(
        R"([{"type":"punchimenu","applicationLayout":{"version":1,"nodes":[]}}])");
}

bool testSuccessAndNoOp()
{
    SkeletonFixture fixture;
    if (!fixture.isValid()) {
        return expect(false, "the success fixture is available");
    }

    int changeSignalCount = 0;
    QObject::connect(fixture.skeleton.get(),
        &KCoreConfigSkeleton::configChanged,
        [&changeSignalCount]() { ++changeSignalCount; });

    const QString committedJson = canonicalLayoutCandidate();
    const auto committed = fixture.commit(
        QStringLiteral("[]"), committedJson);
    bool passed = expect(committed.success && committed.changed
            && !committed.rolledBack && committed.errorCode.isEmpty()
            && committed.currentJson == committedJson,
        "a valid compare-and-swap persists only the candidate key");
    passed &= expect(fixture.dockItemsJson == committedJson
            && fixture.persistedJson() == committedJson
            && changeSignalCount == 1
            && fixture.dockItemsItem()
            && !fixture.dockItemsItem()->isSaveNeeded(),
        "a successful transaction adopts memory, disk, and loaded state");

    const auto unchanged = fixture.commit(committedJson, committedJson);
    passed &= expect(unchanged.success && !unchanged.changed
            && unchanged.currentJson == committedJson
            && changeSignalCount == 1,
        "an identical durable candidate is a successful no-op");

    const QVariantMap structured = unchanged.toVariantMap();
    passed &= expect(structured.value(QStringLiteral("success")).toBool()
            && !structured.value(QStringLiteral("changed")).toBool()
            && structured.value(QStringLiteral("currentJson")).toString()
                == committedJson,
        "the result exposes stable structured fields for QML");
    return passed;
}

bool testIsolatesOtherPendingSettings()
{
    SkeletonFixture fixture;
    if (!fixture.isValid() || !fixture.otherSettingItem()) {
        return expect(false, "the isolation fixture is available");
    }

    fixture.otherSettingItem()->setProperty(QStringLiteral("pending"));
    const auto committed = fixture.commit(
        QStringLiteral("[]"), canonicalLayoutCandidate());
    bool passed = expect(committed.success && committed.changed,
        "the dock item transaction succeeds with another pending setting");
    passed &= expect(fixture.otherSetting == QStringLiteral("pending")
            && fixture.persistedOtherSetting()
                == QStringLiteral("baseline"),
        "the transaction does not flush unrelated pending settings");
    return passed;
}

bool testAcceptsLocalPendingExpectedValue()
{
    SkeletonFixture fixture;
    if (!fixture.isValid() || !fixture.dockItemsItem()) {
        return expect(false, "the local pending fixture is available");
    }

    const QString pending = QStringLiteral(R"([{"type":"punchimenu"}])");
    fixture.dockItemsItem()->setProperty(pending);
    const QString candidate = canonicalLayoutCandidate();
    const auto committed = fixture.commit(pending, candidate);
    bool passed = expect(committed.success && committed.changed,
        "a locally pending expected value can be advanced atomically");
    passed &= expect(fixture.dockItemsJson == candidate
            && fixture.persistedJson() == candidate,
        "the local pending value is replaced by the durable candidate");
    return passed;
}

bool testDurableConflict()
{
    SkeletonFixture fixture;
    if (!fixture.isValid()) {
        return expect(false, "the conflict fixture is available");
    }

    const QString current = QStringLiteral(R"([{"type":"punchimenu"}])");
    const auto initial = fixture.commit(QStringLiteral("[]"), current);
    if (!initial.success) {
        return expect(false, "the conflict fixture has a persisted baseline");
    }

    const QString external = QStringLiteral("[]");
    if (!fixture.writeExternalJson(external)) {
        return expect(false, "the external conflict reaches disk");
    }
    const bool saveSucceeded = fixture.skeleton->save();
    if (!saveSucceeded || fixture.persistedJson() != external) {
        return expect(false,
            "a later skeleton save cannot overwrite the external change");
    }
    const auto conflict = fixture.commit(
        current, canonicalLayoutCandidate());
    bool passed = expect(!conflict.success
            && conflict.errorCode == QStringLiteral("conflict")
            && conflict.currentJson == external && !conflict.changed,
        "a same-key change made outside the skeleton is rejected");
    passed &= expect(fixture.dockItemsJson == current
            && fixture.persistedJson() == external,
        "a conflict preserves both the local and durable values");
    return passed;
}

bool testReconcilesValidatedDurableState()
{
    SkeletonFixture fixture;
    if (!fixture.isValid()) {
        return expect(false, "the reconciliation fixture is available");
    }

    const QString baseline = canonicalLayoutCandidate();
    if (!fixture.commit(QStringLiteral("[]"), baseline).success) {
        return expect(false, "the reconciliation fixture has a baseline");
    }
    const QString external = QStringLiteral(
        R"([{"type":"punchimenu","applicationLayout":{"version":1,"nodes":[]}},{"type":"external"}])");
    if (!fixture.writeExternalJson(external)) {
        return expect(false, "the reconciled value reaches disk");
    }

    int changeSignalCount = 0;
    QObject::connect(fixture.skeleton.get(),
        &KCoreConfigSkeleton::configChanged,
        [&changeSignalCount]() { ++changeSignalCount; });
    const auto reconciled = fixture.reconcile(external);
    bool passed = expect(reconciled.success && reconciled.changed
            && reconciled.currentJson == external
            && fixture.dockItemsJson == external
            && fixture.dockItemsItem()
            && !fixture.dockItemsItem()->isSaveNeeded()
            && changeSignalCount == 1,
        "a validated durable value is adopted and announced reactively");

    const QString invalid = QStringLiteral(
        R"([{"type":"punchimenu","applicationLayout":{"version":1,"nodes":[],"command":"not-allowed"}}])");
    if (!fixture.writeExternalJson(invalid)) {
        return expect(false, "the invalid external value reaches disk");
    }
    const auto rejected = fixture.reconcile(invalid);
    passed &= expect(!rejected.success
            && rejected.errorCode
                == QStringLiteral("invalid-application-layout")
            && fixture.dockItemsJson == external
            && changeSignalCount == 1,
        "an invalid durable value is never adopted into the observed state");
    return passed;
}

bool testInvalidAndBoundedJson()
{
    SkeletonFixture fixture;
    if (!fixture.isValid()) {
        return expect(false, "the validation fixture is available");
    }

    bool passed = true;
    const auto malformed = fixture.commit(
        QStringLiteral("[]"), QStringLiteral("["));
    passed &= expect(!malformed.success
            && malformed.errorCode == QStringLiteral("invalid-json"),
        "malformed JSON is rejected");

    const auto wrongRoot = fixture.commit(
        QStringLiteral("[]"), QStringLiteral("{}"));
    passed &= expect(!wrongRoot.success
            && wrongRoot.errorCode == QStringLiteral("root-not-array"),
        "a non-array JSON root is rejected");

    QJsonArray tooManyItems;
    for (qsizetype index = 0;
         index <= DockItemsJsonTransaction::MaximumItemCount; ++index) {
        tooManyItems.append(QJsonObject{});
    }
    const auto excessiveCount = fixture.commit(
        QStringLiteral("[]"),
        QString::fromUtf8(
            QJsonDocument(tooManyItems).toJson(QJsonDocument::Compact)));
    passed &= expect(!excessiveCount.success
            && excessiveCount.errorCode == QStringLiteral("too-many-items"),
        "more than 512 top-level items are rejected");

    const QString oversized = QStringLiteral("[\"")
        + QString(DockItemsJsonTransaction::MaximumJsonBytes,
            QLatin1Char('a'))
        + QStringLiteral("\"]");
    const auto excessiveSize = fixture.commit(
        QStringLiteral("[]"), oversized);
    passed &= expect(!excessiveSize.success
            && excessiveSize.errorCode == QStringLiteral("json-too-large"),
        "JSON larger than one MiB is rejected before parsing");

    const QString oversizedWhitespace(
        DockItemsJsonTransaction::MaximumJsonBytes + 1, QLatin1Char(' '));
    const auto excessiveWhitespace = fixture.commit(
        QStringLiteral("[]"), oversizedWhitespace);
    passed &= expect(!excessiveWhitespace.success
            && excessiveWhitespace.errorCode
                == QStringLiteral("json-too-large"),
        "oversized whitespace is rejected before normalization");

    const QString injectedLayout = QStringLiteral(
        R"([{"type":"punchimenu","applicationLayout":{"version":1,"nodes":[{"type":"application","storageId":"org.example.App.desktop","command":"not-allowed"}]}}])");
    const auto invalidLayout = fixture.commit(
        QStringLiteral("[]"), injectedLayout);
    passed &= expect(!invalidLayout.success
            && invalidLayout.errorCode
                == QStringLiteral("invalid-application-layout"),
        "non-canonical application folder fields are rejected natively");

    passed &= expect(fixture.dockItemsJson == QStringLiteral("[]")
            && fixture.persistedJson() == QStringLiteral("[]"),
        "invalid candidates cannot mutate configuration");
    return passed;
}

bool testSyncFailurePreservesState()
{
    SkeletonFixture fixture;
    if (!fixture.isValid()) {
        return expect(false, "the sync failure fixture is available");
    }

    const QString baseline = QStringLiteral(R"([{"type":"punchimenu"}])");
    const auto initial = fixture.commit(QStringLiteral("[]"), baseline);
    if (!initial.success) {
        return expect(false, "the sync failure fixture has a baseline");
    }

    int syncAttempts = 0;
    const auto failed = fixture.commit(
        baseline, canonicalLayoutCandidate(),
        [&syncAttempts](KConfig &) {
            ++syncAttempts;
            return false;
        });
    bool passed = expect(!failed.success
            && failed.errorCode == QStringLiteral("persistence-failed")
            && !failed.rolledBack && !failed.changed
            && failed.currentJson == baseline && syncAttempts == 1,
        "a failed isolated sync reports failure without a fake rollback");
    passed &= expect(fixture.dockItemsJson == baseline
            && fixture.persistedJson() == baseline,
        "a failed sync preserves memory and durable state");

    const auto falsePositive = fixture.commit(
        baseline, canonicalLayoutCandidate(),
        [](KConfig &) { return true; });
    passed &= expect(!falsePositive.success
            && falsePositive.errorCode
                == QStringLiteral("persistence-failed")
            && fixture.persistedJson() == baseline,
        "a callback cannot claim success without a durable candidate");
    return passed;
}
}

int main(int argc, char **argv)
{
    QCoreApplication application(argc, argv);
    Q_UNUSED(application)

    bool passed = true;
    passed &= testSuccessAndNoOp();
    passed &= testIsolatesOtherPendingSettings();
    passed &= testAcceptsLocalPendingExpectedValue();
    passed &= testDurableConflict();
    passed &= testReconcilesValidatedDurableState();
    passed &= testInvalidAndBoundedJson();
    passed &= testSyncFailurePreservesState();
    return passed ? EXIT_SUCCESS : EXIT_FAILURE;
}
