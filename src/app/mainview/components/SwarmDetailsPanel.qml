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

    //property alias tabBarIndex: tabBar.currentIndex
    // property int tabBarItemsLength: tabBar.contentChildren.length

    anchors.fill: parent
    anchors.margins: JamiTheme.sidePanelIslandsPadding

    color: JamiTheme.backgroundColor
    radius: JamiTheme.commonRadius
    property var isAdmin: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri) === Member.Role.ADMIN || CurrentConversation.isCoreDialog

    property string textColor: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark

    // Component {
    //     id: memberDelegate

    // }

    ColumnLayout {
        id: rectangleContent

        anchors.fill: parent
        anchors.margins: 24

        ColumnLayout {
            id: swarmDetailsPrimaryColumn

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredHeight: photoboothRow.height
            spacing: 0

            RowLayout {
                id: photoboothRow

                Layout.fillWidth: true
                Layout.preferredHeight: currentSwarmAvatar.avatarSize
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                PhotoboothView {
                    id: currentSwarmAvatar

                    readOnly: !root.isAdmin
                    width: avatarSize
                    height: avatarSize

                    newItem: true
                    imageId: LRCInstance.selectedConvUid
                    avatarSize: 180
                }

                ColumnLayout {
                    Layout.preferredHeight: currentSwarmAvatar.height
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 8
                    Layout.topMargin: 8

                    JamiPushButton {
                        id: muteConversation

                        width: 24
                        height: 24

                        toolTipText: CurrentConversation.ignoreNotifications ? JamiStrings.muteConversation : JamiStrings.unmuteConversation

                        source: CurrentConversation.ignoreNotifications ? JamiResources.notifications_off_24dp_svg : JamiResources.notifications_active_24dp_svg
                        imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
                        normalColor: JamiTheme.backgroundColor

                        onClicked: {
                            CurrentConversation.setPreference("ignoreNotifications", !CurrentConversation.ignoreNotifications);
                        }
                    }

                    ResponsiveImage {
                        id: conversationType

                        width: JamiTheme.swarmDetailsIconSize
                        height: JamiTheme.swarmDetailsIconSize

                        source: {
                            switch (CurrentConversation.modeString) {
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
                        }

                        MaterialToolTip {
                            parent: parent
                            visible: conversationType.hovered
                            delay: Qt.styleHints.mousePressAndHoldInterval
                            text: CurrentConversation.modeString
                        }

                        color: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
                    }

                    Rectangle {
                        id: conversationColorPicker

                        property bool hovered: false

                        width: JamiTheme.swarmDetailsIconSize
                        height: JamiTheme.swarmDetailsIconSize
                        radius: width / 2
                        color: CurrentConversation.color

                        MaterialToolTip {
                            id: conversationColorPickerToolTip
                            parent: parent
                            visible: conversationColorPickerMouseArea.hovered
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

        ColumnLayout {
            id: middleContent
            Layout.fillWidth: true
            Layout.minimumHeight: JamiTheme.swarmDetailsMemberCellHeight
            Layout.maximumHeight: JamiTheme.swarmDetailsMemberCellHeight * 3

            ModalTextEdit {
                id: titleLine

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: currentSwarmAvatar.avatarSize

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

            Text {
                id: membersText
                text: JamiStrings.groupMembers
                Layout.fillWidth: true
            }

            GridLayout {
                id: swarmDetailsMembersGrid

                Layout.fillWidth: true
                columns: CurrentConversation.members.length < 3 ? CurrentConversation.members.length : 4
                uniformCellWidths: true
                uniformCellHeights: true
                Repeater {
                    model: CurrentConversation.members
                    delegate: ColumnLayout {
                        // Note: Layout.* refers to Items in the context of the swarmDetailsMemberGrid GridLayout
                        Layout.fillWidth: true
                        Layout.preferredHeight: JamiTheme.swarmDetailsMemberCellHeight

                        Avatar {
                            id: memberDelegateAvatar
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: JamiTheme.smartListAvatarSize
                            Layout.preferredHeight: JamiTheme.smartListAvatarSize
                            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1

                            imageId: CurrentAccount.uri === MemberUri ? CurrentAccount.id : MemberUri
                            presenceStatus: UtilsAdapter.getContactPresence(CurrentAccount.id, MemberUri)
                            showPresenceIndicator: presenceStatus > 0
                            mode: CurrentAccount.uri === MemberUri ? Avatar.Mode.Account : Avatar.Mode.Contact
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

                            HoverHandler {
                                id: nameTextEditHover
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                Layout.alignment: Qt.AlignTop
                text: JamiStrings.files
            }

            DocumentsScrollview {
                id: documents
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // Item { Scaffold {}
        //     Layout.fillWidth: true
        //     Layout.fillHeight: true

        //     Text {
        //         text: "HEY"
        //     }

        //     ColumnLayout {
        //         width: parent.width
        //         height: parent.height
        //         Text {
        //             id: filesText
        //             text: JamiStrings.files
        //             Layout.fillWidth: true
        //             horizontalAlignment: Text.AlignLeft
        //         }

        //         DocumentsScrollview {
        //             id: documents

        //             visible: visible
        //             Layout.fillWidth: true
        //         }
        //     }
        // }

        MaterialButton {
            id: deleteAccount
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom

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
