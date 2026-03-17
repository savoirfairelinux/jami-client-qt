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
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import QtQuick.Layouts
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


        Column {
            id: rectangleContent

            anchors.fill: parent
            anchors.margins: 16
            anchors.bottomMargin: 0
            spacing: 12

            Row {
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 8

                PhotoboothView {
                    id: currentSwarmAvatar

                    anchors.verticalCenter: parent.verticalCenter

                    width: avatarSize
                    height: avatarSize

                    readOnly: !isAdmin

                    newItem: true
                    imageId: LRCInstance.selectedConvUid
                    avatarSize: 180
                }

                ColumnLayout {
                    anchors.verticalCenter: parent.verticalCenter

                    width: contactDetails.implicitBackgroundWidth

                    spacing: CurrentConversation.isCoreDialog ? 12 : 18

                    NewIconButton {
                        id: contactDetails

                        Layout.alignment: Qt.AlignHCenter

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

                        visible: CurrentConversation.isCoreDialog
                    }

                    NewIconButton {
                        id: muteConversation

                        Layout.alignment: Qt.AlignHCenter

                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: CurrentConversation.ignoreNotifications
                                    ? JamiResources.notifications_off_24dp_svg :
                                      JamiResources.notifications_active_24dp_svg
                        toolTipText: CurrentConversation.ignoreNotifications
                                     ? JamiStrings.muteConversation :
                                       JamiStrings.unmuteConversation

                        onClicked: CurrentConversation.setPreference("ignoreNotifications",
                                                                     !CurrentConversation.ignoreNotifications)
                    }

                    NewIconButton {
                        id: conversationColorPicker

                        Layout.alignment: Qt.AlignHCenter

                        iconSize: JamiTheme.iconButtonMedium
                        toolTipText: JamiStrings.chooseAColor

                        contentItem: Item {
                            anchors.fill: parent
                            Rectangle {
                                anchors.centerIn: parent
                                width: JamiTheme.iconButtonMedium
                                height: JamiTheme.iconButtonMedium
                                radius: width / 2
                                color: CurrentConversation.color
                            }
                        }

                        onClicked: colorDialogComp.createObject(appWindow).open()

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
                    }
                }
            }

            NewMaterialTextField {
                id: titleLine

                // Note that the height of this component is specified internally
                width: parent.width

                leadingIconSource: CurrentConversation.isCoreDialog ? JamiResources.person_24dp_svg : JamiResources.create_swarm_24dp_svg

                placeholderText: JamiStrings.title
                textFieldContent: CurrentConversation.title
                maxCharacters: JamiTheme.maximumCharacters
                readOnly: !isAdmin
                toolTipText: CurrentConversation.isCoreDialog ? JamiStrings.contactName :
                                                                JamiStrings.groupName

                trailingIconSource: JamiResources.cancel_24dp_svg
                trailingIconToolTipText: JamiStrings.clearText
                onTrailingIconClicked: modifiedTextFieldContent = ""

                onAccepted: ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid, modifiedTextFieldContent);
            }

            NewMaterialTextField {
                id: descriptionLineButton

                // Note that the height of this component is specified internally
                width: parent.width

                leadingIconSource: CurrentConversation.isCoreDialog ? JamiResources.jami_id_logo_new_24dp_svg : JamiResources.swarm_details_panel_24dp_svg

                placeholderText: readOnly ? JamiStrings.noDescription : JamiStrings.addDescription
                textFieldContent: CurrentConversation.description
                maxCharacters: JamiTheme.maximumCharacters
                textFieldFontFamily: CurrentConversation.isCoreDialog && CurrentConversation.description.length === 40 ? JamiTheme.ubuntuMonoFontFamily : JamiTheme.ubuntuFontFamily
                textFieldFontPixelSize: JamiTheme.materialLineEditSelectedPixelSize
                readOnly: !isAdmin || CurrentConversation.isCoreDialog
                toolTipText: JamiStrings.addDescription

                trailingIconSource: JamiResources.cancel_24dp_svg
                trailingIconToolTipText: JamiStrings.clearText
                onTrailingIconClicked: modifiedTextFieldContent = ""

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, modifiedTextFieldContent);
                    }
                }

                onAccepted: ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, modifiedTextFieldContent)
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

                width: parent.width
                height: JamiTheme.tabBarHeight

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

                    implicitHeight: swarmDetailsPanelTabBar.contentItem.implicitHeight

                    anchors.fill: parent
                    color: JamiTheme.transparentColor
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
        height: 1
        color: JamiTheme.chatViewFooterRectangleBorderColor
    }
}
