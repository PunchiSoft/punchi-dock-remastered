// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import "punchimenu" as PunchiMenuComponents

// Compact popup caption that keeps a quiet elided resting state and reveals its
// full accessible text while the launcher is hovered or keyboard-focused.
//
// Only the full-text layer moves. The viewport and its parent layout stay fixed,
// so the interaction does not relayout neighbouring delegates per frame.
PunchiMenuComponents.PunchiMenuMarqueeLabel {
    visibleCharacterLimit: 10
    shorteningEnabled: true
    maximumLineCount: 1
    wrapMode: Text.NoWrap
}
