/*
    SPDX-FileCopyrightText: 2026 Krohnkite contributors

    SPDX-License-Identifier: MIT
*/

import QtQuick;
import org.kde.plasma.core as PlasmaCore;

/*
 * Ghost rectangle shown while dragging a window over a dock slot, so the user
 * can see where the window will land before releasing the mouse button.
 *
 * The dialog is an on-screen-display surface, frameless, always on top and
 * fully transparent for input, so it never interferes with the active drag.
 *
 * KWin re-runs OSD placement whenever the window size changes (see
 * Placement::placeOnScreenDisplay), which would override any position we set.
 * To avoid that, the window size/position are fixed to the active output and
 * only the inner rectangle moves; `hide()` merely collapses the rectangle
 * instead of unmapping the window.
 */
PlasmaCore.Dialog {
    id: dragPreview

    type: PlasmaCore.Dialog.OnScreenDisplay
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowTransparentForInput | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Dialog.NoBackground
    outputOnly: true
    hideOnWindowDeactivate: false

    visible: true

    /* Output(full screen) area the overlay is anchored to. */
    property int areaX: 0
    property int areaY: 0
    property int areaW: 0
    property int areaH: 0

    property color frameColor: Qt.rgba(0.24, 0.53, 0.94, 0.30)
    property color borderColor: Qt.rgba(0.24, 0.53, 0.94, 0.90)

    function showRect(ax, ay, aw, ah, x, y, w, h, frame, border) {
        if (frame !== undefined)
            frameColor = frame;
        if (border !== undefined)
            borderColor = border;

        if (aw <= 0 || ah <= 0 || w <= 0 || h <= 0) {
            hide();
            return;
        }

        var areaChanged = (areaX !== ax || areaY !== ay || areaW !== aw || areaH !== ah);
        if (areaChanged) {
            areaX = ax;
            areaY = ay;
            areaW = aw;
            areaH = ah;
            /* The size change makes KWin re-place the OSD; keep the rectangle
             * hidden until the next (size-stable) call re-asserts the position. */
            previewRect.visible = false;
        }

        /* Position-only changes are always honored: the size is unchanged, so
         * KWin does not re-place the window. */
        dragPreview.x = areaX;
        dragPreview.y = areaY;

        previewRect.x = x - areaX;
        previewRect.y = y - areaY;
        previewRect.width = w;
        previewRect.height = h;
        if (!areaChanged)
            previewRect.visible = true;
    }

    function hide() {
        previewRect.visible = false;
    }

    mainItem: Item {
        width: dragPreview.areaW
        height: dragPreview.areaH

        Rectangle {
            id: previewRect

            visible: false
            color: dragPreview.frameColor
            border.width: 2
            border.color: dragPreview.borderColor
            radius: 4
        }
    }
}
