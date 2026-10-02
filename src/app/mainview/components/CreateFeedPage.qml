/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

DualPaneView {
    id: viewNode

    objectName: "CreateFeedPage"

    signal removeMember(string convId, string member)
    signal createFeedClicked(string title, string description, string avatar)

    property var members: []
    property bool creationFailed: false

    splitViewStateKey: "Main"
    inhibits: ["ConversationView"]

    onVisibleChanged: UtilsAdapter.setTempCreationImageFromString()

    leftPaneItem: viewCoordinator.getView("SidePanel", true)
    rightPaneItem: Rectangle {
        id: root
        objectName: "CreateFeedLayout"

        anchors.fill: parent
        color: JamiTheme.chatviewBgColor

        RowLayout {
            id: labelsMember
            objectName: "feedMembersRow"

            width: root.width
            spacing: 16
            visible: viewNode.members.length

            Label {
                text: JamiStrings.to
                font.bold: true
                color: JamiTheme.textColor
                Layout.leftMargin: 16
            }

            Flow {
                Layout.topMargin: 16
                Layout.preferredWidth: root.width - 140
                Layout.preferredHeight: childrenRect.height + 16
                spacing: 8

                Repeater {
                    model: viewNode.members

                    delegate: Control {
                        leftPadding: background.radius
                        rightPadding: background.radius - removeUserBtn.implicitHeight / 2

                        contentItem: RowLayout {
                            spacing: 2

                            Text {
                                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, modelData.uri)
                                color: JamiTheme.textColor
                                verticalAlignment: Qt.AlignVCenter
                            }

                            NewIconButton {
                                id: removeUserBtn
                                QWKSetParentHitTestVisible {}

                                icon.color: hovered || activeFocus ? JamiTheme.textColor : JamiTheme.textColorHovered
                                iconSize: JamiTheme.iconButtonSmall
                                iconSource: JamiResources.round_close_24dp_svg
                                toolTipText: JamiStrings.removeMember

                                background: null

                                onClicked: viewNode.removeMember(modelData.convId, modelData.uri)
                            }
                        }

                        background: Rectangle {
                            radius: height / 2
                            color: JamiTheme.selectedColor
                        }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent

            spacing: JamiTheme.preferredMarginSize

            RowLayout {
                Layout.alignment: Qt.AlignCenter

                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignVCenter

                    text: JamiStrings.createNewFeed
                    color: JamiTheme.textColor
                    horizontalAlignment: Text.AlignHCenter

                    font.pixelSize: JamiTheme.settingsTitlePixelSize
                    font.kerning: true
                }

                NewIconButton {
                    objectName: "feedHelpButton"
                    Layout.alignment: Qt.AlignVCenter

                    iconSource: JamiResources.bidirectional_help_outline_24dp_svg
                    iconSize: JamiTheme.iconButtonMedium
                    toolTipText: qsTr("What is a feed?")

                    onClicked: viewCoordinator.presentDialog(viewNode, "commoncomponents/ConversationTypeInfoPopup.qml", {
                        "titleText": toolTipText,
                        "isFeed": true
                    })
                }
            }

            PhotoboothView {
                objectName: "feedAvatarPicker"
                Layout.alignment: Qt.AlignCenter
                width: avatarSize
                height: avatarSize

                newItem: true
                fallbackKind: Avatar.FallbackKind.Feed
                imageId: root.visible ? "temp" : ""
                avatarSize: 180
            }

            NewMaterialTextField {
                id: feedName
                objectName: "feedNameLineEdit"

                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.maximumWidth: JamiTheme.preferredFieldWidth

                leadingIconSource: JamiResources.feed_24dp_svg

                maxCharacters: JamiTheme.maximumCharacters
                placeholderText: JamiStrings.feedName
                textFieldContent: ""

                onEditingFinished: feedDescription.forceActiveFocus()
            }

            NewMaterialTextField {
                id: feedDescription
                objectName: "feedDescriptionLineEdit"

                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.maximumWidth: JamiTheme.preferredFieldWidth

                leadingIconSource: JamiResources.swarm_details_panel_24dp_svg

                maxCharacters: JamiTheme.maximumCharacters
                placeholderText: JamiStrings.addDescription
                textFieldContent: ""
            }

            NewMaterialButton {
                id: createFeedButton
                objectName: "createFeedButton"

                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.maximumWidth: JamiTheme.preferredFieldWidth
                Layout.alignment: Qt.AlignHCenter

                filledButton: true
                iconSource: JamiResources.create_feed_24dp_svg
                text: JamiStrings.createNewFeed

                onClicked: {
                    viewNode.creationFailed = false;
                    viewNode.createFeedClicked(feedName.modifiedTextFieldContent,
                                               feedDescription.modifiedTextFieldContent,
                                               UtilsAdapter.tempCreationImage());
                }
            }



            Label {
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.maximumWidth: JamiTheme.preferredFieldWidth
                Layout.alignment: Qt.AlignHCenter

                visible: viewNode.creationFailed
                text: JamiStrings.somethingWentWrong
                color: JamiTheme.redColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
