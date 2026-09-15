import QtQml

QtObject {
    // PlasmaQuick::Dialog may snap AppletPopup to the screen center when
    // popupExtent / 2 - anchorExtent / 3 is positive. Keep the anchor centered
    // on its source and make that threshold negative, including integer rounding.
    function centeredExtent(sourceExtent: real, popupExtent: real): real {
        return Math.max(sourceExtent,
            Math.ceil(Math.max(0, popupExtent) * 1.5) + 2)
    }
}
