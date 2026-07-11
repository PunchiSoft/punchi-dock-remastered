import QtQuick
import QtQuick.Dialogs

FolderDialog {
    id: root

    property string titleText: i18n("Choose Folder")
    
    title: titleText

    signal folderChosen(string path)

    onAccepted: {
        folderChosen(selectedFolder.toString())
    }
}
