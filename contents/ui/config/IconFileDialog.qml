import QtQuick
import QtQuick.Dialogs

FileDialog {
    id: root

    property string titleText: i18n("Choose Icon")
    property string imageFilesText: i18n("Image files")
    property string allFilesText: i18n("All files")

    title: titleText
    nameFilters: [imageFilesText + " (*.png *.svg *.svgz *.xpm *.jpg *.jpeg)", allFilesText + " (*)"]

    signal iconChosen(url fileUrl)

    onAccepted: {
        iconChosen(selectedFile)
    }
}
