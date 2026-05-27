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
    property bool completed: false

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
        if (peerUri === CurrentAccount.uri) {
            services = ExposedServicesAdapter.getExposedServices(accountId).map(function(s) {
                return Object.assign({}, s, { isLocal: true });
            });
        }
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
        if (service.isLocal)
            return { localPort: parseInt(service.localPort), scheme: service.scheme || "" };
        return openTunnels[service.id];
    }

    function isHttpService(service) {
        var scheme = service.scheme || "";
        return scheme === "http" || scheme === "https";
    }

    function localEndpoint(service) {
        if (service.isLocal)
            return (service.localHost || "127.0.0.1") + ":" + service.localPort;
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
            var result = status === ExposedServicesAdapter.PeerServicesStatus.OK ? services : [];
            if (root.peerUri === CurrentAccount.uri) {
                var localServices = ExposedServicesAdapter.getExposedServices(root.accountId);
                result = result.concat(localServices.map(function(s) {
                    return Object.assign({}, s, { isLocal: true });
                }));
            }
            root.services = result;
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
                    if (serviceDelegate.modelData.isLocal) {
                        return JamiResources.location_home_24dp_svg;
                    } else {
                        return serviceDelegate.modelData.scheme === "https" ? JamiResources.vpn_lock_2_24dp_svg : JamiResources.language_24dp_svg
                    }
                }
                sourceSize.width: JamiTheme.iconButtonMedium
                sourceSize.height: JamiTheme.iconButtonMedium

                color: {
                    if (serviceDelegate.modelData.isLocal) {
                        return CurrentConversation.color;
                    } else {
                        return root.tunnelFor(serviceDelegate.modelData) !== undefined ? JamiTheme.exposedServiceConnectColor : JamiTheme.buttonTintedGreyHovered
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

                Layout.alignment: Qt.AlignVCenter

                iconSource: JamiResources.stop_circle_24dp_svg
                iconSize: JamiTheme.iconButtonMedium
                iconColor: JamiTheme.red_
                toolTipText: JamiStrings.exposedServiceDisconnect

                background: null

                visible: root.tunnelFor(serviceDelegate.modelData) !== undefined && !serviceDelegate.modelData.isLocal

                scale: hovered ? 1.1 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }

                onClicked: {
                    var tunnel = root.tunnelFor(serviceDelegate.modelData);
                    if (tunnel)
                        ExposedServicesAdapter.closeServiceTunnel(root.accountId, tunnel.tunnelId);
                }
            }
        }

        background: Rectangle {
            radius: height / 2

            color: (serviceDelegate.hovered || serviceDelegate.activeFocus || serviceDelegate.highlighted) ? JamiTheme.smartListHoveredColor : JamiTheme.globalIslandColor

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

            text: root.tunnelFor(serviceDelegate.modelData) !== undefined ? root.isHttpService(serviceDelegate.modelData)
                                                                            ? JamiStrings.exposedServiceOpenInExternalBrowser : JamiStrings.copy : JamiStrings.exposedServiceConnect

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
        x: root.width - width
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