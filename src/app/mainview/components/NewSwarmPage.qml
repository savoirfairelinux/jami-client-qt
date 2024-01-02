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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

DualPaneView {
    id: viewNode
    objectName: "NewSwarmPage"

    signal createSwarmClicked(string title, string description, string avatar)
    signal removeMember(string convId, string member)

    onVisibleChanged: {
        UtilsAdapter.setTempCreationImageFromString();
        title.staticText = "";
        description.staticText = "";
    }

    property var members: []

    splitViewStateKey: "Main"
    inhibits: ["ConversationView"]

    leftPaneItem: viewCoordinator.getView("SidePanel")
    rightPaneItem: Rectangle {
        id: root
        color: JamiTheme.chatviewBgColor

        anchors.fill: parent

        RowLayout {
            id: labelsMember
            Layout.topMargin: 16
            Layout.preferredWidth: root.width
            Layout.preferredHeight: childrenRect.height
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
                Layout.preferredWidth: root.width - 80
                Layout.preferredHeight: childrenRect.height + 16
                spacing: 8

                Repeater {
                    id: repeater

                    delegate: Rectangle {
                        id: delegate
                        radius: (delegate.height + 12) / 2
                        width: label.width + 36
                        height: label.height + 12

                        RowLayout {
                            anchors.centerIn: parent

                            Label {
                                id: label
                                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, modelData.uri)
                                color: JamiTheme.textColor
                                Layout.leftMargin: 8
                            }

                            PushButton {
                                id: removeUserBtn

                                preferredSize: 24

                                source: JamiResources.round_close_24dp_svg
                                toolTipText: JamiStrings.removeMember

                                normalColor: "transparent"
                                imageColor: "transparent"

                                onClicked: removeMember(modelData.convId, modelData.uri)
                            }
                        }

                        color: JamiTheme.selectedColor
                    }
                    model: viewNode.members
                }
            }
        }

        Rectangle {
            anchors.top: labelsMember.bottom
            visible: labelsMember.visible
            height: 1
            width: root.width
            color: "transparent"
            border.width: 1
            border.color: JamiTheme.selectedColor
        }

        ColumnLayout {
            id: mainLayout
            objectName: "mainLayout"
            anchors.centerIn: root

            PhotoboothView {
                id: currentAccountAvatar

                Layout.alignment: Qt.AlignCenter
                width: avatarSize
                height: avatarSize

                newItem: true
                imageId: root.visible ? "temp" : ""
                avatarSize: 180
            }

            ModalTextEdit {
                id: title
                objectName: "titleLineEdit"

                maxCharacters: JamiTheme.maximumCharacters

                Layout.minimumHeight: JamiTheme.preferredFieldHeight
                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.preferredWidth: JamiTheme.preferredFieldWidth

                staticText: ""
                placeholderText: JamiStrings.swarmName

                textColor: {
                    if (UtilsAdapter.luma(root.color)) {
                        return JamiTheme.placeholderTextColorWhite;
                    } else {
                        return JamiTheme.placeholderTextColor;
                    }
                }

                onAccepted: description.forceActiveFocus()
            }

            ModalTextEdit {
                id: description
                objectName: "descriptionLineEdit"

                maxCharacters: JamiTheme.maximumCharacters

                Layout.minimumHeight: JamiTheme.preferredFieldHeight
                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.preferredWidth: JamiTheme.preferredFieldWidth

                staticText: ""
                placeholderText: JamiStrings.addADescription

                textColor: {
                    if (UtilsAdapter.luma(root.color)) {
                        return JamiTheme.placeholderTextColorWhite;
                    } else {
                        return JamiTheme.placeholderTextColor;
                    }
                }

                onAccepted: btnCreateSwarm.forceActiveFocus()
            }

            MaterialButton {
                id: btnCreateSwarm

                TextMetrics {
                    id: textSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: btnCreateSwarm.text
                }

                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: JamiTheme.preferredMarginSize
                autoAccelerator: true

                preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding

                primary: true
                text: JamiStrings.createTheSwarm

                onClicked: createSwarmClicked(title.dynamicText, description.dynamicText, UtilsAdapter.tempCreationImage())
            }
        }
    }
}
