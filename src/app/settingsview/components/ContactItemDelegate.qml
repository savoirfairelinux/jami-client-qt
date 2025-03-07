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
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    property string contactName: ""
    property string contactID: ""
    property string btnImgSource: ""
    property string btnToolTip: ""

    signal btnContactClicked

    background: Rectangle {
        color: JamiTheme.editBackgroundColor
        height: root.height
        radius: 5
    }

    RowLayout {
        anchors.fill: parent

        Label {
            id: labelContactAvatar

            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            horizontalAlignment: Text.AlignLeft

            background: Avatar {
                id: avatar

                anchors.fill: parent

                mode: Avatar.Mode.Contact
                imageId: contactID
                showPresenceIndicator: false
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter

            Label {
                id: labelContactName

                Layout.fillWidth: true

                Layout.preferredHeight: 24

                font.pointSize: JamiTheme.textFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: contactName === "" ? JamiStrings.name : contactName
                color: JamiTheme.textColor
            }

            Label {
                id: labelContactId

                Layout.fillWidth: true

                Layout.minimumHeight: 24
                Layout.preferredHeight: 24
                Layout.maximumHeight: 24

                font.pointSize: JamiTheme.textFontSize
                font.kerning: true

                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                elide: Text.ElideRight
                text: contactID === "" ? JamiStrings.identifier : contactID
                color: JamiTheme.textColor
            }
        }

        MaterialButton {
            id: btnContact

            Layout.rightMargin: 16

            TextMetrics {
                id: textSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.capitalization: Font.AllUppercase
                text: btnContact.text
            }

            secondary: true
            buttontextHeightMargin: 14

            text: btnImgSource
            preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding

            toolTipText: btnToolTip

            onClicked: btnContactClicked()
        }
    }
}
