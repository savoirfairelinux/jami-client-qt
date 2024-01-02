/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <Nicolas.vengeon@savoirfairelinux.com>

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

Rectangle {
    id: root

    color: JamiTheme.secondaryBackgroundColor
    border.color: selectedScreenNumber === elementIndex ? JamiTheme.screenSelectionBorderColor : JamiTheme.tabbarBorderColor

    width: elementWidth
    height: 3 * width / 4

    property var elementIndex
    property string rectTitle
    property var rId

    Text {
        id: textTitle

        anchors.top: parent.top
        anchors.topMargin: marginSize
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 2 * marginSize

        font.pointSize: JamiTheme.textFontSize
        text: rectTitle
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        color: JamiTheme.textColor
    }

    VideoView {
        anchors.top: textTitle.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height - 50
        width: parent.width - 50

        Component.onDestruction: {
            VideoDevices.stopDevice(rendererId);
        }
        Component.onCompleted: {
            if (root.rId !== "") {
                rendererId = VideoDevices.startDevice(root.rId);
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton

        onClicked: {
            if (selectedScreenNumber !== root.elementIndex) {
                selectedScreenNumber = root.elementIndex;
            }
        }
    }
}
