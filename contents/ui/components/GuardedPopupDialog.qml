import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kwindowsystem

PlasmaCore.Dialog {
    id: root

    readonly property bool isX11Session: KWindowSystem.isPlatformX11
    property bool preparingToShow: false
    property int openRequestSerial: 0
    property int openPreparationAttempts: 3
    property Item sizingItem: root.mainItem
    readonly property bool hasPositiveContentGeometry: !!root.sizingItem
        && Number(root.sizingItem.implicitWidth) > 0
        && Number(root.sizingItem.implicitHeight) > 0
        && Number(root.sizingItem.width) > 0
        && Number(root.sizingItem.height) > 0

    type: PlasmaCore.Dialog.AppletPopup
    flags: root.isX11Session
        ? Qt.Popup | Qt.FramelessWindowHint
        : Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false
    backgroundHints: PlasmaCore.Dialog.NoBackground

    signal openFailed()

    function finishPreparedOpen(requestSerial, remainingAttempts) {
        if (requestSerial !== root.openRequestSerial || !root.preparingToShow) {
            return
        }
        if (!root.hasPositiveContentGeometry) {
            if (remainingAttempts > 0) {
                Qt.callLater(function() {
                    root.finishPreparedOpen(requestSerial, remainingAttempts - 1)
                })
            } else {
                root.preparingToShow = false
                root.openFailed()
            }
            return
        }
        root.visible = true
        root.preparingToShow = false
    }

    function openSafely() {
        root.openRequestSerial += 1
        const requestSerial = root.openRequestSerial
        root.preparingToShow = true
        Qt.callLater(function() {
            root.finishPreparedOpen(requestSerial,
                Math.max(0, root.openPreparationAttempts))
        })
    }

    function closeSafely() {
        root.openRequestSerial += 1
        root.preparingToShow = false
        root.visible = false
    }
}
