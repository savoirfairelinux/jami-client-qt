/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

// The services the contacts offer, each telling who offers it. Picking one opens
// a tunnel to it: a web service then opens in the browser, any other one has its
// local address copied.
BaseModalDialog {
    id: root
    objectName: "servicesDialog"

    property var service: SharedServicesAdapter
    property string accountId: CurrentAccount.id
    // The open tunnels, by contact and service
    property var tunnels: ({})
    property var failures: ({})

    signal ownServicesRequested
    signal openUrlRequested(string url)

    titleText: JamiStrings.functionServices

    function key(offered) {
        return offered.peerUri + "/" + offered.id;
    }

    function readTunnels() {
        const open = {};
        for (const tunnel of service.getActiveTunnels(accountId))
            open[tunnel.peerUri + "/" + tunnel.serviceId] = tunnel;
        tunnels = open;
    }

    function isAvailable(offered) {
        return offered.available === undefined || !!offered.available;
    }

    function isWeb(offered) {
        return offered.scheme === "http" || offered.scheme === "https";
    }

    function endpoint(offered) {
        const tunnel = tunnels[key(offered)];
        if (!tunnel)
            return "";
        const address = "127.0.0.1:" + tunnel.localPort;
        return offered.scheme ? offered.scheme + "://" + address : address;
    }

    function status(offered) {
        if (failures[key(offered)])
            return JamiStrings.sharedServicesConnectFailed;
        if (tunnels[key(offered)])
            return endpoint(offered);
        if (!isAvailable(offered))
            return JamiStrings.sharedServicesUnavailable;
        return offered.description || "";
    }

    function openTunnel(offered) {
        const preferred = Number(offered.preferredPort) || 0;
        let tunnelId = service.openServiceTunnel(accountId, offered.peerUri, offered.device || "", offered.id, offered.name, preferred);
        // A busy preferred port gives way to any port
        if (tunnelId === "" && preferred !== 0)
            tunnelId = service.openServiceTunnel(accountId, offered.peerUri, offered.device || "", offered.id, offered.name, 0);
        const copy = Object.assign({}, failures);
        if (tunnelId === "")
            copy[key(offered)] = true;
        else
            delete copy[key(offered)];
        failures = copy;
        // The daemon listens before answering: the tunnel is known right away
        readTunnels();
    }

    function activate(offered) {
        if (!tunnels[key(offered)]) {
            if (!isAvailable(offered))
                return;
            openTunnel(offered);
        }
        const address = endpoint(offered);
        if (address === "")
            return;
        if (isWeb(offered))
            openUrlRequested(address);
        else
            UtilsAdapter.setClipboardText(address);
    }

    function stop(offered) {
        const tunnel = tunnels[key(offered)];
        if (tunnel)
            service.closeServiceTunnel(accountId, tunnel.id);
        readTunnels();
    }

    Component.onCompleted: {
        readTunnels();
        service.refreshOfferedServices(accountId);
    }

    Connections {
        target: root.service
        ignoreUnknownSignals: true

        function onTunnelOpened() {
            root.readTunnels();
        }

        function onTunnelClosed() {
            root.readTunnels();
        }
    }

    popupContent: ColumnLayout {
        width: 460
        height: 500
        spacing: 10

        NewMaterialButton {
            objectName: "myServicesButton"

            Layout.alignment: Qt.AlignHCenter
            filledButton: true
            color: "#14B8A6"
            iconSource: JamiResources.settings_24dp_svg
            text: JamiStrings.myServices
            onClicked: {
                root.ownServicesRequested();
                root.close();
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                objectName: "serviceList"

                anchors.fill: parent
                clip: true
                spacing: 2
                model: root.service.offeredServices
                ScrollBar.vertical: JamiScrollBar {}

                delegate: ItemDelegate {
                    id: row

                    required property var modelData
                    readonly property bool tunnelOpen: root.tunnels[root.key(modelData)] !== undefined

                    objectName: "service-" + modelData.peerUri + "-" + modelData.id
                    width: list.width
                    height: 76
                    enabled: tunnelOpen || root.isAvailable(modelData)
                    opacity: enabled ? 1.0 : 0.5
                    Accessible.name: nameText.text + ", " + provenanceText.text

                    contentItem: RowLayout {
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 12
                            color: "#2614B8A6"

                            ResponsiveImage {
                                anchors.centerIn: parent
                                containerWidth: 22
                                containerHeight: 22
                                source: !root.isAvailable(row.modelData) ? JamiResources.globe_2_cancel_24dp_svg
                                                                         : row.modelData.scheme === "https" ? JamiResources.vpn_lock_2_24dp_svg
                                                                                                            : JamiResources.language_24dp_svg
                                color: row.tunnelOpen ? JamiTheme.sharedServicesConnectColor : "#14B8A6"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                id: nameText

                                Layout.fillWidth: true
                                text: row.modelData.name || row.modelData.id
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: JamiTheme.textColor
                                font.bold: true
                                font.pointSize: JamiTheme.textFontSize
                            }

                            Text {
                                objectName: "serviceStatus"

                                Layout.fillWidth: true
                                visible: text !== ""
                                text: root.status(row.modelData)
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: root.failures[root.key(row.modelData)] ? JamiTheme.red_ : JamiTheme.faddedLastInteractionFontColor
                                font.family: row.tunnelOpen ? JamiTheme.ubuntuMonoFontFamily : JamiTheme.ubuntuFontFamily
                                font.pointSize: JamiTheme.textFontSize
                            }

                            // Who offers it
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Avatar {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    mode: Avatar.Mode.Contact
                                    imageId: row.modelData.peerUri
                                    showPresenceIndicator: false
                                }

                                Text {
                                    id: provenanceText
                                    objectName: "serviceProvenance"

                                    Layout.fillWidth: true
                                    text: JamiStrings.serviceOfferedBy.arg(row.modelData.peerName)
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    color: JamiTheme.textColor
                                    font.pointSize: JamiTheme.textFontSize
                                }
                            }
                        }

                        NewIconButton {
                            objectName: "stopService"

                            visible: row.tunnelOpen
                            iconSource: JamiResources.stop_circle_24dp_svg
                            iconSize: JamiTheme.iconButtonMedium
                            iconColor: JamiTheme.red_
                            toolTipText: JamiStrings.sharedServicesDisconnect
                            onClicked: root.stop(row.modelData)
                        }
                    }

                    onClicked: root.activate(modelData)
                }
            }

            BusyIndicator {
                objectName: "servicesLoading"

                anchors.centerIn: parent
                visible: root.service.loadingOfferedServices && list.count === 0
                running: visible
            }

            Text {
                objectName: "noServices"

                anchors.centerIn: parent
                width: parent.width
                visible: !root.service.loadingOfferedServices && list.count === 0
                text: JamiStrings.noOfferedServices
                color: JamiTheme.faddedLastInteractionFontColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }
}
