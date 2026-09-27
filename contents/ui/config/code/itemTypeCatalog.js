// Canonical catalogue of the element types the «Add item» dialog can create.
//
// Single source for the type key, its icon, its visible title, its description,
// whether the dock allows more than one and which editor renders its form.
//
// Titles and descriptions are read through functions that call i18n when a
// binding asks for them, so a language change reaches the dialog instead of
// being frozen at load time. `editor` is a key, never a component: the dialog is
// the single place that maps a key to a QML type, and this file stays data-only.
//
// This module does not translate anything ahead of time and does not decide
// availability: the singleton rule belongs to `logic.js` and to the draft
// controller, which read the real item list.

const editorItemForm = "item-form"
const editorCalendarOptions = "calendar-options"
// Options panels already extracted from their own dialog. The key is specific to
// each panel, so the dialog can map it to a component without keeping a second
// list of types.
const editorPunchiMenuOptions = "punchimenu-options"
const editorControlCenterOptions = "control-center-options"
const editorMediaOptions = "media-options"
const editorTrashOptions = "trash-options"

function entry(type, icon, title, description, singleton, singletonReason, editor) {
    return {
        "type": type,
        "icon": icon,
        "title": title,
        "description": description,
        "singleton": singleton,
        // Text a disabled entry shows when the type is already in the dock. It
        // reuses the wording the palette already had, so no new message is
        // introduced for the singleton restriction.
        "singletonReason": singletonReason,
        "editor": editor
    }
}

// Order the user reads: the direct launchers first, then the layout helpers,
// then the singletons.
function types() {
    return [
        entry("app", "application-x-executable",
            i18n("Application"),
            i18nc("@info:short description of the application item type",
                "Launch an application"),
            false, "", editorItemForm),
        entry("folder", "folder",
            i18n("Container"),
            i18nc("@info:short description of the container item type",
                "Group applications in a folder"),
            false, "", editorItemForm),
        entry("note", "knotes",
            i18n("Note"),
            i18n("Write a quick editable note"),
            false, "", editorItemForm),
        entry("separator", "draw-line",
            i18n("Separator"),
            i18n("Add a visual separator"),
            false, "", editorItemForm),
        entry("spacer", "distribute-horizontal-x",
            i18n("Spacer"),
            i18n("Add empty space between items"),
            false, "", editorItemForm),
        entry("punchimenu", "start-here-kde",
            i18n("PunchiMenu"),
            i18n("Open application menu & carousel"),
            true, i18n("Only one PunchiMenu item can be added."),
            editorPunchiMenuOptions),
        entry("control-center", "preferences-system",
            i18n("Control Center"),
            i18n("Open system controls and notifications"),
            true, i18n("Only one Control Center item can be added."),
            editorControlCenterOptions),
        entry("dynamic-applications", "window-duplicate",
            i18n("Open applications"),
            i18n("Choose where open apps appear"),
            true, i18n("Only one open applications item can be added."), editorItemForm),
        entry("calendar", "x-office-calendar",
            i18n("Calendar/Clock"),
            i18n("Show date information"),
            false, "", editorCalendarOptions),
        entry("media", "emblem-music-symbolic",
            i18n("Media player"),
            i18n("Automatically select the active player"),
            true, i18n("Only one media player item can be added."),
            editorMediaOptions),
        entry("trash", "user-trash",
            i18n("Trash"),
            i18n("Open or empty the trash"),
            false, "", editorTrashOptions)
    ]
}

function descriptorFor(type) {
    const all = types()
    const wanted = String(type)
    for (let index = 0; index < all.length; index++) {
        if (all[index].type === wanted) {
            return all[index]
        }
    }
    return null
}

function isValidType(type) {
    return descriptorFor(type) !== null
}

// Editor key of a type, empty when the type is unknown.
function editorFor(type) {
    const descriptor = descriptorFor(type)
    return descriptor === null ? "" : descriptor.editor
}

// The type catalogue carries the singleton flag for the selector, but the
// authoritative list is `logic.js`; a contract test keeps both in step.
function singletonTypes() {
    return types().filter(function(item) {
        return item.singleton
    }).map(function(item) {
        return item.type
    })
}

// First type the dock still accepts, used to open the dialog on something the
// user can really add.
function firstAvailableType(hasItemType) {
    const all = types()
    for (let index = 0; index < all.length; index++) {
        const candidate = all[index]
        if (candidate.singleton && hasItemType(candidate.type)) {
            continue
        }
        return candidate.type
    }
    return ""
}
