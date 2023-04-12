/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Albert Babí Oller <albert.babi@savoirfairelinux.com>
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
    property string btnImgSource: ""
    property string btnToolTip: ""
    property string contactID: ""
    property string contactName: ""

    signal btnContactClicked

    RowLayout {
        anchors.fill: parent

        Label {
            id: labelContactAvatar
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.rightMargin: JamiTheme.preferredMarginSize

            background: Avatar {
                id: avatar
                anchors.fill: parent
                imageId: contactID
                mode: Avatar.Mode.Contact
                showPresenceIndicator: false
            }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            Layout.fillWidth: true

            Label {
                id: labelContactName
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                color: JamiTheme.textColor
                elide: Text.ElideRight
                font.kerning: true
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignLeft
                text: contactName === "" ? JamiStrings.name : contactName
                verticalAlignment: Text.AlignVCenter
            }
            Label {
                id: labelContactId
                Layout.fillWidth: true
                Layout.maximumHeight: 24
                Layout.minimumHeight: 24
                Layout.preferredHeight: 24
                color: JamiTheme.textColor
                elide: Text.ElideRight
                font.kerning: true
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Qt.AlignLeft
                text: contactID === "" ? JamiStrings.identifier : contactID
                verticalAlignment: Qt.AlignVCenter
            }
        }
        MaterialButton {
            id: btnContact
            Layout.rightMargin: 16
            buttontextHeightMargin: 14
            preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
            secondary: true
            text: btnImgSource
            toolTipText: btnToolTip

            onClicked: btnContactClicked()

            TextMetrics {
                id: textSize
                font.capitalization: Font.AllUppercase
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.weight: Font.Bold
                text: btnContact.text
            }
        }
    }

    background: Rectangle {
        color: JamiTheme.editBackgroundColor
        height: root.height
        radius: 5
    }
}
