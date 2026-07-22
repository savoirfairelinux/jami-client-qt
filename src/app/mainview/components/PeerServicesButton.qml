import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.impl


import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ComboBox {
    id: root

    property bool active: true
    property string accountId: ""
    property string peerUri: ""
    property int pendingRequestId: 0
    property var services: []
    property var openTunnels: ({})
    property var pendingOpens: ({})
    property var connectErrors: ({})
    property bool completed: false

    function refresh() {
        servicesPopup.close();
        pendingOpens = ({});
        connectErrors = ({});
        if (!active || !accountId || !peerUri) {
            openTunnels = ({});
            services = [];
            pendingRequestId = 0;
            return;
        }
        // Tunnels live in the daemon and outlive this view, so restore the
        // ones still open for this peer instead of dropping them. This keeps
        // the tunnel state from being lost when switching conversation away
        // and back.
        restoreActiveTunnels();
        services = [];
        pendingRequestId = SharedServicesAdapter.queryPeerServices(accountId, peerUri);
    }

    // Rebuild openTunnels from the daemon's authoritative active-tunnel list,
    // keeping only the tunnels that belong to the current peer.
    function restoreActiveTunnels() {
        const restored = ({});
        if (active && accountId && peerUri) {
            const tunnels = SharedServicesAdapter.getActiveTunnels(accountId);
            tunnels.forEach(tunnel => {
                if (tunnel.peerUri === peerUri)
                    restored[tunnel.serviceId] = {
                        tunnelId: tunnel.id,
                        localPort: tunnel.localPort,
                        scheme: ""
                    };
            });
        }
        openTunnels = restored;
    }

    // Re-query availability without tearing down the popup or open tunnels.
    function requeryServices() {
        if (!active || !accountId || !peerUri)
            return;
        pendingRequestId = SharedServicesAdapter.queryPeerServices(accountId, peerUri);
    }

    function scheduleRefresh() {
        if (completed)
            refresh();
    }

    function serviceName(service) {
        return service.name || service.id || "";
    }

    function isAvailable(service) {
        return service.available === undefined ? true : !!service.available;
    }

    function flagConnectError(serviceId) {
        var copy = Object.assign({}, connectErrors);
        copy[serviceId] = true;
        connectErrors = copy;
        connectErrorTimer.restart();
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

    // Secondary line under the service name: transient error, live tunnel
    // endpoint, offline notice, or the service description.
    function serviceStatusText(service) {
        if (connectErrors[service.id])
            return JamiStrings.sharedServicesConnectFailed;
        if (tunnelFor(service) !== undefined) {
            var endpoint = localEndpoint(service);
            return service.scheme ? service.scheme + "://" + endpoint : endpoint;
        }
        if (!isAvailable(service))
            return JamiStrings.sharedServicesUnavailable;
        return service.description || "";
    }

    function openTunnel(service) {
        var pending = Object.assign({}, pendingOpens);
        pending[service.id] = {
            claimed: false,
            scheme: service.scheme || ""
        };
        pendingOpens = pending;
        SharedServicesAdapter.openServiceTunnel(accountId, peerUri, service.device || "", service.id, serviceName(service), 0);
    }

    function activateService(service) {
        var tunnel = tunnelFor(service);
        if (!tunnel)
            openTunnel(service);
    }

    function openOrCopy(service)  {
        if (isHttpService(service)) {
            var dlg = viewCoordinator.presentDialog(appWindow, "../../commoncomponents/ConfirmDialog.qml", {
                                                        "titleText": JamiStrings.openExternalLink,
                                                        "textLabel": JamiStrings.confirmNavigationDescription,
                                                        "confirmLabel": JamiStrings.open
                                                    });
            dlg.accepted.connect(function() {
                Qt.openUrlExternally(service.scheme + "://" + localEndpoint(service));
            });
        } else {
            UtilsAdapter.setClipboardText(localEndpoint(service));
        }
    }

    onActiveChanged: scheduleRefresh()
    onAccountIdChanged: scheduleRefresh()
    onPeerUriChanged: scheduleRefresh()
    Component.onCompleted: {
        completed = true;
        refresh();
    }

    Timer {
        id: connectErrorTimer
        interval: 4000
        onTriggered: root.connectErrors = ({})
    }

    Connections {
        target: SharedServicesAdapter

        function onPeerServicesReceived(requestId, accountId, peerId, status, services) {
            if (accountId !== root.accountId || peerId !== root.peerUri)
                return;
            if (requestId === 0) {
                // Unsolicited availability/cache update push for this peer.
                if (status === SharedServicesAdapter.PeerServicesStatus.OK)
                    root.services = services;
                return;
            }
            if (requestId !== root.pendingRequestId)
                return;
            root.services = status === SharedServicesAdapter.PeerServicesStatus.OK ? services : [];
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
                    if (reason !== "closed")
                        root.flagConnectError(serviceId);
                    break;
                }
            }
        }
    }

    implicitWidth: root.background.implicitWidth
    implicitHeight: root.background.implicitHeight

    padding: 0

    model: root.services

    visible: active && services.length > 0

    delegate: ItemDelegate {
        id: serviceDelegate

        required property var modelData
        required property int index

        width: ListView.view.width
        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding,
                                 implicitIndicatorHeight + topPadding + bottomPadding)

        padding: 4

        highlighted: root.highlightedIndex === index

        enabled: root.isAvailable(serviceDelegate.modelData) || root.tunnelFor(serviceDelegate.modelData) !== undefined
        opacity: enabled ? 1.0 : 0.5

        contentItem: RowLayout {
            spacing: 8

            IconImage {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 6
                Layout.topMargin: 6
                Layout.bottomMargin: 6

                width: JamiTheme.iconButtonMedium
                height: JamiTheme.iconButtonMedium

                source: {
                    if (!root.isAvailable(serviceDelegate.modelData)) {
                        return JamiResources.globe_2_cancel_24dp_svg;
                    } else if (serviceDelegate.modelData.scheme === "https") {
                        return JamiResources.vpn_lock_2_24dp_svg;
                    } else {
                        return JamiResources.language_24dp_svg;
                    }
                }

                sourceSize.width: JamiTheme.iconButtonMedium
                sourceSize.height: JamiTheme.iconButtonMedium

                color: root.tunnelFor(serviceDelegate.modelData) !== undefined ? JamiTheme.sharedServicesConnectColor : JamiTheme.buttonTintedGreyHovered
            }

            Column {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.rightMargin: openOrCopyButton.visible ? 0 : serviceDelegate.background.radius

                Text {
                    width: parent.width

                    text: serviceDelegate.modelData.name
                    elide: Text.ElideRight
                    color: JamiTheme.textColor

                    font.pixelSize: JamiTheme.sharedServicesDelegateTitlePixelSize
                }

                Text {
                    width: parent.width

                    text: root.serviceStatusText(serviceDelegate.modelData)
                    elide: Text.ElideRight
                    color: root.connectErrors[serviceDelegate.modelData.id] ? JamiTheme.red_ : JamiTheme.textColor

                    font.pixelSize: JamiTheme.sharedServicesDelegateDescriptionPixelSize
                    font.family: root.tunnelFor(serviceDelegate.modelData) !== undefined ? JamiTheme.ubuntuMonoFontFamily : JamiTheme.ubuntuFontFamily
                    font.italic: root.tunnelFor(serviceDelegate.modelData) === undefined

                    visible: text.length > 0
                }
            }

            NewIconButton {
                id: openOrCopyButton

                Layout.alignment: Qt.AlignVCenter

                iconSource: JamiResources.stop_circle_24dp_svg
                iconSize: JamiTheme.iconButtonMedium
                iconColor: JamiTheme.red_
                toolTipText: JamiStrings.sharedServicesDisconnect

                background: null

                visible: root.tunnelFor(serviceDelegate.modelData) !== undefined

                scale: hovered ? 1.1 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }

                onClicked: {
                    var tunnel = root.tunnelFor(serviceDelegate.modelData);
                    if (tunnel)
                        SharedServicesAdapter.closeServiceTunnel(root.accountId, tunnel.tunnelId);
                }
            }
        }

        background: Rectangle {
            radius: height / 2

            color: serviceDelegate.enabled && (serviceDelegate.hovered || serviceDelegate.activeFocus || serviceDelegate.highlighted)
                   ? JamiTheme.smartListHoveredColor
                   : JamiTheme.globalIslandColor

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

        onClicked: {
            if (root.tunnelFor(serviceDelegate.modelData) === undefined) {
                root.activateService(modelData);
            }

            root.openOrCopy(modelData)
        }

        MaterialToolTip {
            parent: parent

            text: {
                var service = serviceDelegate.modelData;
                if (root.tunnelFor(service) !== undefined) {
                    if (root.isHttpService(service))
                        return JamiStrings.sharedServicesOpenInExternalBrowser;
                    return JamiStrings.copy;
                }
                if (!root.isAvailable(service))
                    return "";
                return JamiStrings.sharedServicesConnect;
            }

            visible: (serviceDelegate.hovered || serviceDelegate.activeFocus) && !openOrCopyButton.hovered && (text.length > 0)
            delay: Qt.styleHints.mousePressAndHoldInterval
        }
    }

    indicator: null

    contentItem: IconImage {
        anchors.centerIn: parent

        width: JamiTheme.iconButtonMedium
        height: JamiTheme.iconButtonMedium

        source: JamiResources.planet_24dp_svg
        sourceSize.width: JamiTheme.iconButtonMedium
        sourceSize.height: JamiTheme.iconButtonMedium

        color: root.hovered ? Qt.lighter(CurrentConversation.color, 1.5) : Qt.darker(CurrentConversation.color, 1.5)

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        rotation: servicesPopup.opened ? -90 : 0

        Behavior on rotation {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    background: Rectangle {
        implicitWidth: JamiTheme.iconButtonMedium * 1.5
        implicitHeight: JamiTheme.iconButtonMedium * 1.5

        radius: height / 2
        color: root.hovered ? Qt.darker(CurrentConversation.color, 1.5) : Qt.lighter(CurrentConversation.color, 1.5)

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    popup: Popup {
        id: servicesPopup

        parent: root
        x: viewCoordinator.isInSinglePaneMode ? root.width - JamiTheme.iconButtonLarge : root.width - width
        y: root.height
        width: 300
        padding: 4

        opacity: opened ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        contentItem: ListView {
            implicitHeight: Math.min(contentHeight, 320)

            spacing: 8

            clip: true

            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator {}
        }

        onAboutToShow: root.currentIndex = 0
        onOpened: root.requeryServices()

        background: Rectangle {
            color: JamiTheme.globalIslandColor
            radius: 22 + servicesPopup.padding

            layer.enabled: true
            layer.effect: MultiEffect {
                anchors.fill: parent
                shadowEnabled: true
                shadowBlur: JamiTheme.shadowBlur
                shadowColor: JamiTheme.shadowColor
                shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
                shadowVerticalOffset: JamiTheme.shadowVerticalOffset
                shadowOpacity: JamiTheme.shadowOpacity
            }
        }
    }
}