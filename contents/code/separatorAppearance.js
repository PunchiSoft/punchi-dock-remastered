.pragma library

const supportedStyles = [
    "line", "dot", "square", "capsule", "star", "diamond", "ring",
    "doubleLine", "chevron"
]
const itemAppearanceKeys = [
    "separatorStyle", "separatorThickness", "separatorLengthRatio",
    "separatorOpacity", "separatorGlowEnabled"
]

function boundedNumber(value, fallback, minimum, maximum) {
    const number = Number(value)
    const safeValue = Number.isFinite(number) ? number : fallback
    return Math.max(minimum, Math.min(maximum, safeValue))
}

function normalizedStyle(value) {
    const requestedStyle = value === "pill" ? "capsule" : String(value || "line")
    return supportedStyles.indexOf(requestedStyle) >= 0
        ? requestedStyle : "line"
}

function itemHasAppearance(item) {
    if (!item || typeof item !== "object") {
        return false
    }
    for (let index = 0; index < itemAppearanceKeys.length; ++index) {
        if (item[itemAppearanceKeys[index]] !== undefined) {
            return true
        }
    }
    return false
}

function sourceForItem(item) {
    const requestedSource = String(item && item.separatorAppearanceSource || "")
    if (requestedSource === "theme" || requestedSource === "item") {
        return requestedSource
    }
    return itemHasAppearance(item) ? "item" : "theme"
}

function resolvedAppearance(source, item, themeEnabled, theme) {
    const localItem = item && typeof item === "object" ? item : ({})
    const themeObject = theme && typeof theme === "object" ? theme : ({})
    const normalizedSource = source === "item" ? "item" : "theme"
    const themeControlled = normalizedSource === "theme"
        && themeEnabled === true
        && String(themeObject.style || "").length > 0
    const values = themeControlled
        ? themeObject : (normalizedSource === "item" ? localItem : ({}))
    const glow = themeControlled && themeObject.glow
        && typeof themeObject.glow === "object"
        ? themeObject.glow : ({})

    return {
        "source": normalizedSource,
        "themeControlled": themeControlled,
        "style": normalizedStyle(values.separatorStyle === undefined
            ? values.style : values.separatorStyle),
        "thickness": boundedNumber(
            values.separatorThickness === undefined
                ? values.thickness : values.separatorThickness,
            2, 1, themeControlled ? 28 : 16),
        "lengthRatio": boundedNumber(
            values.separatorLengthRatio === undefined
                ? values.lengthRatio : values.separatorLengthRatio,
            0.72, 0.20, 1.0),
        "opacity": boundedNumber(
            values.separatorOpacity === undefined
                ? values.opacity : values.separatorOpacity,
            0.34, themeControlled ? 0.0 : 0.10, 1.0),
        "glowEnabled": themeControlled
            ? (themeObject.glowEnabled === true
                || boundedNumber(glow.size, 0, 0, 28) > 0)
            : (normalizedSource === "item"
                && localItem.separatorGlowEnabled === true),
        "glowSize": themeControlled
            ? boundedNumber(glow.size, 0, 0, 28) : 0
    }
}
