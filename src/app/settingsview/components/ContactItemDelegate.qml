/*
 * Copyright (C) 2019-2026 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    implicitHeight: Math.max(JamiTheme.smartListItemHeight, textColumn.implicitHeight + 2 * (JamiTheme.itemPadding + JamiTheme.itemMarginVertical))

    property string contactName: ""
    property string contactID: ""
    property string btnImgSource: ""
    property string btnToolTip: ""
    property var removedTs: 0

    signal btnContactClicked

    background: Rectangle {
        id: contentRect

        anchors.fill: parent
        anchors.topMargin: JamiTheme.itemMarginVertical
        anchors.bottomMargin: JamiTheme.itemMarginVertical
        anchors.leftMargin: JamiTheme.itemMarginHorizontal
        anchors.rightMargin: JamiTheme.itemMarginHorizontal

        color: JamiTheme.editBackgroundColor
        radius: height / 2
    }

    RowLayout {
        anchors.fill: contentRect
        anchors.margins: JamiTheme.itemPadding
        anchors.leftMargin: Math.max(JamiTheme.itemPadding, contentRect.radius - avatar.width / 2)
        anchors.rightMargin: Math.max(JamiTheme.itemPadding, contentRect.radius - btnContact.height / 2)
        spacing: 16

        Avatar {
            id: avatar

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: JamiTheme.smartListAvatarSize
            Layout.preferredHeight: JamiTheme.smartListAvatarSize

            mode: Avatar.Mode.Contact
            imageId: root.contactID
            showPresenceIndicator: false
        }

        ColumnLayout {
            id: textColumn

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Label {
                id: labelContactName

                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignVCenter

                font.pointSize: JamiTheme.mediumFontSize
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
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignVCenter

                font.family: JamiTheme.ubuntuMonoFontFamily
                font.pointSize: JamiTheme.smallFontSize
                font.kerning: true

                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                elide: Text.ElideRight
                text: contactID === "" ? JamiStrings.identifier : contactID
                color: JamiTheme.textColor
            }

            Label {
                objectName: "labelContactRemovedDate"

                Layout.fillWidth: true
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignVCenter

                visible: root.removedTs > 0
                text: JamiStrings.contactRemovedOn + " " + UtilsAdapter.formatTimestamp(root.removedTs)
                color: JamiTheme.faddedFontColor
                font.pointSize: JamiTheme.smallFontSize
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        NewMaterialButton {
            id: btnContact

            Layout.alignment: Qt.AlignVCenter

            outlinedButton: true

            text: btnImgSource
            toolTipText: btnToolTip

            onClicked: btnContactClicked()
        }
    }
}
