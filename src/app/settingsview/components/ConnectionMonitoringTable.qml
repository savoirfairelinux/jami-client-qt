/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
import "../js/logviewwindowcreation.js" as LogViewWindowCreation

ListView {
    id: listview
    height: contentItem.childrenRect.height
    anchors.top: parent.top
    anchors.topMargin: 10
    width: parent.width

    spacing: 5
    cacheBuffer: 10

    property int rota: 0

    header: Rectangle {
        color: JamiTheme.transparentColor
        height: 55
        width: connectionMonitoringTable.width
        Rectangle {
            color: JamiTheme.connectionMonitoringHeaderColor
            anchors.top: parent.top
            height: 50
            width: connectionMonitoringTable.width

            RowLayout {
                anchors.fill: parent
                Rectangle {
                    id: profile
                    height: 50
                    Layout.leftMargin: 5
                    Layout.preferredWidth: 200
                    color: JamiTheme.transparentColor
                    Text {
                        id: textImage
                        color: JamiTheme.textColor
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: JamiStrings.contact
                    }
                }

                Rectangle {
                    id: device
                    Layout.fillWidth: true
                    Layout.minimumWidth: 50
                    height: 50
                    color: JamiTheme.transparentColor
                    Text {
                        id: deviceText
                        color: JamiTheme.textColor
                        anchors.verticalCenter: parent.verticalCenter
                        text: JamiStrings.device
                    }
                }

                Rectangle {
                    id: connection
                    width: 130
                    height: 50
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
                    id: channel
                    height: 50
                    width: 70
                    color: JamiTheme.transparentColor
                    Text {
                        color: JamiTheme.textColor
                        anchors.verticalCenter: parent.verticalCenter
                        text: JamiStrings.channels
                    }
                }
            }
        }
    }

    model: ConnectionInfoListModel

    Component.onCompleted: {
        ContactAdapter.updateConnectionInfo();
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: {
            ContactAdapter.updateConnectionInfo();
            listview.rota = listview.rota + 5;
        }
    }

    delegate: Rectangle {
        id: delegate
        height: Count == 0 ? 0 : 10 + 40 * Count
        width: connectionMonitoringTable.width
        color: index % 2 === 0 ? JamiTheme.connectionMonitoringTableColor1 : JamiTheme.connectionMonitoringTableColor2

        ListView {
            id: listView2
            height: 40 * Count
            width: parent.width

            anchors.top: delegate.top

            spacing: 0

            model: Count

            delegate: RowLayout {
                id: rowLayoutDelegate
                height: 40
                width: connectionMonitoringTable.width

                Rectangle {
                    id: profile
                    height: 50
                    Layout.leftMargin: 5
                    Layout.preferredWidth: 200
                    color: JamiTheme.transparentColor
                    Avatar {
                        id: avatar
                        visible: index == 0
                        anchors.left: parent.left
                        height: 40
                        width: 40
                        anchors.verticalCenter: parent.verticalCenter
                        imageId: PeerId
                        mode: Avatar.Mode.Contact
                    }
                    Rectangle {
                        id: usernameRect
                        anchors.left: avatar.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: profile.width - 50
                        height: 40
                        color: JamiTheme.transparentColor

                        Rectangle {
                            id: usernameRect2
                            visible: index == 0
                            width: profile.width - 50
                            height: 20
                            anchors.leftMargin: 10
                            anchors.top: parent.top
                            anchors.left: parent.left
                            color: JamiTheme.transparentColor

                            Text {
                                id: usernameText
                                color: JamiTheme.textColor
                                anchors.fill: parent
                                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, PeerId)
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            width: profile.width - 50
                            height: 20
                            anchors.leftMargin: 10
                            anchors.top: usernameRect2.bottom
                            anchors.left: parent.left
                            visible: usernameRect2.visible && (UtilsAdapter.getBestIdForUri(CurrentAccount.id, PeerId) != UtilsAdapter.getBestNameForUri(CurrentAccount.id, PeerId))
                            color: JamiTheme.transparentColor

                            Text {
                                id: idText
                                color: JamiTheme.textColor
                                anchors.fill: parent
                                text: UtilsAdapter.getBestIdForUri(CurrentAccount.id, PeerId)
                                font.pixelSize: 12
                                font.underline: usernameText.font.underline
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                usernameText.font.underline = true;
                                tooltipContact.text = JamiStrings.copyAllData;
                            }
                            onExited: {
                                usernameText.font.underline = false;
                                tooltipContact.text = JamiStrings.copyAllData;
                            }

                            MaterialToolTip {
                                id: tooltipContact
                                visible: usernameText.font.underline
                                text: JamiStrings.copyAllData
                            }
                            onClicked: {
                                tooltipContact.text = JamiStrings.logsViewCopied;
                                UtilsAdapter.setClipboardText(ConnectionDatas);
                            }
                        }
                    }
                }

                Rectangle {
                    height: 40
                    Layout.fillWidth: true
                    Layout.minimumWidth: 50
                    color: delegate.color
                    Text {
                        id: delegateDeviceText
                        color: JamiTheme.textColor
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        text: {
                            if (DeviceId[index] != undefined) {
                                return DeviceId[index];
                            } else {
                                return "";
                            }
                        }
                        elide: Text.ElideMiddle
                        width: parent.width - 10
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                delegateDeviceText.font.underline = true;
                            }
                            onExited: {
                                delegateDeviceText.font.underline = false;
                                tooltipDevice.text = delegateDeviceText.text;
                            }

                            MaterialToolTip {
                                id: tooltipDevice
                                visible: delegateDeviceText.font.underline
                                text: delegateDeviceText.text
                            }
                            onClicked: {
                                tooltipDevice.text = delegateDeviceText.text + " (" + JamiStrings.logsViewCopied + ")";
                                UtilsAdapter.setClipboardText(delegateDeviceText.text);
                            }
                        }
                    }
                }

                Rectangle {
                    id: connectionRectangle
                    color: delegate.color
                    height: 40
                    Layout.preferredWidth: 130
                    property var status: Status[index]
                    ResponsiveImage {
                        id: connectionImage
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        rotation: connectionRectangle.status == 0 ? 0 : listview.rota
                        source: {
                            if (connectionRectangle.status == 0) {
                                return JamiResources.connected_black_24dp_svg;
                            } else {
                                return JamiResources.connecting_black_24dp_svg;
                            }
                        }
                        color: {
                            if (connectionRectangle.status == 0) {
                                return "#009c7f";
                            } else {
                                if (connectionRectangle.status == 4) {
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
                        text: if (connectionRectangle.status == 0) {
                            return JamiStrings.connected;
                        } else {
                            if (connectionRectangle.status == 1) {
                                return JamiStrings.connectingTLS;
                            } else {
                                if (connectionRectangle.status == 2) {
                                    return JamiStrings.connectingICE;
                                } else {
                                    if (connectionRectangle.status == 3) {
                                        return JamiStrings.connecting;
                                    } else {
                                        return JamiStrings.waiting;
                                    }
                                }
                            }
                        }
                        color: connectionImage.color
                        property var tooltipText: JamiStrings.remote + RemoteAddress[index]
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
                    id: channelDelegateRectangle
                    height: 40
                    Layout.preferredWidth: 70
                    color: delegate.color
                    Text {
                        id: channelText
                        color: JamiTheme.textColor
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.left: parent.left
                        text: {
                            if (Channels[index] != undefined) {
                                return Channels[index];
                            } else {
                                return "";
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onExited: {
                                channelText.font.underline = false;
                            }

                            onEntered: {
                                channelText.font.underline = true;
                            }

                            onClicked: {
                                var output = "";
                                var channelMap = ChannelsMap[index];
                                for (var key in channelMap) {
                                    var value = channelMap[key];
                                    var keyHexa = parseInt(key, 16).toString();
                                    output += keyHexa + " : " + value + "\n";
                                }
                                viewCoordinator.presentDialog(parent, "settingsview/components/ChannelsPopup.qml", {
                                        "text": output,
                                        "maxWidth": connectionMonitoringTable.width
                                    });
                            }
                        }
                    }
                }
            }
        }
    }
}
