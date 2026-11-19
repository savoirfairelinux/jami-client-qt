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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1
import "../../commoncomponents"

// Generic dialog to pick existing lists or create new ones. It does not
// persist anything itself: callers handle `submitted` and close the dialog.
BaseModalDialog {
    id: root
    objectName: "AddToListDialog"

    // Lists that already exist and can be picked.
    property var availableLists: []
    // Lists selected when the dialog opens.
    property var initialSelection: []
    property string errorText: ""
    property bool busy: false

    property var selectedLists: []
    // Lists created in this dialog, before they are saved.
    property var createdLists: []

    readonly property var allLists: {
        const result = [];
        for (const name of [...availableLists, ...createdLists, ...selectedLists]) {
            if (!result.includes(name))
                result.push(name);
        }
        return result.sort((a, b) => a.localeCompare(b, undefined, {
                    "sensitivity": "base"
                }));
    }
    readonly property string query: searchBar.text.trim()
    readonly property var filteredLists: {
        const q = query.toLowerCase();
        return q.length ? allLists.filter(name => name.toLowerCase().includes(q)) : allLists;
    }
    readonly property bool canCreate: query.length > 0 && findList(query) === ""

    signal submitted(var lists)

    titleText: JamiStrings.addToList
    title: titleText
    implicitWidth: Math.min(400, parent ? Math.max(0, parent.width - 64) : 400)
    autoClose: !busy
    closeButtonVisible: !busy

    function findList(name) {
        const lower = name.toLowerCase();
        return allLists.find(existing => existing.toLowerCase() === lower) || "";
    }

    function isSelected(name) {
        return selectedLists.includes(name);
    }

    function toggleList(name) {
        if (isSelected(name))
            selectedLists = selectedLists.filter(selected => selected !== name);
        else
            selectedLists = [...selectedLists, name];
    }

    // Selects the matching list, or creates it when there is none.
    function createOrSelect(text) {
        const name = text.trim();
        if (!name.length)
            return;
        const existing = findList(name);
        if (existing === "")
            createdLists = [...createdLists, name];
        const target = existing || name;
        if (!isSelected(target))
            selectedLists = [...selectedLists, target];
        searchBar.clearText();
    }

    onAboutToShow: {
        selectedLists = Array.from(initialSelection);
        createdLists = [];
        errorText = "";
    }
    onOpened: searchBar.setTextAreaFocus()

    button3.objectName: "addToListSaveButton"
    button3.text: JamiStrings.optionSave
    button3.textButton: false
    button3.filledButton: true
    button3.enabled: !busy
    button3.onClicked: {
        errorText = "";
        root.submitted(Array.from(selectedLists));
    }

    contentItem: ColumnLayout {
        spacing: 12

        Searchbar {
            id: searchBar
            objectName: "addToListSearch"
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
            placeHolderText: JamiStrings.searchOrCreateList
            enabled: !root.busy
            onAccepted: function (text) {
                root.createOrSelect(text);
            }
        }

        Flow {
            id: listFlow
            objectName: "addToListFlow"
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.filteredLists

                delegate: JamiChip {
                    objectName: "addToListChip_" + modelData
                    text: modelData
                    clickable: !root.busy
                    variant: root.isSelected(modelData) ? JamiChip.Variant.Filled : JamiChip.Variant.Outlined
                    width: Math.min(implicitWidth, listFlow.width)
                    toolTipText: text
                    Accessible.checkable: true
                    Accessible.checked: root.isSelected(modelData)
                    onClicked: root.toggleList(modelData)
                }
            }

            JamiChip {
                objectName: "addToListCreateChip"
                visible: root.canCreate
                text: JamiStrings.createList.arg(root.query)
                clickable: !root.busy
                variant: JamiChip.Variant.Neutral
                width: Math.min(implicitWidth, listFlow.width)
                toolTipText: text
                onClicked: root.createOrSelect(root.query)
            }
        }

        Label {
            objectName: "addToListEmptyLabel"
            Layout.fillWidth: true
            visible: root.allLists.length === 0 && !root.canCreate
            text: JamiStrings.noListsYet
            color: JamiTheme.faddedLastInteractionFontColor
            wrapMode: Text.WordWrap
        }

        Label {
            objectName: "addToListErrorLabel"
            Layout.fillWidth: true
            visible: root.errorText.length > 0
            text: root.errorText
            color: JamiTheme.redColor
            wrapMode: Text.WordWrap
        }
    }
}
