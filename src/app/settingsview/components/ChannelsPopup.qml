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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Popup {
    id: popup

    // The raw channel map: { hexKey: name }.
    property var channels: ({})
    property int maxWidth: 0

    // Turn the map into a list sorted by channel id.
    readonly property var channelList: {
        var list = [];
        for (const key in channels) {
            list.push({
                          "id": parseInt(key, 16).toString(),
                          "name": channels[key]
                      });
        }
        list.sort(function (a, b) {
            return parseInt(a.id) - parseInt(b.id);
        });
        return list;
    }

    readonly property int rowHeight: 34
    readonly property int contentPadding: 10
    readonly property int preferredWidth: 320

    padding: 0

    width: Math.min(preferredWidth, maxWidth > 60 ? maxWidth - 20 : preferredWidth)
    height: Math.min(header.height + 2 * contentPadding + Math.max(rowHeight, list.contentHeight), 360)
    x: -1 * (popup.width - 20)

    background: Rectangle {
        color: JamiTheme.secondaryBackgroundColor
        radius: 12
        border.width: 1
        border.color: JamiTheme.tabbarBorderColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header with title and channel count
        Item {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: JamiStrings.channels
                color: JamiTheme.textColor
                font.weight: Font.DemiBold
                font.pixelSize: 14
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: popup.channelList.length
                color: JamiTheme.textColor
                opacity: 0.6
                font.pixelSize: 13
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                height: 1
                color: JamiTheme.tabbarBorderColor
            }
        }

        // Empty state
        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: popup.channelList.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: JamiStrings.noChannels
            color: JamiTheme.textColor
            opacity: 0.6
            font.pixelSize: 13
        }

        // Channel list
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: popup.contentPadding
            Layout.bottomMargin: popup.contentPadding
            visible: popup.channelList.length > 0

            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: popup.channelList

            ScrollBar.vertical: JamiScrollBar {
                active: list.contentHeight > list.height
            }

            delegate: Item {
                width: list.width
                height: popup.rowHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    radius: 6
                    color: rowMouse.containsMouse ? (JamiTheme.darkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05)) : JamiTheme.transparentColor
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: idText.width + 16
                        Layout.preferredHeight: 22
                        radius: 6
                        color: JamiTheme.darkTheme ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                        Text {
                            id: idText
                            anchors.centerIn: parent
                            text: modelData.id
                            color: JamiTheme.textColor
                            font.family: JamiTheme.ubuntuMonoFontFamily
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: JamiTheme.textColor
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: UtilsAdapter.setClipboardText(modelData.id + " : " + modelData.name)

                    MaterialToolTip {
                        visible: rowMouse.containsMouse && modelData.name.length > 0
                        text: modelData.name
                    }
                }
            }
        }
    }
}
