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
        name: i18n("Files")
        icon: "text-json"
        source: "config/ConfigFiles.qml"
    }
}
