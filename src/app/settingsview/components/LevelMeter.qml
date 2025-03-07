/*
 * Copyright (C) 2019-2025 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

ProgressBar {
    id: root

    property real rmsLevel: 0

    LayoutMirroring.enabled: false

    value: {
        return clamp(rmsLevel * 300.0, 0.0, 100.0);
    }

    Behavior on value {
        NumberAnimation {
            duration: 50
        }
    }

    contentItem: Item {
        implicitWidth: parent.width
        implicitHeight: parent.height

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            color: JamiTheme.tintedBlue
        }
    }

    onVisibleChanged: {
        if (visible) {
            rmsLevel = 0;
            AvAdapter.startAudioMeter();
        } else
            AvAdapter.stopAudioMeter();
    }

    function clamp(num, a, b) {
        return Math.max(Math.min(num, Math.max(a, b)), Math.min(a, b));
    }

    Connections {
        target: AVModel
        enabled: root.visible

        function onAudioMeter(id, level) {
            if (id === "audiolayer_id") {
                rmsLevel = level;
            }
        }
    }
}
