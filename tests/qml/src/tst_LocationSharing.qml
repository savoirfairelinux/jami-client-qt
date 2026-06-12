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
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview"
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

TestWrapper {

    // ── WebEngine instantiation (requires WITH_WEBENGINE) ─────────────────────
    //
    // These tests exercise the full open/close/reopen cycle through ChatView,
    // including actual MapPosition.qml creation.  This is the scenario that
    // caused the "Single mode supports only single profile" fatal crash:
    //   1. open  → WebEngineProfile created inside MapPosition
    //   2. close → root.destroy() deferred; profile still alive in C++
    //   3. reopen → second profile attempted → CRASH
    //
    // The fix uses lazy creation: ChatView loads MapProfileHolder.qml on first
    // map open, then keeps its profile alive for the lifetime of ChatView.
    // MapPosition never creates/destroys a profile, so steps 2→3 are safe.

    ListSelectionView {
        id: viewNode
        objectName: "ConversationView"
        managed: false

        leftPaneItem: Rectangle {}

        rightPaneItem: ChatView {
            id: chatView
            inCallView: false

            TestCase {
                name: "LocationSharing_WebEngine"
                when: windowShown

                readonly property string accountId: CurrentAccount.id

                function init() {
                    if (!WITH_WEBENGINE)
                        skip("WebEngine not available (WITH_WEBENGINE=0)");
                }

                function cleanup() {
                    if (PositionManager.isMapActive(accountId))
                        PositionManager.setMapInactive(accountId);
                    // Give the event loop a chance to process deferred deletes
                    // before the next test starts.
                    wait(50);
                    // Reset the map profile holder so each test starts with a clean state.
                    if (chatView.mapProfileHolder !== null) {
                        chatView.mapProfileHolder.destroy();
                        chatView.mapProfileHolder = null;
                        chatView.mapProfile = null;
                        wait(50);
                    }
                }

                // Opening the map must create a MapPosition containing a WebEngineView.
                function test_openMap_createsWebEngineView() {
                    PositionManager.setMapActive(accountId);
                    // instanceMapObject runs synchronously on the signal
                    var webEngineView = findChild(chatView, "mapWebEngine");
                    verify(webEngineView !== null,
                           "A WebEngineView named 'mapWebEngine' should exist after setMapActive");
                }

                // After closing, the WebEngineView must be gone.
                function test_closeMap_destroysWebEngineView() {
                    PositionManager.setMapActive(accountId);
                    PositionManager.setMapInactive(accountId);
                    // Wait for the deferred QML destroy() to be processed.
                    wait(50);
                    var webEngineView = findChild(chatView, "mapWebEngine");
                    verify(webEngineView === null,
                           "WebEngineView should be gone after setMapInactive");
                }

                // This is the exact crash regression:
                // open → close → reopen must not crash and must produce a
                // live WebEngineView using the persistent ChatView profile.
                function test_reopen_afterClose_doesNotCrashAndCreatesWebEngineView() {
                    PositionManager.setMapActive(accountId);
                    PositionManager.setMapInactive(accountId);
                    // Let the deferred destroy run so the old MapPosition is gone.
                    wait(50);
                    // Reopen — this was the crash point before the fix.
                    PositionManager.setMapActive(accountId);
                    var webEngineView = findChild(chatView, "mapWebEngine");
                    verify(webEngineView !== null,
                           "A new WebEngineView should exist after reopen");
                }

                // The WebEngineProfile must be lazily created on first map
                // open (not at ChatView construction time) and then persist
                // across map close/reopen cycles within the same ChatView
                // lifetime – avoiding the "Single mode supports only single
                // profile" fatal assertion.
                function test_webEngineProfile_lazyCreationAndPersistence() {
                    // The profile property starts null (lazy – not eagerly created).
                    compare(chatView.mapProfile, null,
                            "mapProfile must be null before any map open (lazy creation)");

                    // First map open triggers lazy instantiation.
                    PositionManager.setMapActive(accountId);
                    var profile = findChild(chatView, "mapProfile");
                    verify(profile !== null,
                           "mapProfile should be created on first map open");
                    verify(chatView.mapProfile !== null,
                           "chatView.mapProfile property should be set after first map open");

                    // Closing the map must NOT destroy the profile.
                    PositionManager.setMapInactive(accountId);
                    wait(50);
                    verify(chatView.mapProfile !== null,
                           "mapProfile must persist after map close");
                    verify(findChild(chatView, "mapProfile") !== null,
                           "mapProfile child must still be findable after map close");

                    // Reopening must reuse the same profile instance (no second
                    // profile – that would trigger the Chromium fatal assertion).
                    var savedProfile = chatView.mapProfile;
                    PositionManager.setMapActive(accountId);
                    compare(chatView.mapProfile, savedProfile,
                            "mapProfile must be the same instance after reopen (no recreation)");
                }
            }
        }
    }

    // Map state
    TestCase {
        name: "LocationSharing_MapState"

        readonly property string accountId: CurrentAccount.id

        function init() {
            chatView.createMapViewOnPositionSignal = false;
        }

        // Ensure a clean slate after every individual test function.
        function cleanup() {
            if (PositionManager.isMapActive(accountId))
                PositionManager.setMapInactive(accountId);
            chatView.createMapViewOnPositionSignal = true;
        }

        function test_setMapActive_makesMapActive() {
            PositionManager.setMapActive(accountId);
            compare(PositionManager.isMapActive(accountId), true);
        }

        function test_setMapInactive_makesMapInactive() {
            PositionManager.setMapActive(accountId);
            PositionManager.setMapInactive(accountId);
            compare(PositionManager.isMapActive(accountId), false);
        }

        function test_setMapActive_mapStatusContainsKey() {
            PositionManager.setMapActive(accountId);
            verify(accountId in PositionManager.mapStatus,
                   "mapStatus should contain the account key after setMapActive");
        }

        function test_setMapInactive_mapStatusNoLongerContainsKey() {
            PositionManager.setMapActive(accountId);
            PositionManager.setMapInactive(accountId);
            verify(!(accountId in PositionManager.mapStatus),
                   "mapStatus should not contain the account key after setMapInactive");
        }
    }

    // openNewMap / closeMap signals
    TestCase {
        name: "LocationSharing_MapSignals"

        readonly property string accountId: CurrentAccount.id

        SignalSpy {
            id: openNewMapSpy
            target: PositionManager
            signalName: "onOpenNewMap"
        }

        SignalSpy {
            id: closeMapSpy
            target: PositionManager
            signalName: "onCloseMap"
        }

        function init() {
            chatView.createMapViewOnPositionSignal = false;
        }

        function cleanup() {
            openNewMapSpy.clear();
            closeMapSpy.clear();
            if (PositionManager.isMapActive(accountId))
                PositionManager.setMapInactive(accountId);
            chatView.createMapViewOnPositionSignal = true;
        }

        function test_setMapActive_emitsOpenNewMap() {
            PositionManager.setMapActive(accountId);
            compare(openNewMapSpy.count, 1);
        }

        // This is the regression test for the double-instantiation crash:
        // calling setMapActive for a key that is already active must NOT
        // emit openNewMap a second time (it should call pinMap instead).
        function test_setMapActive_twice_emitsOpenNewMapOnlyOnce() {
            PositionManager.setMapActive(accountId);
            PositionManager.setMapActive(accountId);
            compare(openNewMapSpy.count, 1,
                    "openNewMap must only fire for the first setMapActive call on a given key");
        }

        function test_setMapInactive_emitsCloseMap() {
            PositionManager.setMapActive(accountId);
            closeMapSpy.clear();
            PositionManager.setMapInactive(accountId);
            compare(closeMapSpy.count, 1);
        }

        function test_setMapInactive_closeMapCarriesCorrectKey() {
            PositionManager.setMapActive(accountId);
            closeMapSpy.clear();
            PositionManager.setMapInactive(accountId);
            compare(closeMapSpy.signalArguments[0][0], accountId);
        }

        // After a full open → close → open cycle, openNewMap must fire again
        // (a fresh map creation is legitimate after the previous one was closed).
        function test_reopenAfterClose_emitsOpenNewMapAgain() {
            PositionManager.setMapActive(accountId);
            PositionManager.setMapInactive(accountId);
            openNewMapSpy.clear();
            PositionManager.setMapActive(accountId);
            compare(openNewMapSpy.count, 1,
                    "openNewMap should fire again after a close/reopen cycle");
        }
    }

    // Position sharing counters
    TestCase {
        name: "LocationSharing_SharingCounters"

        readonly property string accountId: CurrentAccount.id
        readonly property string convId: CurrentConversation.id

        function cleanup() {
            PositionManager.stopSharingPosition(accountId, convId);
        }

        function test_positionShareConvIdsCount_startsAtZero() {
            compare(PositionManager.positionShareConvIdsCount, 0);
        }

        function test_sharePosition_incrementsCount() {
            var before = PositionManager.positionShareConvIdsCount;
            PositionManager.sharePosition(0, accountId, convId);
            compare(PositionManager.positionShareConvIdsCount, before + 1);
        }

        function test_stopSharingPosition_decrementsCount() {
            PositionManager.sharePosition(0, accountId, convId);
            var after = PositionManager.positionShareConvIdsCount;
            PositionManager.stopSharingPosition(accountId, convId);
            compare(PositionManager.positionShareConvIdsCount, after - 1);
        }

        function test_isPositionSharedToConv_trueWhileSharing() {
            PositionManager.sharePosition(0, accountId, convId);
            compare(PositionManager.isPositionSharedToConv(accountId, convId), true);
        }

        function test_isPositionSharedToConv_falseAfterStop() {
            PositionManager.sharePosition(0, accountId, convId);
            PositionManager.stopSharingPosition(accountId, convId);
            compare(PositionManager.isPositionSharedToConv(accountId, convId), false);
        }

        function test_isPositionSharedToConv_falseInitially() {
            compare(PositionManager.isPositionSharedToConv(accountId, convId), false);
        }
    }
}
