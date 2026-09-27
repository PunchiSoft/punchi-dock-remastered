// SPDX-License-Identifier: GPL-2.0-or-later

.pragma library

// Reveal motion of the Control Center surface.
//
// The entrance and the exit are derived from a single progress driver, so the
// surface has one origin: it never cross-fades while it travels. These are pure
// functions because the overlay itself cannot be instantiated in the offscreen
// test harness; the contract of the values lives in
// tests/control_center_overlay_layout_test.qml.

// The surface becomes fully opaque in the first part of the motion, so the eye
// follows a solid panel instead of a semi-transparent one.
const OPACITY_LEAD = 1.6
const MINIMUM_SCALE_DELTA = 0.0
// A larger shrink would re-raster the text at a visibly different size.
const MAXIMUM_SCALE_DELTA = 0.25

function finiteNumber(value, fallback) {
    const numericValue = Number(value)
    return Number.isFinite(numericValue) ? numericValue : fallback
}

// An unusable progress is read as a settled surface: showing the panel at its
// final size is always safer than fading a visible surface out by accident.
function settledProgress(value) {
    return Math.max(0.0, Math.min(1.0, finiteNumber(value, 1.0)))
}

function revealOpacity(progress) {
    return Math.min(1.0, settledProgress(progress) * OPACITY_LEAD)
}

function revealScale(progress, scaleDelta) {
    const delta = Math.max(MINIMUM_SCALE_DELTA, Math.min(MAXIMUM_SCALE_DELTA,
        finiteNumber(scaleDelta, MINIMUM_SCALE_DELTA)))
    return 1.0 - (1.0 - settledProgress(progress)) * delta
}

// Remaining travel of a surface that slides instead of growing.
function revealTravel(progress, distance) {
    return (1.0 - settledProgress(progress)) * finiteNumber(distance, 0.0)
}
