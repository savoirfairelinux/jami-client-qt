/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import "../../commoncomponents"

/*!
 * Embedded section listing the network services that a remote peer
 * exposes to the local account, with controls to open a local TCP
 * tunnel to each one.
 */
ColumnLayout {
    id: root

    property string accountId: ""
    property string peerUri: ""

    // Set when a query is sent; updated when the matching response arrives.
    property int pendingRequestId: 0
    // List of {id,name,description,proto} entries, or [] when none/unknown.
    property var services: []
    // Map: serviceId -> {tunnelId, localPort, deviceId}.
    property var openTunnels: ({})
    property bool loading: false
    // Last terminal status reported by the daemon for this peer query.
    // -1 means "no result yet for the current refresh".
    property int lastStatus: -1

    function refresh() {
        if (!accountId || !peerUri)
            return;
        services = [];
        loading = true;
        lastStatus = -1;
        pendingRequestId = ExposedServicesAdapter.queryPeerServices(accountId, peerUri);
    }

    function statusMessage() {
        switch (lastStatus) {
        case ExposedServicesAdapter.PeerServicesStatus.OK:
            return JamiStrings.peerServicesEmpty;
        case ExposedServicesAdapter.PeerServicesStatus.NoDevices:
            return JamiStrings.peerServicesNoDevices;
        case ExposedServicesAdapter.PeerServicesStatus.Unreachable:
            return JamiStrings.peerServicesUnreachable;
        case ExposedServicesAdapter.PeerServicesStatus.Timeout:
            return JamiStrings.peerServicesTimeout;
        case ExposedServicesAdapter.PeerServicesStatus.InternalError:
            return JamiStrings.peerServicesInternalError;
        }
        return "";
    }

    function pickFirstDeviceForPeer() {
        // The daemon-side openServiceTunnel resolves the device on its own
        // when given an empty deviceId, but the API requires a string. We
        // pass an empty value here as a placeholder; a future iteration
        // could surface a per-device chooser.
        return "";
    }

    spacing: 8

    onAccountIdChanged: refresh()
    onPeerUriChanged: refresh()
    Component.onCompleted: refresh()

    Connections {
        target: ExposedServicesAdapter

        function onPeerServicesReceived(requestId, accountId, peerId, status, services) {
            if (requestId !== root.pendingRequestId)
                return;
            if (accountId !== root.accountId || peerId !== root.peerUri)
                return;
            root.loading = false;
            root.lastStatus = status;
            root.services = services;
        }

        function onTunnelOpened(accountId, tunnelId, localPort) {
            // Match the freshly opened tunnel back to the service that
            // requested it. We track the last-requested serviceId in a
            // pending map and resolve on first matching open event.
            for (var sid in root.pendingOpens) {
                if (root.pendingOpens[sid].claimed)
                    continue;
                var copy = Object.assign({}, root.openTunnels);
                copy[sid] = {
                    tunnelId: tunnelId,
                    localPort: localPort
                };
                root.openTunnels = copy;
                root.pendingOpens[sid].claimed = true;
                break;
            }
        }

        function onTunnelClosed(accountId, tunnelId, reason) {
            for (var sid in root.openTunnels) {
                if (root.openTunnels[sid].tunnelId === tunnelId) {
                    var copy = Object.assign({}, root.openTunnels);
                    delete copy[sid];
                    root.openTunnels = copy;
                    break;
                }
            }
        }
    }

    // Tracks openServiceTunnel calls awaiting the matching tunnelOpened.
    property var pendingOpens: ({})

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: JamiStrings.peerServicesSectionTitle
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.textFontSize
            font.weight: Font.DemiBold
        }

        BusyIndicator {
            visible: root.loading
            running: visible
            implicitHeight: 18
            implicitWidth: 18
        }

        Button {
            visible: !root.loading
            flat: true
            text: JamiStrings.peerServicesRefresh
            onClicked: root.refresh()
        }
    }

    Text {
        visible: !root.loading && root.services.length === 0 && root.lastStatus !== -1
        Layout.fillWidth: true
        text: root.statusMessage()
        color: JamiTheme.faddedFontColor
        font.italic: true
        font.pixelSize: JamiTheme.textFontSize - 1
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: root.services

        delegate: Rectangle {
            id: serviceRow

            required property var modelData

            Layout.fillWidth: true
            implicitHeight: rowLayout.implicitHeight + 12
            radius: 5
            color: JamiTheme.editBackgroundColor

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: serviceRow.modelData.name
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.textFontSize
                        font.weight: Font.Medium
                    }

                    Text {
                        visible: text.length > 0
                        text: serviceRow.modelData.description || ""
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.textFontSize - 2
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.openTunnels[serviceRow.modelData.id] !== undefined
                        text: JamiStrings.peerServiceTunnelOpened.arg("127.0.0.1:" + (root.openTunnels[serviceRow.modelData.id] ? root.openTunnels[serviceRow.modelData.id].localPort : ""))
                        color: JamiTheme.tintedBlue
                        font.family: JamiTheme.ubuntuMonoFontFamily
                        font.pixelSize: JamiTheme.textFontSize - 2
                    }
                }

                Button {
                    visible: root.openTunnels[serviceRow.modelData.id] === undefined
                    text: JamiStrings.peerServiceOpenTunnel
                    onClicked: {
                        var pending = Object.assign({}, root.pendingOpens);
                        pending[serviceRow.modelData.id] = {
                            claimed: false
                        };
                        root.pendingOpens = pending;
                        ExposedServicesAdapter.openServiceTunnel(root.accountId, root.peerUri, root.pickFirstDeviceForPeer(), serviceRow.modelData.id, serviceRow.modelData.name, 0);
                    }
                }

                Button {
                    visible: root.openTunnels[serviceRow.modelData.id] !== undefined
                    text: JamiStrings.peerServiceCloseTunnel
                    onClicked: {
                        var t = root.openTunnels[serviceRow.modelData.id];
                        if (t)
                            ExposedServicesAdapter.closeServiceTunnel(root.accountId, t.tunnelId);
                    }
                }
            }
        }
    }
}
