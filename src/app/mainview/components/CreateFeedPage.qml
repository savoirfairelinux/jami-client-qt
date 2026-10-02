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

    property var members: []

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

            PhotoboothView {
                Layout.alignment: Qt.AlignCenter
                width: avatarSize
                height: avatarSize

                newItem: true
                imageId: root.visible ? "temp" : ""
                avatarSize: 180
            }

            NewMaterialTextField {
                id: feedName
                objectName: "feedNameLineEdit"

                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.maximumWidth: JamiTheme.preferredFieldWidth

                leadingIconSource: JamiResources.rss_feed_24dp_svg

                maxCharacters: JamiTheme.maximumCharacters
                placeholderText: JamiStrings.feedName
                textFieldContent: ""

                onEditingFinished: feedDescription.forceActiveFocus()
            }

            NewMaterialTextField {
                id: feedDescription
                objectName: "feedDescriptionLineEdit"

                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.maximumWidth: JamiTheme.preferredFieldWidth

                leadingIconSource: JamiResources.swarm_details_panel_24dp_svg

                maxCharacters: JamiTheme.maximumCharacters
                placeholderText: JamiStrings.addDescription
                textFieldContent: ""
            }
        }
    }
}
