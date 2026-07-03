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

    readonly property real panelMargin: viewCoordinator.isInSinglePaneMode
                                        ? JamiTheme.sidePanelIslandsSinglePaneModePadding
                                        : JamiTheme.sidePanelIslandsPadding
    readonly property real panelTopMargin: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding * 2

    Rectangle {
        id: shadowRect
        anchors.fill: parent
        anchors.margins: root.panelMargin
        anchors.topMargin: root.panelTopMargin

        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius

        layer.enabled: true
        layer.effect: MultiEffect {
            anchors.fill: shadowRect
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }
    }

    Rectangle {
        id: innerRect
        anchors.fill: parent
        anchors.margins: root.panelMargin
        anchors.topMargin: root.panelTopMargin

        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius

        // Panel header with title and close button
        Item {
            id: panelHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.right: closeButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: JamiStrings.swarmConnectivity
                color: JamiTheme.textColor
                font.weight: Font.DemiBold
                font.pixelSize: 16
                elide: Text.ElideRight
            }

            NewIconButton {
                id: closeButton
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                iconSize: root.iconButtonSize
                iconSource: JamiResources.round_close_24dp_svg
                backgroundColor: JamiTheme.transparentColor
                iconColor: JamiTheme.textColor
                toolTipText: JamiStrings.close
                onClicked: extrasPanel.switchToPanel(ChatView.SwarmDetailsPanel)
            }
        }

        ScrollView {
            id: scrollView
            anchors.top: panelHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true

            ColumnLayout {
                width: scrollView.availableWidth
                spacing: 16

                // Routing table
                Item {
                    id: routingSection
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.topMargin: 8
                    Layout.preferredHeight: visible ? routingHeader.height + listview.contentHeight : 0
                    visible: listview.count > 0

                    Item {
                        id: routingHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: listview.rowHeight

                        RowLayout {
                            anchors.fill: parent
                            spacing: listview.colSpacing

                            Text {
                                Layout.fillWidth: true
                                text: JamiStrings.device
                                color: JamiTheme.textColor
                                opacity: 0.6
                                font.weight: Font.DemiBold
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Item {
                                Layout.preferredWidth: listview.connectionColWidth
                            }

                            Text {
                                Layout.preferredWidth: listview.timeColWidth
                                text: JamiStrings.connectionTime
                                color: JamiTheme.textColor
                                opacity: 0.6
                                font.weight: Font.DemiBold
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                    }

                    ListView {
                        id: listview
                        anchors.top: routingHeader.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: contentHeight

                        spacing: 0
                        cacheBuffer: 10

                        boundsBehavior: Flickable.StopAtBounds
                        interactive: false

                        readonly property int colSpacing: 10
                        readonly property int connectionColWidth: 40
                        readonly property int timeColWidth: 104
                        readonly property int rowHeight: 34

                        model: ConversationStatusModel

                        Component.onCompleted: {
                            ConversationStatusModel.conversationId = CurrentConversation.id;
                            ConversationStatusModel.update();
                        }

                        delegate: Item {
                            id: nodeDelegate
                            width: listview.width
                            height: Count === 0 ? 0 : listview.rowHeight * Count

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
                                    readonly property string connLabel: {
                                        switch (connStatus) {
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

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: listview.colSpacing

                                        // Device id (+ mobile marker)
                                        Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            Row {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width
                                                spacing: 6

                                                ResponsiveImage {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    visible: IsMobile[index] === "true"
                                                    width: visible ? 18 : 0
                                                    height: 18
                                                    source: JamiResources.phone_in_talk_24dp_svg
                                                    color: JamiTheme.textColor
                                                }

                                                Text {
                                                    id: delegateDeviceText
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: parent.width - (IsMobile[index] === "true" ? 24 : 0)
                                                    text: DeviceId[index] !== undefined ? DeviceId[index] : ""
                                                    color: deviceMouse.containsMouse ? JamiTheme.textColorHovered : JamiTheme.textColor
                                                    font.family: JamiTheme.ubuntuMonoFontFamily
                                                    font.pixelSize: 12
                                                    elide: Text.ElideMiddle
                                                }
                                            }

                                            MouseArea {
                                                id: deviceMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onExited: tooltipDevice.text = delegateDeviceText.text
                                                onClicked: {
                                                    var fullKey = DeviceId[index] !== undefined ? DeviceId[index] : "";
                                                    tooltipDevice.text = fullKey + " (" + JamiStrings.logsViewCopied + ")";
                                                    UtilsAdapter.setClipboardText(fullKey);
                                                }

                                                MaterialToolTip {
                                                    id: tooltipDevice
                                                    visible: deviceMouse.containsMouse
                                                    text: DeviceId[index] !== undefined ? DeviceId[index] : ""
                                                    toolTipFont: JamiTheme.ubuntuMonoFontFamily
                                                }
                                            }
                                        }

                                        // Connection state (icon only)
                                        Item {
                                            Layout.preferredWidth: listview.connectionColWidth
                                            Layout.fillHeight: true

                                            Rectangle {
                                                id: statusBadge
                                                anchors.centerIn: parent
                                                width: 28
                                                height: 28
                                                radius: width / 2
                                                color: Qt.rgba(deviceRow.connColor.r, deviceRow.connColor.g, deviceRow.connColor.b, 0.14)

                                                ResponsiveImage {
                                                    id: connectionImage
                                                    anchors.centerIn: parent
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

                                                MouseArea {
                                                    id: statusMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true

                                                    MaterialToolTip {
                                                        visible: statusMouse.containsMouse
                                                        text: deviceRow.connLabel + " \u00b7 " + JamiStrings.remote.arg(RemoteAddress[index])
                                                        toolTipFont: JamiTheme.ubuntuMonoFontFamily
                                                    }
                                                }
                                            }
                                        }

                                        // Connection time
                                        Item {
                                            Layout.preferredWidth: listview.timeColWidth
                                            Layout.fillHeight: true

                                            Text {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width
                                                color: JamiTheme.textColor
                                                opacity: 0.8
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                text: {
                                                    if (ConnectionTime === undefined)
                                                        return "";
                                                    const time = ConnectionTime[index];
                                                    if (time === undefined || time === "")
                                                        return "";
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
                    }
                }

                // Searched contacts
                Item {
                    id: trackedMembersSection
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 16
                    Layout.preferredHeight: visible ? trackedMembersHeader.height + trackedMembersList.contentHeight : 0
                    visible: trackedMembersList.count > 0

                    Item {
                        id: trackedMembersHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 34

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            Text {
                                Layout.fillWidth: true
                                text: JamiStrings.searchedContact
                                color: JamiTheme.textColor
                                opacity: 0.6
                                font.weight: Font.DemiBold
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 60
                                horizontalAlignment: Text.AlignRight
                                text: JamiStrings.devices
                                color: JamiTheme.textColor
                                opacity: 0.6
                                font.weight: Font.DemiBold
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                    }

                    ListView {
                        id: trackedMembersList
                        anchors.top: trackedMembersHeader.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: contentHeight

                        spacing: 0
                        cacheBuffer: 10
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: false

                        readonly property int rowHeight: 52

                        model: TrackedMembersModel

                        Component.onCompleted: {
                            TrackedMembersModel.conversationId = CurrentConversation.id;
                            TrackedMembersModel.update();
                        }

                        delegate: Item {
                            id: trackedDelegate
                            width: trackedMembersList.width
                            height: trackedMembersList.rowHeight

                            RowLayout {
                                anchors.fill: parent
                                spacing: 10

                                // Contact info
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        spacing: 10

                                        Avatar {
                                            id: trackedAvatar
                                            width: 38
                                            height: 38
                                            anchors.verticalCenter: parent.verticalCenter
                                            imageId: PeerUri
                                            mode: Avatar.Mode.Contact
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - trackedAvatar.width - parent.spacing
                                            spacing: 2

                                            Text {
                                                width: parent.width
                                                color: JamiTheme.textColor
                                                font.weight: Font.DemiBold
                                                font.pixelSize: 14
                                                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, PeerUri)
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                color: JamiTheme.textColor
                                                opacity: 0.55
                                                font.pixelSize: 12
                                                text: UtilsAdapter.getBestIdForUri(CurrentAccount.id, PeerUri)
                                                elide: Text.ElideRight
                                                visible: UtilsAdapter.getBestIdForUri(CurrentAccount.id, PeerUri) !== UtilsAdapter.getBestNameForUri(CurrentAccount.id, PeerUri)
                                            }
                                        }
                                    }
                                }

                                // Devices count
                                Text {
                                    Layout.preferredWidth: 60
                                    Layout.fillHeight: true
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    color: JamiTheme.textColor
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
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
                ConversationStatusModel.conversationId = CurrentConversation.id;
                TrackedMembersModel.conversationId = CurrentConversation.id;
            }
        }

        Timer {
            interval: 2000
            running: root.visible
            repeat: true
            onTriggered: {
                ConversationStatusModel.update();
                TrackedMembersModel.update();
            }
        }

    }
}
