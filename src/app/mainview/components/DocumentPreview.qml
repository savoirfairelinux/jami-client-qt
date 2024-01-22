/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

    property real margin: 2
    signal removeFileButtonClicked(int index)
    property var mediaInfo: MessagesAdapter.getMediaInfo(Body)

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: {
            cursorShape = Qt.PointingHandCursor;
        }

        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                ctxMenu.x = mouse.x;
                ctxMenu.y = mouse.y;
                ctxMenu.openMenu();
            } else {
                MessagesAdapter.openUrl(icon.fileSource);
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
        spacing: 2

        Rectangle {
            id: mainRect

            radius: JamiTheme.filesToSendDelegateRadius
            Layout.preferredHeight: root.height
            Layout.preferredWidth: root.height
            color: JamiTheme.transparentColor

            Rectangle {
                id: rect

                anchors.fill: parent
                color: fileIcon.visible ? CurrentConversation.color : JamiTheme.transparentColor
                layer.enabled: true

                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: rect.width
                        height: rect.height
                        Rectangle {
                            anchors.centerIn: parent
                            width: rect.width
                            height: rect.height
                            radius: JamiTheme.chatViewFooterButtonRadius
                        }
                    }
                }

                Rectangle {

                    anchors.fill: parent
                    anchors.margins: fileIcon.visible ? margin : 0
                    radius: JamiTheme.chatViewFooterButtonRadius
                    color: JamiTheme.secondaryBackgroundColor

                    ResponsiveImage {
                        id: fileIcon
                        visible: (!mediaInfo.isImage && !mediaInfo.isAnimatedImage) || icon.status == Image.Error
                        anchors.fill: parent
                        anchors.margins: 8
                        source: {
                            if (mediaInfo.isVideo)
                                return JamiResources.video_file_svg;
                            if (mediaInfo.isAudio)
                                return JamiResources.audio_file_svg;
                            return JamiResources.attached_file_svg;
                        }
                        cache: false
                        color: JamiTheme.textColor
                    }

                    AnimatedImage {
                        id: icon

                        property string fileSource: ""
                        anchors.fill: parent
                        cache: false

                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop

                        source: {
                            fileSource = UtilsAdapter.urlFromLocalPath(Body);
                            if (!mediaInfo.isImage && !mediaInfo.isAnimatedImage) {
                                return "";
                            }
                            return fileSource;
                        }
                    }
                }
            }
        }

        Rectangle {
            id: info
            Layout.preferredHeight: root.height
            Layout.fillWidth: true
            color: JamiTheme.transparentColor
            Layout.alignment: Qt.AlignLeft

            ColumnLayout {

                anchors.margins: 5
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left

                Text {
                    id: fileName

                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: info.width
                    font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                    color: JamiTheme.chatviewTextColor
                    text: TransferName
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }

                RowLayout {
                    id: infoLayout
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
                        Layout.maximumWidth: info.width - fileExtension.width - infoLayout.spacing
                        text: " " + UtilsAdapter.humanFileSize(TotalSize) + ", " + MessagesAdapter.getFormattedDay(Timestamp) + " - " + MessagesAdapter.getFormattedTime(Timestamp)
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
