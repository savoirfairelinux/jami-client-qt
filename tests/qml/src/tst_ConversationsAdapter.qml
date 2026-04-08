/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

// Tests for ConversationsAdapter logic that does not require a rendered UI.
Item {
    id: root

    // Spy on every textFilterChanged emission so we can assert both the
    // intermediate filter value and the final cleared state.
    SignalSpy {
        id: filterSpy
        target: ConversationsAdapter
        signalName: "textFilterChanged"
    }

    TestCase {
        name: "ConversationsAdapter"

        function cleanup() {
            // Reset the filter and spy after every test.
            ConversationsAdapter.setFilter("");
            filterSpy.clear();
        }

        // Regression test: when setFilterAndSelect() is called (e.g. triggered by
        // a jami: URI at startup), the search filter must be cleared automatically
        // once the search result has been processed, so the search bar is not left
        // populated after the conversation has been opened.
        function test_uriSearch_filterIsClearedAfterSelection() {
            // Trigger the URI-search flow with an arbitrary string that will produce
            // no matches (we only care about the side-effect on the filter state).
            ConversationsAdapter.setFilterAndSelect("__regression_uri_test__");

            // The first emission must carry the search string.
            filterSpy.wait(2000);
            verify(filterSpy.count >= 1,
                   "textFilterChanged should have been emitted with the search string");
            compare(filterSpy.signalArguments[0][0], "__regression_uri_test__");

            // After the search completes, onSearchResultEnded() must schedule a
            // setFilter("") via QTimer::singleShot, producing a second emission.
            if (filterSpy.count < 2)
                filterSpy.wait(2000);

            verify(filterSpy.count >= 2,
                   "textFilterChanged should have been emitted a second time to clear the filter");
            compare(filterSpy.signalArguments[filterSpy.count - 1][0], "",
                    "The last textFilterChanged emission must clear the filter");
        }
    }
}
