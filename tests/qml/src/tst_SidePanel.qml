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
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1

import "../../../src/app/"
import "../../../src/app/mainview/components"

TestWrapper {
    SidePanel {
        id: uut

        width: 300
        height: 600

        QtObject {
            id: testNewSwarmPage

            property var members: []

            signal removeMember(string convId, string member)
            signal createSwarmClicked(string title, string description, string avatar)
        }

        QtObject {
            id: testCreateFeedPage

            property var members: []
            property bool creationFailed: false

            signal removeMember(string convId, string member)
            signal createFeedClicked(string title, string description, string avatar)
        }

        QtObject {
            id: testViewCoordinator

            property string currentViewName: ""
            property bool isInSinglePaneMode: false

            function present(viewName) {
                currentViewName = viewName;
            }

            function dismiss(viewName) {
                if (currentViewName === viewName)
                    currentViewName = "";
            }

            function getView(viewName) {
                if (viewName === "NewSwarmPage")
                    return testNewSwarmPage;
                if (viewName === "CreateFeedPage")
                    return testCreateFeedPage;
                return null;
            }
        }

        QtObject {
            id: testAppContext

            property var viewCoordinator: testViewCoordinator
        }

        TestCase {
            name: "New swarm member selection"

            readonly property string self: CurrentAccount.uri
            readonly property var aliceDm: ["alice", self]
            readonly property var bobDm: ["bob", self]
            readonly property var carolDm: ["carol", self]
            readonly property var group: [self, "alice", "bob"]

            function init() {
                uut.clearHighlighted();
            }

            function test_cancelingNewGroupClosesCreationView() {
                const previousFilterRequests = ConversationsAdapter.filterRequests;
                const previousAppContext = uut.appContext;

                try {
                    uut.appContext = testAppContext;
                    ConversationsAdapter.filterRequests = false;

                    uut.toggleCreateSwarmView();
                    compare(uut.inNewSwarm, true);

                    const closeButton = findChild(uut, "closeCreationButton");
                    verify(closeButton);
                    verify(closeButton.visible);
                    mouseClick(closeButton);
                    compare(uut.inNewSwarm, false);
                } finally {
                    testViewCoordinator.currentViewName = "";
                    uut.appContext = previousAppContext;
                    ConversationsAdapter.filterRequests = previousFilterRequests;
                }
            }

            function test_cancelingNewFeedClosesCreationView() {
                const previousFilterRequests = ConversationsAdapter.filterRequests;
                const previousAppContext = uut.appContext;

                try {
                    uut.appContext = testAppContext;
                    uut.openCreateFeedView();
                    compare(uut.inCreateFeed, true);

                    const closeButton = findChild(uut, "closeCreationButton");
                    verify(closeButton);
                    verify(closeButton.visible);
                    mouseClick(closeButton);
                    compare(uut.inCreateFeed, false);
                } finally {
                    testViewCoordinator.currentViewName = "";
                    uut.appContext = previousAppContext;
                    ConversationsAdapter.filterRequests = previousFilterRequests;
                }
            }

            function memberUris() {
                return uut.highlightedMembers.map(m => m.uri).sort();
            }

            function test_selectingGroupHighlightsMembersConversations() {
                uut.toggleHighlighted("group", group);

                compare(memberUris(), ["alice", "bob"]);
                verify(uut.isHighlighted(group));
                verify(uut.isHighlighted(aliceDm));
                verify(uut.isHighlighted(bobDm));
                verify(!uut.isHighlighted(carolDm));
            }

            function test_selectingAllMembersHighlightsGroup() {
                uut.toggleHighlighted("aliceDm", aliceDm);
                verify(!uut.isHighlighted(group));

                uut.toggleHighlighted("bobDm", bobDm);
                verify(uut.isHighlighted(group));
            }

            function test_deselectingMemberConversationUnhighlightsGroup() {
                uut.toggleHighlighted("group", group);
                uut.toggleHighlighted("aliceDm", aliceDm);

                compare(memberUris(), ["bob"]);
                verify(!uut.isHighlighted(group));
                verify(!uut.isHighlighted(aliceDm));
                verify(uut.isHighlighted(bobDm));
            }

            function test_deselectingGroupRemovesAllItsMembers() {
                uut.toggleHighlighted("carolDm", carolDm);
                uut.toggleHighlighted("group", group);
                uut.toggleHighlighted("group", group);

                compare(memberUris(), ["carol"]);
                verify(!uut.isHighlighted(aliceDm));
                verify(!uut.isHighlighted(bobDm));
            }

            function test_removingMemberChipUnhighlightsItsConversations() {
                uut.toggleHighlighted("group", group);
                uut.removeMember("group", "alice");

                compare(memberUris(), ["bob"]);
                verify(!uut.isHighlighted(group));
                verify(!uut.isHighlighted(aliceDm));
                verify(uut.isHighlighted(bobDm));
            }

            function test_selfConversationCannotBeHighlighted() {
                uut.toggleHighlighted("note", [self]);

                compare(uut.highlightedMembers.length, 0);
                verify(!uut.isHighlighted([self]));
            }

            function test_membersAreNotDuplicated() {
                uut.toggleHighlighted("aliceDm", aliceDm);
                uut.toggleHighlighted("group", group);

                compare(memberUris(), ["alice", "bob"]);
                compare(Array.from(uut.highlighted).sort(), ["aliceDm", "group"]);
            }
        }
    }
}
