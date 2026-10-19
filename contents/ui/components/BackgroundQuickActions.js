// SPDX-License-Identifier: GPL-3.0-or-later
// Pure decisions for the dock background quick controls. Keeping them here
// makes the toggle semantics testable without a live Plasmoid configuration.
.pragma library

function normalizeVisibilityMode(value) {
    const mode = String(value || "")
    if (mode === "alwaysVisible" || mode === "autoHide"
            || mode === "dodgeWindows" || mode === "windowsGoBelow") {
        return mode
    }
    return "system"
}

function visibilityOffMode(previousMode) {
    const mode = normalizeVisibilityMode(previousMode)
    if (mode === "alwaysVisible" || mode === "dodgeWindows"
            || mode === "windowsGoBelow") {
        return mode
    }
    // A panel-level "system" mode may itself be auto-hide. Turning the toggle
    // off must produce a visible dock, so fall back to always visible.
    return "alwaysVisible"
}

function visibilityToggle(autoHide, currentMode, previousMode) {
    if (autoHide) {
        return {
            "mode": visibilityOffMode(previousMode),
            "previous": ""
        }
    }
    return {
        "mode": "autoHide",
        "previous": normalizeVisibilityMode(currentMode)
    }
}

// PanelView::VisibilityMode values exposed by the hosting window.
function panelModeToVisibilityMode(value) {
    const mode = Number(value)
    if (mode === 0) {
        return "alwaysVisible"
    }
    if (mode === 1) {
        return "autoHide"
    }
    if (mode === 2) {
        return "dodgeWindows"
    }
    if (mode === 3) {
        return "windowsGoBelow"
    }
    return ""
}

// The quick action describes the panel's effective state. When the hosting
// window does not expose visibilityMode yet, fall back to the stored
// preference instead of showing the toggle as disabled.
function autoHideActive(detectedMode, configuredMode) {
    const detected = Number(detectedMode)
    if (Number.isFinite(detected) && detected >= 0) {
        return detected === 1
    }
    return normalizeVisibilityMode(configuredMode) === "autoHide"
}

// Current mode used to remember what the toggle must restore later. The
// effective panel mode wins over the stored preference so an external mode
// change is not replaced by a stale value.
function effectiveVisibilityMode(detectedMode, configuredMode) {
    const detected = Number(detectedMode)
    if (Number.isFinite(detected) && detected >= 0) {
        const mode = panelModeToVisibilityMode(detected)
        if (mode !== "") {
            return mode
        }
    }
    return normalizeVisibilityMode(configuredMode)
}

// "system" means "follow the panel" and must never be replaced by an
// observed value. An explicit stored mode that no longer matches the panel is
// adopted so the menu and the configuration page do not disagree.
function visibilitySyncTarget(detectedMode, configuredMode) {
    const configured = normalizeVisibilityMode(configuredMode)
    if (configured === "system") {
        return ""
    }
    const detected = Number(detectedMode)
    if (!Number.isFinite(detected) || detected < 0) {
        return ""
    }
    const mode = panelModeToVisibilityMode(detected)
    if (mode === "" || mode === configured) {
        return ""
    }
    return mode
}

function boundedHoverScale(value, fallback) {
    const scale = Number(value)
    if (!Number.isFinite(scale) || scale < 1.0 || scale > 2.0) {
        return fallback
    }
    return scale
}

function magnificationToggle(enabled, currentScale, previousScale) {
    if (enabled) {
        return {
            "scale": 1.0,
            "previous": boundedHoverScale(currentScale, 1.65)
        }
    }
    return {
        "scale": boundedHoverScale(previousScale, 1.65),
        "previous": 0
    }
}
