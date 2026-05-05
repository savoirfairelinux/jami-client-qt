import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.impl


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
        if (!tunnel)
            openTunnel(service);
    }

    function openOrCopy(service)  {
        if (isHttpService(service)) {
            var dlg = viewCoordinator.presentDialog(appWindow, "../../commoncomponents/ConfirmDialog.qml", {
                                                        "titleText": JamiStrings.confirmAction,
                                                        "textLabel": JamiStrings.confirmNavigationDescription,
                                                        "confirmLabel": JamiStrings.leaveJami
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
        y: root.height
        width: 300
        padding: 4

        contentItem: ListView {
            implicitHeight: Math.min(contentHeight, 320)

            spacing: 8

            model: root.services
            clip: true

            delegate: ItemDelegate {
                id: serviceDelegate

                required property var modelData

                width: ListView.view.width
                implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                        implicitContentWidth + leftPadding + rightPadding)
                implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                         implicitContentHeight + topPadding + bottomPadding,
                                         implicitIndicatorHeight + topPadding + bottomPadding)

                padding: 4

                contentItem: RowLayout {
                    spacing: 8

                    NewIconButton {
                        id: activateButton

                        iconSource: root.tunnelFor(serviceDelegate.modelData) !== undefined ? JamiResources.power_24dp_svg : JamiResources.power_off_24dp_svg
                        iconSize: JamiTheme.iconButtonMedium
                        iconColor: root.tunnelFor(serviceDelegate.modelData) !== undefined ? JamiTheme.exposedServiceConnectColor : JamiTheme.red_
                        toolTipText: root.tunnelFor(serviceDelegate.modelData) !== undefined ? JamiStrings.exposedServiceDisconnect : JamiStrings.exposedServiceConnect

                        background: null

                        scale: hovered ? 1.1 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: JamiTheme.shortFadeDuration
                            }
                        }

                        onClicked: {
                            if (root.tunnelFor(serviceDelegate.modelData) === undefined) {
                                root.activateService(modelData);
                            } else {
                                var tunnel = root.tunnelFor(serviceDelegate.modelData);
                                if (tunnel)
                                    ExposedServicesAdapter.closeServiceTunnel(root.accountId, tunnel.tunnelId);
                            }
                        }
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

                            font.pixelSize: JamiTheme.exposedServiceDelegateTitlePixelSize
                        }

                        Text {
                            width: parent.width

                            text: root.tunnelFor(serviceDelegate.modelData) !== undefined ? serviceDelegate.modelData.scheme + "://" + root.localEndpoint(serviceDelegate.modelData)
                                                                                            : serviceDelegate.modelData.description
                            elide: Text.ElideRight
                            color: JamiTheme.textColor

                            font.pixelSize: JamiTheme.exposedServiceDelegateDescriptionPixelSize
                            font.family: root.tunnelFor(serviceDelegate.modelData) !== undefined ? JamiTheme.ubuntuMonoFontFamily : JamiTheme.ubuntuFontFamily
                            font.italic: root.tunnelFor(serviceDelegate.modelData) === undefined

                            visible: text.length > 0
                        }
                    }

                    NewIconButton {
                        id: openOrCopyButton

                        iconSource: root.isHttpService(serviceDelegate.modelData) ? JamiResources.captive_portal_24dp_svg : JamiResources.content_copy_24dp_svg
                        iconSize: JamiTheme.iconButtonMedium
                        toolTipText: root.isHttpService(serviceDelegate) ? JamiStrings.exposedServiceOpenInExternalBrowser : JamiStrings.copy

                        background: null

                        visible: root.tunnelFor(serviceDelegate.modelData) !== undefined

                        scale: hovered ? 1.1 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: JamiTheme.shortFadeDuration
                            }
                        }

                        onClicked: root.openOrCopy(serviceDelegate.modelData)
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
            }
        }

        background: Rectangle {
            color: JamiTheme.globalIslandColor
            radius: 22

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
