/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Franck Laurent <franck.laurent@savoirfairelinux.com>
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
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Item {

    id: root

    property real margin: 3
    signal removeFileButtonClicked(int index)
    property var mediaInfo: MessagesAdapter.getMediaInfo(Body)

    visible: MessagesAdapter.isDocument(Type) && ( Status === Interaction.Status.TRANSFER_FINISHED || Status === Interaction.Status.SUCCESS )

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: {
            cursorShape = Qt.PointingHandCursor
        }

        onClicked: function(mouse)  {
            if (mouse.button === Qt.RightButton) {
                ctxMenu.x = mouse.x
                ctxMenu.y = mouse.y
                ctxMenu.openMenu()
            } else {
                MessagesAdapter.openUrl(name.fileSource)
            }
        }
    }

    SBSContextMenu {
        id: ctxMenu

        msgId: Id
        location: Body
        transferId: Id
        transferName: TransferName
    }

    RowLayout {

        anchors.fill: root
        anchors.rightMargin: JamiTheme.preferredMarginSize
        anchors.leftMargin: JamiTheme.preferredMarginSize
        spacing : 2

        Rectangle {
            id: mainRect

            radius: JamiTheme.filesToSendDelegateRadius
            Layout.preferredHeight: root.height
            Layout.preferredWidth: root.height
            color: JamiTheme.transparentColor

            Rectangle {
                id: rect

                anchors.fill: parent
                color: CurrentConversation.color
                layer.enabled: true

                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: rect.width
                        height: rect.height
                        Rectangle {
                            anchors.centerIn: parent
                            width:  rect.width
                            height:  rect.height
                            radius: JamiTheme.chatViewFooterButtonRadius
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    anchors.bottom: parent.bottom
                    height: 3/4 * mainRect.height
                    color: CurrentConversation.color
                }

                Rectangle {

                    anchors.fill: parent
                    anchors.margins: margin
                    radius: JamiTheme.chatViewFooterButtonRadius
                    color: JamiTheme.whiteColor

                    ResponsiveImage {
                        id: fileIcon
                        visible : !mediaInfo.isImage && !mediaInfo.isAnimatedImage
                        anchors.fill: parent
                        anchors.margins: margin
                        source: JamiResources.file_black_24dp_svg
                        cache: false
                    }

                    AnimatedImage {
                        id: name

                        property string fileSource: ""
                        anchors.fill: parent
                        anchors.margins: margin
                        cache: false

                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        mipmap: false

                        source: {
                            fileSource = "file://" + Body
                            if (!mediaInfo.isImage && !mediaInfo.isAnimatedImage){
                                return ""
                            }
                            return "file://" + Body
                        }

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: mainRect.width
                                height: mainRect.height
                                radius: JamiTheme.filesToSendDelegateRadius
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: info
            Layout.preferredHeight: root.height
            Layout.fillWidth: true
            color : JamiTheme.transparentColor
            Layout.alignment: Qt.AlignLeft

            ColumnLayout {

                anchors.margins: margin
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left

                Text {
                    id: fileName

                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: info.width
                    font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                    color: JamiTheme.chatviewTextColor
                    font.bold : true
                    text: TransferName
                    elide: Text.ElideRight
                }

                RowLayout {

                    Layout.alignment: Qt.AlignLeft
                    spacing: FileExtension.length === 0 ? 0 : 2

                    Text {
                        id: fileExtension
                        Layout.alignment: Qt.AlignLeft
                        font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                        font.capitalization: Font.AllUppercase
                        color: JamiTheme.chatviewTextColor
                        text: FileExtension

                        elide: Text.ElideMiddle
                    }

                    Text {
                        id: fileProperty
                        font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                        color: JamiTheme.chatviewTextColor
                        Layout.alignment: Qt.AlignLeft
                        Layout.maximumWidth: info.width - fileExtension.width - test.spacing
                        text: " " + UtilsAdapter.humanFileSize(TotalSize) + ", " + MessagesAdapter.getFormattedDay(Timestamp)
                              + " - " + MessagesAdapter.getFormattedTime(Timestamp)
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
