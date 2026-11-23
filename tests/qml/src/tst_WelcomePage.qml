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
import net.jami.Adapters 1.1
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview/components"

TestWrapper {
    WelcomePage {
        id: uut

        TestCase {
            name: "Open 'About Jami' popup"
            when: windowShown

            function test_openAboutPopup() {
                var aboutJamiButton = findChild(uut, "aboutJami")
                aboutJamiButton.clicked()

                var aboutJamiPopup = viewManager.getView("AboutPopUp")
                verify(aboutJamiPopup !== null, "About Jami popup should be created")
                compare(aboutJamiPopup.visible, true, "About Jami popup should be visible")
            }
        }

        TestCase {
            name: "WelcomePageTips"
            when: windowShown

            property var previousSetting
            property var previousCustomization
            property Item previousPaneParent

            Item {
                id: welcomePaneHost
                width: 900
                height: 700
            }

            function init() {
                previousSetting = UtilsAdapter.getAppValue(Settings.Key.ShowHomepageTips);
                previousCustomization = uut.uiCustomization;
                previousPaneParent = uut.rightPaneItem.parent;
                uut.uiCustomization = {};
                uut.rightPaneItem.parent = welcomePaneHost;
            }

            function cleanup() {
                uut.rightPaneItem.parent = previousPaneParent;
                UtilsAdapter.setAppValue(Settings.Key.ShowHomepageTips, previousSetting);
                uut.uiCustomization = previousCustomization;
            }

            function test_disableAndRestoreTips() {
                const tipsRow = findChild(uut.rightPaneItem, "loader_tipsRow");
                verify(tipsRow);

                UtilsAdapter.setToDefault(Settings.Key.ShowHomepageTips);
                tryVerify(() => tipsRow.item !== null);

                UtilsAdapter.setAppValue(Settings.Key.ShowHomepageTips, false);
                tryCompare(tipsRow, "item", null);

                UtilsAdapter.setToDefault(Settings.Key.ShowHomepageTips);
                tryVerify(() => tipsRow.item !== null);
            }

            function test_customizationCanStillDisableTips() {
                const tipsRow = findChild(uut.rightPaneItem, "loader_tipsRow");
                verify(tipsRow);

                UtilsAdapter.setToDefault(Settings.Key.ShowHomepageTips);
                tryVerify(() => tipsRow.item !== null);
                uut.uiCustomization = {
                    title: "",
                    description: "",
                    areTipsEnabled: false
                };
                tryCompare(tipsRow, "item", null);
            }
        }
    }
}
