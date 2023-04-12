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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

DualPaneView {
    id: viewNode
    property var members: []

    inhibits: ["ConversationView"]
    leftPaneItem: viewCoordinator.getView("SidePanel")
    objectName: "NewSwarmPage"
    splitViewStateKey: "Main"

    signal createSwarmClicked(string title, string description, string avatar)
    signal removeMember(string convId, string member)

    onVisibleChanged: {
        UtilsAdapter.setTempCreationImageFromString();
        title.clear();
        description.clear();
    }

    rightPaneItem: Rectangle {
        id: root
        anchors.fill: parent
        color: JamiTheme.chatviewBgColor

        RowLayout {
            id: labelsMember
            Layout.preferredHeight: childrenRect.height
            Layout.preferredWidth: root.width
            Layout.topMargin: 16
            spacing: 16
            visible: viewNode.members.length

            Label {
                Layout.leftMargin: 16
                color: JamiTheme.textColor
                font.bold: true
                text: JamiStrings.to
            }
            Flow {
                Layout.preferredHeight: childrenRect.height + 16
                Layout.preferredWidth: root.width - 80
                Layout.topMargin: 16
                spacing: 8

                Repeater {
                    id: repeater
                    model: viewNode.members

                    delegate: Rectangle {
                        id: delegate
                        color: JamiTheme.selectedColor
                        height: label.height + 12
                        radius: (delegate.height + 12) / 2
                        width: label.width + 36

                        RowLayout {
                            anchors.centerIn: parent

                            Label {
                                id: label
                                Layout.leftMargin: 8
                                color: JamiTheme.textColor
                                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, modelData.uri)
                            }
                            PushButton {
                                id: removeUserBtn
                                imageColor: "transparent"
                                normalColor: "transparent"
                                preferredSize: 24
                                source: JamiResources.round_close_24dp_svg
                                toolTipText: JamiStrings.removeMember

                                onClicked: removeMember(modelData.convId, modelData.uri)
                            }
                        }
                    }
                }
            }
        }
        Rectangle {
            anchors.top: labelsMember.bottom
            border.color: JamiTheme.selectedColor
            border.width: 1
            color: "transparent"
            height: 1
            visible: labelsMember.visible
            width: root.width
        }
        ColumnLayout {
            id: mainLayout
            anchors.centerIn: root
            objectName: "mainLayout"

            PhotoboothView {
                id: currentAccountAvatar
                Layout.alignment: Qt.AlignCenter
                avatarSize: 180
                height: avatarSize
                imageId: root.visible ? "temp" : ""
                newItem: true
                width: avatarSize
            }
            EditableLineEdit {
                id: title
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.topMargin: JamiTheme.preferredMarginSize
                backgroundColor: root.color
                color: UtilsAdapter.luma(backgroundColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                font.pointSize: JamiTheme.titleFontSize
                objectName: "titleLineEdit"
                placeholderText: JamiStrings.swarmName
                placeholderTextColor: {
                    if (editable) {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.placeholderTextColorWhite;
                        } else {
                            return JamiTheme.placeholderTextColor;
                        }
                    } else {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.chatviewTextColorLight;
                        } else {
                            return JamiTheme.chatviewTextColorDark;
                        }
                    }
                }
                tooltipText: JamiStrings.swarmName
                verticalAlignment: Text.AlignVCenter
            }
            EditableLineEdit {
                id: description
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.topMargin: JamiTheme.preferredMarginSize
                backgroundColor: root.color
                color: UtilsAdapter.luma(backgroundColor) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                font.pointSize: JamiTheme.menuFontSize
                objectName: "descriptionLineEdit"
                placeholderText: JamiStrings.addADescription
                placeholderTextColor: {
                    if (editable) {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.placeholderTextColorWhite;
                        } else {
                            return JamiTheme.placeholderTextColor;
                        }
                    } else {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.chatviewTextColorLight;
                        } else {
                            return JamiTheme.chatviewTextColorDark;
                        }
                    }
                }
                tooltipText: JamiStrings.addADescription
                verticalAlignment: Text.AlignVCenter
            }
            MaterialButton {
                id: btnCreateSwarm
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: JamiTheme.preferredMarginSize
                autoAccelerator: true
                preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
                primary: true
                text: JamiStrings.createTheSwarm

                onClicked: createSwarmClicked(title.text, description.text, UtilsAdapter.tempCreationImage())

                TextMetrics {
                    id: textSize
                    font.capitalization: Font.AllUppercase
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.weight: Font.Bold
                    text: btnCreateSwarm.text
                }
            }
        }
    }
}
