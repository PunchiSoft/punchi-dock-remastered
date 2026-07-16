.pragma library

var items = [
    {
        "_comment": "Pinned application. Runs command and can expose optional right-click actions.",
        "type": "app",
        "name": "Mozilla Firefox",
        "icon": "firefox",
        "command": "firefox",
        "actions": [
            { "name": "New Window", "icon": "window-new-symbolic", "command": "firefox --new-window" },
            { "name": "New Tab", "icon": "tab-new-symbolic", "command": "firefox --new-tab about:newtab" },
            { "name": "Private Window", "icon": "view-private-symbolic", "command": "firefox --private-window" },
            { "name": "Profile Manager", "icon": "preferences-desktop-user", "command": "firefox --ProfileManager" }
        ]
    },
    {
        "_comment": "Pinned application. command should be the executable or action to launch.",
        "type": "app",
        "name": "Konsole",
        "icon": "utilities-terminal",
        "command": "konsole"
    },
    {
        "_comment": "Folder item. Groups common user folders inside a Plasma-themed popup.",
        "type": "folder",
        "name": "Home",
        "icon": "user-home",
        "layout": "grid",
        "columns": 3,
        "rows": 0,
        "popupMaxWidth": 0,
        "popupMaxHeight": 0,
        "innerIconSize": 48,
        "showLabels": true,
        "closeOnLaunch": true,
        "apps": [
            { "type": "app", "name": "Home", "icon": "user-home", "command": "xdg-open \"$HOME\"" },
            { "type": "app", "name": "Documents", "icon": "folder-documents", "command": "xdg-open \"$(xdg-user-dir DOCUMENTS)\"" },
            { "type": "app", "name": "Downloads", "icon": "folder-downloads", "command": "xdg-open \"$(xdg-user-dir DOWNLOAD)\"" },
            { "type": "app", "name": "Pictures", "icon": "folder-pictures", "command": "xdg-open \"$(xdg-user-dir PICTURES)\"" },
            { "type": "app", "name": "Music", "icon": "folder-music", "command": "xdg-open \"$(xdg-user-dir MUSIC)\"" },
            { "type": "app", "name": "Videos", "icon": "folder-videos", "command": "xdg-open \"$(xdg-user-dir VIDEOS)\"" }
        ]
    },
    {
        "_comment": "Folder item in detailed mode. Useful for larger groups where labels and commands matter.",
        "type": "folder",
        "name": "LibreOffice",
        "icon": "folder-documents",
        "layout": "detailed",
        "columns": 0,
        "rows": 0,
        "popupMaxWidth": 0,
        "popupMaxHeight": 0,
        "innerIconSize": 48,
        "showLabels": true,
        "closeOnLaunch": true,
        "apps": [
            { "type": "app", "name": "Writer", "icon": "libreoffice-writer", "command": "libreoffice --writer" },
            { "type": "app", "name": "Calc", "icon": "libreoffice-calc", "command": "libreoffice --calc" },
            { "type": "app", "name": "Impress", "icon": "libreoffice-impress", "command": "libreoffice --impress" },
            { "type": "app", "name": "Draw", "icon": "libreoffice-draw", "command": "libreoffice --draw" },
            { "type": "app", "name": "LibreOffice Math", "icon": "libreoffice-math", "command": "libreoffice --math" },
            { "type": "app", "name": "LibreOffice Base", "icon": "libreoffice-base", "command": "libreoffice --base" }
        ],
        "sourceType": "manual",
        "sourcePath": "",
        "sourceCategory": "Development"
    },
    {
        "_comment": "Category container. Defaults to Graphics and can be refreshed from the user's installed launchers.",
        "type": "folder",
        "name": "Graphics",
        "icon": "folder-pictures",
        "layout": "list",
        "sourceType": "category",
        "sourceCategory": "Graphics",
        "columns": 0,
        "rows": 0,
        "popupMaxWidth": 0,
        "popupMaxHeight": 0,
        "innerIconSize": 48,
        "showLabels": false,
        "sourcePath": "",
        "closeOnLaunch": true,
        "apps": [
            { "type": "app", "name": "Gwenview", "icon": "gwenview", "command": "gwenview" },
            { "type": "app", "name": "Spectacle", "icon": "spectacle", "command": "spectacle" },
            { "type": "app", "name": "Krita", "icon": "krita", "command": "krita" },
            { "type": "app", "name": "Inkscape", "icon": "inkscape", "command": "inkscape" },
            { "type": "app", "name": "GIMP", "icon": "gimp", "command": "gimp" },
            { "type": "app", "name": "KolourPaint", "icon": "kolourpaint", "command": "kolourpaint" }
        ]
    },
    {
        "_comment": "Trash item. Opens the trash, can show empty/full state, and can accept dropped files.",
        "type": "trash",
        "name": "Trash",
        "icon": "user-trash",
        "fullIcon": "user-trash-full",
        "showState": true,
        "acceptDrops": true
    },
    {
        "_comment": "Welcome note. Demonstrates the editable note item and can be removed by the user.",
        "type": "note",
        "name": "Welcome note",
        "icon": "knotes",
        "note": "Thank you for choosing Punchi Dock.\n\nPlease consider leaving a comment or reporting bugs on KDE Store or GitHub; your feedback helps improve the project.\n\n(This is a welcome note: you can edit it, delete it, or move it whenever you like.)\n\nGracias por preferir Punchi Dock.\n\nNo olvides dejar tus comentarios o reportar bugs en KDE Store o GitHub; tu feedback ayuda a mejorar el proyecto.\n\n(Esta es una nota de bienvenida: puedes editarla, borrarla o moverla cuando quieras.)",
        "popupWidth": 380,
        "popupHeight": 260
    },
    {
        "_comment": "Visual separator. Useful before date or time widgets.",
        "type": "separator"
    },
    {
        "_comment": "Calendar item. Shows date information as a tile or as text.",
        "type": "calendar",
        "name": "Calendar",
        "icon": "x-office-calendar",
        "width": 0,
        "height": 0,
        "calendarDisplayMode": "tile",
        "textShowWeekday": true,
        "textShowDay": true,
        "textShowMonth": true,
        "showWeekday": true,
        "showWeekNumbers": true,
        "hoverInteraction": false
    }
]

function cloneItems() {
    return JSON.parse(JSON.stringify(items))
}
