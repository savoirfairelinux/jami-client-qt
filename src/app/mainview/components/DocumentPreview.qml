/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Item {
    id: root

    property real margin: 2
    signal removeFileButtonClicked(int index)

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
                MessagesAdapter.openUrl(preview.fileUrl);
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
        spacing: 2

        AttachmentPreview {
            id: preview

            Layout.preferredHeight: root.height
            Layout.preferredWidth: root.height
            filePath: Body
            fallbackColor: CurrentConversation.color
            margin: root.margin
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
