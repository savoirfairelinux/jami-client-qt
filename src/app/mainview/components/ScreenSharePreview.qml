/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
    property var elementIndex
    property var rId
    property string rectTitle

    border.color: selectedScreenNumber === elementIndex ? JamiTheme.screenSelectionBorderColor : JamiTheme.tabbarBorderColor
    color: JamiTheme.secondaryBackgroundColor
    height: 3 * width / 4
    width: elementWidth

    Text {
        id: textTitle
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: marginSize
        color: JamiTheme.textColor
        elide: Text.ElideRight
        font.pointSize: JamiTheme.textFontSize
        horizontalAlignment: Text.AlignHCenter
        text: rectTitle
        width: parent.width - 2 * marginSize
    }
    VideoView {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: textTitle.bottom
        anchors.topMargin: 10
        height: parent.height - 50
        width: parent.width - 50

        Component.onCompleted: {
            if (root.rId !== "") {
                rendererId = VideoDevices.startDevice(root.rId);
            }
        }
        Component.onDestruction: {
            VideoDevices.stopDevice(rendererId);
        }
    }
    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent

        onClicked: {
            if (selectedScreenNumber !== root.elementIndex) {
                selectedScreenNumber = root.elementIndex;
            }
        }
    }
}
