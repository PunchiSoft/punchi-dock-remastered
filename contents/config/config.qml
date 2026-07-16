import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Items")
        icon: "kmenuedit"
        source: "config/ConfigItems.qml"
    }
    
    ConfigCategory {
        name: i18n("General")
        icon: "systemsettings"
        source: "config/ConfigGeneral.qml"
    }

    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-theme"
        source: "config/ConfigAspect.qml"
    }

    // qmllint disable unqualified
    ConfigCategory {
        name: i18n("Audio visualizer")
        icon: "audio-volume-high"
        source: "config/ConfigAudioVisualizer.qml"
    }
    // qmllint enable unqualified

    ConfigCategory {
        name: i18n("Mouse")
        icon: "input-mouse"
        source: "config/ConfigMouse.qml"
    }

    ConfigCategory {
        name: i18n("Windows")
        icon: "window"
        source: "config/ConfigWindows.qml"
    }
    
    ConfigCategory {
        name: i18n("Files")
        icon: "text-json"
        source: "config/ConfigFiles.qml"
    }
}
