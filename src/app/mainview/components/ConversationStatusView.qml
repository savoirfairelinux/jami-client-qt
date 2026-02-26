/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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
import QtQuick.Effects

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

import "../../commoncomponents"

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
        id: innerRect
        anchors.fill: parent
        anchors.margins: JamiTheme.sidePanelIslandsPadding

        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius

        ScrollView {
            id: scrollView
            anchors.fill: parent
            clip: true

            ColumnLayout {
                width: scrollView.availableWidth
                spacing: 20

                // Routing table Title
                Text {
                    text: qsTr("Swarm routing table")
                    color: JamiTheme.textColor
                    font.weight: Font.DemiBold
                    font.pixelSize: 16 
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    Layout.leftMargin: 10
                }

                // Routing table
                ListView {
                    id: listview
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight
                    
                    spacing: 5
                    cacheBuffer: 10

                    boundsBehavior: Flickable.StopAtBounds
                    interactive: false

                    property int rota: 0

                    header: Rectangle {
                        color: JamiTheme.connectionMonitoringHeaderColor
                        height: 40
                        width: listview.width

                        RowLayout {
                            anchors.fill: parent
                            Rectangle {
                                id: device
                                Layout.fillWidth: true
                                Layout.minimumWidth: 50
                                height: 40
                                color: JamiTheme.transparentColor
                                Layout.leftMargin: 10
                                Text {
                                    id: deviceText
                                    color: JamiTheme.textColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: JamiStrings.device
                                }
                            }

                            Rectangle {
                                width: 40
                                height: 40
                                color: JamiTheme.transparentColor
                            }

                            Rectangle {
                                id: connection
                                width: 130
                                height: 40
                                radius: 5
                                color: JamiTheme.transparentColor
                                Text {
                                    id: connectionText
                                    color: JamiTheme.textColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 10
                                    text: JamiStrings.connection
                                }
                            }

                            Rectangle {
                                id: connectionTime
                                width: 130
                                height: 40
                                color: JamiTheme.transparentColor
                                Text {
                                    id: connectionTimeText
                                    color: JamiTheme.textColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 10
                                    text: qsTr("Connection Time")
                                }
                            }
                        }
                    }

                    model: ConversationStatusModel

                    Component.onCompleted: {
                        ConversationStatusModel.conversationId = CurrentConversation.id
                        ConversationStatusModel.update()
                    }

                    delegate: Rectangle {
                        id: delegate
                        height: Count == 0 ? 0 : 10 + 20 * Count
                        width: listview.width
                        color: index % 2 === 0 ? JamiTheme.connectionMonitoringTableColor1 : JamiTheme.connectionMonitoringTableColor2

                        ListView {
                            id: listView2
                            height: 20 * Count
                            width: parent.width

                            anchors.verticalCenter: parent.verticalCenter

                            spacing: 0

                            model: Count

                            boundsBehavior: Flickable.StopAtBounds
                            interactive: false

                            delegate: RowLayout {
                                id: rowLayoutDelegate
                                height: 20
                                width: listview.width

                                Rectangle {
                                    height: 20
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 50
                                    Layout.alignment: Qt.AlignVCenter
                                    color: delegate.color
                                    Text {
                                        id: delegateDeviceText
                                        color: JamiTheme.textColor
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        text: {
                                            if (DeviceId[index] !== undefined) {
                                                return DeviceId[index].substring(0, 16);
                                            } else {
                                                return "";
                                            }
                                        }
                                        width: parent.width - 10
                                        elide: Text.ElideRight
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onEntered: {
                                                delegateDeviceText.font.underline = true;
                                            }
                                            onExited: {
                                                delegateDeviceText.font.underline = false;
                                                if (DeviceId[index] !== undefined) {
                                                    tooltipDevice.text = DeviceId[index];
                                                }
                                            }

                                            MaterialToolTip {
                                                id: tooltipDevice
                                                visible: delegateDeviceText.font.underline
                                                text: DeviceId[index] !== undefined ? DeviceId[index] : ""
                                            }
                                            onClicked: {
                                                var fullKey = DeviceId[index] !== undefined ? DeviceId[index] : "";
                                                tooltipDevice.text = fullKey + " (" + JamiStrings.logsViewCopied + ")";
                                                UtilsAdapter.setClipboardText(fullKey);
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    height: 20
                                    width: 20
                                    color: delegate.color
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: IsMobile[index] === "true"
                                    ResponsiveImage {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        source: JamiResources.phone_in_talk_24dp_svg
                                        color: JamiTheme.textColor
                                    }
                                }

                                Rectangle {
                                    id: connectionRectangle
                                    color: delegate.color
                                    height: 20
                                    Layout.preferredWidth: 130
                                    Layout.alignment: Qt.AlignVCenter
                                    property var status: Status[index]
                                    ResponsiveImage {
                                        id: connectionImage
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        rotation: connectionRectangle.status === 0 ? 0 : listview.rota
                                        source: {
                                            if (connectionRectangle.status === 0) {
                                                return JamiResources.connected_black_24dp_svg;
                                            } else {
                                                return JamiResources.connecting_black_24dp_svg;
                                            }
                                        }
                                        color: {
                                            if (connectionRectangle.status === 0) {
                                                return "#009c7f";
                                            } else {
                                                if (connectionRectangle.status === 4) {
                                                    return "red";
                                                } else {
                                                    return "#ff8100";
                                                }
                                            }
                                        }
                                    }
                                    Text {
                                        id: connectionText
                                        anchors.left: connectionImage.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 5
                                        text: if (connectionRectangle.status === 0) {
                                            return JamiStrings.connected;
                                        } else {
                                            if (connectionRectangle.status === 1) {
                                                return JamiStrings.connectingTLS;
                                            } else {
                                                if (connectionRectangle.status === 2) {
                                                    return JamiStrings.connectingICE;
                                                } else {
                                                    if (connectionRectangle.status === 3) {
                                                        return JamiStrings.connecting;
                                                    } else {
                                                        return JamiStrings.waiting;
                                                    }
                                                }
                                            }
                                        }
                                        color: connectionImage.color
                                        property var tooltipText: JamiStrings.remote.arg(RemoteAddress[index])
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onEntered: {
                                                connectionText.font.underline = true;
                                            }
                                            onExited: {
                                                connectionText.font.underline = false;
                                            }

                                            MaterialToolTip {
                                                visible: connectionText.font.underline
                                                text: connectionText.tooltipText
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: connectionTimeRect
                                    height: 20
                                    Layout.preferredWidth: 130
                                    Layout.alignment: Qt.AlignVCenter
                                    color: delegate.color
                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 10
                                        color: JamiTheme.textColor
                                        text: {
                                            if (ConnectionTime === undefined) return "";
                                            const time = ConnectionTime[index];
                                            if (time === undefined || time === "") return "";
                                            const date = new Date(parseInt(time) * 1000);
                                            const now = new Date();
                                            const diff = now - date;
                                            const oneDay = 24 * 60 * 60 * 1000;
                                            const oneHour = 60 * 60 * 1000;
                                            const oneMinute = 60 * 1000;
                                            if (diff < oneMinute) {
                                                const seconds = Math.floor(diff / 1000);
                                                return qsTr("%1 seconds ago").arg(seconds);
                                            } else if (diff < oneHour) {
                                                const minutes = Math.floor(diff / oneMinute);
                                                return qsTr("%1 minutes ago").arg(minutes);
                                            } else if (diff < oneDay) {
                                                const hours = Math.floor(diff / oneHour);
                                                return qsTr("%1 hours ago").arg(hours);
                                            } else if (diff < 7 * oneDay) {
                                                const days = Math.floor(diff / oneDay);
                                                return qsTr("%1 days ago").arg(days);
                                            } else
                                                return date.toLocaleString(Qt.locale(), Locale.ShortFormat);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Tracked members Title
                Text {
                    text: qsTr("Tracked members")
                    color: JamiTheme.textColor
                    font.weight: Font.DemiBold
                    font.pixelSize: 16
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    visible: trackedMembersList.count > 0
                }

                // Tracked members
                ListView {
                    id: trackedMembersList
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight
                    visible: count > 0

                    spacing: 5
                    cacheBuffer: 10
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: false

                    header: Rectangle {
                        color: JamiTheme.transparentColor
                        height: 45
                        width: trackedMembersList.width
                        Rectangle {
                            color: JamiTheme.connectionMonitoringHeaderColor
                            anchors.top: parent.top
                            height: 40
                            width: trackedMembersList.width

                            RowLayout {
                                anchors.fill: parent
                                Rectangle {
                                    height: 40
                                    Layout.leftMargin: 10
                                    Layout.fillWidth: true
                                    color: JamiTheme.transparentColor
                                    Text {
                                        color: JamiTheme.textColor
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: JamiStrings.contact
                                    }
                                }
                                Rectangle {
                                    width: 130
                                    height: 40
                                    color: JamiTheme.transparentColor
                                    Text {
                                        color: JamiTheme.textColor
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: JamiStrings.devices
                                    }
                                }
                            }
                        }
                    }

                    model: TrackedMembersModel

                    Component.onCompleted: {
                        TrackedMembersModel.conversationId = CurrentConversation.id
                        TrackedMembersModel.update()
                    }

                    delegate: Rectangle {
                        id: trackedDelegate
                        height: 50
                        width: trackedMembersList.width
                        color: index % 2 === 0 ? JamiTheme.connectionMonitoringTableColor1 : JamiTheme.connectionMonitoringTableColor2

                        RowLayout {
                            anchors.fill: parent
                            // Contact Info
                            Rectangle {
                                height: 50
                                Layout.leftMargin: 5
                                Layout.fillWidth: true
                                color: JamiTheme.transparentColor
                                Avatar {
                                    id: trackedAvatar
                                    anchors.left: parent.left
                                    height: 40
                                    width: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                    imageId: PeerUri
                                    mode: Avatar.Mode.Contact
                                }
                                Rectangle {
                                    anchors.left: trackedAvatar.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 50
                                    height: 40
                                    color: JamiTheme.transparentColor
                                    
                                    Text {
                                        color: JamiTheme.textColor
                                        font.bold: true
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        width: parent.width
                                        text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, PeerUri)
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        color: JamiTheme.textColor
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        width: parent.width
                                        text: UtilsAdapter.getBestIdForUri(CurrentAccount.id, PeerUri)
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        visible: UtilsAdapter.getBestIdForUri(CurrentAccount.id, PeerUri) !== UtilsAdapter.getBestNameForUri(CurrentAccount.id, PeerUri)
                                    }
                                }
                            }

                            // Count
                            Rectangle {
                                width: 130
                                height: 40
                                color: JamiTheme.transparentColor
                                Text {
                                    color: JamiTheme.textColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Count
                                }
                            }
                        }
                    }
                }
            }
        }

        Connections {
            target: CurrentConversation
            function onIdChanged() {
                ConversationStatusModel.conversationId = CurrentConversation.id
                TrackedMembersModel.conversationId = CurrentConversation.id
            }
        }

        Timer {
            interval: 2000
            running: root.visible
            repeat: true
            onTriggered: {
                ConversationStatusModel.update();
                TrackedMembersModel.update();
                listview.rota = listview.rota + 5;
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            anchors.fill: innerRect
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }
    }
}
