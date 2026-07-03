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

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

import "../../commoncomponents"

Rectangle {
    id: listview

    anchors.top: parent.top
    anchors.topMargin: 10
    width: parent.width
    height: (deviceGroups.count > 0 ? headerHeight : 0) + deviceGroups.contentHeight + bottomPadding

    radius: 12
    color: JamiTheme.globalIslandColor

    // Shared column metrics keep the header and the rows aligned.
    readonly property int hMargin: 16
    readonly property int colSpacing: 12
    readonly property int contactColWidth: 210
    readonly property int connectionColWidth: 150
    readonly property int channelsColWidth: 84
    readonly property int rowHeight: 44
    readonly property int headerHeight: 46
    readonly property int bottomPadding: 8

    Component.onCompleted: ConnectionInfoListModel.update()

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: ConnectionInfoListModel.update()
    }

    // Column titles
    Item {
        id: headerItem
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: deviceGroups.count > 0
        height: visible ? listview.headerHeight : 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: listview.hMargin
            anchors.rightMargin: listview.hMargin
            spacing: listview.colSpacing

            Text {
                Layout.preferredWidth: listview.contactColWidth
                text: JamiStrings.contact
                color: JamiTheme.textColor
                opacity: 0.6
                font.weight: Font.DemiBold
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: JamiStrings.device
                color: JamiTheme.textColor
                opacity: 0.6
                font.weight: Font.DemiBold
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                Layout.preferredWidth: listview.connectionColWidth
                text: JamiStrings.connection
                color: JamiTheme.textColor
                opacity: 0.6
                font.weight: Font.DemiBold
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                Layout.preferredWidth: listview.channelsColWidth
                text: JamiStrings.channels
                color: JamiTheme.textColor
                opacity: 0.6
                font.weight: Font.DemiBold
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }

    // Contact groups
    ListView {
        id: deviceGroups
        anchors.top: headerItem.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: contentHeight

        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        spacing: 0

        model: ConnectionInfoListModel

        delegate: Item {
            id: groupDelegate
            width: deviceGroups.width
            height: Count === 0 ? 0 : listview.rowHeight * Count

            // One row per device/connection of this contact.
            ListView {
                id: deviceRows
                anchors.fill: parent

                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                spacing: 0

                model: Count

                delegate: Item {
                    id: deviceRow
                    width: deviceRows.width
                    height: listview.rowHeight

                    readonly property int connStatus: Status[index] === undefined ? -1 : Status[index]
                    readonly property color connColor: connStatus === 0 ? "#009c7f" : (connStatus === 4 ? "#e5484d" : "#ff8100")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: listview.hMargin
                        anchors.rightMargin: listview.hMargin
                        spacing: listview.colSpacing

                        // Contact (shown once per group)
                        Item {
                            Layout.preferredWidth: listview.contactColWidth
                            Layout.fillHeight: true

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                spacing: 10

                                Avatar {
                                    id: avatar
                                    visible: index === 0
                                    width: 36
                                    height: 36
                                    anchors.verticalCenter: parent.verticalCenter
                                    imageId: PeerId
                                    mode: Avatar.Mode.Contact
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - (avatar.visible ? avatar.width + parent.spacing : 0)
                                    visible: index === 0
                                    spacing: 2

                                    Text {
                                        id: nameText
                                        width: parent.width
                                        text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, PeerId)
                                        color: JamiTheme.textColor
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        id: idText
                                        width: parent.width
                                        visible: UtilsAdapter.getBestIdForUri(CurrentAccount.id, PeerId) !== nameText.text
                                        text: UtilsAdapter.getBestIdForUri(CurrentAccount.id, PeerId)
                                        color: JamiTheme.textColor
                                        opacity: 0.55
                                        font.family: text === PeerId ? JamiTheme.ubuntuMonoFontFamily : JamiTheme.ubuntuFontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: contactMouse
                                anchors.fill: parent
                                enabled: index === 0
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    contactTooltip.text = JamiStrings.logsViewCopied;
                                    UtilsAdapter.setClipboardText(ConnectionDatas);
                                }
                                onExited: contactTooltip.text = JamiStrings.copyAllData

                                MaterialToolTip {
                                    id: contactTooltip
                                    visible: contactMouse.containsMouse && index === 0
                                    text: JamiStrings.copyAllData
                                }
                            }
                        }

                        // Device id
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                id: deviceText
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                text: DeviceId[index] !== undefined ? DeviceId[index] : ""
                                color: deviceMouse.containsMouse ? JamiTheme.textColorHovered : JamiTheme.textColor
                                font.family: JamiTheme.ubuntuMonoFontFamily
                                font.pixelSize: 13
                                elide: Text.ElideMiddle
                            }

                            MouseArea {
                                id: deviceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    deviceTooltip.text = deviceText.text + " (" + JamiStrings.logsViewCopied + ")";
                                    UtilsAdapter.setClipboardText(deviceText.text);
                                }
                                onExited: deviceTooltip.text = deviceText.text

                                MaterialToolTip {
                                    id: deviceTooltip
                                    visible: deviceMouse.containsMouse
                                    text: deviceText.text
                                    toolTipFont: JamiTheme.ubuntuMonoFontFamily
                                }
                            }
                        }

                        // Connection status pill
                        Item {
                            Layout.preferredWidth: listview.connectionColWidth
                            Layout.fillHeight: true

                            Rectangle {
                                id: statusPill
                                anchors.verticalCenter: parent.verticalCenter
                                height: 28
                                width: Math.min(parent.width, statusRow.width + 20)
                                radius: height / 2
                                color: Qt.rgba(deviceRow.connColor.r, deviceRow.connColor.g, deviceRow.connColor.b, 0.14)

                                Row {
                                    id: statusRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    ResponsiveImage {
                                        id: statusIcon
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        source: deviceRow.connStatus === 0 ? JamiResources.connected_black_24dp_svg : JamiResources.connecting_black_24dp_svg
                                        color: deviceRow.connColor

                                        RotationAnimation on rotation {
                                            running: deviceRow.connStatus !== 0
                                            from: 0
                                            to: 360
                                            duration: 3000
                                            loops: Animation.Infinite
                                            direction: RotationAnimation.Clockwise
                                        }
                                    }

                                    Text {
                                        id: statusText
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: deviceRow.connColor
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        text: {
                                            switch (deviceRow.connStatus) {
                                            case 0:
                                                return JamiStrings.connected;
                                            case 1:
                                                return JamiStrings.connectingTLS;
                                            case 2:
                                                return JamiStrings.connectingICE;
                                            case 3:
                                                return JamiStrings.connecting;
                                            default:
                                                return JamiStrings.waiting;
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: statusMouse
                                    anchors.fill: parent
                                    hoverEnabled: true

                                    MaterialToolTip {
                                        visible: statusMouse.containsMouse
                                        text: JamiStrings.remote.arg(RemoteAddress[index])
                                        toolTipFont: JamiTheme.ubuntuMonoFontFamily
                                    }
                                }
                            }
                        }

                        // Channels badge
                        Item {
                            Layout.preferredWidth: listview.channelsColWidth
                            Layout.fillHeight: true

                            Rectangle {
                                id: channelsBadge
                                anchors.verticalCenter: parent.verticalCenter
                                height: 28
                                width: Math.max(44, channelsText.width + 24)
                                radius: height / 2
                                color: channelsMouse.containsMouse ? JamiTheme.hoverColor : (JamiTheme.darkTheme ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05))

                                Text {
                                    id: channelsText
                                    anchors.centerIn: parent
                                    color: JamiTheme.textColor
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    text: Channels[index] !== undefined ? Channels[index] : ""
                                }

                                MouseArea {
                                    id: channelsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        viewCoordinator.presentDialog(parent, "settingsview/components/ChannelsPopup.qml", {
                                                "channels": ChannelsMap[index],
                                                "maxWidth": listview.width
                                            });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
