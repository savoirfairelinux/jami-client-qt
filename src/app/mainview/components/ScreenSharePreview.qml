/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    property var elementIndex
    property string rectTitle
    property var rId

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: 8
    topPadding: marginSize

    activeFocusOnTab: true

    contentItem: ColumnLayout {

        spacing: 10

        Text {
            id: textTitle

            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            text: rectTitle
            color: JamiTheme.textColor
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pointSize: JamiTheme.textFontSize
        }

        VideoView {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.fillHeight: true

            Component.onDestruction: {
                VideoDevices.stopDevice(rendererId);
            }
            Component.onCompleted: {
                if (root.rId !== "") {
                    rendererId = VideoDevices.startDevice(root.rId);
                }
            }
        }
    }

    background: Rectangle {
        radius: 8

        color: selectedScreenNumber === elementIndex ? JamiTheme.smartListSelectedColor : JamiTheme.editBackgroundColor
        border.color: root.activeFocus || root.hovered || selectedScreenNumber === elementIndex ? JamiTheme.tintedBlue : JamiTheme.hoveredButtonColor
        border.width: 2

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    onClicked: {
        if (selectedScreenNumber !== root.elementIndex) {
            selectedScreenNumber = root.elementIndex;
        }
    }
}
