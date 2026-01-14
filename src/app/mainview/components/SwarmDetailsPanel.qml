/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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

Rectangle {
    id: root

    anchors.fill: parent
    anchors.margins: JamiTheme.sidePanelIslandsPadding

    color: JamiTheme.globalIslandColor
    radius: JamiTheme.commonRadius
    property var isAdmin: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri) === Member.Role.ADMIN || CurrentConversation.isCoreDialog

    property string textColor: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark

    ColumnLayout {
        id: rectangleContent

        anchors.fill: parent
        anchors.margins: 24

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: currentSwarmAvatar.height
            Layout.alignment: Qt.AlignTop

            RowLayout {
                id: photoboothRow

                anchors.centerIn: parent
                spacing: 8

                PhotoboothView {
                    id: currentSwarmAvatar

                    Layout.preferredWidth: avatarSize
                    Layout.preferredHeight: avatarSize
                    Layout.alignment: Qt.AlignVCenter

                    readOnly: !root.isAdmin

                    newItem: true
                    imageId: LRCInstance.selectedConvUid
                    avatarSize: 180
                }

                ColumnLayout {
                    Layout.preferredHeight: currentSwarmAvatar.height
                    Layout.preferredWidth: JamiTheme.iconButtonMedium
                    Layout.alignment: Qt.AlignVCenter

                    NewIconButton {
                        id: muteConversation

                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: CurrentConversation.ignoreNotifications ? JamiResources.notifications_off_24dp_svg : JamiResources.notifications_active_24dp_svg
                        toolTipText: CurrentConversation.ignoreNotifications ? JamiStrings.muteConversation : JamiStrings.unmuteConversation

                        onClicked: CurrentConversation.setPreference("ignoreNotifications", !CurrentConversation.ignoreNotifications)
                    }

                    NewIconButton {
                        id: conversationType

                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: switch (CurrentConversation.modeString) {
                        case JamiStrings.publicGroup:
                            JamiResources.public_24dp_svg;
                            break;
                        case JamiStrings.privateConversation:
                            JamiResources.lock_svg;
                            break;
                        case JamiStrings.privateRestrictedGroup:
                            JamiResources.mail_lock_24dp_svg;
                            break;
                        case JamiStrings.privateGroup:
                            JamiResources.create_swarm_svg;
                        }
                        toolTipText: CurrentConversation.modeString
                    }

                    Rectangle {
                        id: conversationColorPicker

                        property bool hovered: false

                        Layout.alignment: Qt.AlignHCenter

                        width: JamiTheme.iconButtonMedium
                        height: JamiTheme.iconButtonMedium
                        radius: width / 2
                        color: CurrentConversation.color

                        MaterialToolTip {
                            id: conversationColorPickerToolTip
                            parent: parent
                            visible: conversationColorPickerMouseArea.containsMouse
                            delay: Qt.styleHints.mousePressAndHoldInterval
                            text: JamiStrings.chooseAColor
                        }

                        MouseArea {
                            id: conversationColorPickerMouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: colorDialogComp.createObject(appWindow).open()
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

                    infoTipLineText: CurrentConversation.isCoreDialog ? JamiStrings.contactName : JamiStrings.groupName
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

                    onAccepted: ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, dynamicText)

                    editMode: false

                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, dynamicText);
                        }
                        descriptionLineButton.editMode = activeFocus;
                    }

                    infoTipLineText: JamiStrings.addDescription
                }
            }
        }

        Item {
            id: centerContent

            Layout.fillWidth: true
            Layout.preferredHeight: 42
            Layout.bottomMargin: CurrentConversation.isCoreDialog ? 0 : 8
            Layout.alignment: Qt.AlignTop

            ColumnLayout {
                anchors.fill: parent

                TabBar {
                    id: swarmDetailsPanelTabBar

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop

                    visible: !CurrentConversation.isCoreDialog

                    padding: 4

                    currentIndex: 0

                    FilterTabButton {
                        id: membersTabButton

                        down: swarmDetailsPanelTabBar.currentIndex === TabBar.index
                        labelText: {
                            var membersNb = CurrentConversation.members.count;
                            if (membersNb > 1)
                                return JamiStrings.members.arg(membersNb);
                            return JamiStrings.member;
                        }
                    }

                    FilterTabButton {
                        id: filesTabButton

                        down: swarmDetailsPanelTabBar.currentIndex === TabBar.index
                        labelText: JamiStrings.files
                    }

                    background: Rectangle {
                        id: swarmDetailsPanelTabBarBackground

                        anchors.fill: parent
                        color: JamiTheme.transparentColor
                    }
                }

                Text {
                    id: filesText

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop

                    visible: CurrentConversation.isCoreDialog

                    text: JamiStrings.files
                    color: JamiTheme.textColor
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                id: scrollView

                anchors.fill: parent

                contentWidth: availableWidth
                clip: true

                visible: !CurrentConversation.isCoreDialog && (!CurrentConversation.isCoreDialog && swarmDetailsPanelTabBar.currentIndex === 0)

                Grid {
                    id: membersGrid
                    width: parent.width
                    columns: CurrentConversation.members.length < 3 ? CurrentConversation.members.length : 4
                    spacing: 4

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

                    Repeater {
                        model: CurrentConversation.members
                        delegate: ColumnLayout {
                            id: memberDelegate

                            width: (scrollView.width - (membersGrid.columns - 1) * membersGrid.spacing) / membersGrid.columns

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: JamiTheme.smartListAvatarSize
                                Layout.preferredHeight: JamiTheme.smartListAvatarSize

                                Avatar {
                                    id: memberDelegateAvatar
                                    anchors.fill: parent
                                    opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1

                                    imageId: CurrentAccount.uri === MemberUri ? CurrentAccount.id : MemberUri
                                    presenceStatus: UtilsAdapter.getContactPresence(CurrentAccount.id, MemberUri)
                                    showPresenceIndicator: presenceStatus > 0
                                    mode: CurrentAccount.uri === MemberUri ? Avatar.Mode.Account : Avatar.Mode.Contact

                                    MouseArea {
                                        id: memberDelegateMouseArea

                                        anchors.fill: parent

                                        acceptedButtons: Qt.RightButton
                                        hoverEnabled: true

                                        onClicked: function (mouse) {
                                            const position = mapToItem(membersGrid, mouse.x, mouse.y);
                                            contextMenu.openMenuAt(position.x, position.y, MemberUri);
                                        }
                                    }

                                    MaterialToolTip {
                                        parent: memberDelegateMouseArea
                                        property string tip: (MemberRole === Member.Role.ADMIN) ? JamiStrings.administrator : (MemberRole === Member.Role.INVITED) ? JamiStrings.invited : (MemberRole === Member.Role.BANNED) ? JamiStrings.blocked : ""
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
                                eText: UtilsAdapter.getContactBestName(CurrentAccount.id, MemberUri)
                                maxWidth: width

                                font.pointSize: JamiTheme.participantFontSize
                                color: JamiTheme.primaryForegroundColor
                                opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1
                                font.kerning: true

                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }

            DocumentsScrollview {
                id: documents

                anchors.fill: parent

                visible: CurrentConversation.isCoreDialog || (!CurrentConversation.isCoreDialog && swarmDetailsPanelTabBar.currentIndex === 1)
            }

            Text {
                anchors.fill: parent

                text: JamiStrings.noFilesInConversation
                color: JamiTheme.textColor

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop

                wrapMode: Text.WordWrap

                visible: documents.visible && documents.model.count === 0
            }
        }

        MaterialButton {
            id: deleteAccount

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom

            primary: true

            iconSource: JamiResources.exit_to_app_24dp_svg
            color: JamiTheme.buttonTintedRed
            hoveredColor: JamiTheme.buttonTintedRedHovered
            pressedColor: JamiTheme.buttonTintedRedPressed

            text: CurrentConversation.modeString.indexOf("group") >= 0 ? JamiStrings.leaveGroup : JamiStrings.removeConversation
            onClicked: {}
        }
    }

    layer.enabled: true
    layer.effect: MultiEffect {
        anchors.fill: root
        shadowEnabled: true
        shadowBlur: JamiTheme.shadowBlur
        shadowColor: JamiTheme.shadowColor
        shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
        shadowVerticalOffset: JamiTheme.shadowVerticalOffset
        shadowOpacity: JamiTheme.shadowOpacity
    }
}
