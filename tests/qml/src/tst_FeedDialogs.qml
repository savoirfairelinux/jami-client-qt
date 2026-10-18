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
        property var authorizations: []
        function clearError() { error = ""; }
        function refresh() {}
        function contacts(account) { return [{uri: "peer", name: "Alice"}]; }
        function details(id) { return id === "shared" ? {id: "shared", title: "News", feedAccess: "bob"} : {}; }
        function authorize(account, id, uri, allowed) {
            authorizations = authorizations.concat([[id, uri, allowed]]);
            return true;
        }
        function createFeed(account, title, avatar, replies) {
            lastCreate = [account, title, replies];
            return "new-feed";
        }
    }
    QtObject {
        id: fakeCircles
        property var circles: [{id: "friends", name: "Friends", members: ["jami:alice", "bob"]},
                               {id: "empty", name: "Family", members: []}]
    }
    FeedSettingsDialog { id: settings; service: fakeService; circleService: fakeCircles; accountId: "test" }
    FeedCatalogueDialog { id: catalogue; service: fakeService; accountId: "test" }
    TestCase {
        name: "FeedDialogs"
        when: windowShown
        function cleanup() {
            fakeService.feeds = [];
            fakeService.authorizations = [];
            settings.close();
            catalogue.close();
        }
        // findChild() does not walk into the ListView contentItem, so reach the
        // catalogue delegates explicitly.
        function catalogueAction(feedId) {
            const items = findChild(catalogue, "feedCatalogueList").contentItem.children;
            for (var i = 0; i < items.length; ++i) {
                const row = items[i].contentItem;
                if (!row)
                    continue;
                for (var j = 0; j < row.children.length; ++j) {
                    if (row.children[j].objectName === "feedAction-" + feedId)
                        return row.children[j];
                }
            }
            return null;
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
        // findChild() does not walk into the dialog content Flickable.
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
        function test_circle_authorizes_all_its_members() {
            settings.feedId = "shared";
            settings.initialized = false;
            settings.updateDetails();
            settings.open();
            tryCompare(settings, "opened", true);
            const circle = find(settings.contentItem, "feedCircle-friends");
            verify(circle !== null);
            verify(circle.visible);
            // Only one member is authorized yet: the Circle is not.
            verify(!circle.checked);
            // A Circle without members has nothing to authorize.
            verify(!find(settings.contentItem, "feedCircle-empty").visible);
            mouseClick(circle);
            compare(fakeService.authorizations, [["shared", "alice", true], ["shared", "bob", true]]);
        }
        function test_catalogue_empty() {
            catalogue.open();
            tryCompare(catalogue, "opened", true);
            compare(findChild(catalogue, "feedCatalogueList").count, 0);
        }
        function test_closed_feed_cannot_be_subscribed() {
            fakeService.feeds = [{id: "closed", title: "Archive", owned: false, avatar: "",
                                  feedOwner: "peer", ownerName: "Alice", available: true,
                                  feedClosed: true, subscribed: false, requested: false,
                                  feedReplies: false}];
            catalogue.open();
            tryCompare(catalogue, "opened", true);
            tryVerify(() => catalogueAction("closed") !== null);
            const action = catalogueAction("closed");
            // Closing a Feed is permanent: the daemon would reject the request, so
            // the UI must not offer it in the first place.
            compare(action.text, qsTr("Subscribe"));
            compare(action.enabled, false);
        }
        function test_closed_feed_can_still_be_left() {
            fakeService.feeds = [{id: "closed", title: "Archive", owned: false, avatar: "",
                                  feedOwner: "peer", ownerName: "Alice", available: true,
                                  feedClosed: true, subscribed: true, requested: false,
                                  feedReplies: false}];
            catalogue.open();
            tryCompare(catalogue, "opened", true);
            tryVerify(() => catalogueAction("closed") !== null);
            const action = catalogueAction("closed");
            // Subscribers of a closed Feed must keep a way out.
            compare(action.text, qsTr("Unsubscribe"));
            compare(action.enabled, true);
        }
    }
}
