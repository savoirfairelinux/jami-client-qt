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
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root
    property var isAdmin: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri) === Member.Role.ADMIN || CurrentConversation.isCoreDialog
    property alias tabBarIndex: tabBar.currentIndex
    property int tabBarItemsLength: tabBar.contentChildren.length
    property string textColor: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark

    color: CurrentConversation.color

    ColumnLayout {
        id: swarmProfileDetails
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            id: header
            Layout.fillWidth: true
            Layout.topMargin: JamiTheme.swarmDetailsPageTopMargin
            spacing: JamiTheme.preferredMarginSize

            RowLayout {
                Layout.leftMargin: 15
                spacing: 15

                PhotoboothView {
                    id: currentAccountAvatar
                    Layout.alignment: Qt.AlignHCenter
                    avatarSize: JamiTheme.smartListAvatarSize * 3 / 2
                    height: avatarSize
                    imageId: LRCInstance.selectedConvUid
                    newItem: true
                    readOnly: !root.isAdmin
                    width: avatarSize
                }
                ColumnLayout {
                    signal accepted

                    ModalTextEdit {
                        id: titleLine
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight
                        Layout.preferredWidth: Math.min(217, swarmProfileDetails.width - currentAccountAvatar.width - 30 - JamiTheme.settingsMarginSize)
                        infoTipLineText: JamiStrings.swarmName
                        isSwarmDetail: true
                        prefixIconColor: root.textColor
                        readOnly: !isAdmin
                        staticText: CurrentConversation.title
                        textColor: root.textColor

                        onAccepted: {
                            ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid, dynamicText);
                        }
                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid, dynamicText);
                            }
                        }
                    }
                    ModalTextEdit {
                        id: descriptionLineButton
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight
                        Layout.preferredWidth: Math.min(217, swarmProfileDetails.width - currentAccountAvatar.width - 30 - JamiTheme.settingsMarginSize)
                        infoTipLineText: JamiStrings.addADescription
                        isSwarmDetail: true
                        placeholderText: JamiStrings.addADescription
                        prefixIconColor: root.textColor
                        readOnly: !isAdmin || CurrentConversation.isCoreDialog
                        staticText: CurrentConversation.description
                        textColor: root.textColor

                        onAccepted: ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, dynamicText)
                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, dynamicText);
                            }
                        }
                    }
                }
            }
            TabBar {
                id: tabBar
                property string currentItemName: itemAt(currentIndex).objectName

                Layout.preferredHeight: settingsTabButton.height
                Layout.preferredWidth: root.width
                currentIndex: 0

                function addRemoveButtons() {
                    if (CurrentConversation.isCoreDialog) {
                        if (tabBar.contentChildren.length === 3)
                            tabBar.removeItem(tabBar.itemAt(1));
                    } else {
                        if (tabBar.contentChildren.length === 2) {
                            const obj = membersTabButtonComp.createObject(tabBar);
                            tabBar.insertItem(1, obj);
                        }
                    }
                }

                Component.onCompleted: addRemoveButtons()

                Connections {
                    target: CurrentConversation

                    function onIsCoreDialogChanged() {
                        tabBar.addRemoveButtons();
                    }
                }
                Component {
                    id: membersTabButtonComp
                    DetailsTabButton {
                        id: membersTabButton
                        labelText: {
                            var membersNb = CurrentConversationMembers.count;
                            if (membersNb > 1)
                                return JamiStrings.members.arg(membersNb);
                            return JamiStrings.member;
                        }
                        objectName: "members"
                        visible: !CurrentConversation.isCoreDialog
                    }
                }
                DetailsTabButton {
                    id: documentsTabButton
                    labelText: JamiStrings.documents
                    objectName: "documents"
                }
                DetailsTabButton {
                    id: settingsTabButton
                    labelText: JamiStrings.settings
                    objectName: "settings"
                }
            }
        }
        Component {
            id: colorDialogComp
            ColorDialog {
                id: colorDialog
                title: JamiStrings.chooseAColor

                onAccepted: {
                    CurrentConversation.setPreference("color", colorDialog.color);
                    this.destroy();
                }
                onRejected: this.destroy()
            }
        }
        Rectangle {
            id: details
            Layout.fillWidth: true
            Layout.preferredHeight: root.height - header.height - 2 * JamiTheme.preferredMarginSize
            color: JamiTheme.secondaryBackgroundColor

            JamiFlickable {
                id: settingsScrollView
                property ScrollBar vScrollBar: ScrollBar.vertical

                anchors.fill: parent
                contentHeight: aboutSwarm.height + JamiTheme.preferredMarginSize

                ColumnLayout {
                    id: aboutSwarm
                    Layout.alignment: Qt.AlignTop
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0
                    visible: tabBar.currentItemName === "settings"

                    SwarmDetailsItem {
                        id: firstParameter
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                        ToggleSwitch {
                            id: ignoreSwarm
                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize
                            anchors.rightMargin: JamiTheme.settingsMarginSize
                            checked: CurrentConversation.ignoreNotifications
                            labelText: JamiStrings.muteConversation
                            tooltipText: JamiStrings.ignoreNotificationsTooltip

                            onSwitchToggled: {
                                CurrentConversation.setPreference("ignoreNotifications", checked ? "true" : "false");
                            }
                        }
                    }
                    SwarmDetailsItem {
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                        Text {
                            anchors.left: parent.left
                            anchors.margins: JamiTheme.preferredMarginSize
                            anchors.top: parent.top
                            color: JamiTheme.textColor
                            elide: Text.ElideRight
                            font.kerning: true
                            font.pixelSize: JamiTheme.participantSwarmDetailFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: JamiStrings.leaveConversation
                            verticalAlignment: Text.AlignVCenter
                        }
                        TapHandler {
                            enabled: parent.visible
                            target: parent

                            onTapped: function onTapped(eventPoint) {
                                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                                        "title": JamiStrings.confirmAction,
                                        "textLabel": JamiStrings.confirmRmConversation,
                                        "confirmLabel": JamiStrings.optionRemove
                                    });
                                dlg.accepted.connect(function () {
                                        MessagesAdapter.removeConversation(LRCInstance.selectedConvUid);
                                    });
                            }
                        }
                    }
                    SwarmDetailsItem {
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        visible: CurrentAccount.type !== Profile.Type.SIP // TODO for SIP save in VCard

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize
                            anchors.rightMargin: JamiTheme.preferredMarginSize

                            Text {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                Layout.rightMargin: JamiTheme.preferredMarginSize
                                color: JamiTheme.textColor
                                elide: Text.ElideRight
                                font.kerning: true
                                font.pixelSize: JamiTheme.participantSwarmDetailFontSize
                                horizontalAlignment: Text.AlignLeft
                                text: JamiStrings.chooseAColor
                                verticalAlignment: Text.AlignVCenter
                            }
                            Rectangle {
                                id: chooseAColorBtn
                                Layout.alignment: Qt.AlignRight
                                color: CurrentConversation.color
                                height: JamiTheme.aboutBtnSize
                                radius: JamiTheme.aboutBtnSize / 2
                                width: JamiTheme.aboutBtnSize
                            }
                        }
                        TapHandler {
                            enabled: parent.visible
                            target: parent

                            onTapped: function onTapped(eventPoint) {
                                colorDialogComp.createObject(appWindow).open();
                            }
                        }
                    }
                    SwarmDetailsItem {
                        id: settingsSwarmItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        visible: !CurrentConversation.isCoreDialog

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: JamiTheme.preferredMarginSize
                            anchors.rightMargin: JamiTheme.preferredMarginSize

                            Text {
                                id: settingsSwarmText
                                Layout.fillWidth: true
                                Layout.maximumWidth: settingsSwarmItem.width / 2
                                Layout.preferredHeight: 30
                                Layout.rightMargin: JamiTheme.preferredMarginSize
                                color: JamiTheme.textColor
                                elide: Text.ElideRight
                                font.kerning: true
                                font.pixelSize: JamiTheme.participantSwarmDetailFontSize
                                horizontalAlignment: Text.AlignLeft
                                text: JamiStrings.defaultCallHost
                                verticalAlignment: Text.AlignVCenter
                            }
                            RowLayout {
                                id: swarmRdvPref
                                Layout.alignment: Qt.AlignRight
                                Layout.fillWidth: true
                                spacing: 10

                                Connections {
                                    target: CurrentConversation

                                    function onRdvAccountChanged() {
                                        // This avoid incorrect avatar by always modifying the mode before the imageId
                                        avatar.mode = CurrentConversation.rdvAccount === CurrentAccount.uri ? Avatar.Mode.Account : Avatar.Mode.Contact;
                                        avatar.imageId = CurrentConversation.rdvAccount === CurrentAccount.uri ? CurrentAccount.id : CurrentConversation.rdvAccount;
                                    }
                                }
                                Avatar {
                                    id: avatar
                                    Layout.leftMargin: JamiTheme.preferredMarginSize
                                    Layout.topMargin: JamiTheme.preferredMarginSize / 2
                                    height: JamiTheme.contactMessageAvatarSize
                                    imageId: ""
                                    mode: Avatar.Mode.Account
                                    showPresenceIndicator: false
                                    visible: CurrentConversation.rdvAccount !== ""
                                    width: JamiTheme.contactMessageAvatarSize
                                }
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    spacing: 0

                                    ElidedTextLabel {
                                        id: bestName
                                        color: JamiTheme.primaryForegroundColor
                                        eText: {
                                            if (CurrentConversation.rdvAccount === "")
                                                return JamiStrings.none;
                                            else if (CurrentConversation.rdvAccount === CurrentAccount.uri)
                                                return CurrentAccount.bestName;
                                            else
                                                return UtilsAdapter.getBestNameForUri(CurrentAccount.id, CurrentConversation.rdvAccount);
                                        }
                                        font.kerning: true
                                        font.pointSize: eText === JamiStrings.none ? JamiTheme.settingsFontSize : JamiTheme.smartlistItemInfoFontSize
                                        font.weight: eText === JamiStrings.none ? Font.Medium : Font.Normal
                                        horizontalAlignment: Text.AlignRight
                                        maxWidth: settingsSwarmItem.width / 2 - JamiTheme.contactMessageAvatarSize
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    ElidedTextLabel {
                                        id: deviceId
                                        color: JamiTheme.textColorHovered
                                        eText: CurrentConversation.rdvDevice === "" ? JamiStrings.none : CurrentConversation.rdvDevice
                                        font.kerning: true
                                        font.pointSize: JamiTheme.settingsFontSize
                                        horizontalAlignment: Text.AlignRight
                                        maxWidth: settingsSwarmItem.width / 2 - JamiTheme.contactMessageAvatarSize
                                        verticalAlignment: Text.AlignVCenter
                                        visible: CurrentConversation.rdvDevice !== ""
                                    }
                                }
                            }
                        }
                        TapHandler {
                            enabled: parent.visible && root.isAdmin
                            target: parent

                            onTapped: function onTapped(eventPoint) {
                                viewCoordinator.presentDialog(appWindow, "mainview/components/DevicesListPopup.qml");
                            }
                        }
                    }
                    RowLayout {
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        visible: CurrentAccount.type !== Profile.Type.SIP

                        Text {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            Layout.rightMargin: JamiTheme.preferredMarginSize
                            color: JamiTheme.textColor
                            elide: Text.ElideRight
                            font.kerning: true
                            font.pixelSize: JamiTheme.participantSwarmDetailFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: JamiStrings.typeOfSwarm
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            id: typeOfSwarmLabel
                            Layout.alignment: Qt.AlignRight
                            Layout.rightMargin: JamiTheme.preferredMarginSize
                            color: JamiTheme.textColor
                            font.pixelSize: JamiTheme.participantSwarmDetailFontSize
                            font.weight: Font.Medium
                            text: CurrentConversation.modeString
                        }
                    }
                    RowLayout {
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        Layout.maximumWidth: parent.width
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        visible: LRCInstance.debugMode()

                        Text {
                            id: idLabel
                            Layout.maximumWidth: parent.width / 2
                            Layout.preferredHeight: 30
                            Layout.rightMargin: JamiTheme.preferredMarginSize
                            color: JamiTheme.textColor
                            elide: Text.ElideRight
                            font.kerning: true
                            font.pixelSize: JamiTheme.participantSwarmDetailFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: JamiStrings.identifier
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            Layout.alignment: Qt.AlignRight
                            Layout.maximumWidth: parent.width / 2
                            Layout.rightMargin: JamiTheme.settingsMarginSize
                            color: JamiTheme.textColor
                            elide: Text.ElideRight
                            font.pixelSize: JamiTheme.participantSwarmDetailFontSize
                            text: CurrentConversation.id
                        }
                    }
                }
            }
            JamiListView {
                id: members
                anchors.bottomMargin: JamiTheme.preferredMarginSize
                anchors.fill: parent
                anchors.topMargin: JamiTheme.preferredMarginSize
                model: CurrentConversationMembers
                visible: tabBar.currentItemName === "members"

                SwarmParticipantContextMenu {
                    id: contextMenu
                    role: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri)

                    function openMenuAt(x, y, participantUri) {
                        contextMenu.x = x;
                        contextMenu.y = y;
                        contextMenu.conversationId = CurrentConversation.id;
                        contextMenu.participantUri = participantUri;
                        openMenu();
                    }
                }

                delegate: ItemDelegate {
                    id: member
                    height: JamiTheme.smartListItemHeight
                    width: members.width

                    MouseArea {
                        id: memberMouseArea
                        acceptedButtons: Qt.RightButton
                        anchors.fill: parent
                        enabled: MemberUri !== CurrentAccount.uri

                        onClicked: function (mouse) {
                            var position = mapToItem(members, mouse.x, mouse.y);
                            contextMenu.openMenuAt(position.x, position.y, MemberUri);
                        }
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.rightMargin: JamiTheme.preferredMarginSize
                        spacing: 10

                        Avatar {
                            Layout.leftMargin: JamiTheme.preferredMarginSize
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
                            height: JamiTheme.smartListAvatarSize
                            imageId: CurrentAccount.uri === MemberUri ? CurrentAccount.id : MemberUri
                            mode: CurrentAccount.uri === MemberUri ? Avatar.Mode.Account : Avatar.Mode.Contact
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1
                            showPresenceIndicator: UtilsAdapter.getContactPresence(CurrentAccount.id, MemberUri)
                            width: JamiTheme.smartListAvatarSize
                            z: -index
                        }
                        ElidedTextLabel {
                            id: nameTextEdit
                            Layout.fillWidth: true
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
                            color: JamiTheme.primaryForegroundColor
                            eText: UtilsAdapter.getContactBestName(CurrentAccount.id, MemberUri)
                            font.kerning: true
                            font.pointSize: JamiTheme.settingsFontSize
                            maxWidth: width
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1
                            verticalAlignment: Text.AlignVCenter

                            HoverHandler {
                                id: nameTextEditHover
                            }
                        }
                        ElidedTextLabel {
                            id: roleLabel
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
                            color: JamiTheme.textColorHovered
                            eText: {
                                if (MemberRole === Member.Role.ADMIN)
                                    return JamiStrings.administrator;
                                if (MemberRole === Member.Role.INVITED)
                                    return JamiStrings.invited;
                                if (MemberRole === Member.Role.BANNED)
                                    return JamiStrings.banned;
                                return "";
                            }
                            font.kerning: true
                            font.pointSize: JamiTheme.settingsFontSize
                            horizontalAlignment: Text.AlignRight
                            maxWidth: JamiTheme.preferredFieldWidth
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    background: Rectangle {
                        anchors.fill: parent
                        color: {
                            if (member.hovered || nameTextEditHover.hovered)
                                return JamiTheme.smartListHoveredColor;
                            else
                                return "transparent";
                        }
                    }
                }
            }
            DocumentsScrollview {
                id: documents
                anchors.fill: parent
                visible: tabBar.currentItemName === "documents"
            }
        }
    }

    component DetailsTabButton: FilterTabButton {
        Layout.fillWidth: true
        backgroundColor: CurrentConversation.color
        borderWidth: 4
        bottomMargin: JamiTheme.settingsMarginSize
        down: tabBar.currentIndex === TabBar.index
        fontSize: JamiTheme.menuFontSize
        hoverColor: CurrentConversation.color
        textColor: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
        textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
        underlineContentOnly: true
    }
}
