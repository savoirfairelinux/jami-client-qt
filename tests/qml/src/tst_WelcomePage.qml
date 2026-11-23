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

        Item {
            id: welcomePaneHost
            width: 900
            height: 700
        }

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

            Component {
                id: tipsRowComponent

                TipsRow {
                    width: welcomePaneHost.width
                    y: 200
                    z: 1
                }
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
                const disableButton = findChild(uut.rightPaneItem, "disableHomepageTipsButton");
                verify(tipsRow);
                verify(disableButton);

                UtilsAdapter.setToDefault(Settings.Key.ShowHomepageTips);
                tryVerify(() => tipsRow.item !== null);
                tryCompare(disableButton, "visible", true);

                mouseClick(disableButton);
                tryCompare(tipsRow, "item", null);
                compare(disableButton.visible, false);
                compare(UtilsAdapter.getAppValue(Settings.Key.ShowHomepageTips), false);

                UtilsAdapter.setToDefault(Settings.Key.ShowHomepageTips);
                tryVerify(() => tipsRow.item !== null);
                tryCompare(disableButton, "visible", true);
            }

            function test_dismissTipWithMouse() {
                const tipsRow = createTemporaryObject(tipsRowComponent, welcomePaneHost);
                verify(tipsRow);
                const row = tipsRow.contentItem.children.find(item =>
                    item.children.some(child => child.type === "tip"));
                verify(row);
                const tip = row.children.find(item => item.type === "tip");
                verify(tip);
                const count = tipsRow.visibleTipBoxCount;
                tip.forceActiveFocus();
                tryCompare(tip, "opened", true);
                const deleteButton = findChild(tip, "dismissTipButton");
                verify(deleteButton);
                mouseClick(deleteButton);
                tryCompare(tip, "visible", false);
                compare(tipsRow.visibleTipBoxCount, count - 1);
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
