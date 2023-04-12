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
    property real margin: 2
    property var mediaInfo: MessagesAdapter.getMediaInfo(Body)

    signal removeFileButtonClicked(int index)

    MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent
        hoverEnabled: true

        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                ctxMenu.x = mouse.x;
                ctxMenu.y = mouse.y;
                ctxMenu.openMenu();
            } else {
                MessagesAdapter.openUrl(name.fileSource);
            }
        }
        onEntered: {
            cursorShape = Qt.PointingHandCursor;
        }
    }
    SBSContextMenu {
        id: ctxMenu
        location: Body
        msgId: Id
        transferId: Id
        transferName: TransferName
    }
    RowLayout {
        anchors.fill: root
        anchors.leftMargin: JamiTheme.preferredMarginSize
        anchors.rightMargin: JamiTheme.preferredMarginSize
        spacing: 2

        Rectangle {
            id: mainRect
            Layout.preferredHeight: root.height
            Layout.preferredWidth: root.height
            color: JamiTheme.transparentColor
            radius: JamiTheme.filesToSendDelegateRadius

            Rectangle {
                id: rect
                anchors.fill: parent
                color: fileIcon.visible ? CurrentConversation.color : JamiTheme.transparentColor
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: fileIcon.visible ? margin : 0
                    color: JamiTheme.secondaryBackgroundColor
                    radius: JamiTheme.chatViewFooterButtonRadius

                    ResponsiveImage {
                        id: fileIcon
                        anchors.fill: parent
                        anchors.margins: 8
                        cache: false
                        color: JamiTheme.textColor
                        source: JamiResources.file_black_24dp_svg
                        visible: !mediaInfo.isImage && !mediaInfo.isAnimatedImage
                    }
                    AnimatedImage {
                        id: name
                        property string fileSource: ""

                        anchors.fill: parent
                        asynchronous: true
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        source: {
                            fileSource = "file://" + Body;
                            if (!mediaInfo.isImage && !mediaInfo.isAnimatedImage) {
                                return "";
                            }
                            return "file://" + Body;
                        }
                    }
                }

                layer.effect: OpacityMask {
                    maskSource: Item {
                        height: rect.height
                        width: rect.width

                        Rectangle {
                            anchors.centerIn: parent
                            height: rect.height
                            radius: JamiTheme.chatViewFooterButtonRadius
                            width: rect.width
                        }
                    }
                }
            }
        }
        Rectangle {
            id: info
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            Layout.preferredHeight: root.height
            color: JamiTheme.transparentColor

            ColumnLayout {
                anchors.left: parent.left
                anchors.margins: 5
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: fileName
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: info.width
                    color: JamiTheme.chatviewTextColor
                    elide: Text.ElideRight
                    font.bold: true
                    font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                    text: TransferName
                }
                RowLayout {
                    id: infoLayout
                    Layout.alignment: Qt.AlignLeft
                    spacing: FileExtension.length === 0 ? 0 : 2

                    Text {
                        id: fileExtension
                        Layout.alignment: Qt.AlignLeft
                        color: JamiTheme.chatviewTextColor
                        elide: Text.ElideMiddle
                        font.capitalization: Font.AllUppercase
                        font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                        text: FileExtension
                    }
                    Text {
                        id: fileProperty
                        Layout.alignment: Qt.AlignLeft
                        Layout.maximumWidth: info.width - fileExtension.width - infoLayout.spacing
                        color: JamiTheme.chatviewTextColor
                        elide: Text.ElideRight
                        font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                        text: " " + UtilsAdapter.humanFileSize(TotalSize) + ", " + MessagesAdapter.getFormattedDay(Timestamp) + " - " + MessagesAdapter.getFormattedTime(Timestamp)
                    }
                }
            }
        }
    }
}
