/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtTest
import net.jami.Constants 1.1
import "../../../src/app/mainview/components"

TestWrapper {
    width: 900
    height: 800

    QtObject {
        id: fakeService

        property var offeredServices: []
        property bool loadingOfferedServices: false
        property var activeTunnels: []
        property var refreshedAccounts: []
        property var opened: []
        property var closed: []
        // Port: tunnel id answered by openServiceTunnel, "" when it fails
        property var answers: ({})

        signal tunnelOpened(string accountId, string tunnelId, int localPort)
        signal tunnelClosed(string accountId, string tunnelId, string reason)

        function refreshOfferedServices(accountId) {
            refreshedAccounts = refreshedAccounts.concat([accountId]);
        }

        function getActiveTunnels(accountId) {
            return activeTunnels;
        }

        function openServiceTunnel(accountId, peerUri, peerDevice, serviceId, serviceName, localPort) {
            opened = opened.concat([[accountId, peerUri, peerDevice, serviceId, serviceName, localPort]]);
            const tunnelId = answers[localPort] !== undefined ? answers[localPort] : "tunnel-" + serviceId;
            if (tunnelId !== "")
                activeTunnels = activeTunnels.concat([{"id": tunnelId, "peerUri": peerUri, "serviceId": serviceId,
                                                       "localPort": localPort || 40000}]);
            return tunnelId;
        }

        function closeServiceTunnel(accountId, tunnelId) {
            closed = closed.concat([[accountId, tunnelId]]);
            activeTunnels = activeTunnels.filter(tunnel => tunnel.id !== tunnelId);
            tunnelClosed(accountId, tunnelId, "closed");
            return true;
        }
    }

    ServicesDialog {
        id: uut
        service: fakeService
        accountId: "account"

        SignalSpy { id: ownSpy; target: uut; signalName: "ownServicesRequested" }
        SignalSpy { id: urlSpy; target: uut; signalName: "openUrlRequested" }
    }

    TestCase {
        name: "ServicesDialog"
        when: windowShown

        readonly property var wiki: ({"id": "wiki", "name": "Wiki", "description": "Team wiki", "scheme": "http",
                                       "device": "alice-device", "preferredPort": "8080",
                                       "peerUri": "alice-uri", "peerName": "Alice"})
        readonly property var ssh: ({"id": "ssh", "name": "SSH", "description": "", "scheme": "",
                                      "device": "bob-device", "peerUri": "bob-uri", "peerName": "Bob"})
        readonly property var printer: ({"id": "printer", "name": "Printer", "description": "", "scheme": "ipp",
                                          "device": "bob-device", "available": false,
                                          "peerUri": "bob-uri", "peerName": "Bob"})

        function init() {
            fakeService.offeredServices = [wiki, ssh, printer];
            fakeService.loadingOfferedServices = false;
            fakeService.activeTunnels = [];
            fakeService.opened = [];
            fakeService.closed = [];
            fakeService.answers = ({});
            ownSpy.clear();
            urlSpy.clear();
            uut.failures = ({});
            uut.open();
            tryCompare(uut, "opened", true);
            uut.readTunnels();
            tryVerify(() => find(uut.contentItem, "service-bob-uri-ssh") !== null);
        }

        function cleanup() {
            uut.close();
            tryCompare(uut, "visible", false);
        }

        // findChild() does not walk into the dialog content nor the ListView contentItem.
        function find(item, name) {
            if (!item)
                return null;
            if (item.objectName === name)
                return item;
            const children = Array.from(item.children || []);
            if (item.contentItem && children.indexOf(item.contentItem) < 0)
                children.push(item.contentItem);
            for (const child of children) {
                const found = find(child, name);
                if (found)
                    return found;
            }
            return null;
        }

        function row(peerUri, serviceId) {
            return find(uut.contentItem, "service-" + peerUri + "-" + serviceId);
        }

        function test_opening_asks_the_contacts_again() {
            const before = fakeService.refreshedAccounts.length;
            const dialog = createTemporaryObject(Qt.createComponent("../../../src/app/mainview/components/ServicesDialog.qml"),
                                                 parent, {"service": fakeService, "accountId": "account"});
            verify(dialog !== null);
            compare(fakeService.refreshedAccounts.length, before + 1);
            compare(fakeService.refreshedAccounts[before], "account");
        }

        function test_each_service_tells_who_offers_it() {
            const fromAlice = row("alice-uri", "wiki");
            compare(find(fromAlice, "serviceProvenance").text, JamiStrings.serviceOfferedBy.arg("Alice"));
            compare(find(fromAlice, "serviceStatus").text, "Team wiki");

            const fromBob = row("bob-uri", "ssh");
            compare(find(fromBob, "serviceProvenance").text, JamiStrings.serviceOfferedBy.arg("Bob"));
            verify(!find(fromBob, "serviceStatus").visible);
        }

        function test_picking_a_service_opens_it_and_tells_where() {
            mouseClick(row("bob-uri", "ssh"));

            compare(fakeService.opened.length, 1);
            compare(fakeService.opened[0], ["account", "bob-uri", "bob-device", "ssh", "SSH", 0]);
            tryCompare(find(row("bob-uri", "ssh"), "serviceStatus"), "text", "127.0.0.1:40000");
            verify(find(row("bob-uri", "ssh"), "stopService").visible);
            compare(urlSpy.count, 0);
        }

        function test_a_web_service_opens_in_the_browser() {
            mouseClick(row("alice-uri", "wiki"));

            compare(fakeService.opened[0], ["account", "alice-uri", "alice-device", "wiki", "Wiki", 8080]);
            compare(urlSpy.count, 1);
            compare(urlSpy.signalArguments[0][0], "http://127.0.0.1:8080");

            // Picked again, it opens again without a second tunnel
            mouseClick(row("alice-uri", "wiki"));
            compare(fakeService.opened.length, 1);
            compare(urlSpy.count, 2);
        }

        function test_a_busy_preferred_port_gives_way_to_any_port() {
            fakeService.answers = {"8080": ""};

            mouseClick(row("alice-uri", "wiki"));

            compare(fakeService.opened.length, 2);
            compare(fakeService.opened[1][5], 0);
            compare(urlSpy.signalArguments[0][0], "http://127.0.0.1:40000");
        }

        function test_a_service_that_cannot_be_opened_says_so() {
            fakeService.answers = {"0": ""};

            mouseClick(row("bob-uri", "ssh"));

            tryCompare(find(row("bob-uri", "ssh"), "serviceStatus"), "text", JamiStrings.sharedServicesConnectFailed);
            verify(!find(row("bob-uri", "ssh"), "stopService").visible);
        }

        function test_an_open_service_can_be_stopped() {
            fakeService.activeTunnels = [{"id": "tunnel-ssh", "peerUri": "bob-uri", "serviceId": "ssh", "localPort": 2222}];
            uut.readTunnels();
            const stop = find(row("bob-uri", "ssh"), "stopService");
            tryVerify(() => stop.visible);

            mouseClick(stop);

            compare(fakeService.closed, [["account", "tunnel-ssh"]]);
            tryVerify(() => !stop.visible);
        }

        function test_an_unavailable_service_cannot_be_picked() {
            const unavailable = row("bob-uri", "printer");
            compare(find(unavailable, "serviceStatus").text, JamiStrings.sharedServicesUnavailable);

            mouseClick(unavailable);

            compare(fakeService.opened.length, 0);
        }

        function test_my_services_opens_their_settings() {
            mouseClick(find(uut.contentItem, "myServicesButton"));

            compare(ownSpy.count, 1);
            tryCompare(uut, "visible", false);
        }

        function test_nothing_to_list_says_so_once_asked() {
            fakeService.offeredServices = [];
            fakeService.loadingOfferedServices = true;
            const noServices = find(uut.contentItem, "noServices");
            const loading = find(uut.contentItem, "servicesLoading");
            verify(loading.visible);
            verify(!noServices.visible);

            fakeService.loadingOfferedServices = false;
            verify(!loading.visible);
            verify(noServices.visible);
        }
    }
}
