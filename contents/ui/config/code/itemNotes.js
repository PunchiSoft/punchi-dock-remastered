// Notes the Items page shows beside the dock item list.
//
// One note per element type, read for the type the list has selected. The text is
// returned by a function that calls i18nc when a binding asks for it, so a language
// change reaches the page instead of being frozen at load time. A type without a
// note returns an empty string, and the page then leaves the area empty.
//
// The wording of every note is approved before it is written here: propose the text
// with its emphasis and wait for the answer. A note explains what the item does and
// what the reader has to know, it does not announce a decision or a promise.
//
// The wording reuses the labels the rest of the dock already shows, so the note
// names the menu modes exactly as the Configure dialog and the item's own menu in
// the dock do.
//
// A note opens with a short label in bold and continues in normal weight, so the
// text carries <b> markup and the label that shows it uses styled text. The markup
// belongs to the translatable message: a translation must keep the tags and mark
// only the label.

// The markup must not reach a screen reader through the accessible name of the
// label that shows the note, so the words are exposed without their tags.
function plainText(markup) {
    return String(markup).replace(/<\/?b>/g, "")
}

function noteFor(type) {
    switch (String(type)) {
    case "app":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> An Application item opens one program, and the Dock accepts as many as you want. Typing a name or alias in Alias searches the installed applications and fills in the other fields; Command runs as a shell command line.")
        // qmllint enable unqualified
    case "folder":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> A Container groups applications and shows them when you click it. Its Content chooses what fills it: Manual — applications you add yourself —, a Folder on disk, or an Application category. In a Manual Container you can also drop applications from PunchiMenu.")
        // qmllint enable unqualified
    case "dynamic-applications":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> Only one Open applications item can be added to the Dock. It marks where the windows of running applications appear, and removing it also turns off Show active windows in the dock, which can be enabled again in the Windows settings.")
        // qmllint enable unqualified
    case "punchimenu":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> Only one PunchiMenu can be added to the Dock. Its menu mode can be Full screen, Normal (anchored), Normal (floating center) or Compact, and is changed with Configure in this window or from the item's menu in the Dock with a right click. Applications can be dragged out of the menu to the Dock or onto another application to group them, and an application's menu creates folders, moves applications between them and marks favorites.")
        // qmllint enable unqualified
    case "control-center":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Preview:</b> The Control Center is not fully polished yet. Only one can be added to the Dock. It groups quick system controls — such as volume, brightness, networks and night light — and notifications. Use Configure above to choose which controls appear and adjust their layout.")
        // qmllint enable unqualified
    case "calendar":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> A Calendar item displays date or time information directly on the Dock and opens a monthly calendar when clicked. Use Configure above to switch between tile and text views, format the date and customize colors.")
        // qmllint enable unqualified
    case "trash":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> A Trash item shows the state of the system trash and lets you open or empty it. You can drop files onto its icon in the Dock to move them to the trash.")
        // qmllint enable unqualified
    case "media":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> Only one Media player can be added to the Dock. It automatically follows the active MPRIS audio player, displays playback status and provides quick playback controls. Use Configure above to set track information and appearance.")
        // qmllint enable unqualified
    case "note":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> A Note item places a quick editable sticky note on the Dock. Clicking it opens a popup where you can read and write personal notes without opening an external editor.")
        // qmllint enable unqualified
    case "separator":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> A Separator draws a visual dividing line between dock items to organize them into logical groups. Use Configure above to adjust its style, thickness and margins.")
        // qmllint enable unqualified
    case "spacer":
        // qmllint disable unqualified
        return i18nc("@info <b> marks the note label",
            "<b>Note:</b> A Spacer adds empty space between dock items to separate them without drawing a visible line. Use Configure above to adjust its size in pixels.")
        // qmllint enable unqualified
    default:
        return ""
    }
}
