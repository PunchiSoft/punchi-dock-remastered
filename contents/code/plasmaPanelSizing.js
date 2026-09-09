.pragma library

// Pure sizing policy shared by the Plasma panel and its preferences.
function calculate(requestedIconSize, requestedScale, thickness, vertical, labels, padding) {
    const icon = Math.max(1, Math.min(96, Math.round(Number(requestedIconSize) || 32)))
    const scale = Math.max(1, Math.min(1.65, Number(requestedScale) || 1))
    const margin = Math.max(0, Number(padding) || 0)
    const available = Math.max(0, Number(thickness) || 0)
    let effectiveIcon = icon

    function labelHeight(size) {
        return labels && !vertical ? Math.max(10, Math.round(size * 0.22)) + 12 : 0
    }
    function baseExtent(size) {
        return vertical && labels
            ? Math.max(size + margin, Math.round(size * 1.85))
            : size + margin + labelHeight(size)
    }

    // Shrink the base icon only when it cannot fit without enlargement.
    // Use requested values, never the previously calculated panel extent.
    if (available > 0) {
        while (effectiveIcon > 1 && baseExtent(effectiveIcon) > available) {
            effectiveIcon--
        }
    }
    // Configured thickness is not the clipping boundary of a floating panel.
    // Keep its base allocation stable; measure zoom against the actual window.
    const extent = available > 0 ? Math.max(available, baseExtent(effectiveIcon))
        : Math.max(baseExtent(effectiveIcon),
            Math.ceil(effectiveIcon * scale + margin + labelHeight(effectiveIcon)))
    return {iconSize: effectiveIcon, hoverScale: scale, extent: extent}
}

function boundedHoverScale(requestedScale, iconExtent, center, windowExtent, direction, mode) {
    const requested = Math.max(1, Math.min(1.65, requestedScale))
    if (!(iconExtent > 0) || !(windowExtent > 0) || !Number.isFinite(center)) {
        return requested
    }
    const lower = center
    const upper = windowExtent - center
    const toward = direction > 0 ? upper : lower
    const away = direction > 0 ? lower : upper
    let maximum
    if (mode === "wave") {
        // DockItem moves by half the growth: the opposite edge stays fixed.
        maximum = away < iconExtent / 2 ? 1 : 0.5 + toward / iconExtent
    } else if (mode === "single") {
        // At peak, DockItem translates by round(iconSize * 0.32).
        maximum = Math.min(2 * away / iconExtent,
            2 * (toward - Math.round(iconExtent * 0.32)) / iconExtent)
    } else {
        maximum = 2 * Math.min(lower, upper) / iconExtent
    }
    return Math.max(1, Math.min(requested, maximum))
}
