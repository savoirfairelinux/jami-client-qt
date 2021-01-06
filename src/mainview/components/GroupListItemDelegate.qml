/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

ItemDelegate {
    id: groupListItemDelegate


    Rectangle {
        id: groupListItemDelegateRect

        height: 36
        width: 160

        //Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
        //Layout.leftMargin: 10

        //Layout.minimumHeight: 36
        //Layout.preferredHeight: 36
        //Layout.maximumHeight: 36

        //Layout.minimumWidth: 160
        //Layout.preferredWidth: 160
        //Layout.maximumWidth: 160

        radius: height / 2

        color: "transparent"

        AvatarImage {
            id: memberAvatarImage
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            width: 36
            height: 36

            mode: AvatarImage.Mode.FromContactUri
            imageId: URI
        }

        Text {
            id: groupMemberContactName

            //Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
//            Layout.leftMargin: 36+10
//            Layout.minimumWidth: 60
//            Layout.maximumWidth: 100
//            Layout.preferredWidth: 80


            anchors.left: memberAvatarImage.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 8

            width: 120

            color: JamiTheme.textColor
            text: textMetricsContactName.elidedText
            font.pointSize: JamiTheme.textFontSize

            TextMetrics {
                id: textMetricsContactName
                font: groupMemberContactName.font
                elide: Text.ElideRight
                elideWidth: 90
                text: DisplayName
            }
        }

        PushButton {
            id: removeGroupMember

//            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
//            Layout.rightMargin: 10


            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 10

            visible: true

            preferredSize: 16

            normalColor: JamiTheme.pressedButtonColor
            hoveredColor: JamiTheme.hoveredButtonColor
            pressedColor: JamiTheme.normalButtonColor

            source: "qrc:/images/icons/round-close-24px.svg"
            imageColor: hovered? JamiTheme.darkGreyColor
                               : JamiTheme.whiteColor

            onClicked: console.error("Clicked!")
        }
    }

    background: Rectangle {
        id: itemSmartListBackground

        color: JamiTheme.backgroundColor


        implicitWidth: groupListItemDelegateRect.width
        implicitHeight: groupListItemDelegateRect.height
        border.width: 0

        radius: height / 2
    }

    MouseArea {
        id: mouseAreaContactPickerItemDelegate

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onPressed: {
            itemSmartListBackground.color = JamiTheme.pressColor
        }

        onReleased: {
            itemSmartListBackground.color = JamiTheme.normalButtonColor
        }

        onEntered: {
            itemSmartListBackground.color = JamiTheme.hoverColor
        }

        onExited: {
            itemSmartListBackground.color = JamiTheme.backgroundColor
        }
    }
}
