/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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

import "../../../src/app/"
import "../../../src/app/mainview/components"

WelcomePage {
    id: uut

    width: 800
    height: 600

    // The appWindow, viewManager and viewCoordinator properties
    // are required in order for the "aboutJami" button to work.
    property Item appWindow: uut
    property ViewManager viewManager: ViewManager {
    }
    property ViewCoordinator viewCoordinator: ViewCoordinator {
        viewManager: uut.viewManager
    }

    TestCase {
        name: "Open 'About Jami' popup"

        function test_openAboutPopup() {
            compare(viewManager.viewCount(), 0)

            var aboutJamiButton = findChild(uut, "aboutJami")
            aboutJamiButton.clicked()

            compare(viewManager.viewCount(), 1)

            var aboutJamiPopup = viewManager.getView("AboutPopUp")
            verify(aboutJamiPopup !== null)
            compare(aboutJamiPopup.visible, true)
        }
    }
}