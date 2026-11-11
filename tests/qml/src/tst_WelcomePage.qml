/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls

import QtTest
import net.jami.Constants 1.1

import "../../../src/app/"
import "../../../src/app/mainview/components"

TestWrapper {
    id: wrapper
    width: 900
    height: 700

    WelcomePage {
        id: uut
        anchors.fill: parent

        TestCase {
            name: "Open 'About Jami' popup"
            when: windowShown

            function init() {
                wrapper.width = 900;
            }

            function test_aboutIconBesideShortcuts_data() {
                const minimumWidth = uut.majorPaneMinWidth + Math.max(uut.previousMinorPaneWidth, uut.minorPaneMinWidth);
                return [{tag: "wide", width: minimumWidth + 500}, {tag: "narrow", width: minimumWidth + 20}];
            }

            function test_aboutIconBesideShortcuts(data) {
                wrapper.width = data.width;
                const about = findChild(uut, "aboutJami");
                verify(about);
                compare(about.iconSource, JamiResources.i_informations_black_24dp_svg);
                compare(about.toolTipText, JamiStrings.aboutJami);
                compare(about.Accessible.name, JamiStrings.aboutJami);
                compare(about.text, "");
                const shortcuts = findChild(uut, "keyboardShortcuts");
                verify(shortcuts);
                const pane = uut.rightPaneItem;
                tryVerify(() => pane.parent !== null);
                tryVerify(() => {
                    const aboutPosition = about.mapToItem(pane, 0, 0);
                    const shortcutsPosition = shortcuts.mapToItem(pane, 0, 0);
                    const gap = shortcutsPosition.x - aboutPosition.x - about.width;
                    return aboutPosition.x >= 0 && gap >= 0 && gap <= JamiTheme.preferredMarginSize
                            && shortcutsPosition.x + shortcuts.width <= pane.width
                            && aboutPosition.y === shortcutsPosition.y;
                });
                compare(about.width, shortcuts.width);
                compare(about.height, shortcuts.height);
            }

            function test_openAboutPopup() {
                var aboutJamiButton = findChild(uut, "aboutJami")
                aboutJamiButton.clicked()

                var aboutJamiPopup = viewManager.getView("AboutPopUp")
                verify(aboutJamiPopup !== null, "About Jami popup should be created")
                compare(aboutJamiPopup.visible, true, "About Jami popup should be visible")
            }
        }
    }
}
