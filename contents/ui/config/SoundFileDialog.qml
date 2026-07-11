import QtQuick
import QtQuick.Dialogs

FileDialog {
    id: root

    property string startFolder: ""
    property string audioFilesText: i18n("Audio files")
    property string allFilesText: i18n("All files")

    title: i18n("Choose Sound File")
    currentFolder: startFolder
    nameFilters: [audioFilesText + " (*.oga *.ogg *.wav *.mp3 *.flac)", allFilesText + " (*)"]

    signal soundChosen(string path)

    onAccepted: {
        soundChosen(selectedFile.toString())
    }
}
