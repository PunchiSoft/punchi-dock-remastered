pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import "punchimenu" as PunchiMenuComponents

Item {
    id: root

    property var apps: []
    property int iconSize: 42
    property int rowLimit: 6
    // Height the popup can give the arc, in pixels. Zero means it has no
    // ceiling: the fan then shows the number of rows it is configured with.
    property int maximumContentHeight: 0
    // Name of the file manager the container opens with. The closing row names it
    // next to the count of the entries the fan leaves out, the way the macOS
    // stack fan names its Finder. Empty when the desktop association is unknown.
    property string folderOpenerName: ""
    property bool showLabels: true
    // Whether the fan may scroll. This single value governs the wheel, the
    // touchpad, drag and the keyboard alike; it is not a pointer-only switch.
    // It is a request, not the effective behaviour: a container without a
    // folder keeps scrolling through the accessibility fallback, so that no
    // entry ever becomes unreachable.
    property bool scrollEnabled: false
    property string fontFamily: Kirigami.Theme.defaultFont.family
    property int fontSize: 10
    property bool textShadowsEnabled: false
    // Amount of the text shadow of this fan, in percent. Zero removes it.
    property int textShadowPercent: 25
    property bool motionEnabled: Kirigami.Units.longDuration > 1
    property int popupDirection: Qt.BottomEdge
    // Folder the container points at. When it exists, the fan closes with the
    // action that opens it: macOS keeps the equivalent entry at the end of its
    // stack fan, with a round back-arrow glyph and the file manager named in the
    // text.
    property string folderPath: ""
    readonly property bool hasLocationAction: folderPath.length > 0
    property real revealProgress: 1.0
    property real revealOffsetX: 0
    property real revealOffsetY: 0
    property int displacedDuration: motionEnabled
        ? Kirigami.Units.shortDuration : 0
    // Share of the shared opening progress spent sweeping the arc. The item
    // that faces the panel finishes earlier and the far end closes the sweep.
    property real revealSweepShare: 0.35
    readonly property real safeRevealSweepShare: Math.max(0,
        Math.min(0.8, Number(revealSweepShare) || 0))
    // Scale and opacity support of the unfold. Items do not fade in and never
    // start from zero: they travel from the anchor row and settle, so the fan
    // reads as one structure opening instead of a list appearing.
    property real revealStartScale: 0.90
    property real revealStartOpacity: 0.78
    // Opening and closing are one continuous progress: the fan has no timeline of
    // its own and never restarts. `revealProgress` is the shared popup progress,
    // animated by PopupAnimatedContent (LongDuration scaled by the user's
    // animation speed, OutCubic when opening and InCubic when closing) with a
    // Behavior that retargets from the current value, so interrupting mid-flight
    // continues from where it is. The fan only derives per-item scale, opacity
    // and travel from that value.

    readonly property int itemCount: apps ? apps.length : 0
    readonly property int safeRowLimit: Math.max(1, Math.min(8,
        Number(rowLimit || 6)))
    readonly property int contentPadding: Kirigami.Units.smallSpacing
    readonly property int labelSpacing: Kirigami.Units.smallSpacing
    readonly property int labelHorizontalPadding:
        Kirigami.Units.smallSpacing * 2
    // The rendered glyph advance can exceed the measured advance by a fraction
    // of a pixel. Without this margin a capsule sits exactly on the wrap
    // threshold and the theme label breaks its word into two lines.
    readonly property int labelRoundingMargin: 1
    // Single source of truth for the text silhouette inside a row, so the
    // capsule-shaped highlight cannot drift from the text it wraps.
    readonly property int labelHeight: Math.max(
        labelMetrics.height + Kirigami.Units.smallSpacing * 2,
        Math.round(iconSize * 0.72))
    // Silhouette of the hover and focus highlight. The theme corner radius
    // reads rectangular around a capsule and half the height reads as a full
    // pill, so the highlight adopts the curvature of the text it wraps.
    // It is derived, not fixed, so it scales with the icon size.
    readonly property real highlightRadius: labelHeight / 2
    property int rowHeight: Math.max(iconSize
        + Kirigami.Units.smallSpacing,
        labelMetrics.height + Kirigami.Units.smallSpacing * 3,
        preferredRowHeight)
    // Rows of the band the popup can show: the configured limit while the
    // height allows it, and fewer when the display does not. The envelope grows
    // with the row count, so the search walks down from the configured maximum
    // and stops at the first count whose reserve, band and closing row fit
    // together. One row is always kept: a fan that shows nothing cannot be used.
    readonly property int visibleItemRows: {
        const configuredRows = Math.max(1, Math.min(itemCount, safeRowLimit))
        const ceiling = Number(maximumContentHeight)
        if (!Number.isFinite(ceiling) || ceiling <= 0) {
            return configuredRows
        }
        for (let rows = configuredRows; rows > 1; rows--) {
            const visibleRows = rows + locationActionRows
            const envelope = envelopeForRows(visibleRows)
            if (envelope.leading + visibleRows * rowHeight + envelope.trailing
                    <= ceiling) {
                return rows
            }
        }
        return 1
    }
    readonly property int visibleRowCount: visibleItemRows
        + locationActionRows
    // Entries the band leaves outside its resting area. They are the ones the
    // fan could reach by scrolling, not yet the ones it really omits.
    readonly property int overflowItemCount: Math.max(0,
        itemCount - visibleItemRows)
    // Whether the fan holds more entries than the band shows at rest.
    readonly property bool scrollRequired: overflowItemCount > 0
    // The action row is extra, not a stolen item row: the container keeps all
    // the entries its row limit allows and the action is added at the far end.
    readonly property int locationActionRows: hasLocationAction ? 1 : 0
    // Effective behaviour, which is not always the request: a container without
    // a folder has no row that opens the entries the fan would leave out, so
    // the fan keeps scrolling to preserve access to them. The preference itself
    // is untouched; only its runtime effect changes.
    readonly property bool effectiveScrollEnabled: scrollEnabled
        || (overflowItemCount > 0 && !hasLocationAction)
    // Entries the effective model keeps.
    readonly property int displayedItemCount: effectiveScrollEnabled
        ? itemCount
        : Math.min(itemCount, visibleItemRows)
    // Model the list consumes. It is the source array itself while the fan
    // scrolls, and a derived copy of its leading entries while the fan is
    // static, so the full model is never duplicated and the array the container
    // owns keeps feeding the counter and the name measurements.
    readonly property var displayedApps: {
        const items = root.apps || []
        if (root.effectiveScrollEnabled) {
            return items
        }
        return items.slice(0,
            Math.min(items.length, root.visibleItemRows))
    }
    // Entries the effective model really leaves out. It stays zero while the fan
    // scrolls, because every entry remains reachable inside the popup: the
    // closing row must not claim an omission that did not happen.
    readonly property int omittedItemCount: Math.max(0,
        itemCount - displayedItemCount)
    // Index of the entry that holds the keyboard, so a change of the effective
    // model can keep a valid row focused instead of leaving the ring on a row
    // that no longer exists. Negative while the closing row or nothing holds it.
    property int focusedItemIndex: -1
    // The action always closes the arc away from the panel: the head of the list
    // when the popup opens upward, the tail when it opens downward.
    readonly property bool locationActionAtListStart:
        popupDirection !== Qt.BottomEdge
    readonly property bool iconsOnRight: popupDirection !== Qt.RightEdge
    readonly property bool horizontalPanel: popupDirection === Qt.TopEdge
        || popupDirection === Qt.BottomEdge
    // Shape of the arc, taken from the macOS reference
    // (docs/Referencias/referencia-composicion-abanico-macos.md). Its rows sit on
    // a circle whose angular step per row is constant, and that single angle
    // produces both the position of a row and the lean of its card. Deriving the
    // two from different laws is what made the arc look twisted: the path of the
    // rows reached 15° of slope while the pills only turned 9.3°, a mismatch of
    // more than 6° in the middle of the fan. With one law the mismatch stays at
    // the 1.5° the origin row is tilted from the tangent, and it is constant.
    property real rowArcStepDegrees: 1.30
    // Sag of one row, as a fraction of the pitch per row and per row squared.
    // Measured on the same capture: the row step is 1.65 px + 0.70 px per row
    // over a 64 px pitch, that is 1.65/64 and 0.70/64.
    property real rowSagPerPitch: 0.0258
    property real rowSagPerPitchSquared: 0.0109
    // Width the fan reserves for one name, from the same capture: its rows show
    // names of about 141 px over a 64 px pitch, that is 2.2 pitches.
    property real maximumLabelWidthPitchFactor: 2.2
    // One entry is one pill that carries its name, plus its own icon beside it.
    // The pill hugs the text, so its margin belongs to the entry and can never
    // cross the pill of a neighbouring one, and the icon keeps the place the arc
    // gives it with no surface of its own: that is the arrangement measured on
    // the reference capture, where the pills are about 141 x 28 px and the icon
    // sits outside them.
    readonly property int pillPadding: Kirigami.Units.smallSpacing
    // Height of the content a row carries: the icon is the tallest element.
    readonly property int contentHeight: iconSize
    // Pitch of the reference, as a share of the icon: its rows are 64 px apart
    // for a 48 px icon, that is 1.33 icons.
    property real rowPitchIconFactor: 1.33
    // Pitch this fan needs so its pills never collide. The container uses it as
    // its cell height.
    readonly property int preferredRowHeight:
        Math.round(iconSize * rowPitchIconFactor)
    // Air between two rows, derived from the pitch so the two never drift.
    readonly property int rowAir: Math.max(1,
        preferredRowHeight - contentHeight)
    // Travel of the arc: the rows the viewport shows, from the row that faces the
    // panel to the far end. Both the sag and the lean are functions of it.
    readonly property real arcRowSpan: Math.max(0,
        Math.max(1, visibleRowCount) - 1)
    // Lean of the far end of the arc, in degrees, which is the angular step of
    // one row repeated along the arc.
    readonly property real farEndLeanDegrees: arcRowSpan * rowArcStepDegrees
    // A row needs no envelope of its own: the icon keeps its place on the arc
    // and the pill is built around its own text.
    readonly property int iconSpacing: labelSpacing
    // Sag of the arc in the same law: the second order of that angular step, so
    // the rows sit on a circle of uniform angular step and their tangent and the
    // lean of their pill agree.
    readonly property real requestedCurveAmplitude: rowHeight
        * (rowSagPerPitch * arcRowSpan
            + rowSagPerPitchSquared * arcRowSpan * arcRowSpan)
    readonly property real curveAmplitude: Math.min(
        requestedCurveAmplitude,
        Math.max(0, width - iconSize - contentPadding * 2))
    readonly property real maximumNaturalLabelWidth: showLabels
        ? Math.ceil(labelWidthProbe.implicitWidth)
            + labelHorizontalPadding * 2 + labelRoundingMargin : 0
    // Font-aware resting ceiling requested for popup names: roughly ten wide
    // glyphs plus the pill padding. The full name remains in the model and the
    // shared marquee reveals it without changing this geometry.
    readonly property real maximumRestingLabelWidth: showLabels
        ? Math.ceil(restingLabelWidthMetrics.advanceWidth)
            + labelHorizontalPadding * 2 + labelRoundingMargin : 0
    // Width the fan reserves for one name, so a single long entry cannot widen
    // the popup on its own, derived from the reference as a share of the pitch.
    //
    // The text of the closing row is measured apart and used as a floor below,
    // never as part of this cap: that text is the count of the entries the fan
    // leaves out, so folding it in here would make the reservation depend on the
    // row count that the reservation itself decides.
    readonly property real maximumLabelWidth: Math.max(1,
        rowHeight * maximumLabelWidthPitchFactor)
    readonly property real itemLabelWidthLimit: Math.min(maximumLabelWidth,
        maximumRestingLabelWidth)
    // Width the closing row needs for its own text, from the variants it can show
    // and from the model alone. It is a floor of the reservation, so neither the
    // short label nor the count with the file manager is ever cut, even when
    // every entry has a short name.
    readonly property real actionCaptionWidth: hasLocationAction
        ? Math.ceil(actionCaptionProbe.implicitWidth)
            + labelHorizontalPadding * 2 + labelRoundingMargin : 0
    // Width reserved for a name: the natural width of the widest entry, held
    // back to what one row may take, but never less than the closing row needs.
    readonly property real desiredLabelWidth: showLabels
        ? Math.max(actionCaptionWidth,
            Math.min(maximumNaturalLabelWidth, itemLabelWidthLimit)) : 0
    // Widest row the fan shows (pill, gap and icon). A row turns about the
    // centre of its icon, so its pill leaves the row band with distance: the
    // room it needs is measured below, per row and per end, instead of guessed
    // once for the whole fan.
    readonly property real maximumRowWidth: iconSize + iconSpacing
        + (showLabels ? desiredLabelWidth : 0)
    // Flight of one pill outside its row band, for a given lean in radians. The
    // pivot is the centre of the icon, which never leaves the band, and the pill
    // sits beside it on the side the arc leaves free, so the rotation carries
    // the pill towards one end of the band and away from the other.
    //   reach = iconSize/2 + iconSpacing + reserved label width
    //   half extent = width/2 · |sin θ| + labelHeight/2 · cos θ
    function overhangForLean(radians) {
        const pivotDistance = iconSize / 2 + iconSpacing
            + desiredLabelWidth / 2
        const halfExtent = desiredLabelWidth / 2 * Math.abs(Math.sin(radians))
            + labelHeight / 2 * Math.cos(radians)
        const pillSide = iconsOnRight ? -1 : 1
        const centreOffset = pillSide * pivotDistance * Math.sin(radians)
        return {
            "up": Math.max(0, -centreOffset + halfExtent - rowHeight / 2),
            "down": Math.max(0, centreOffset + halfExtent - rowHeight / 2)
        }
    }

    // Position of a row inside the band, from 0 at the row that faces the panel
    // to 1 at the far end of the sweep. It mirrors normalizedDistanceForItem so
    // the reserve of a row count is measured with the same law the rows use.
    function normalizedDistanceForIndex(index, rows) {
        const span = Math.max(1, rows - 1)
        const fromTop = Math.max(0, Math.min(1, index / span))
        if (popupDirection === Qt.TopEdge) {
            return 1 - fromTop
        }
        if (popupDirection === Qt.BottomEdge) {
            return fromTop
        }
        return Math.abs(fromTop - 0.5) * 2
    }

    // Signed lean of a row of the band. Every row of a horizontal panel turns
    // the way the popup opens; a vertical panel turns the rows above its middle
    // towards one side and the rows below towards the other.
    function leanForIndex(index, rows) {
        const span = Math.max(0, rows - 1)
        const travelSign = horizontalPanel
            ? (popupDirection === Qt.TopEdge ? 1 : -1)
            : (span > 0 && index / span >= 0.5 ? -1 : 1)
        return travelSign * curveDirection * rowArcStepDegrees * span
            * normalizedDistanceForIndex(index, rows)
    }

    // Reserve the arc needs at each end of a band of `rowCount` rows. Up is the
    // start of the list and down its end: the pill of the far end is the one that
    // flies the most, and the row that faces the panel needs no reserve at all.
    function envelopeForRows(rowCount) {
        if (!showLabels) {
            return { "leading": 0, "trailing": 0 }
        }
        const rows = Math.max(1, Math.floor(Number(rowCount) || 1))
        let leading = 0
        let trailing = 0
        for (let index = 0; index < rows; index++) {
            const overhang = overhangForLean(leanForIndex(index, rows)
                * Math.PI / 180)
            leading = Math.max(leading, overhang.up)
            trailing = Math.max(trailing, overhang.down)
        }
        return {
            "leading": Math.ceil(leading),
            "trailing": Math.ceil(trailing)
        }
    }

    readonly property var envelope: envelopeForRows(visibleRowCount)
    // Room the leaning pills need at the start and at the end of the band. It is
    // content, not spare viewport: the list keeps it as a margin, so the rows and
    // the reserve add up to the viewport and nothing is cut. The border that
    // faces the panel needs none, because the row leaning on it stands upright.
    readonly property int leadingOverhang: envelope.leading
    readonly property int trailingOverhang: envelope.trailing
    readonly property int bandHeight: visibleRowCount * rowHeight
    // The closing row occupies a row of the band, so when it sits at the head of
    // the list the band starts one row before the first entry.
    readonly property bool closingRowAtListStart: hasLocationAction
        && locationActionAtListStart
    readonly property int bandStartOffset: closingRowAtListStart
        ? rowHeight : 0
    readonly property real curveDirection: horizontalPanel || !iconsOnRight
        ? 1 : -1
    readonly property real baseIconX: horizontalPanel
        ? (iconsOnRight
            ? width - contentPadding - iconSize - curveAmplitude
            : contentPadding)
        : (iconsOnRight
            ? width - contentPadding - iconSize
            : contentPadding)
    readonly property real originIconCenterX: baseIconX + iconSize / 2
    implicitWidth: Math.ceil(contentPadding * 2 + desiredLabelWidth
        + (showLabels ? labelSpacing : 0) + iconSize
        + requestedCurveAmplitude)
    implicitHeight: bandHeight + leadingOverhang + trailingOverhang

    signal appLaunched(var app)
    signal appContextMenuRequested(var app)
    signal closeRequested()
    signal openLocationRequested(string path)

    TextMetrics {
        id: labelMetrics
        font.family: root.fontFamily
        font.pointSize: root.fontSize
        font.weight: Font.DemiBold
        text: "Ag"
    }

    TextMetrics {
        id: restingLabelWidthMetrics
        font.family: root.fontFamily
        font.pointSize: root.fontSize
        font.weight: Font.DemiBold
        text: "MMMMMMMMMM"
    }

    Text {
        id: labelWidthProbe
        visible: false
        text: {
            const names = []
            for (let index = 0; root.apps
                    && index < root.apps.length; index++) {
                const app = root.apps[index]
                names.push(app && app.name ? String(app.name) : "")
            }
            // The closing row is measured at its longest, so its text can never
            // be cut. The count is bounded by the model, never by the rows the
            // height finally fits: measuring the count on screen would tie this
            // width to the row count that the width itself decides.
            if (root.hasLocationAction) {
                names.push(root.openActionLabelText)
                names.push(root.longestActionCaptionText)
            }
            return names.join("\n")
        }
        textFormat: Text.PlainText
        wrapMode: Text.NoWrap
        font.family: root.fontFamily
        font.pointSize: root.fontSize
        font.weight: Font.DemiBold
    }

    // Width of the text the closing row can show, measured from its variants and
    // from the model, never from the count on screen: measuring that one would
    // tie the reserved width to the row count that the width itself decides. The
    // longest line wins, so both the short label and the count fit.
    Text {
        id: actionCaptionProbe
        visible: false
        text: {
            if (!root.hasLocationAction) {
                return ""
            }
            return root.openActionLabelText + "\n"
                + root.longestActionCaptionText
        }
        textFormat: Text.PlainText
        wrapMode: Text.NoWrap
        font.family: root.fontFamily
        font.pointSize: root.fontSize
        font.weight: Font.DemiBold
    }

    // Measurement used only by the name fitting below. It is written and read
    // imperatively, never through a binding, so it cannot start a loop.
    TextMetrics {
        id: labelWidthFitMetrics
        font.family: root.fontFamily
        font.pointSize: root.fontSize
        font.weight: Font.DemiBold
        text: ""
    }

    // Label of the closing row when the fan omits nothing: the glyph beside it
    // opens the folder, so the text stays a short action word on purpose. When
    // the static fan really leaves entries out, the same row counts them the way
    // the macOS stack fan names its Finder.
    readonly property string openActionLabelText:
        i18nc("@action:button open the container", "Open") // qmllint disable unqualified
    // Text the closing row shows for a number of entries the fan leaves out: the
    // count and the file manager that opens the container, the way the macOS
    // stack fan names its Finder. Without a known file manager the count stands
    // alone, because the glyph beside it already says that the row opens the
    // folder.
    function countActionLabelText(count) {
        // qmllint disable unqualified
        if (folderOpenerName.length > 0) {
            // i18n: label of the closing row of the fan; %1 is how many entries
            // the fan leaves out and %2 the file manager the row opens.
            return i18ncp("@item:inlistbox closing row of the folder fan",
                "%1 more in %2", "%1 more in %2", count, folderOpenerName)
        }
        // i18n: label of the closing row of the fan; %1 is how many entries the
        // fan leaves out, next to a glyph that opens the container.
        return i18ncp("@item:inlistbox closing row of the folder fan",
            "%1 more", "%1 more", count)
        // qmllint enable unqualified
    }
    // Longest text the closing row can ever show, derived from the model alone:
    // the count of every entry the fan could leave out. The width the fan
    // reserves is measured with it, so no count can be cut and the width of the
    // popup does not jump when the number of shown rows changes.
    readonly property string longestActionCaptionText: itemCount > 1
        ? countActionLabelText(itemCount - 1) : openActionLabelText
    // Text of the closing row, and its own fitted version. The source stays a
    // binding so a language change still reaches it, while the fitting is
    // written from a handler: measuring inside a binding would make that
    // binding depend on the metrics it writes and would loop.
    readonly property string locationActionLabelText: omittedItemCount > 0
        ? countActionLabelText(omittedItemCount) : openActionLabelText
    property string locationActionDisplayName: ""
    readonly property real maximumLabelTextWidth: Math.max(0, desiredLabelWidth
        - labelHorizontalPadding * 2 - labelRoundingMargin)

    function fitLabelToWidth(value, maximumWidth) {
        const text = String(value)
        if (text.length === 0 || maximumWidth <= 0) {
            return text
        }
        labelWidthFitMetrics.text = text
        if (labelWidthFitMetrics.advanceWidth <= maximumWidth) {
            return text
        }
        const words = text.split(" ")
        let fitted = ""
        for (let index = 0; index < words.length; index++) {
            const candidate = fitted.length === 0
                ? words[index] : fitted + " " + words[index]
            labelWidthFitMetrics.text = candidate + "…"
            if (labelWidthFitMetrics.advanceWidth > maximumWidth) {
                break
            }
            fitted = candidate
        }
        if (fitted.length > 0) {
            return fitted + "…"
        }
        // A single word wider than the label: fall back to a cut by character.
        let characters = words[0]
        while (characters.length > 1) {
            characters = characters.slice(0, -1)
            labelWidthFitMetrics.text = characters + "…"
            if (labelWidthFitMetrics.advanceWidth <= maximumWidth) {
                break
            }
        }
        return characters + "…"
    }

    // Fits the fixed sentence of the closing row. Application names remain
    // complete and are elided and revealed by PopupMarqueeLabel.
    function refreshFittedLabels() {
        locationActionDisplayName = fitLabelToWidth(locationActionLabelText,
            maximumLabelTextWidth)
    }

    function labelDisplayNameFor(index) {
        const items = apps || []
        const app = index >= 0 && index < items.length ? items[index] : null
        return app && app.name ? String(app.name) : ""
    }

    onAppsChanged: {
        refreshFittedLabels()
        reconcileAfterModelChange()
    }
    onMaximumLabelTextWidthChanged: refreshFittedLabels()
    onLocationActionLabelTextChanged: refreshFittedLabels()
    // The row count follows the model, the configuration and the height the
    // popup offers, so the resting position is re-applied whenever it changes.
    onVisibleRowCountChanged: scheduleSettleAtBeginning()
    onScrollEnabledChanged: reconcileAfterModelChange()
    onDisplayedItemCountChanged: reconcileAfterModelChange()
    onEnabledChanged: {
        if (enabled) {
            root.reconcileAfterModelChange()
        }
    }
    Component.onDestruction: root.enabled = false
    Component.onCompleted: {
        refreshFittedLabels()
        scheduleSettleAtBeginning()
    }

    // Position of an item along the fan, from 0 at the panel-facing item to 1
    // at the far end of the visible travel. Recomputed from the viewport so it
    // stays valid while the list scrolls. The reserve the leaning pills need is
    // not part of the travel: the arc still starts on its origin row, so the
    // band is the part of the viewport the rows occupy.
    function normalizedDistanceForItem(itemY) {
        const viewportHeight = Math.max(1, fanList.height
            - root.leadingOverhang - root.trailingOverhang)
        const travel = Math.max(1, viewportHeight - rowHeight)
        const rowTop = Math.max(0, Math.min(travel,
            itemY - fanList.contentY - root.leadingOverhang))
        const fromTop = rowTop / travel
        let distanceFromOrigin = 0
        if (popupDirection === Qt.BottomEdge) {
            distanceFromOrigin = fromTop
        } else if (popupDirection === Qt.TopEdge) {
            distanceFromOrigin = 1 - fromTop
        } else {
            distanceFromOrigin = Math.abs(fromTop - 0.5) * 2
        }
        return distanceFromOrigin
    }

    // Per-item opening progress. `distance` is the normalized position along
    // the arc, 0 at the panel-facing item. Dividing by a rate below one makes
    // the near end settle earlier, and because every rate stays above zero no
    // item has to wait before it starts moving.
    function revealProgressForDistance(distance, progress) {
        const requestedProgress = Number(progress)
        const safeProgress = Number.isFinite(requestedProgress)
            ? Math.max(0, Math.min(1, requestedProgress)) : 1
        const sweep = safeRevealSweepShare
        if (sweep <= 0) {
            return safeProgress
        }
        const requestedDistance = Number(distance)
        const clampedDistance = Number.isFinite(requestedDistance)
            ? Math.max(0, Math.min(1, requestedDistance)) : 0
        return Math.max(0, Math.min(1,
            safeProgress / (1 - sweep + sweep * clampedDistance)))
    }

    // Sign of the screen direction the fan travels: up is 1, down is -1. It
    // also decides which way an icon leans, so the arc reads as a fan and not
    // as a mirrored shear on top and bottom panels.
    function travelDirectionSignForItem(itemY) {
        if (popupDirection === Qt.TopEdge) {
            return 1
        }
        if (popupDirection === Qt.BottomEdge) {
            return -1
        }
        const viewportHeight = Math.max(1, fanList.height)
        const rowCenter = itemY - fanList.contentY + rowHeight / 2
        return rowCenter < viewportHeight / 2 ? 1 : -1
    }

    // Position of an item along the arc, in the same law as its lean: the rows
    // sit on a circle of uniform angular step, so the offset is the second order
    // of the very angle that turns the row. One law for both is what keeps the
    // row tangent to the path it travels.
    function curveOffsetForItem(itemY) {
        const row = normalizedDistanceForItem(itemY) * arcRowSpan
        return rowHeight * (rowSagPerPitch * row
            + rowSagPerPitchSquared * row * row)
    }

    function rowLeanForItem(itemY) {
        return travelDirectionSignForItem(itemY) * curveDirection
            * farEndLeanDegrees * normalizedDistanceForItem(itemY)
    }

    // Final position, in list coordinates, of the row that faces the panel: the
    // dock icon. Every item starts on it and travels to its own row, and the
    // action row counts because it occupies a row of its own at the far end.
    readonly property real anchorRowY: {
        const actionOffset = locationActionRows > 0 && locationActionAtListStart
            ? rowHeight : 0
        if (popupDirection === Qt.TopEdge) {
            return actionOffset + Math.max(0, visibleItemRows - 1) * rowHeight
        }
        if (popupDirection === Qt.BottomEdge) {
            return actionOffset
        }
        return actionOffset + Math.max(0, visibleItemRows - 1) * rowHeight / 2
    }
    // Travel from the anchor row to the item's own row, in list coordinates. It
    // is the full distance, not a one-row nudge, so the items visibly leave the
    // icon and unfold into the arc.
    function revealOffsetYForItem(itemY) {
        return anchorRowY - Math.max(0, itemY)
    }

    // Row of the arc that opens the container, wherever the arc puts it: the
    // head of the list when the popup opens upwards and its tail when it opens
    // downwards. Null while the container has no folder.
    readonly property Item locationActionItem: root.locationActionAtListStart
        ? fanList.headerItem : fanList.footerItem

    // Focuses one entry of the effective model. Any index outside that model
    // travels to the closing row instead of scrolling towards an entry the fan
    // does not show, so a keyboard step can never reveal an omitted one.
    function focusItem(index, reason) {
        if (displayedItemCount <= 0) {
            focusLocationAction(reason)
            return
        }
        if (hasLocationAction && (index < 0 || index >= displayedItemCount)) {
            focusLocationAction(reason)
            return
        }
        const count = displayedItemCount
        const targetIndex = ((index % count) + count) % count
        fanList.currentIndex = targetIndex
        if (root.effectiveScrollEnabled) {
            // Only a scrolling fan may move: a static one already shows every
            // entry its model holds, so a keyboard step never leaves the
            // resting position.
            fanList.positionViewAtIndex(targetIndex, ListView.Contain)
        }
        Qt.callLater(function() {
            if (fanList.currentItem) {
                fanList.currentItem.forceActiveFocus(reason)
            }
        })
    }

    function focusFirstItem(reason) {
        focusItem(0, reason === undefined ? Qt.TabFocusReason : reason)
    }

    function focusLastItem(reason) {
        focusItem(displayedItemCount - 1,
            reason === undefined ? Qt.TabFocusReason : reason)
    }

    // Gives the keyboard to the closing row, which is the only other row of the
    // arc.
    function focusLocationAction(reason) {
        if (!root.hasLocationAction) {
            return
        }
        Qt.callLater(function() {
            const action = root.locationActionItem
            if (action) {
                action.forceActiveFocus(reason)
            }
        })
    }

    // Keyboard ring of the arc: the closing row sits between the two ends of
    // the entries, whichever end the arc puts it at, so one step reaches every
    // row the fan really shows.
    function focusStepFromLocationAction(step, reason) {
        if (displayedItemCount <= 0) {
            return
        }
        focusItem(step > 0 ? 0 : displayedItemCount - 1,
            reason === undefined ? Qt.TabFocusReason : reason)
    }

    // A change of the effective model can leave the ring pointing at a row that
    // no longer exists: the current index is corrected to the nearest surviving
    // row, and the keyboard follows it when an entry held the focus. The list
    // has to lay its content out again first, so the correction is deferred like
    // the resting position.
    function reconcileAfterModelChange() {
        if (root.enabled) {
            Qt.callLater(root.applyModelChange)
        }
    }

    function applyModelChange() {
        if (!root.enabled) {
            return
        }
        if (displayedItemCount <= 0) {
            fanList.currentIndex = -1
            root.focusedItemIndex = -1
        } else if (root.focusedItemIndex >= displayedItemCount) {
            root.focusItem(displayedItemCount - 1,
                Qt.OtherFocusReason)
        }
        root.scheduleSettleAtBeginning()
    }

    // Resting position of the content: the band starts after the reserve of the
    // end the arc opens to. Without it the list rests with the first row of the
    // band flush with its edge, which wastes the reserve at the other end and
    // leaves a half row visible there. This position is the beginning of the
    // range the margins define, so scrolling back to the start returns to it.
    // It holds whether or not the content overflows its viewport: the reserve is
    // part of the list content, so the offset that shows it is never clipped.
    function settleAtBeginning() {
        if (root.enabled) {
            fanList.contentY = -(leadingOverhang + bandStartOffset)
        }
    }

    // The list lays its content out again after a model or a row change, so the
    // resting position is applied once that pass is over.
    function scheduleSettleAtBeginning() {
        // An inactive presentation must not enqueue work during pane teardown.
        if (root.enabled) {
            Qt.callLater(root.settleAtBeginning)
        }
    }

    ListView {
        id: fanList
        objectName: "folderFanList"
        anchors.fill: parent
        // The list consumes the effective model, so the static fan really holds
        // only the entries it shows and the scrolling fan keeps them all.
        model: root.displayedApps
        // A static fan cannot be scrolled by any means: the wheel, the touchpad
        // and drag are refused here and the keyboard never targets a row that
        // the model does not hold.
        interactive: root.effectiveScrollEnabled
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // The room the leaning pills need at the ends of the band is a margin of
        // the view: it is content, so the list paints it instead of cutting it,
        // and the rows and the reserve add up to the viewport.
        topMargin: root.leadingOverhang
        bottomMargin: root.trailingOverhang
        keyNavigationEnabled: false
        activeFocusOnTab: false
        currentIndex: -1
        cacheBuffer: root.rowHeight

        move: Transition {
            enabled: root.motionEnabled
            NumberAnimation {
                properties: "x,y"
                duration: root.displacedDuration
                easing.type: Easing.InOutCubic
            }
        }

        moveDisplaced: Transition {
            enabled: root.motionEnabled
            NumberAnimation {
                properties: "x,y"
                duration: root.displacedDuration
                easing.type: Easing.InOutCubic
            }
        }

        delegate: Controls.ItemDelegate {
            id: fanDelegate

            required property int index
            required property var modelData

            objectName: "folderFanDelegate-" + index
            readonly property real curveOffset:
                root.curveOffsetForItem(y)
            readonly property real iconPosition: root.baseIconX
                + root.curveDirection * curveOffset
            readonly property real safeRevealProgress: {
                if (!root.motionEnabled) {
                    return 1
                }
                const requestedProgress = Number(root.revealProgress)
                return Number.isFinite(requestedProgress)
                    ? Math.max(0, Math.min(1, requestedProgress)) : 1
            }
            // The fan opens as an arc: the item facing the panel settles first
            // and the far end of the sweep closes the reveal.
            readonly property real itemRevealProgress:
                root.revealProgressForDistance(
                    root.normalizedDistanceForItem(y), safeRevealProgress)
            // Lean of the whole row, shared by its icon and its name, so the
            // text follows the opening of the fan.
            readonly property real rowLean:
                root.rowLeanForItem(y) * itemRevealProgress
            // Cheap transform-only support: no size, anchor or layout changes
            // happen while the reveal runs.
            readonly property real revealScale: root.motionEnabled
                ? root.revealStartScale
                    + (1 - root.revealStartScale) * itemRevealProgress
                : 1
            readonly property real revealOpacity: root.motionEnabled
                ? root.revealStartOpacity
                    + (1 - root.revealStartOpacity) * itemRevealProgress
                : 1

            width: fanList.width
            height: root.rowHeight
            padding: 0
            hoverEnabled: true
            activeFocusOnTab: true
            opacity: revealOpacity
            transform: Translate {
                x: root.revealOffsetX
                    - root.curveDirection * fanDelegate.curveOffset
                        * (1 - fanDelegate.itemRevealProgress)
                y: root.revealOffsetY
                    + root.revealOffsetYForItem(fanDelegate.y)
                        * (1 - fanDelegate.itemRevealProgress)
            }
            background: Item {}

            Accessible.name: fanDelegate.modelData
                && fanDelegate.modelData.name
                ? fanDelegate.modelData.name
                : i18n("Application") // qmllint disable unqualified
            // qmllint disable unqualified
            Accessible.description: i18nc("@info:accessible",
                "Launch this application")
            Accessible.onPressAction: root.appLaunched(
                fanDelegate.modelData)
            // qmllint enable unqualified

            onActiveFocusChanged: {
                if (activeFocus) {
                    fanList.currentIndex = index
                    root.focusedItemIndex = index
                } else if (root.focusedItemIndex === index) {
                    root.focusedItemIndex = -1
                }
            }

            Keys.onUpPressed: function(event) {
                root.focusItem(fanDelegate.index - 1,
                    Qt.BacktabFocusReason)
                event.accepted = true
            }
            Keys.onDownPressed: function(event) {
                root.focusItem(fanDelegate.index + 1,
                    Qt.TabFocusReason)
                event.accepted = true
            }
            Keys.onEscapePressed: function(event) {
                root.closeRequested()
                event.accepted = true
            }
            Keys.onReturnPressed: function(event) {
                root.appLaunched(fanDelegate.modelData)
                event.accepted = true
            }
            Keys.onEnterPressed: function(event) {
                root.appLaunched(fanDelegate.modelData)
                event.accepted = true
            }
            Keys.onSpacePressed: function(event) {
                root.appLaunched(fanDelegate.modelData)
                event.accepted = true
            }
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Menu
                        || (event.key === Qt.Key_F10
                            && (event.modifiers & Qt.ShiftModifier))) {
                    root.appContextMenuRequested(fanDelegate.modelData)
                    event.accepted = true
                }
            }

            MouseArea {
                id: fanPointer
                objectName: "folderFanPointer-" + fanDelegate.index
                anchors.fill: parent
                z: 10
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        root.appContextMenuRequested(
                            fanDelegate.modelData)
                        return
                    }
                    root.appLaunched(fanDelegate.modelData)
                }
            }

            contentItem: Item {
                id: fanContent

                readonly property real iconX: fanDelegate.iconPosition
                readonly property real availableLabelWidth: root.iconsOnRight
                    ? Math.max(0, iconX - root.iconSpacing
                        - root.contentPadding)
                    : Math.max(0, width - root.contentPadding
                        - (iconX + root.iconSize + root.iconSpacing))
                readonly property real naturalLabelWidth:
                    Math.ceil(fanLabelMetrics.advanceWidth)
                        + root.labelHorizontalPadding * 2
                        + root.labelRoundingMargin
                readonly property real labelWidth: Math.min(
                    availableLabelWidth, naturalLabelWidth,
                    root.itemLabelWidthLimit)
                // The pill hugs its own name and sits next to the icon, so a name
                // always reads inside the pill that carries it, beside its own
                // icon, instead of at the far end of a row-wide surface.
                readonly property real pillX: root.iconsOnRight
                    ? iconX - root.iconSpacing - labelWidth
                    : iconX + root.iconSize + root.iconSpacing

                TextMetrics {
                    id: fanLabelMetrics
                    font.family: root.fontFamily
                    font.pointSize: root.fontSize
                    font.weight: Font.DemiBold
                    // Measure the full name; the pill applies the resting cap
                    // and the shared label reveals this same source on hover.
                    text: root.labelDisplayNameFor(fanDelegate.index)
                }

                Item {
                    id: rowContent
                    objectName: "folderFanRowContent-" + fanDelegate.index

                    anchors.fill: parent
                    // The whole row turns as one rigid group about the centre of
                    // its icon, so the icon stays exactly on the arc and its pill
                    // travels with it: that is the offset the reference capture
                    // measures, constant in the row's own frame.
                    transform: Rotation {
                        origin.x: fanContent.iconX + root.iconSize / 2
                        origin.y: rowContent.height / 2
                        angle: fanDelegate.rowLean
                    }
                    // The row travels, scales and fades with its own entry.
                    scale: root.motionEnabled && fanPointer.pressed
                        ? 0.97 : (itemHighlight.visualScale
                            * fanDelegate.revealScale)

                    PunchiMenuComponents.PunchiMenuItemHighlight {
                        id: itemHighlight
                        objectName: "folderFanHighlight-" + fanDelegate.index
                        // The marked element is the icon, never the pill beside
                        // it.
                        x: fanContent.iconX - Kirigami.Units.smallSpacing
                        y: Kirigami.Units.smallSpacing / 2
                        width: root.iconSize + Kirigami.Units.smallSpacing * 2
                        height: parent.height - Kirigami.Units.smallSpacing
                        radius: root.highlightRadius
                        hovered: fanPointer.containsMouse
                        focused: fanDelegate.visualFocus
                        pressed: fanPointer.pressed
                        motionEnabled: root.motionEnabled
                        transformSelf: false
                    }

                    Rectangle {
                        id: labelPill
                        objectName: "folderFanPill-" + fanDelegate.index
                        x: fanContent.pillX
                        width: fanContent.labelWidth
                        height: root.labelHeight
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.showLabels && width > 0
                        radius: height / 2
                        color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.88)
                        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                        border.width: 1
                        antialiasing: true
                        Accessible.ignored: true

                        PopupMarqueeLabel {
                            objectName: "folderFanLabel-" + fanDelegate.index
                            anchors.fill: parent
                            anchors.leftMargin: root.labelHorizontalPadding
                            anchors.rightMargin: root.labelHorizontalPadding
                            // The source remains complete; the shared viewport
                            // owns the resting ellipsis and hover/focus reveal.
                            text: root.labelDisplayNameFor(fanDelegate.index)
                            hovered: fanPointer.containsMouse
                            focused: fanDelegate.visualFocus
                            motionEnabled: root.motionEnabled
                            color: Kirigami.Theme.textColor
                            // The leaned rows take the same graduated shadow as
                            // the rest of the popup: the arc turns the texture of
                            // the label with the row, so the amount decides how far
                            // the name separates from the surface behind it.
                            shadowEnabled: root.textShadowsEnabled
                            shadowPercent: root.textShadowPercent
                            font.family: root.fontFamily
                            font.pointSize: root.fontSize
                            font.weight: Font.DemiBold
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: root.iconsOnRight
                                ? Text.AlignRight : Text.AlignLeft
                        }
                    }

                    Kirigami.Icon {
                        objectName: "folderFanIcon-" + fanDelegate.index
                        x: fanContent.iconX
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.iconSize
                        height: root.iconSize
                        source: fanDelegate.modelData
                            && fanDelegate.modelData.icon
                            ? fanDelegate.modelData.icon
                            : "application-x-executable"
                        // No lean of its own: the row carries the angle.
                        Accessible.ignored: true
                    }
                }
            }
        }

        // Closing row of the arc: opens the folder the container points at. It
        // sits at the far end, away from the panel, and leans with the arc like
        // any other row. Without a folder the head and the tail stay null, so
        // the arc geometry is untouched.
        header: root.hasLocationAction && root.locationActionAtListStart
            ? locationActionComponent : null
        footer: root.hasLocationAction && !root.locationActionAtListStart
            ? locationActionComponent : null
    }

    Component {
        id: locationActionComponent

        Controls.ItemDelegate {
            id: locationAction

            objectName: "folderFanLocationAction"
            width: fanList.width
            height: root.rowHeight
            hoverEnabled: true
            activeFocusOnTab: true
            padding: 0
            background: Item {}

            readonly property real curveOffset:
                root.curveOffsetForItem(y)
            readonly property real iconPosition: root.baseIconX
                + root.curveDirection * curveOffset
            readonly property real safeRevealProgress: {
                if (!root.motionEnabled) {
                    return 1
                }
                const requestedProgress = Number(root.revealProgress)
                return Number.isFinite(requestedProgress)
                    ? Math.max(0, Math.min(1, requestedProgress)) : 1
            }
            readonly property real itemRevealProgress:
                root.revealProgressForDistance(
                    root.normalizedDistanceForItem(y), safeRevealProgress)
            // Lean of the whole row, shared by its glyph and its name.
            readonly property real rowLean:
                root.rowLeanForItem(y) * itemRevealProgress
            readonly property real revealScale: root.motionEnabled
                ? root.revealStartScale
                    + (1 - root.revealStartScale) * itemRevealProgress
                : 1
            readonly property real revealOpacity: root.motionEnabled
                ? root.revealStartOpacity
                    + (1 - root.revealStartOpacity) * itemRevealProgress
                : 1

            opacity: revealOpacity
            transform: Translate {
                x: root.revealOffsetX
                    - root.curveDirection * locationAction.curveOffset
                        * (1 - locationAction.itemRevealProgress)
                y: root.revealOffsetY
                    + root.revealOffsetYForItem(locationAction.y)
                        * (1 - locationAction.itemRevealProgress)
            }

            // The row's own text may be a count, so its accessible name keeps
            // telling what the row does while its description adds how many
            // entries the effective model really leaves out. A scrolling fan
            // omits none, so its description stays empty instead of announcing
            // an omission that did not happen.
            // qmllint disable unqualified
            Accessible.name: i18nc("@info:accessible",
                "Open this folder in the file manager")
            Accessible.description: root.omittedItemCount > 0
                ? i18np("%1 more entry is not shown",
                    "%1 more entries are not shown", root.omittedItemCount)
                : ""
            // qmllint enable unqualified
            onActiveFocusChanged: {
                if (activeFocus) {
                    // The closing row is not an entry, so the ring is cleared:
                    // a later model change must not pull the focus back to the
                    // entries while this row holds it.
                    root.focusedItemIndex = -1
                }
            }
            Keys.onDownPressed: function(event) {
                root.focusStepFromLocationAction(1, Qt.TabFocusReason)
                event.accepted = true
            }
            Keys.onUpPressed: function(event) {
                root.focusStepFromLocationAction(-1, Qt.BacktabFocusReason)
                event.accepted = true
            }
            onClicked: root.openLocationRequested(root.folderPath)
            Keys.onReturnPressed: root.openLocationRequested(root.folderPath)
            Keys.onEnterPressed: root.openLocationRequested(root.folderPath)
            Keys.onSpacePressed: root.openLocationRequested(root.folderPath)
            // The row is a button and the click belongs to the delegate, so the
            // hand is asked for with a hover handler: a mouse area would take
            // the click away from the delegate that already handles it.
            HoverHandler {
                objectName: "folderFanLocationCursor"
                cursorShape: Qt.PointingHandCursor
            }

            contentItem: Item {
                id: locationActionContent

                readonly property real iconX: locationAction.iconPosition
                readonly property real availableLabelWidth: root.iconsOnRight
                    ? Math.max(0, iconX - root.iconSpacing
                        - root.contentPadding)
                    : Math.max(0, width - root.contentPadding
                        - (iconX + root.iconSize + root.iconSpacing))
                readonly property real naturalLabelWidth:
                    Math.ceil(locationLabelMetrics.advanceWidth)
                        + root.labelHorizontalPadding * 2
                        + root.labelRoundingMargin
                readonly property real labelWidth: Math.min(
                    availableLabelWidth, naturalLabelWidth,
                    root.desiredLabelWidth)
                // The closing row is one row of the same shape: a pill around its
                // own caption, next to its own glyph.
                readonly property real pillX: root.iconsOnRight
                    ? iconX - root.iconSpacing - labelWidth
                    : iconX + root.iconSize + root.iconSpacing

                TextMetrics {
                    id: locationLabelMetrics
                    font.family: root.fontFamily
                    font.pointSize: root.fontSize
                    font.weight: Font.DemiBold
                    // The same fitting as an application row: the text follows
                    // what is really painted.
                    text: root.locationActionDisplayName
                }

                Item {
                    id: locationRowContent
                    objectName: "folderFanLocationRowContent"

                    anchors.fill: parent
                    // The closing row turns as one rigid group about the centre of
                    // its glyph, exactly like an application row.
                    transform: Rotation {
                        origin.x: locationActionContent.iconX
                            + root.iconSize / 2
                        origin.y: locationRowContent.height / 2
                        angle: locationAction.rowLean
                    }
                    scale: root.motionEnabled && locationAction.pressed
                        ? 0.97 : locationAction.revealScale

                    PunchiMenuComponents.PunchiMenuItemHighlight {
                        objectName: "folderFanLocationHighlight"
                        // The marked element of the closing row is its glyph, the
                        // same way an application row marks its icon.
                        x: locationActionContent.iconX
                            - Kirigami.Units.smallSpacing
                        y: Kirigami.Units.smallSpacing / 2
                        width: root.iconSize + Kirigami.Units.smallSpacing * 2
                        height: parent.height - Kirigami.Units.smallSpacing
                        radius: root.highlightRadius
                        hovered: locationAction.hovered
                        focused: locationAction.visualFocus
                        pressed: locationAction.pressed
                        motionEnabled: root.motionEnabled
                        transformSelf: false
                    }

                    Rectangle {
                        id: locationLabelPill
                        objectName: "folderFanLocationPill"
                        x: locationActionContent.pillX
                        width: locationActionContent.labelWidth
                        height: root.labelHeight
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.showLabels && width > 0
                        radius: height / 2
                        color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.88)
                        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                        border.width: 1
                        antialiasing: true
                        Accessible.ignored: true

                        PunchiMenuComponents.PunchiMenuTextShadowLabel {
                            id: locationActionLabel
                            objectName: "folderFanLocationLabel"
                            anchors.fill: parent
                            anchors.leftMargin: root.labelHorizontalPadding
                            anchors.rightMargin: root.labelHorizontalPadding
                            text: root.locationActionDisplayName
                            color: Kirigami.Theme.textColor
                            // Same graduated shadow as an application row: the
                            // closing caption is the row the arc leans the most.
                            shadowEnabled: root.textShadowsEnabled
                            shadowPercent: root.textShadowPercent
                            font.family: root.fontFamily
                            font.pointSize: root.fontSize
                            font.weight: Font.DemiBold
                            wrapMode: Text.NoWrap
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: root.iconsOnRight
                                ? Text.AlignRight : Text.AlignLeft
                            elide: Text.ElideMiddle
                        }
                    }

                    // Glyph of the entry that opens the container, taken from the
                    // macOS reference: a round grey disc with an arrow pointing
                    // towards the folder, with the file manager named in the pill
                    // beside it. The disc is the same themed surface as that pill,
                    // so it stays nearly opaque and readable over the desktop or
                    // over any window behind the fan instead of dissolving into
                    // it, and it follows a light and a dark theme without a fixed
                    // grey. The arrow then uses the contrasting theme text colour:
                    // with a light theme the disc is light, so the arrow cannot be.
                    // A translucent veil of the text colour is not valid here: the
                    // glyph sits outside the pill, with no surface of its own
                    // behind it.
                    Item {
                        id: locationGlyph
                        objectName: "folderFanLocationGlyph"
                        x: locationActionContent.iconX
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.iconSize
                        height: root.iconSize
                        // No lean of its own: the row carries the angle, exactly
                        // like an application row.

                        Rectangle {
                            objectName: "folderFanLocationDisc"
                            anchors.centerIn: parent
                            width: Math.round(parent.width * 0.6)
                            height: width
                            radius: width / 2
                            color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.88)
                            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                            border.width: 1
                            antialiasing: true
                        }

                        Kirigami.Icon {
                            objectName: "folderFanLocationArrow"
                            anchors.centerIn: parent
                            width: Math.round(parent.width * 0.34)
                            height: width
                            // The reference points towards the container it opens.
                            source: "go-next-symbolic"
                            color: Kirigami.Theme.textColor
                            Accessible.ignored: true
                        }
                    }
                }
            }
        }
    }
}
