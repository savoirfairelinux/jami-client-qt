import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Item {
    id: root

    property bool active: true
    property string accountId: ""
    property string peerUri: ""
    property int pendingRequestId: 0
    property var services: []
    property var openTunnels: ({})
    property var pendingOpens: ({})
    property bool completed: false

    visible: active && services.length > 0
    implicitWidth: servicesButton.implicitWidth
    implicitHeight: servicesButton.implicitHeight

    function refresh() {
        servicesPopup.close();
        openTunnels = ({});
        pendingOpens = ({});
        if (!active || !accountId || !peerUri) {
            services = [];
            pendingRequestId = 0;
            return;
        }
        services = [];
        pendingRequestId = ExposedServicesAdapter.queryPeerServices(accountId, peerUri);
    }

    function scheduleRefresh() {
        if (completed)
            refresh();
    }

    function serviceName(service) {
        return service.name || service.id || "";
    }

    function tunnelFor(service) {
        return openTunnels[service.id];
    }

    function isHttpService(service) {
        var scheme = service.scheme || "";
        return scheme === "http" || scheme === "https";
    }

    function localEndpoint(service) {
        var tunnel = tunnelFor(service);
        return tunnel ? "127.0.0.1:" + tunnel.localPort : "";
    }

    function openTunnel(service) {
        var pending = Object.assign({}, pendingOpens);
        pending[service.id] = {
            claimed: false,
            scheme: service.scheme || ""
        };
        pendingOpens = pending;
        ExposedServicesAdapter.openServiceTunnel(accountId, peerUri, service.device || "", service.id, serviceName(service), 0);
    }

    function activateService(service) {
        var tunnel = tunnelFor(service);
        if (tunnel) {
            if (isHttpService(service))
                Qt.openUrlExternally(tunnel.scheme + "://127.0.0.1:" + tunnel.localPort);
            else
                UtilsAdapter.setClipboardText(localEndpoint(service));
            return;
        }
        openTunnel(service);
    }

    onActiveChanged: scheduleRefresh()
    onAccountIdChanged: scheduleRefresh()
    onPeerUriChanged: scheduleRefresh()
    Component.onCompleted: {
        completed = true;
        refresh();
    }

    Connections {
        target: ExposedServicesAdapter

        function onPeerServicesReceived(requestId, accountId, peerId, status, services) {
            if (requestId !== root.pendingRequestId)
                return;
            if (accountId !== root.accountId || peerId !== root.peerUri)
                return;
            root.services = status === ExposedServicesAdapter.PeerServicesStatus.OK ? services : [];
        }

        function onTunnelOpened(accountId, tunnelId, localPort) {
            if (accountId !== root.accountId)
                return;
            for (var serviceId in root.pendingOpens) {
                if (root.pendingOpens[serviceId].claimed)
                    continue;
                var copy = Object.assign({}, root.openTunnels);
                copy[serviceId] = {
                    tunnelId: tunnelId,
                    localPort: localPort,
                    scheme: root.pendingOpens[serviceId].scheme || ""
                };
                root.openTunnels = copy;
                root.pendingOpens[serviceId].claimed = true;
                var scheme = root.pendingOpens[serviceId].scheme || "";
                if (scheme === "http" || scheme === "https")
                    Qt.openUrlExternally(scheme + "://127.0.0.1:" + localPort);
                break;
            }
        }

        function onTunnelClosed(accountId, tunnelId, reason) {
            if (accountId !== root.accountId)
                return;
            for (var serviceId in root.openTunnels) {
                if (root.openTunnels[serviceId].tunnelId === tunnelId) {
                    var copy = Object.assign({}, root.openTunnels);
                    delete copy[serviceId];
                    root.openTunnels = copy;
                    break;
                }
            }
        }
    }

    NewIconButton {
        id: servicesButton

        anchors.centerIn: parent
        iconSize: JamiTheme.iconButtonMedium
        iconSource: JamiResources.planet_24dp_svg
        toolTipText: JamiStrings.peerServicesSectionTitle

        onClicked: servicesPopup.open()
    }

    Popup {
        id: servicesPopup

        parent: root
        x: root.width - width
        y: root.height + JamiTheme.qwkTitleBarHeight / 2
        width: 300
        padding: 1

        contentItem: ListView {
            id: servicesListView

            clip: true
            implicitHeight: Math.min(contentHeight, 320)
            model: root.services

            delegate: ItemDelegate {
                id: serviceDelegate

                required property var modelData

                width: ListView.view.width
                height: Math.max(64, serviceContent.implicitHeight + 16)
                topInset: 4
                leftInset: 4
                rightInset: 4
                bottomInset: 4
                topPadding: topInset * 2
                leftPadding: leftInset * 2
                rightPadding: rightInset * 2
                bottomPadding: bottomInset * 2

                contentItem: RowLayout {
                    id: serviceContent

                    spacing: 10

                    Button {
                        Layout.preferredWidth: background.width
                        Layout.preferredHeight: background.height
                        Layout.leftMargin: 2
                        Layout.alignment: Qt.AlignVCenter
                        enabled: false

                        icon.width: JamiTheme.iconButtonMedium
                        icon.height: JamiTheme.iconButtonMedium
                        icon.color: JamiTheme.textColor
                        icon.source: root.isHttpService(serviceDelegate.modelData) ? JamiResources.captive_portal_24dp_svg : JamiResources.play_circle_outline_24dp_svg

                        background: Rectangle {
                            width: icon.width + (icon.width / 2)
                            height: icon.height + (icon.height / 2)
                            radius: height / 2
                            color: serviceDelegate.hovered ? JamiTheme.buttonCallDarkGreen : JamiTheme.buttonCallLightGreen

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: root.serviceName(serviceDelegate.modelData)
                            color: JamiTheme.textColor
                            font.pixelSize: JamiTheme.textFontSize
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.tunnelFor(serviceDelegate.modelData) ? JamiStrings.peerServiceTunnelOpened.arg(root.localEndpoint(serviceDelegate.modelData)) : (serviceDelegate.modelData.description || serviceDelegate.modelData.scheme || "")
                            color: JamiTheme.textColor
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    NewIconButton {
                        visible: root.tunnelFor(serviceDelegate.modelData) !== undefined
                        Layout.alignment: Qt.AlignVCenter
                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: JamiResources.stop_circle_24dp_svg
                        color: JamiTheme.buttonTintedRed
                        hoveredColor: JamiTheme.buttonTintedRedHovered
                        pressedColor: JamiTheme.buttonTintedRedPressed
                        toolTipText: JamiStrings.peerServiceCloseTunnel
                        onClicked: {
                            var tunnel = root.tunnelFor(serviceDelegate.modelData);
                            if (tunnel)
                                ExposedServicesAdapter.closeServiceTunnel(root.accountId, tunnel.tunnelId);
                        }
                    }
                }

                background: Rectangle {
                    radius: height / 2
                    color: serviceDelegate.hovered ? JamiTheme.smartListHoveredColor : JamiTheme.globalIslandColor

                    Behavior on color {
                        ColorAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }

                onClicked: {
                    root.activateService(modelData);
                    if (!root.tunnelFor(modelData) || root.isHttpService(modelData))
                        servicesPopup.close();
                }
            }
        }

        background: Rectangle {
            radius: 25
            color: JamiTheme.globalIslandColor
        }
    }
}
