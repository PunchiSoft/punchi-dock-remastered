import QtQuick
import org.kde.plasma.plasmoid

QtObject {
    id: root

    property bool inPanel: false
    property bool horizontalPanel: false
    property int effectiveIconSize: 48
    property bool themeRepositoryValid: false
    property var theme: ({})

    readonly property string windowPreviewStyle: String(Plasmoid.configuration.windowPreviewStyle || "card")
    readonly property bool mediaControlsOnHover: !!Plasmoid.configuration.mediaControlsOnHover
    readonly property real windowPreviewScale: Math.max(1.5, Math.min(4.5,
        Number(Plasmoid.configuration.windowPreviewScale || 1.5)))
    readonly property string windowPreviewInfoMode: {
        const mode = String(Plasmoid.configuration.windowPreviewInfoMode || "full")
        return mode === "icon" || mode === "none" ? mode : "full"
    }
    readonly property int maxPopupRows: Math.max(1, Math.min(8,
        Number(Plasmoid.configuration.maxPopupRows || 4)))
    readonly property bool windowPreviewTextShadowsEnabled:
        Plasmoid.configuration.windowPreviewTextShadowsEnabled !== false
    readonly property bool popupTextShadowsEnabled:
        Plasmoid.configuration.popupTextShadowsEnabled !== false
    readonly property bool menuTextShadowsEnabled:
        Plasmoid.configuration.menuTextShadowsEnabled !== false

    readonly property int folderGridIconSize: Math.max(24, Math.min(64,
        Number(Plasmoid.configuration.folderGridIconSize || 36)))
    readonly property int folderGridColumns: Math.max(1, Math.min(8,
        Number(Plasmoid.configuration.folderGridColumns || 3)))
    readonly property int folderGridRows: Math.max(1, Math.min(8,
        Number(Plasmoid.configuration.folderGridRows || 4)))
    readonly property bool folderGridShowLabels:
        Plasmoid.configuration.folderGridShowLabels !== false
    readonly property string folderGridFontFamily:
        String(Plasmoid.configuration.folderGridFontFamily || "")
    readonly property int folderGridFontSize: Math.max(8, Math.min(18,
        Number(Plasmoid.configuration.folderGridFontSize || 9)))

    readonly property int folderListIconSize: Math.max(24, Math.min(64,
        Number(Plasmoid.configuration.folderListIconSize || 32)))
    readonly property int folderListRows: Math.max(1, Math.min(8,
        Number(Plasmoid.configuration.folderListRows || 4)))
    readonly property bool folderListShowLabels:
        Plasmoid.configuration.folderListShowLabels !== false
    readonly property string folderListFontFamily:
        String(Plasmoid.configuration.folderListFontFamily || "")
    readonly property int folderListFontSize: Math.max(8, Math.min(18,
        Number(Plasmoid.configuration.folderListFontSize || 10)))

    readonly property int folderDetailedIconSize: Math.max(24, Math.min(64,
        Number(Plasmoid.configuration.folderDetailedIconSize || 32)))
    readonly property int folderDetailedRows: Math.max(1, Math.min(8,
        Number(Plasmoid.configuration.folderDetailedRows || 4)))
    readonly property bool folderDetailedShowLabels:
        Plasmoid.configuration.folderDetailedShowLabels !== false
    readonly property string folderDetailedFontFamily:
        String(Plasmoid.configuration.folderDetailedFontFamily || "")
    readonly property int folderDetailedFontSize: Math.max(8, Math.min(18,
        Number(Plasmoid.configuration.folderDetailedFontSize || 10)))
    readonly property int folderPopupExtraDistance: Math.max(0, Math.min(32,
        Number(Plasmoid.configuration.folderPopupExtraDistance || 0)))

    readonly property bool dockShowLabels: !!Plasmoid.configuration.showLabels
    readonly property bool dockTextShadowsEnabled:
        Plasmoid.configuration.dockTextShadowsEnabled !== false
    readonly property bool dockShowItemHoverBackground:
        Plasmoid.configuration.showItemHoverBackground !== false
    readonly property bool dockIconReflectionsEnabled: (!root.inPanel || root.horizontalPanel)
        && !dockShowLabels
        && !!Plasmoid.configuration.iconReflectionsEnabled
    readonly property real dockIconReflectionOpacity: {
        const configuredPercent = Number(Plasmoid.configuration.iconReflectionOpacity)
        const safePercent = Number.isFinite(configuredPercent)
            ? configuredPercent
            : 22
        return Math.max(5, Math.min(50, safePercent)) / 100.0
    }
    readonly property int dockLabelFontSize: Math.max(10,
        Math.round(root.effectiveIconSize * 0.22))
    readonly property int dockLabelAreaHeight: dockShowLabels
        ? (dockLabelFontSize + 12)
        : 0
    readonly property string dockClickEffect: String(Plasmoid.configuration.clickEffect || "none")
    readonly property string dockWindowMinimizeEffect: {
        const configuredEffect = String(Plasmoid.configuration.windowMinimizeEffect || "none")
        return ["none", "slowBounce", "lateralRipple"].indexOf(configuredEffect) >= 0
            ? configuredEffect
            : "none"
    }
    readonly property string dockIndicatorType: String(Plasmoid.configuration.indicatorType || "line")
    readonly property string dockIndicatorPosition: String(Plasmoid.configuration.indicatorPosition || "bottom")
    readonly property real dockIndicatorOpacity: Math.max(0.0, Math.min(1.0,
        Number(Plasmoid.configuration.indicatorOpacity || 100) / 100.0))
    readonly property int dockIndicatorThickness: Math.max(2,
        Number(Plasmoid.configuration.indicatorThickness || 4))

    readonly property string dockThemeMode: {
        const configuredMode = String(Plasmoid.configuration.dockThemeMode || "plasma")
        return configuredMode === "custom" ? "custom" : "plasma"
    }
    readonly property string dockThemeCustomId: String(Plasmoid.configuration.dockThemeCustomId || "")
    readonly property bool customDockThemeActive: !root.inPanel
        && dockThemeMode === "custom"
        && root.themeRepositoryValid
    readonly property var customDockSeparatorTheme: customDockThemeActive
        && root.theme
        && root.theme.separator
        ? root.theme.separator
        : ({})
    readonly property bool customDockSeparatorActive: !root.inPanel
        && String(customDockSeparatorTheme.style || "").length > 0

    readonly property bool audioSpectrumConfigured: Plasmoid.configuration.audioSpectrumEnabled === true
    readonly property real audioSpectrumIntensity: Math.max(0.1, Math.min(0.6,
        Number(Plasmoid.configuration.audioSpectrumIntensity || 35) / 100.0))
    readonly property bool audioSpectrumUsePlasmaTheme:
        Plasmoid.configuration.audioSpectrumUsePlasmaTheme !== false
    readonly property int audioSpectrumBarCount: {
        const configuredCount = Number(Plasmoid.configuration.audioSpectrumBarCount || 12)
        return [8, 12, 16, 24, 32, 48].indexOf(configuredCount) >= 0
            ? configuredCount
            : 12
    }
    readonly property string audioSpectrumStyle: {
        const configuredStyle = String(Plasmoid.configuration.audioSpectrumStyle || "edge")
        const supportedStyles = ["edge", "centered", "capsules", "pixel", "cloud", "particles"]
        return supportedStyles.indexOf(configuredStyle) >= 0 ? configuredStyle : "edge"
    }
    readonly property string audioSpectrumBackgroundMode: {
        const configuredMode = String(Plasmoid.configuration.audioSpectrumBackgroundMode || "plasma")
        return configuredMode === "spectrumOnly" ? "spectrumOnly" : "plasma"
    }
    readonly property string audioSpectrumOrigin: {
        const configuredOrigin = String(Plasmoid.configuration.audioSpectrumOrigin || "bottom")
        return configuredOrigin === "top" ? "top" : "bottom"
    }
    readonly property string audioSpectrumFlow: {
        const configuredFlow = String(Plasmoid.configuration.audioSpectrumFlow || "none")
        return ["left", "right"].indexOf(configuredFlow) >= 0 ? configuredFlow : "none"
    }

    readonly property real configuredHoverScale: Math.max(1.0,
        Number(Plasmoid.configuration.hoverScale || 1.0))
    readonly property real panelHoverScale: root.inPanel
        ? Math.min(configuredHoverScale, 1.18)
        : configuredHoverScale

    readonly property string popupAnimationStyle: {
        const configuredStyle = String(Plasmoid.configuration.popupAnimation || "scale")
        return ["scale", "bounce", "fade", "slide", "none"].indexOf(configuredStyle) >= 0
            ? configuredStyle
            : "scale"
    }
    readonly property int popupAnimationSpeedPercent: Math.max(10, Math.min(200,
        Number(Plasmoid.configuration.popupAnimationSpeedPercent || 100)))
    readonly property int popupAnimationIntensity: Math.max(10, Math.min(200,
        Number(Plasmoid.configuration.popupAnimationIntensity || 100)))
    readonly property string menuAnimationStyle: {
        const configuredStyle = String(Plasmoid.configuration.menuAnimation || "fade")
        return ["scale", "bounce", "fade", "slide", "none"].indexOf(configuredStyle) >= 0
            ? configuredStyle
            : "fade"
    }
    readonly property int menuAnimationSpeedPercent: Math.max(10, Math.min(200,
        Number(Plasmoid.configuration.menuAnimationSpeedPercent || 125)))
    readonly property int menuAnimationIntensity: Math.max(10, Math.min(200,
        Number(Plasmoid.configuration.menuAnimationIntensity || 75)))
    readonly property string windowPreviewAnimationStyle: {
        const configuredStyle = String(
            Plasmoid.configuration.windowPreviewAnimation || "slide")
        return ["scale", "bounce", "fade", "slide", "none"].indexOf(configuredStyle) >= 0
            ? configuredStyle
            : "slide"
    }
    readonly property int windowPreviewAnimationSpeedPercent: Math.max(10,
        Math.min(200, Number(
            Plasmoid.configuration.windowPreviewAnimationSpeedPercent || 100)))
    readonly property int windowPreviewAnimationIntensity: Math.max(10,
        Math.min(200, Number(
            Plasmoid.configuration.windowPreviewAnimationIntensity || 100)))

    readonly property int contextMenuTransitionSpeed: Math.max(10, Math.min(200,
        Number(Plasmoid.configuration.contextMenuTransitionSpeed || 100)))
    readonly property string contextMenuTransitionDirection: {
        const direction = String(
            Plasmoid.configuration.contextMenuTransitionDirection || "fromRight")
        return ["fromRight", "fromLeft", "fromTop", "fromBottom", "morphOnly"]
            .indexOf(direction) >= 0 ? direction : "fromRight"
    }
    readonly property int contextMenuVisibleRows: Math.max(3, Math.min(12,
        Number(Plasmoid.configuration.contextMenuVisibleRows || 6)))
    readonly property int contextMenuRowHeight: Math.max(32, Math.min(64,
        Number(Plasmoid.configuration.contextMenuRowHeight || 46)))
    readonly property int contextMenuIconSize: Math.max(16, Math.min(40,
        Number(Plasmoid.configuration.contextMenuIconSize || 26)))
    readonly property int contextMenuWidth: Math.max(240, Math.min(520,
        Number(Plasmoid.configuration.contextMenuWidth || 360)))
}
