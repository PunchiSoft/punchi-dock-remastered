import QtQuick
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui/components"

TestCase {
    id: testCase
    name: "PopupSpacingMetrics"

    PopupSpacingMetrics {
        id: metrics
    }

    function init() {
        failOnWarning(/.?/)
    }

    function test_usesAdaptiveMaximumAndClampedPercentage() {
        compare(metrics.maximumGap,
            Math.round(Kirigami.Units.gridUnit * 2))
        compare(metrics.gapForPercent(0), 0)
        compare(metrics.gapForPercent(50),
            Math.round(metrics.maximumGap * 0.5))
        compare(metrics.gapForPercent(100), metrics.maximumGap)
        compare(metrics.gapForPercent(-50), 0)
        compare(metrics.gapForPercent(150), metrics.maximumGap)
        compare(metrics.gapForPercent("invalid"), 0)
    }

    function test_roundsToFivePercentSteps() {
        compare(metrics.normalizedPercent(52), 50)
        compare(metrics.normalizedPercent(53), 55)
        compare(metrics.gapForPercent(75),
            Math.round(metrics.maximumGap * 0.75))
        compare(metrics.gapForPercent(25),
            Math.round(metrics.maximumGap * 0.25))
    }
}
