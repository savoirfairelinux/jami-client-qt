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

import net.jami.Constants 1.1

import "../../../src/app/"
import "../../../src/app/mainview/components"

Item {
    id: root

    width: 600
    height: 600

    Item {
        id: sidePanelStub
    }

    CreateFeedPage {
        id: uut

        anchors.fill: parent
        property QtObject viewCoordinator: QtObject {
            function getView() {
                return sidePanelStub;
            }
        }
    }

    SignalSpy {
        id: createFeedSpy
        target: uut
        signalName: "createFeedClicked"
    }

    TestCase {
        name: "CreateFeedPage"
        when: windowShown

        function test_createButtonEmitsFeedDetails() {
            const name = findChild(uut, "feedNameLineEdit");
            const description = findChild(uut, "feedDescriptionLineEdit");
            const createButton = findChild(uut, "createFeedButton");
            verify(name);
            verify(description);
            verify(createButton);

            name.modifiedTextFieldContent = "Announcements";
            description.modifiedTextFieldContent = "Team updates";
            mouseClick(createButton);

            tryCompare(createFeedSpy, "count", 1);
            compare(createFeedSpy.signalArguments[0][0], "Announcements");
            compare(createFeedSpy.signalArguments[0][1], "Team updates");
            compare(createFeedSpy.signalArguments[0].length, 3);
        }
    }
}
