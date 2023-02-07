/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
import Qt.labs.platform
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root

    color: CurrentConversation.color
    property var isAdmin: !CurrentConversation.isCoreDialog &&
        UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri) === Member.Role.ADMIN

    DevicesListPopup {
        id: devicesListPopup
    }

    ColumnLayout {
        id: swarmProfileDetails
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            id: header
            Layout.topMargin: JamiTheme.swarmDetailsPageTopMargin
            Layout.fillWidth: true
            spacing: JamiTheme.preferredMarginSize

            PhotoboothView {
                id: currentAccountAvatar
                darkTheme: UtilsAdapter.luma(root.color)
                readOnly: !root.isAdmin
                width: avatarSize
                height: avatarSize

                Layout.alignment: Qt.AlignHCenter

                newItem: true
                imageId: LRCInstance.selectedConvUid
                avatarSize: JamiTheme.smartListAvatarSize * 3/2
            }

            EditableLineEdit {
                id: titleLine

                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 5

                TextMetrics {
                    id: formattedTitle

                    font.pointSize: JamiTheme.titleFontSize
                    elide: !titleLine.editable ? Text.ElideRight : Text.ElideNone
                    elideWidth: titleLine.lineEdit.width - 25
                    text: CurrentConversation.title
                }

                wrapMode: Text.NoWrap
                font.pointSize: JamiTheme.titleFontSize

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                firstIco:  JamiResources.round_edit_24dp_svg
                secondIco: editable ? JamiResources.close_black_24dp_svg : ""

                fontSize: 20
                borderColor: "transparent"

                text: formattedTitle.elidedText
                readOnly: !root.isAdmin
                placeholderText: JamiStrings.swarmName
                placeholderTextColor: {
                    if (editable) {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.placeholderTextColorWhite
                        } else {
                            return JamiTheme.placeholderTextColor
                        }
                    } else {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.chatviewTextColorLight
                        } else {
                            return JamiTheme.chatviewTextColorDark
                        }
                    }
                }
                tooltipText: JamiStrings.swarmName
                backgroundColor: root.color
                color: UtilsAdapter.luma(backgroundColor) ?
                           JamiTheme.chatviewTextColorLight :
                           JamiTheme.chatviewTextColorDark

                onEditingFinished: {
                    if (text !== CurrentConversation.title)
                        ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid, text)
                }
                onSecondIcoClicked: {editable = !editable}
            }

            EditableLineEdit {
                id: descriptionLine

                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                font.pointSize: JamiTheme.menuFontSize

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                fontSize: 16

                firstIco:  JamiResources.round_edit_24dp_svg
                secondIco: editable ? JamiResources.close_black_24dp_svg : ""
                borderColor: "transparent"

                TextMetrics {
                    id: formattedDescription

                    font.pointSize: JamiTheme.titleFontSize
                    elide: !descriptionLine.editable ? Text.ElideRight : Text.ElideNone
                    elideWidth: descriptionLine.lineEdit.width - 25
                    text: CurrentConversation.description
                }

                wrapMode: Text.NoWrap

                text: formattedDescription.elidedText
                readOnly: !root.isAdmin
                visible: root.isAdmin || text.length > 0
                placeholderText: JamiStrings.addADescription
                placeholderTextColor: {
                    if (editable) {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.placeholderTextColorWhite
                        } else {
                            return JamiTheme.placeholderTextColor
                        }
                    } else {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.chatviewTextColorLight
                        } else {
                            return JamiTheme.chatviewTextColorDark
                        }
                    }
                }
                tooltipText: JamiStrings.addADescription
                backgroundColor: root.color
                color: UtilsAdapter.luma(backgroundColor) ?
                           JamiTheme.chatviewTextColorLight :
                           JamiTheme.chatviewTextColorDark

                onEditingFinished: {
                    if (text !== CurrentConversation.description)
                        ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, text)
                }

                onSecondIcoClicked: {editable = !editable}
            }

            TabBar {
                id: tabBar

                currentIndex: getTabIndex()

                onVisibleChanged: {
                    getTabIndex()
                }

                Layout.preferredWidth: root.width
                Layout.preferredHeight: settingsTabButton.height
                onCurrentIndexChanged: {
                    UtilsAdapter.setAppValue(Settings.tabIndex, currentIndex)
                }

                function getTabIndex() {
                    tabBar.currentIndex = UtilsAdapter.getAppValue(Settings.tabIndex)
                }

                FilterTabButton {
                    id: settingsTabButton

                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                                   JamiTheme.chatviewTextColorLight :
                                   JamiTheme.chatviewTextColorDark

                    down: tabBar.currentIndex === 0 || (CurrentConversation.isCoreDialog && tabBar.currentIndex === 1 )
                    labelText: JamiStrings.settings
                    Layout.fillWidth: true
                }

                FilterTabButton {
                    id: membersTabButton
                    visible: !CurrentConversation.isCoreDialog

                    Layout.fillWidth: true
                    width: visible ? tabBar.width/3 : 0
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                                   JamiTheme.chatviewTextColorLight :
                                   JamiTheme.chatviewTextColorDark

                    down: tabBar.currentIndex === 1 && !CurrentConversation.isCoreDialog
                    labelText: {
                        var membersNb = CurrentConversation.uris.length;
                        if (membersNb > 1)
                            return JamiStrings.members.arg(membersNb)
                        return JamiStrings.member
                    }
                }

                FilterTabButton {
                    id: documentsTabButton
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    Layout.fillWidth: true
                    textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                                   JamiTheme.chatviewTextColorLight :
                                   JamiTheme.chatviewTextColorDark

                    down: tabBar.currentIndex === 2
                    labelText: JamiStrings.documents
                }
            }
        }

        ColorDialog {
            id: colorDialog
            title: JamiStrings.chooseAColor
            onAccepted: {
                CurrentConversation.setPreference("color", colorDialog.color)
            }
        }

        ConfirmDialog {
            id: rmDialog

            title: JamiStrings.confirmAction
            textLabel: JamiStrings.confirmRmConversation
            confirmLabel: JamiStrings.optionRemove
            onAccepted: {
                MessagesAdapter.removeConversation(LRCInstance.selectedConvUid)
            }
        }

        Rectangle {
            id: details
            Layout.fillWidth: true
            Layout.preferredHeight: root.height - header.height - JamiTheme.preferredMarginSize
            color: JamiTheme.secondaryBackgroundColor


            JamiFlickable {
                id: settingsScrollView
                property ScrollBar vScrollBar: ScrollBar.vertical
                anchors.fill: parent

                contentHeight: aboutSwarm.height + JamiTheme.preferredMarginSize

                ColumnLayout {
                    id: aboutSwarm
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: JamiTheme.settingsMarginSize
                    visible: tabBar.currentIndex === 0 || (CurrentConversation.isCoreDialog && tabBar.currentIndex === 1)
                    Layout.alignment: Qt.AlignTop

                    SwarmDetailsItem {
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                        ToggleSwitch {
                            id: ignoreSwarm

                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize

                            checked: CurrentConversation.ignoreNotifications

                            labelText: JamiStrings.muteConversation
                            fontPointSize: JamiTheme.settingsFontSize

                            tooltipText: JamiStrings.ignoreNotificationsTooltip

                            onSwitchToggled: {
                                CurrentConversation.setPreference("ignoreNotifications", checked ? "true" : "false")
                            }
                        }
                    }

                    SwarmDetailsItem {
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: JamiTheme.preferredMarginSize
                            text: JamiStrings.leaveConversation
                            font.pointSize: JamiTheme.settingsFontSize
                            font.kerning: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor
                        }

                        TapHandler {
                            target: parent
                            enabled: parent.visible
                            onTapped: function onTapped(eventPoint) {
                                rmDialog.open()
                            }
                        }
                    }

                    SwarmDetailsItem {
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize

                            Text {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                Layout.rightMargin: JamiTheme.preferredMarginSize

                                text: JamiStrings.chooseAColor
                                font.pointSize: JamiTheme.settingsFontSize
                                font.kerning: true
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter

                                color: JamiTheme.textColor
                            }

                            Rectangle {
                                id: chooseAColorBtn

                                Layout.alignment: Qt.AlignRight

                                width: JamiTheme.aboutBtnSize
                                height: JamiTheme.aboutBtnSize
                                radius: JamiTheme.aboutBtnSize / 2

                                color: CurrentConversation.color
                            }
                        }

                        TapHandler {
                            target: parent
                            enabled: parent.visible
                            onTapped: function onTapped(eventPoint) {
                                colorDialog.open()
                            }
                        }
                    }

                    SwarmDetailsItem {
                        id: settingsSwarmItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize

                            Text {
                                id: settingsSwarmText
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                Layout.rightMargin: JamiTheme.preferredMarginSize
                                Layout.maximumWidth: settingsSwarmItem.width / 2

                                text: JamiStrings.defaultCallHost
                                font.pointSize: JamiTheme.settingsFontSize
                                font.kerning: true
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter

                                color: JamiTheme.textColor
                            }


                            RowLayout {
                                id: swarmRdvPref
                                spacing: 10
                                Layout.alignment: Qt.AlignRight
                                Layout.maximumWidth: settingsSwarmItem.width / 2

                                Connections {
                                    target: CurrentConversation

                                    function onRdvAccountChanged() {
                                        // This avoid incorrect avatar by always modifying the mode before the imageId
                                        avatar.mode = CurrentConversation.rdvAccount === CurrentAccount.uri ? Avatar.Mode.Account : Avatar.Mode.Contact
                                        avatar.imageId = CurrentConversation.rdvAccount === CurrentAccount.uri ? CurrentAccount.id : CurrentConversation.rdvAccount
                                    }
                                }

                                Avatar {
                                    id: avatar
                                    width: JamiTheme.contactMessageAvatarSize
                                    height: JamiTheme.contactMessageAvatarSize
                                    Layout.leftMargin: JamiTheme.preferredMarginSize
                                    Layout.topMargin: JamiTheme.preferredMarginSize / 2
                                    visible: CurrentConversation.rdvAccount !== ""

                                    imageId: ""
                                    showPresenceIndicator: false
                                    mode: Avatar.Mode.Account
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.alignment: Qt.AlignVCenter

                                    ElidedTextLabel {
                                        id: bestName

                                        eText: {
                                            if (CurrentConversation.rdvAccount === "")
                                                return JamiStrings.none
                                            else if (CurrentConversation.rdvAccount === CurrentAccount.uri)
                                                return CurrentAccount.bestName
                                            else
                                                return UtilsAdapter.getBestNameForUri(CurrentAccount.id, CurrentConversation.rdvAccount)
                                        }
                                        maxWidth: JamiTheme.preferredFieldWidth

                                        font.pointSize: JamiTheme.participantFontSize
                                        color: JamiTheme.primaryForegroundColor
                                        font.kerning: true

                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    ElidedTextLabel {
                                        id: deviceId

                                        eText: CurrentConversation.rdvDevice === "" ? JamiStrings.none : CurrentConversation.rdvDevice
                                        visible: CurrentConversation.rdvDevice !== ""
                                        maxWidth: JamiTheme.preferredFieldWidth

                                        font.pointSize: JamiTheme.participantFontSize
                                        color: JamiTheme.textColorHovered
                                        font.kerning: true

                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }

                        TapHandler {
                            target: parent

                            enabled: parent.visible && root.isAdmin
                            onTapped: function onTapped(eventPoint) {
                                devicesListPopup.open()
                            }
                        }
                    }

                    RowLayout {
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                        Text {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            Layout.rightMargin: JamiTheme.preferredMarginSize

                            text: JamiStrings.typeOfSwarm
                            font.pointSize: JamiTheme.settingsFontSize
                            font.kerning: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor
                        }

                        Label {
                            id: typeOfSwarmLabel

                            Layout.alignment: Qt.AlignRight

                            color: JamiTheme.textColor

                            text: CurrentConversation.modeString
                        }
                    }

                    RowLayout {
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        Layout.maximumWidth: parent.width
                        visible: LRCInstance.debugMode()

                        Text {
                            id: idLabel
                            Layout.preferredHeight: 30
                            Layout.rightMargin: JamiTheme.preferredMarginSize
                            Layout.maximumWidth: parent.width / 2

                            text: JamiStrings.identifier
                            font.pointSize: JamiTheme.settingsFontSize
                            font.kerning: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            Layout.maximumWidth: parent.width / 2

                            color: JamiTheme.textColor


                            text: CurrentConversation.id
                            elide: Text.ElideRight

                        }
                    }
                }
            }

            JamiListView {
                id: members
                anchors.topMargin: JamiTheme.preferredMarginSize
                anchors.bottomMargin: JamiTheme.preferredMarginSize
                anchors.fill: parent

                visible: tabBar.currentIndex === 1 && !CurrentConversation.isCoreDialog

                SwarmParticipantContextMenu {
                    id: contextMenu
                    role: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri)

                    function openMenuAt(x, y, participantUri) {
                        contextMenu.x = x
                        contextMenu.y = y
                        contextMenu.conversationId = CurrentConversation.id
                        contextMenu.participantUri = participantUri

                        openMenu()
                    }
                }

                model: CurrentConversation.uris
                delegate: ItemDelegate {
                    id: member

                    width: members.width
                    height: JamiTheme.smartListItemHeight

                    background: Rectangle {
                        anchors.fill: parent
                        color: {
                            if (member.hovered || nameTextEditHover.hovered)
                                return Qt.darker(JamiTheme.selectedColor, 1.05)
                            else
                                return "transparent"
                        }
                    }

                    MouseArea {
                        id: memberMouseArea

                        anchors.fill: parent
                        enabled: modelData !== CurrentAccount.uri
                        acceptedButtons: Qt.RightButton
                        onClicked: function (mouse) {
                            var position = mapToItem(members, mouse.x, mouse.y)
                            contextMenu.openMenuAt(position.x, position.y, modelData)
                        }
                    }

                    RowLayout {
                        spacing: 10
                        anchors.fill: parent
                        anchors.rightMargin: JamiTheme.preferredMarginSize

                        Avatar {
                            width: JamiTheme.smartListAvatarSize
                            height: JamiTheme.smartListAvatarSize
                            Layout.leftMargin: JamiTheme.preferredMarginSize
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
                            z: -index
                            opacity: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                return role === Member.Role.INVITED ? 0.5 : 1
                            }

                            imageId: CurrentAccount.uri == modelData ? CurrentAccount.id : modelData
                            showPresenceIndicator: UtilsAdapter.getContactPresence(CurrentAccount.id, modelData)
                            mode: CurrentAccount.uri == modelData ? Avatar.Mode.Account : Avatar.Mode.Contact
                        }

                        ElidedTextLabel {
                            id: nameTextEdit

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
                            Layout.fillWidth: true

                            eText: UtilsAdapter.getContactBestName(CurrentAccount.id, modelData)
                            maxWidth: width

                            font.pointSize: JamiTheme.participantFontSize
                            color: JamiTheme.primaryForegroundColor
                            opacity: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                return role === Member.Role.INVITED ? 0.5 : 1
                            }

                            font.kerning: true

                            verticalAlignment: Text.AlignVCenter

                            HoverHandler {
                                id: nameTextEditHover
                            }
                        }

                        ElidedTextLabel {
                            id: role

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2

                            eText: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                if (role === Member.Role.ADMIN)
                                    return JamiStrings.administrator
                                if (role === Member.Role.INVITED)
                                    return JamiStrings.invited
                                return ""
                            }
                            maxWidth: JamiTheme.preferredFieldWidth

                            font.pointSize: JamiTheme.participantFontSize
                            color: JamiTheme.textColorHovered
                            opacity: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                return role === Member.Role.INVITED ? 0.5 : 1
                            }
                            font.kerning: true

                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            DocumentsScrollview {
                id: documents

                clip: true
                visible: tabBar.currentIndex === 2
                anchors.fill: parent
            }
        }
    }
}
