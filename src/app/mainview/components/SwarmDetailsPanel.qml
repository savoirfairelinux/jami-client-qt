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
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import SortFilterProxyModel

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../settingsview/components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    property var isAdmin: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id,
                                                          CurrentAccount.uri) === Member.Role.ADMIN
                          || CurrentConversation.isCoreDialog
    property string textColor: UtilsAdapter.luma(innerRect.color)
                               ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark

    Rectangle {
        id: innerRect

        anchors.fill: parent
        anchors.margins: viewCoordinator.isInSinglePaneMode ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding
        anchors.topMargin: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding * 2

        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius

        function updateSwarmDetailsTabModel() {
            swarmDetailsTabModel.clear();
            if (!CurrentConversation.isCoreDialog) {
                swarmDetailsTabModel.append({
                                                "name": JamiStrings.members.arg(
                                                            CurrentConversation.members.count)
                                            });
                swarmDetailsTabModel.append({
                                                "name": JamiStrings.files
                                            });
            } else {
                swarmDetailsTabModel.append({
                                                "name": JamiStrings.files
                                            });
            }

            swarmDetailsTabModel.append({
                                            "name": JamiStrings.details
                                        });
        }
        ColumnLayout {
            id: rectangleContent

            anchors.fill: parent
            anchors.margins: 16
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: currentSwarmAvatar.height
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                RowLayout {
                    id: photoboothRow

                    anchors.centerIn: parent
                    spacing: 16

                    PhotoboothView {
                        id: currentSwarmAvatar

                        Layout.preferredWidth: avatarSize
                        Layout.preferredHeight: avatarSize
                        Layout.alignment: Qt.AlignVCenter

                        readOnly: !isAdmin

                        newItem: true
                        imageId: LRCInstance.selectedConvUid
                        avatarSize: 180
                    }

                    Column {
                        Layout.preferredWidth: JamiTheme.iconButtonMedium
                        Layout.fillHeight: true
                        Item {
                            id: infoBlock

                            width: parent.width
                            height: parent.height / 3

                            visible: CurrentConversation.isCoreDialog

                            NewIconButton {
                                id: contactDetails

                                anchors.centerIn: parent

                                iconSize: JamiTheme.iconButtonMedium
                                iconSource: JamiResources.informations_black_24dp_svg
                                toolTipText: JamiStrings.contactDetails

                                onClicked: viewCoordinator.presentDialog(appWindow,
                                                                         "mainview/components/UserProfile.qml",
                                                                         {
                                                                             "aliasText":
                                                                             CurrentConversation.title,
                                                                             "registeredNameText":
                                                                             CurrentConversation.description,
                                                                             "idText": CurrentConversation.id,
                                                                             "convId": CurrentConversation.id
                                                                         })
                            }
                        }
                        Item {
                            id: notificationsBlock

                            width: parent.width
                            height: CurrentConversation.isCoreDialog ? parent.height / 3 :
                                                                       parent.height / 2

                            NewIconButton {
                                id: notificationSettingButton

                                anchors.centerIn: parent

                                iconSize: JamiTheme.iconButtonMedium
                                iconSource: CurrentConversation.ignoreNotifications
                                            ? JamiResources.notifications_off_24dp_svg :
                                              JamiResources.notifications_active_24dp_svg
                                toolTipText: CurrentConversation.ignoreNotifications
                                             ? JamiStrings.notificationsOff :
                                               JamiStrings.notificationsOn

                                onClicked: CurrentConversation.setPreference("ignoreNotifications",
                                                                             !CurrentConversation.ignoreNotifications)
                            }
                        }
                        Item {
                            id: colorBlock

                            width: parent.width
                            height: CurrentConversation.isCoreDialog ? parent.height / 3 :
                                                                       parent.height / 2

                            Rectangle {
                                id: conversationColorPicker

                                property bool hovered:
                                    conversationColorPickerMouseArea.containsMouse

                                anchors.centerIn: parent

                                activeFocusOnTab: true

                                width: JamiTheme.iconButtonMedium
                                height: JamiTheme.iconButtonMedium

                                radius: width / 2

                                color: CurrentConversation.color

                                border.color: JamiTheme.tintedBlue
                                border.width: hovered || activeFocus ? 2 : 0

                                MaterialToolTip {
                                    id: conversationColorPickerToolTip
                                    parent: parent
                                    visible: conversationColorPickerMouseArea.containsMouse
                                    delay: Qt.styleHints.mousePressAndHoldInterval
                                    text: JamiStrings.color
                                }

                                MouseArea {
                                    id: conversationColorPickerMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: colorDialogComp.createObject(appWindow).open()
                                }

                                Component {
                                    id: colorDialogComp
                                    ColorDialog {
                                        id: colorDialog
                                        title: JamiStrings.color
                                        currentColor: CurrentConversation.color
                                        onAccepted: {
                                            CurrentConversation.setPreference("color",
                                                                              colorDialog.color);
                                            this.destroy();
                                        }
                                        onRejected: this.destroy()
                                    }
                                }

                                Accessible.role: Accessible.Button
                                Accessible.name: JamiStrings.color
                                Accessible.description: JamiStrings.chooseAColor
                            }
                        }
                    }
                }
            }

            Item {
                id: textEditContents

                Layout.fillWidth: true
                Layout.preferredHeight: 80
                Layout.alignment: Qt.AlignTop

                ColumnLayout {

                    anchors.fill: parent
                    spacing: 0

                    ModalTextEdit {
                        id: titleLine

                        Layout.fillWidth: true
                        Layout.fillHeight: true

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

                        staticText: CurrentConversation.title
                        elidedText: titleLineTextSize.elidedText

                        textColor: root.textColor
                        prefixIconColor: root.textColor

                        onAccepted: {
                            ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid,
                                                                         dynamicText);
                        }

                        editMode: false

                        placeholderText: JamiStrings.title

                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                ConversationsAdapter.updateConversationTitle(
                                            LRCInstance.selectedConvUid, dynamicText);
                            }
                            titleLine.editMode = activeFocus;
                        }

                        infoTipLineText: CurrentConversation.isCoreDialog ? JamiStrings.contactName :
                                                                            JamiStrings.groupName
                    }

                    ModalTextEdit {
                        id: descriptionLineButton

                        Layout.fillWidth: true
                        Layout.fillHeight: true

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

                        staticText: CurrentConversation.description
                        placeholderText: JamiStrings.addDescription
                        elidedText: descriptionLineButtonTextSize.elidedText

                        textColor: root.textColor
                        prefixIconColor: root.textColor

                        onAccepted: ConversationsAdapter.updateConversationDescription(
                                        LRCInstance.selectedConvUid, dynamicText)

                        editMode: false

                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                ConversationsAdapter.updateConversationDescription(
                                            LRCInstance.selectedConvUid, dynamicText);
                            }
                            descriptionLineButton.editMode = activeFocus;
                        }

                        infoTipLineText: JamiStrings.addDescription
                    }
                }
            }

            ListModel {
                id: swarmDetailsTabModel
            }

           Connections {
                target: CurrentConversation

                onIdChanged: innerRect.updateSwarmDetailsTabModel()
            }

            TabBar {
                id: swarmDetailsPanelTabBar

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.tabBarHeight
                Layout.bottomMargin: 0
                Layout.alignment: Qt.AlignTop

                spacing: JamiTheme.tabBarSpacing

                currentIndex: 0

                Repeater {
                    model: swarmDetailsTabModel

                    FilterTabButton {
                        down: swarmDetailsPanelTabBar.currentIndex === index
                        labelText: name

                        onSelected: swarmDetailsPanelTabBar.currentIndex = index
                    }
                }

                background: Rectangle {
                    id: swarmDetailsPanelTabBarBackground

                    anchors.fill: parent
                    color: JamiTheme.transparentColor
                }
            }

            ColumnLayout {
                id: membersView

                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: !CurrentConversation.isCoreDialog && swarmDetailsPanelTabBar.currentIndex
                         === 0

                NewMaterialButton {
                    id: inviteMemberButton

                    Layout.fillWidth: true
                    Layout.bottomMargin: 8

                    filledButton: true
                    iconSource: JamiResources.add_people_24dp_svg
                    text: JamiStrings.inviteMember

                    visible: !CurrentConversation.isCoreDialog

                    onClicked: extrasPanel.switchToPanel(ChatView.AddMemberPanel)
                }

                JamiFlickable {
                    id: scrollView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    contentWidth: width
                    contentHeight: membersGrid.implicitHeight
                    clip: true

                    Grid {
                        id: membersGrid
                        width: parent.width
                        columns: CurrentConversation.members.length < 3
                                 ? CurrentConversation.members.length : 4
                        spacing: 12

                        SwarmParticipantContextMenu {
                            id: contextMenu
                            role: UtilsAdapter.getParticipantRole(CurrentAccount.id,
                                                                  CurrentConversation.id,
                                                                  CurrentAccount.uri)

                            function openMenuAt(x, y, participantUri) {
                                contextMenu.x = x;
                                contextMenu.y = y;
                                contextMenu.conversationId = CurrentConversation.id;
                                contextMenu.participantUri = participantUri;
                                openMenu();
                            }
                        }

                        Repeater {
                            model: CurrentConversation.members
                            delegate: ColumnLayout {
                                id: memberDelegate

                                width: (scrollView.width - (membersGrid.columns - 1)
                                        * membersGrid.spacing) / membersGrid.columns

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: JamiTheme.smartListAvatarSize
                                    Layout.preferredHeight: JamiTheme.smartListAvatarSize

                                    Avatar {
                                        id: memberDelegateAvatar
                                        anchors.fill: parent
                                        opacity: (MemberRole === Member.Role.INVITED || MemberRole
                                                  === Member.Role.BANNED) ? 0.5 : 1

                                        imageId: CurrentAccount.uri === MemberUri
                                                 ? CurrentAccount.id : MemberUri
                                        presenceStatus: UtilsAdapter.getContactPresence(
                                                            CurrentAccount.id, MemberUri)
                                        showPresenceIndicator: presenceStatus > 0
                                        mode: CurrentAccount.uri === MemberUri
                                              ? Avatar.Mode.Account : Avatar.Mode.Contact

                                        MouseArea {
                                            id: memberDelegateMouseArea

                                            anchors.fill: parent

                                            acceptedButtons: Qt.RightButton | Qt.LeftButton
                                            hoverEnabled: true

                                            onClicked: function (mouse) {
                                                if (mouse.button === Qt.LeftButton) {
                                                    if (ConversationsAdapter.dialogId(MemberUri)
                                                            !== "")
                                                        ConversationsAdapter.openDialogConversationWith(
                                                                    MemberUri);
                                                    else
                                                        ConversationsAdapter.setFilter(MemberUri);
                                                } else if (mouse.button === Qt.RightButton) {
                                                    const position = mapToItem(membersGrid, mouse.x,
                                                                               mouse.y);
                                                    contextMenu.openMenuAt(position.x, position.y,
                                                                           MemberUri);
                                                }
                                            }
                                        }

                                        MaterialToolTip {
                                            parent: memberDelegateMouseArea
                                            property string tip: (MemberRole === Member.Role.ADMIN)
                                                                 ? JamiStrings.administrator : (
                                                                       MemberRole
                                                                       === Member.Role.INVITED)
                                                                   ? JamiStrings.invited : (
                                                                         MemberRole
                                                                         === Member.Role.BANNED)
                                                                     ? JamiStrings.blocked : ""
                                            text: tip
                                            visible: parent.containsMouse && tip.length > 0
                                            delay: Qt.styleHints.mousePressAndHoldInterval
                                        }
                                    }

                                    ResponsiveImage {
                                        id: memberDelegateIcon

                                        anchors.top: parent.top
                                        anchors.right: parent.right

                                        visible: MemberRole !== undefined

                                        containerHeight: JamiTheme.iconButtonSmall
                                        containerWidth: JamiTheme.iconButtonSmall

                                        source: {
                                            switch (MemberRole) {
                                            case Member.Role.ADMIN:
                                                return JamiResources.moderator_filled_svg;
                                            case Member.Role.BANNED:
                                                return JamiResources.ic_disconnect_participant_24dp_svg;
                                            case Member.Role.INVITED:
                                                return JamiResources.mail_24dp_svg;
                                            default:
                                                return "";
                                            }
                                        }
                                        color: {
                                            switch (MemberRole) {
                                            case Member.Role.ADMIN:
                                                return "#bf9b30";
                                            case Member.Role.BANNED:
                                                return JamiTheme.redColor;
                                            case Member.Role.INVITED:
                                                return JamiTheme.tintedBlue;
                                            default:
                                                return JamiTheme.transparentColor;
                                            }
                                        }
                                    }
                                }

                                ElidedTextLabel {
                                    id: nameTextEdit

                                    Layout.fillWidth: true
                                    eText: UtilsAdapter.getContactBestName(CurrentAccount.id,
                                                                           MemberUri)
                                    maxWidth: width

                                    font.pointSize: JamiTheme.participantFontSize
                                    color: JamiTheme.primaryForegroundColor
                                    opacity: (MemberRole === Member.Role.INVITED || MemberRole
                                              === Member.Role.BANNED) ? 0.5 : 1
                                    font.kerning: true

                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: filesView

                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: CurrentConversation.isCoreDialog ? swarmDetailsPanelTabBar.currentIndex
                                                            === 0 : swarmDetailsPanelTabBar.currentIndex
                                                            === 1

                DocumentsScrollview {
                    id: documents

                    anchors.fill: parent
                }

                Text {
                    anchors.fill: parent

                    text: JamiStrings.noFilesInConversation
                    color: JamiTheme.textColor

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop

                    wrapMode: Text.WordWrap

                    visible: documents.count === 0
                }
            }

            Item {
                id: detailsView

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: JamiTheme.preferredMarginSize

                visible: CurrentConversation.isCoreDialog ? swarmDetailsPanelTabBar.currentIndex
                                                            === 1 : swarmDetailsPanelTabBar.currentIndex
                                                            === 2

                ScrollView {
                    id: detailsScrollView

                    anchors.fill: parent
                    contentWidth: availableWidth

                    ColumnLayout {
                        width: detailsScrollView.availableWidth

                        spacing: 16

                        RowLayout {
                            id: detailsScrollViewConversationType

                            Layout.fillWidth: true

                            Text {
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                                text: JamiStrings.conversationType
                                color: JamiTheme.textColor
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                                font.pointSize: JamiTheme.smallFontSize
                            }

                            Text {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                Layout.fillWidth: true

                                text: CurrentConversation.modeString
                                color: JamiTheme.textColor
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                                font.pointSize: JamiTheme.smallFontSize
                            }
                        }

                        RowLayout {
                            id: detailsScrollViewDefaultCallHost

                            visible: !CurrentConversation.isCoreDialog

                            Layout.fillWidth: true

                            Text {
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                                text: JamiStrings.defaultCallHost
                                color: JamiTheme.textColor
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                                font.pointSize: JamiTheme.smallFontSize

                                visible: !CurrentConversation.isCoreDialog
                            }

                            Text {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                Layout.fillWidth: true

                                text: JamiStrings.none
                                color: JamiTheme.textColor
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                                font.pointSize: JamiTheme.smallFontSize

                                visible: !CurrentConversation.isCoreDialog
                                         && CurrentConversation.rdvAccount === ""
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft

                            visible: !CurrentConversation.isCoreDialog
                                     && CurrentConversation.rdvAccount !== ""

                            spacing: 16

                            Connections {
                                target: CurrentConversation

                                function onRdvAccountChanged() {
                                    // This avoid incorrect avatar by always modifying the mode before the imageId
                                    avatar.mode = CurrentConversation.rdvAccount
                                            === CurrentAccount.uri ? Avatar.Mode.Account :
                                                                     Avatar.Mode.Contact;
                                    avatar.imageId = CurrentConversation.rdvAccount
                                            === CurrentAccount.uri ? CurrentAccount.id :
                                                                     CurrentConversation.rdvAccount;
                                }
                            }

                            Avatar {
                                id: avatar

                                Layout.preferredWidth: width
                                Layout.preferredHeight: height

                                width: JamiTheme.smartListAvatarSize
                                height: JamiTheme.smartListAvatarSize

                                imageId: CurrentConversation.rdvAccount === CurrentAccount.uri
                                         ? CurrentAccount.id : CurrentConversation.rdvAccount
                                mode: Avatar.Mode.Account
                                showPresenceIndicator: false

                                visible: CurrentConversation.rdvAccount !== ""
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: avatar.height - 10
                                Layout.alignment: Qt.AlignVCenter

                                visible: CurrentConversation.rdvDevice !== ""

                                Text {
                                    id: bestName

                                    Layout.fillWidth: true

                                    text: {
                                        if (CurrentConversation.rdvAccount === "")
                                            return JamiStrings.none;
                                        else if (CurrentConversation.rdvAccount
                                                 === CurrentAccount.uri)
                                            return CurrentAccount.bestName;
                                        else
                                            return UtilsAdapter.getBestNameForUri(CurrentAccount.id,
                                                                                  CurrentConversation.rdvAccount);
                                    }

                                    color: JamiTheme.primaryForegroundColor
                                    elide: Text.ElideRight

                                    textFormat: TextEdit.PlainText
                                    font.pointSize: JamiTheme.smallFontSize
                                    font.weight: text === JamiStrings.none ? Font.Medium :
                                                                             Font.Normal
                                    font.kerning: true

                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                }

                                ElidedTextLabel {
                                    id: deviceID

                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                                    LineEditContextMenu {
                                        id: deviceIDContextMenu
                                        lineEditObj: deviceID
                                        selectOnly: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton
                                        cursorShape: Qt.IBeamCursor
                                        onClicked: function (mouse) {
                                            deviceIDContextMenu.openMenuAt(mouse);
                                        }
                                    }

                                    textFormat: TextEdit.PlainText
                                    font.pointSize: JamiTheme.smallFontSize
                                    font.kerning: true

                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter

                                    eText: CurrentConversation.rdvDevice === "" ? JamiStrings.none :
                                                                                  CurrentConversation.rdvDevice
                                    maxWidth: parent.width
                                }
                            }
                        }

                        NewMaterialButton {
                            Layout.fillWidth: true

                            outlinedButton: true
                            text: CurrentConversation.rdvAccount === ""
                                  ? JamiStrings.selectDefaultHost : JamiStrings.changeDefaultHost
                            color: JamiTheme.buttonTintedBlue

                            visible: !CurrentConversation.isCoreDialog && root.isAdmin

                            onClicked: {
                                viewCoordinator.presentDialog(appWindow,
                                                              "mainview/components/DevicesListPopup.qml");
                            }
                        }

                        NewMaterialButton {
                            id: removeConversation

                            Layout.fillWidth: true

                            outlinedButton: true
                            color: JamiTheme.buttonTintedRed
                            iconSource: JamiResources.ic_disconnect_participant_24dp_svg
                            text: CurrentConversation.isCoreDialog ? JamiStrings.removeConversation :
                                                                     JamiStrings.leaveGroup

                            onClicked: {
                                var dlg = viewCoordinator.presentDialog(appWindow,
                                                                        "commoncomponents/ConfirmDialog.qml",
                                                                        {
                                                                            "title": JamiStrings.confirmAction,
                                                                            "textLabel":
                                                                            JamiStrings.confirmRemoveContact,
                                                                            "confirmLabel":
                                                                            JamiStrings.optionRemove
                                                                        });
                                dlg.accepted.connect(function () {
                                    MessagesAdapter.removeConversation(LRCInstance.selectedConvUid,
                                                                       true);
                                });
                            }
                        }

                        NewMaterialButton {
                            id: removeContactButton

                            Layout.fillWidth: true

                            outlinedButton: true
                            color: JamiTheme.buttonTintedRed
                            iconSource: JamiResources.kick_member_svg
                            text: JamiStrings.removeContact

                            visible: CurrentConversation.isCoreDialog
                            onClicked: {
                                var dlg = viewCoordinator.presentDialog(appWindow,
                                                                        "commoncomponents/ConfirmDialog.qml",
                                                                        {
                                                                            "title": JamiStrings.confirmAction,
                                                                            "textLabel":
                                                                            JamiStrings.confirmRemoveContact,
                                                                            "confirmLabel":
                                                                            JamiStrings.optionRemove
                                                                        });
                                dlg.accepted.connect(function () {
                                    MessagesAdapter.removeConversation(LRCInstance.selectedConvUid);
                                });
                            }
                        }

                        NewMaterialButton {
                            id: blockContactButton

                            Layout.fillWidth: true

                            outlinedButton: true
                            color: JamiTheme.buttonTintedRed
                            iconSource: JamiResources.block_black_24dp_svg
                            text: JamiStrings.blockContact

                            visible: CurrentConversation.isCoreDialog

                            onClicked: {
                                var dlg = viewCoordinator.presentDialog(appWindow,
                                                                        "commoncomponents/ConfirmDialog.qml",
                                                                        {
                                                                            "title": JamiStrings.confirmAction,
                                                                            "textLabel":
                                                                            JamiStrings.confirmBlockContact,
                                                                            "confirmLabel":
                                                                            JamiStrings.optionBlock
                                                                        });
                                dlg.accepted.connect(function () {
                                    MessagesAdapter.blockConversation(CurrentConversation.id);
                                });
                            }
                        }
                    }
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            anchors.fill: innerRect
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }
    }
    Component.onCompleted: innerRect.updateSwarmDetailsTabModel()

    component HairlineDivider: Rectangle {
        Layout.fillWidth: true
        height: 1
        color: JamiTheme.chatViewFooterRectangleBorderColor
    }
}
