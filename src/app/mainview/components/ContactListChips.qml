/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick

import net.jami.Constants 1.1
import "../../commoncomponents"

// Compact, read-only chips for a contact's lists. Shows as many chips as fit
// in the given width and summarizes the rest in a "+N" chip.
Item {
    id: root

    property var lists: []
    property real spacing: 4

    readonly property real fullWidth: {
        let total = 0;
        for (let i = 0; i < repeater.count; i++)
            total += chipWidth(i) + (i > 0 ? spacing : 0);
        return total;
    }

    readonly property int visibleCount: {
        const count = repeater.count;
        if (fullWidth <= width)
            return count;
        // Reserve room for the widest possible overflow chip to avoid a binding loop on its text.
        const available = width - overflowMeasure.implicitWidth - spacing;
        let used = 0;
        for (let i = 0; i < count; i++) {
            used += chipWidth(i) + (i > 0 ? spacing : 0);
            if (used > available)
                return i;
        }
        return count;
    }
    readonly property int hiddenCount: repeater.count - visibleCount

    function chipWidth(i) {
        const chip = repeater.itemAt(i);
        return chip ? chip.width : 0;
    }

    implicitWidth: fullWidth
    implicitHeight: overflowMeasure.implicitHeight
    clip: true

    component ListChip: JamiChip {
        variant: JamiChip.Variant.Neutral
        textFont.pointSize: JamiTheme.smallFontSize
        verticalPadding: 1
        leftPadding: 6
        rightPadding: 6
        activeFocusOnTab: false
        toolTipText: text
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing

        Repeater {
            id: repeater

            model: root.lists

            delegate: ListChip {
                text: modelData
                width: Math.min(implicitWidth, JamiTheme.smartListListChipMaxWidth)
                visible: index < root.visibleCount
            }
        }

        ListChip {
            visible: root.hiddenCount > 0 && root.width >= implicitWidth
            text: "+" + root.hiddenCount
            toolTipText: root.lists.slice(root.visibleCount).join(", ")
        }
    }

    ListChip {
        id: overflowMeasure

        visible: false
        text: "+" + root.lists.length
    }
}
