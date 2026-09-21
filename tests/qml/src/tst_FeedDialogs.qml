/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtTest
import "../../../src/app/commoncomponents"

TestWrapper {
    width: 900
    height: 800
    QtObject {
        id: fakeService
        property string error: ""
        property var feeds: []
        property var lastCreate: []
        function clearError() { error = ""; }
        function refresh() {}
        function contacts(account) { return [{uri: "peer", name: "Alice"}]; }
        function details(id) { return {}; }
        function createFeed(account, title, avatar, replies) {
            lastCreate = [account, title, replies];
            return "new-feed";
        }
    }
    FeedSettingsDialog { id: settings; service: fakeService; accountId: "test" }
    FeedCatalogueDialog { id: catalogue; service: fakeService; accountId: "test" }
    TestCase {
        name: "FeedDialogs"
        when: windowShown
        function cleanup() {
            settings.close();
            catalogue.close();
        }
        function test_creation_requires_name() {
            settings.feedId = "";
            settings.feedName = "";
            settings.open();
            tryCompare(settings, "opened", true);
            verify(!settings.button1.enabled);
            settings.feedName = "News";
            settings.replies = true;
            verify(settings.button1.enabled);
            settings.button1.clicked();
            compare(fakeService.lastCreate[0], "test");
            compare(fakeService.lastCreate[1], "News");
            compare(fakeService.lastCreate[2], true);
            compare(settings.feedId, "new-feed");
        }
        function test_catalogue_empty() {
            catalogue.open();
            tryCompare(catalogue, "opened", true);
            compare(findChild(catalogue, "feedCatalogueList").count, 0);
        }
    }
}
