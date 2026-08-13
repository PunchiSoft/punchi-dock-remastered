import QtQuick
import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.ComboBox {
    id: root

    readonly property Item popupParentItem: root.popup.parent

    function mappedPopupOrigin() {
        if (!popupParentItem || popupParentItem === root) {
            return Qt.point(0, root.height)
        }

        return root.mapToItem(popupParentItem, 0, root.height)
    }

    popup.x: {
        const visibleNow = root.popup.visible
        return root.mappedPopupOrigin().x
    }
    popup.y: {
        const visibleNow = root.popup.visible
        return root.mappedPopupOrigin().y
    }
}
