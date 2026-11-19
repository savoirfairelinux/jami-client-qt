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

import "../../../src/app/commoncomponents"
import "../../../src/app/mainview/components"

TestWrapper {
    id: root

    width: 600
    height: 640

    Component {
        id: dialogComponent

        AddToListDialog {}
    }

    Component {
        id: chipComponent

        JamiChip {
            text: "Add"
            iconSource: JamiResources.add_24dp_svg
        }
    }

    SignalSpy {
        id: submittedSpy
        signalName: "submitted"
    }

    Component {
        id: signalSpy

        SignalSpy {}
    }

    TestCase {
        name: "AddToListDialog"
        when: windowShown

        function openDialog(available, selected) {
            const dialog = createTemporaryObject(dialogComponent, root, {
                availableLists: available,
                initialSelection: selected
            });
            verify(dialog);
            submittedSpy.clear();
            submittedSpy.target = dialog;
            dialog.open();
            tryCompare(dialog, "opened", true);
            return dialog;
        }

        function child(dialog, name) {
            const item = findChild(dialog.contentItem, name);
            verify(item, name);
            return item;
        }

        function submit(dialog) {
            mouseClick(dialog.button3);
            compare(submittedSpy.count, 1);
            return submittedSpy.signalArguments[0][0];
        }

        function test_chipClickOnlyWhenClickable() {
            const chip = createTemporaryObject(chipComponent, root);
            const clickedSpy = signalSpy.createObject(chip, {target: chip, signalName: "clicked"});
            const iconSpy = signalSpy.createObject(chip, {target: chip, signalName: "iconClicked"});
            waitForRendering(chip);
            const plainChip = createTemporaryObject(chipComponent, root, {iconSource: "", y: 100});
            compare(chip.height, plainChip.height);

            mouseClick(chip, 10, chip.height / 2);
            compare(clickedSpy.count, 0);

            chip.clickable = true;
            mouseClick(chip, 10, chip.height / 2);
            compare(clickedSpy.count, 1);
            chip.forceActiveFocus();
            keyClick(Qt.Key_Space);
            compare(clickedSpy.count, 2);

            mouseClick(chip, chip.width - 12, chip.height / 2);
            compare(iconSpy.count, 1);
            compare(clickedSpy.count, 2);
        }

        function test_toggleExistingLists() {
            const dialog = openDialog(["Family", "work"], ["work"]);
            compare(child(dialog, "addToListChip_work").variant, JamiChip.Variant.Filled);
            compare(child(dialog, "addToListChip_Family").variant, JamiChip.Variant.Outlined);

            mouseClick(child(dialog, "addToListChip_Family"));
            mouseClick(child(dialog, "addToListChip_work"));

            compare(submit(dialog), ["Family"]);
        }

        function test_createFromSearch() {
            const dialog = openDialog(["work"], []);
            const search = child(dialog, "addToListSearch");
            tryCompare(search.textField, "activeFocus", true);

            search.text = "  Friends ";
            const createChip = child(dialog, "addToListCreateChip");
            tryCompare(createChip, "visible", true);
            compare(dialog.filteredLists, []);
            waitForRendering(createChip);
            mouseClick(createChip);

            compare(search.text, "");
            compare(child(dialog, "addToListChip_Friends").variant, JamiChip.Variant.Filled);
            compare(submit(dialog), ["Friends"]);
        }

        function test_enterSelectsExistingListCaseInsensitively() {
            const dialog = openDialog(["Work"], []);
            const search = child(dialog, "addToListSearch");
            search.text = "work";
            compare(dialog.canCreate, false);
            search.textField.forceActiveFocus();
            keyClick(Qt.Key_Return);

            compare(dialog.allLists, ["Work"]);
            compare(submit(dialog), ["Work"]);
        }

        function test_emptyState() {
            const dialog = openDialog([], []);
            verify(child(dialog, "addToListEmptyLabel").visible);
            child(dialog, "addToListSearch").text = "New";
            tryCompare(child(dialog, "addToListEmptyLabel"), "visible", false);
        }
    }
}
