/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Sébastien blin <sebastien.blin@savoirfairelinux.com>
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

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import net.jami.Constants 1.0

TextField {

    property int fieldLayoutWidth: 256
    property int fieldLayoutHeight: 48
    property bool layoutFillwidth: false

    property int borderColorMode: 0
    property var iconSource: ""
    property var backgroundColor: JamiTheme.editBackgroundColor
    property var borderColor: JamiTheme.greyBorderColor

    signal imageClicked

    onBorderColorModeChanged: {
        if (!enabled)
            borderColor = "transparent"
        if (readOnly)
            iconSource = ""

        switch(borderColorMode){
        case 1:
            iconSource = "qrc:/images/jami_rolling_spinner.gif"
            borderColor = JamiTheme.greyBorderColor
            break
        case 0:
            iconSource = ""
            borderColor = JamiTheme.greyBorderColor
            break
        case 2:
            iconSource = "qrc:/images/icons/round-check_circle-24px.svg"
            borderColor = "green"
            break
        case 3:
            iconSource = "qrc:/images/icons/round-error-24px.svg"
            borderColor = "red"
            break
        }
    }

    wrapMode: Text.Wrap
    readOnly: false
    selectByMouse: true
    font.pointSize: 10
    padding: 16
    //font.kerning: true
    horizontalAlignment: Text.AlignLeft
    verticalAlignment: Text.AlignVCenter
    color: JamiTheme.textColor

    Image {
        id: lineEditImage

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 16

        width: 24
        height: 24

        visible: borderColorMode !== 1
        source: borderColorMode === 1 ? "" : iconSource
        layer {
            enabled: true
            effect: ColorOverlay {
                id: overlay
                color: borderColor
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            enabled: borderColorMode === 2

            onReleased: {
                imageClicked()
            }
        }
    }

    AnimatedImage {
        anchors.left: lineEditImage.left
        anchors.verticalCenter: parent.verticalCenter

        width: 24
        height: 24

        source: borderColorMode !== 1 ? "" : iconSource
        playing: true
        paused: false
        fillMode: Image.PreserveAspectFit
        mipmap: true
        visible: borderColorMode === 1
    }

    background: Rectangle {
        anchors.fill: parent
        radius: 4
        border.color: readOnly? "transparent" : borderColor
        color: readOnly? "transparent" : backgroundColor
    }
}
