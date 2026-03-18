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
            anchors.bottomMargin: 0

            spacing: 12

            Row {
                Layout.alignment: Qt.AlignCenter

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

                Layout.fillWidth: true

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

                Layout.fillWidth: true

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

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.tabBarHeight

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

            ColumnLayout {
                id: membersView

                Layout.fillWidth: true
                Layout.fillHeight: true

                spacing: 12

                visible: !CurrentConversation.isCoreDialog && swarmDetailsPanelTabBar.currentIndex
                         === 0

                NewMaterialButton {
                    id: inviteMemberButton

                    Layout.fillWidth: true

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

                    bottomMargin: JamiTheme.sidePanelIslandsPadding

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        anchors.fill: scrollView
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: root.width
                                height: root.height
                                bottomLeftRadius: innerRect.radius
                                bottomRightRadius: innerRect.radius
                            }
                        }
                    }

                    Grid {
                        id: membersGrid

                        width: parent.width
                        spacing: 8

                        columns: CurrentConversation.members.length < 3
                                 ? CurrentConversation.members.length : 4

                        Repeater {
                            model: CurrentConversation.members
                            delegate: GridItemDelegate {
                                width: (scrollView.width - (membersGrid.columns - 1)
                                        * membersGrid.spacing) / membersGrid.columns
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

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        anchors.fill: filesView
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: root.width
                                height: root.height
                                bottomLeftRadius: innerRect.radius
                                bottomRightRadius: innerRect.radius
                            }
                        }
                    }
                }

                // We dont want to immediately show the user that they have no files while the model is in fact populating,
                // so we add a 300ms delay before showing the "no files" text, and in the meantime we show a spinner if there
                // are no files
                Timer {
                    id: showEmptyTextTimer
                    interval: 300
                    running: documents.count === 0
                }

                Button {
                    id: spinnerIcon

                    anchors.centerIn: parent

                    padding: 0

                    icon.width: JamiTheme.iconButtonMedium
                    icon.height: JamiTheme.iconButtonMedium
                    icon.source: JamiResources.jami_rolling_spinner_gif
                    icon.color: JamiTheme.tintedBlue

                    visible: showEmptyTextTimer.running

                    background: null
                    enabled: false

                    RotationAnimator {
                        id: rotationAnimator
                        target: spinnerIcon
                        running: showEmptyTextTimer.running
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                Text {
                    anchors.fill: parent

                    text: JamiStrings.noFilesInConversation
                    color: JamiTheme.textColor

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    wrapMode: Text.WordWrap

                    visible: documents.count === 0 && !showEmptyTextTimer.running
                }
            }

            Column {
                id: detailsView

                Layout.fillWidth: true
                Layout.fillHeight: true

                spacing: 16

                visible: CurrentConversation.isCoreDialog ? swarmDetailsPanelTabBar.currentIndex
                                                            === 1 : swarmDetailsPanelTabBar.currentIndex
                                                            === 2

                RowLayout {
                    width: parent.width

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        text: JamiStrings.conversationType
                        color: JamiTheme.textColor
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                        font.pointSize: JamiTheme.smallFontSize
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        text: CurrentConversation.modeString
                        color: JamiTheme.textColor
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        font.pointSize: JamiTheme.smallFontSize
                    }
                }

                RowLayout {
                    width: parent.width

                    visible: !CurrentConversation.isCoreDialog

                    Text {
                        Layout.alignment: Qt.AlignVCenter

                        text: JamiStrings.defaultCallHost
                        color: JamiTheme.textColor
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                        font.pointSize: JamiTheme.smallFontSize

                        visible: !CurrentConversation.isCoreDialog
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

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
                    width: parent.width

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
                    width: parent.width

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

                    width: parent.width

                    outlinedButton: true
                    color: JamiTheme.buttonTintedRed
                    iconSource: JamiResources.disconnect_participant_24dp_svg
                    text: CurrentConversation.isCoreDialog ? JamiStrings.removeConversation :
                                                             JamiStrings.leaveGroup

                    onClicked: {
                        var dlg = viewCoordinator.presentDialog(appWindow,
                                                                "commoncomponents/ConfirmDialog.qml",
                                                                {
                                                                    "titleText": JamiStrings.confirmAction,
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

                    width: parent.width

                    outlinedButton: true
                    color: JamiTheme.buttonTintedRed
                    iconSource: JamiResources.kick_member_24dp_svg
                    text: JamiStrings.removeContact

                    visible: CurrentConversation.isCoreDialog
                    onClicked: {
                        var dlg = viewCoordinator.presentDialog(appWindow,
                                                                "commoncomponents/ConfirmDialog.qml",
                                                                {
                                                                    "titleText": JamiStrings.confirmAction,
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

                    width: parent.width

                    outlinedButton: true
                    color: JamiTheme.buttonTintedRed
                    iconSource: JamiResources.block_black_24dp_svg
                    text: JamiStrings.blockContact

                    visible: CurrentConversation.isCoreDialog

                    onClicked: {
                        var dlg = viewCoordinator.presentDialog(appWindow,
                                                                "commoncomponents/ConfirmDialog.qml",
                                                                {
                                                                    "titleText": JamiStrings.confirmAction,
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
}
