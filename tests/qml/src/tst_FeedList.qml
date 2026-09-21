/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtTest
import "../../../src/app/mainview/components"

TestWrapper {
    width: 500
    height: 500
    FeedList {
        id: uut
        width: 380
        SignalSpy { id: openSpy; target: uut; signalName: "openRequested" }
        SignalSpy { id: createSpy; target: uut; signalName: "createRequested" }
        SignalSpy { id: catalogueSpy; target: uut; signalName: "catalogueRequested" }
    }
    TestCase {
        name: "FeedList"
        when: windowShown
        function init() {
            uut.feeds = [];
            uut.selectedId = "";
            openSpy.clear();
            createSpy.clear();
            catalogueSpy.clear();
        }
        function test_empty_state() {
            const create = findChild(uut, "firstFeedButton");
            verify(create.visible);
            create.clicked();
            compare(createSpy.count, 1);
            findChild(uut, "feedCatalogueButton").clicked();
            compare(catalogueSpy.count, 1);
        }
        function test_feed_selection() {
            uut.feeds = [{id: "first", title: "News", owned: true, avatar: "", unread: 2},
                         {id: "second", title: "Updates", owned: false, avatar: "", unread: 0}];
            tryVerify(() => findChild(uut, "feedEntry-second") !== null);
            verify(!findChild(uut, "firstFeedButton").visible);
            const item = findChild(uut, "feedEntry-second");
            item.clicked();
            compare(openSpy.count, 1);
            compare(openSpy.signalArguments[0][0], "second");
            uut.selectedId = "second";
            tryCompare(item, "highlighted", true);
        }
    }
}
