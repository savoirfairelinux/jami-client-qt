/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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

    property alias tabBarIndex: tabBar.currentIndex
    property int tabBarItemsLength: tabBar.contentChildren.length

    color: CurrentConversation.color

    property var isAdmin: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri) === Member.Role.ADMIN || CurrentConversation.isCoreDialog

    property string textColor: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark

    Item {
        id: swarmProfileDetails
        anchors.fill: parent

        Item {
            id: header

            anchors.top: parent.top
            anchors.topMargin: JamiTheme.swarmDetailsPageTopMargin
            anchors.left: parent.left
            anchors.right: parent.right
            height: headerRow.implicitHeight + JamiTheme.preferredMarginSize + settingsTabButton.height

            RowLayout {
                id: headerRow
                spacing: 15
                anchors.top: parent.top
                anchors.leftMargin: 15
                anchors.left: parent.left
                anchors.right: parent.right

                PhotoboothView {
                    id: currentAccountAvatar

                    readOnly: !root.isAdmin
                    width: avatarSize
                    height: avatarSize

                    newItem: true
                    imageId: LRCInstance.selectedConvUid
                    avatarSize: JamiTheme.smartListAvatarSize
                }

                ColumnLayout {
                    signal accepted
                    Layout.fillWidth: true

                    ModalTextEdit {
                        id: titleLine

                        TextMetrics {
                            id: titleLineTextSize
                            text: CurrentConversation.title
                            elide: Text.ElideRight
                            elideWidth: titleLine.width
                        }

                        maxCharacters: JamiTheme.maximumCharacters
                        fontPixelSize: JamiTheme.materialLineEditPixelSize

                        isSwarmDetail: true
                        readOnly: !isAdmin
                        Layout.fillWidth: true
                        Layout.rightMargin: 2 * JamiTheme.settingsMarginSize

                        staticText: CurrentConversation.title
                        elidedText: titleLineTextSize.elidedText

                        textColor: root.textColor
                        prefixIconColor: root.textColor

                        onAccepted: {
                            ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid, dynamicText);
                        }

                        editMode: false

                        placeholderText: JamiStrings.title

                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid, dynamicText);
                            }
                            titleLine.editMode = activeFocus;
                        }

                        infoTipLineText: CurrentConversation.isCoreDialog ? JamiStrings.contactName : JamiStrings.swarmName
                    }

                    ModalTextEdit {
                        id: descriptionLineButton

                        TextMetrics {
                            id: descriptionLineButtonTextSize
                            text: CurrentConversation.description
                            elide: Text.ElideRight
                            elideWidth: descriptionLineButton.width
                        }

                        maxCharacters: JamiTheme.maximumCharacters
                        fontPixelSize: JamiTheme.materialLineEditSelectedPixelSize

                        isSwarmDetail: true

                        readOnly: !isAdmin || CurrentConversation.isCoreDialog

                        Layout.fillWidth: true
                        Layout.rightMargin: 2 * JamiTheme.settingsMarginSize

                        staticText: CurrentConversation.description
                        placeholderText: JamiStrings.addADescription
                        elidedText: descriptionLineButtonTextSize.elidedText

                        textColor: root.textColor
                        prefixIconColor: root.textColor

                        onAccepted: ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, dynamicText)

                        editMode: false

                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, dynamicText);
                            }
                            descriptionLineButton.editMode = activeFocus;
                        }

                        infoTipLineText: JamiStrings.addADescription
                    }
                }
            }

            TabBar {
                id: tabBar

                currentIndex: 0

                anchors.top: headerRow.bottom
                anchors.topMargin: JamiTheme.preferredMarginSize
                anchors.left: parent.left
                anchors.right: parent.right
                height: settingsTabButton.height

                property string currentItemName: itemAt(currentIndex).objectName

                function addRemoveButtons() {
                    if (CurrentConversation.isCoreDialog) {
                        if (tabBar.contentChildren.length === 3) {
                            tabBar.setCurrentIndex(1);
                            tabBar.removeItem(tabBar.itemAt(0));
                        }
                    } else {
                        if (tabBar.contentChildren.length === 2) {
                            const obj = membersTabButtonComp.createObject(tabBar);
                            tabBar.insertItem(0, obj);
                        }
                        tabBar.setCurrentIndex(0);
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
                        objectName: "members"
                        visible: !CurrentConversation.isCoreDialog
                        labelText: {
                            var membersNb = CurrentConversation.members.count;
                            if (membersNb > 1)
                                return JamiStrings.members.arg(membersNb);
                            return JamiStrings.member;
                        }
                    }
                }

                DetailsTabButton {
                    id: filesTabButton
                    objectName: "files"
                    labelText: JamiStrings.files
                }

                DetailsTabButton {
                    id: settingsTabButton
                    objectName: "settings"
                    labelText: JamiStrings.settings
                }
            }
        }

        Component {
            id: colorDialogComp
            ColorDialog {
                id: colorDialog
                title: JamiStrings.chooseAColor
                currentColor: CurrentConversation.color
                onAccepted: {
                    CurrentConversation.setPreference("color", colorDialog.color);
                    this.destroy();
                }
                onRejected: this.destroy()
            }
        }

        Rectangle {
            id: details
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

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
                    visible: tabBar.currentItemName === "settings"
                    Layout.alignment: Qt.AlignTop
                    spacing: 0

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
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: JamiTheme.preferredMarginSize
                            text: JamiStrings.leaveConversation
                            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
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

                                text: JamiStrings.chooseAColor
                                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
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
                                Layout.preferredHeight: 30
                                Layout.rightMargin: JamiTheme.preferredMarginSize
                                Layout.maximumWidth: settingsSwarmItem.width / 2

                                text: JamiStrings.defaultCallHost
                                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
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
                                Layout.fillWidth: true

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
                                    Layout.fillWidth: true

                                    ElidedTextLabel {
                                        id: bestName

                                        eText: {
                                            if (CurrentConversation.rdvAccount === "")
                                                return JamiStrings.none;
                                            else if (CurrentConversation.rdvAccount === CurrentAccount.uri)
                                                return CurrentAccount.bestName;
                                            else
                                                return UtilsAdapter.getBestNameForUri(CurrentAccount.id, CurrentConversation.rdvAccount);
                                        }
                                        maxWidth: settingsSwarmItem.width / 2 - JamiTheme.contactMessageAvatarSize

                                        font.pointSize: eText === JamiStrings.none ? JamiTheme.settingsFontSize : JamiTheme.smallFontSize
                                        font.weight: eText === JamiStrings.none ? Font.Medium : Font.Normal
                                        color: JamiTheme.primaryForegroundColor
                                        font.kerning: true

                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    ElidedTextLabel {
                                        id: deviceId

                                        eText: CurrentConversation.rdvDevice === "" ? JamiStrings.none : CurrentConversation.rdvDevice
                                        visible: CurrentConversation.rdvDevice !== ""
                                        maxWidth: settingsSwarmItem.width / 2 - JamiTheme.contactMessageAvatarSize

                                        font.pointSize: JamiTheme.settingsFontSize
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

                            text: JamiStrings.typeOfSwarm
                            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                            font.kerning: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor


                        }

                        Text {
                            id: typeOfSwarmLabel

                            Layout.alignment: Qt.AlignRight
                            Layout.rightMargin: JamiTheme.preferredMarginSize

                            color: JamiTheme.textColor
                            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                            font.weight: Font.Medium
                            text: CurrentConversation.modeString
                        }
                    }

                    RowLayout {
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                        visible: LRCInstance.debugMode()

                        Text {
                            id: identifierText
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            Layout.rightMargin: JamiTheme.preferredMarginSize

                            text: JamiStrings.identifier
                            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                            font.kerning: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor
                        }

                        TextEdit {
                            Layout.alignment: Qt.AlignRight
                            Layout.rightMargin: JamiTheme.preferredMarginSize

                            color: JamiTheme.textColor
                            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                            font.weight: Font.Medium

                            selectByMouse: true
                            readOnly: true
                            text: textMetricsIdentifier.elidedText

                            TextMetrics {
                                id: textMetricsIdentifier
                                text: CurrentConversation.id
                                elideWidth: aboutSwarm.width - identifierText.width - 2 * JamiTheme.preferredMarginSize
                                elide: Qt.ElideRight
                            }
                        }
                    }
                }
            }

            JamiListView {
                id: members
                anchors.fill: parent

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

                model: CurrentConversation.members
                delegate: ItemDelegate {
                    id: member

                    width: members.width
                    height: JamiTheme.smartListItemHeight

                    background: Rectangle {
                        anchors.fill: parent
                        color: {
                            if (member.hovered || nameTextEditHover.hovered)
                                return JamiTheme.smartListHoveredColor;
                            else
                                return "transparent";
                        }
                    }

                    MouseArea {
                        id: memberMouseArea

                        anchors.fill: parent
                        enabled: MemberUri !== CurrentAccount.uri
                        acceptedButtons: Qt.RightButton
                        onClicked: function (mouse) {
                            var position = mapToItem(members, mouse.x, mouse.y);
                            contextMenu.openMenuAt(position.x, position.y, MemberUri);
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
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1

                            imageId: CurrentAccount.uri === MemberUri ? CurrentAccount.id : MemberUri
                            showPresenceIndicator: UtilsAdapter.getContactPresence(CurrentAccount.id, MemberUri)
                            mode: CurrentAccount.uri === MemberUri ? Avatar.Mode.Account : Avatar.Mode.Contact
                        }

                        ElidedTextLabel {
                            id: nameTextEdit

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
                            Layout.fillWidth: true

                            eText: UtilsAdapter.getContactBestName(CurrentAccount.id, MemberUri)
                            maxWidth: width

                            font.pointSize: JamiTheme.settingsFontSize
                            color: JamiTheme.primaryForegroundColor
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1
                            font.kerning: true

                            verticalAlignment: Text.AlignVCenter

                            HoverHandler {
                                id: nameTextEditHover
                            }
                        }

                        ElidedTextLabel {
                            id: roleLabel

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2

                            eText: {
                                if (MemberRole === Member.Role.ADMIN)
                                    return JamiStrings.administrator;
                                if (MemberRole === Member.Role.INVITED)
                                    return JamiStrings.invited;
                                if (MemberRole === Member.Role.BANNED)
                                    return JamiStrings.banned;
                                return "";
                            }
                            maxWidth: JamiTheme.preferredFieldWidth

                            font.pointSize: JamiTheme.settingsFontSize
                            color: JamiTheme.textColorHovered
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1
                            font.kerning: true

                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            DocumentsScrollview {
                id: documents

                visible: tabBar.currentItemName === "files"
                anchors.fill: parent
            }
        }
    }

    component DetailsTabButton: FilterTabButton {
        backgroundColor: CurrentConversation.color
        hoverColor: CurrentConversation.color
        borderWidth: 4
        bottomMargin: JamiTheme.settingsMarginSize
        fontSize: JamiTheme.menuFontSize
        underlineContentOnly: true
        textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
        textColor: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
        Layout.fillWidth: true
        down: tabBar.currentIndex === TabBar.index
    }
}
