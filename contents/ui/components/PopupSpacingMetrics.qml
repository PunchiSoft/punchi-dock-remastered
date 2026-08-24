import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    id: root

    readonly property int maximumGap:
        Math.max(0, Math.round(Kirigami.Units.gridUnit * 2))

    function normalizedPercent(value) {
        const requestedPercent = Number(value)
        return Number.isFinite(requestedPercent)
            ? Math.max(0, Math.min(100,
                Math.round(requestedPercent / 5) * 5))
            : 0
    }

    function gapForPercent(value) {
        return Math.round(root.maximumGap
            * root.normalizedPercent(value) / 100)
    }
}
