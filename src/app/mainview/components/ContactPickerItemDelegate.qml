/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

    width: ListView.view.width
    height: JamiTheme.smartListItemHeight//Math.max(contactPickerContactName.height + textMetricsContactPickerContactId.height + 10, avatar.height + 10)

    property bool showPresenceIndicator: false

    signal contactClicked

    RowLayout {
        id: rowLayout

        anchors.fill: itemSmartListBackground
        anchors.margins: JamiTheme.itemPadding

        spacing: 16

        ConversationAvatar {
            id: avatar

            Layout.preferredWidth: JamiTheme.smartListAvatarSize
            Layout.preferredHeight: JamiTheme.smartListAvatarSize

            imageId: UID

            showPresenceIndicator: root.showPresenceIndicator && Presence
        }

        ColumnLayout {
            id: colLayout

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Text {
                id: contactPickerContactName

                Layout.fillWidth: true
                Layout.fillHeight: true

                TextMetrics {
                    id: textMetricsContactPickerContactName
                    font: contactPickerContactName.font
                    elide: Text.ElideMiddle
                    elideWidth: colLayout.width
                    text: Title
                }

                color: JamiTheme.textColor
                text: textMetricsContactPickerContactName.elidedText
                textFormat: TextEdit.PlainText
                font.pointSize: JamiTheme.textFontSize

                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: contactPickerContactId

                Layout.fillWidth: true
                Layout.fillHeight: true

                fontSizeMode: Text.Fit
                color: JamiTheme.faddedFontColor

                TextMetrics {
                    id: textMetricsContactPickerContactId
                    font: contactPickerContactId.font
                    elide: Text.ElideMiddle
                    elideWidth: colLayout.width
                    text: !BestId || BestId == Title ? "" : BestId
                }

                text: textMetricsContactPickerContactId.elidedText
                textFormat: TextEdit.PlainText
                font.pointSize: JamiTheme.textFontSize

                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    background: Rectangle {
        id: itemSmartListBackground

        anchors.fill: root
        anchors.topMargin: JamiTheme.itemMarginVertical
        anchors.bottomMargin: JamiTheme.itemMarginVertical
        anchors.leftMargin: JamiTheme.itemMarginHorizontal
        anchors.rightMargin: JamiTheme.itemMarginHorizontal

        radius: JamiTheme.commonRadius

        color: JamiTheme.backgroundColor
    }

    states: [
        State {
            name: "normal"
            when: !highlighted && !hovered
            PropertyChanges {
                target: itemSmartListBackground
                color: JamiTheme.globalIslandColor
            }
            PropertyChanges {
                target: root
                scale: 1.0
            }
        },
        State {
            name: "hovered"
            when: root.activeFocus || (!highlighted && hovered)
            PropertyChanges {
                target: itemSmartListBackground
                color: JamiTheme.smartListHoveredColor
            }
            PropertyChanges {
                target: root
                scale: ListView.view.width / itemSmartListBackground.width
            }
        },
        State {
            name: "highlighted"
            when: (highlighted && !hovered) || (highlighted && hovered)
            PropertyChanges {
                target: itemSmartListBackground
                color: JamiTheme.smartListSelectedColor
            }
            PropertyChanges {
                target: root
                scale: 1.0
            }
        }
    ]

    // Animations within a transition run in parallel
    transitions: [
        Transition {
            from: "normal"
            to: "hovered"
            reversible: true
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
            NumberAnimation {
                target: root
                property: "scale"
                duration: JamiTheme.shortFadeDuration
                easing.type: Easing.OutCubic
            }
        },
        Transition {
            from: "highlighted"
            to: "normal"
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        },
        Transition {
            from: "hovered"
            to: "highlighted"

            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
            NumberAnimation {
                target: root
                property: "scale"
                duration: JamiTheme.shortFadeDuration - 50
                easing.type: Easing.OutCubic
            }
        }
    ]

    MouseArea {
        id: mouseAreaContactPickerItemDelegate

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onPressed: {
            itemSmartListBackground.color = JamiTheme.pressColor;
        }

        onReleased: {
            itemSmartListBackground.color = JamiTheme.normalButtonColor;
            ContactAdapter.contactSelected(index);
            root.contactClicked();
            // TODO remove from there
            if (contactPickerPopup)
                contactPickerPopup.close();
        }
    }
}
