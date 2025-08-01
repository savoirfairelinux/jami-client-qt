/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "contextmenu"
import "../mainview"
import "../mainview/components"

ContextMenuAutoLoader {
    id: root

    // lineEdit (TextEdit) selection will be lost when menu is opened
    property var lineEditObj
    property var selectionStart
    property var selectionEnd
    property bool customizePaste: false
    property bool selectOnly: false
    property bool spellCheckEnabled: false
    property var suggestionList
    property var menuItemsLength
    property var language

    signal contextMenuRequirePaste

    SpellLanguageContextMenu {
        id: spellLanguageContextMenu
        active: spellCheckEnabled
    }

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: cut

            canTrigger: true
            isActif: lineEditObj.selectedText.length && !selectOnly
            itemName: JamiStrings.cut
            hasIcon: false
            onClicked: lineEditObj.cut()
        },
        GeneralMenuItem {
            id: copy

            canTrigger: true
            isActif: lineEditObj.selectedText.length
            itemName: JamiStrings.copy
            hasIcon: false
            onClicked: lineEditObj.copy()
        },
        GeneralMenuItem {
            id: paste

            canTrigger: !selectOnly
            itemName: JamiStrings.paste
            hasIcon: false
            onClicked: {
                if (customizePaste)
                    root.contextMenuRequirePaste();
                else
                    lineEditObj.paste();
            }
        },
        GeneralMenuItem {
            id: textLanguage
            canTrigger: spellCheckEnabled && SpellCheckAdapter.installedDictionaryCount > 0
            itemName: JamiStrings.textLanguage
            hasIcon: false
            onClicked: {
                spellLanguageContextMenu.openMenu();
            }
        },
        GeneralMenuItem {
            id: manageLanguages
            itemName: JamiStrings.dictionaryManager
            canTrigger: spellCheckEnabled
            hasIcon: false
            onClicked: {
                viewCoordinator.presentDialog(appWindow, "commoncomponents/DictionaryManagerDialog.qml");
            }
        }
    ]

    ListView {
        model: ListModel {
            id: suggestionListModel
        }

        Instantiator {
            model: suggestionListModel
            delegate: GeneralMenuItem {
                id: suggestion

                canTrigger: true
                isActif: true
                itemName: model.name
                bold: true
                hasIcon: false
                onClicked: {
                    replaceWord(model.name);
                }
            }

            onObjectAdded: {
                menuItems.push(object);
            }

            onObjectRemoved: {
                menuItems.splice(menuItemsLength, suggestionList.length);
            }
        }
    }

    function removeItems() {
        suggestionListModel.clear();
        suggestionList.length = 0;
    }

    function addMenuItem(wordList) {
        menuItemsLength = menuItems.length; // Keep initial number of items for easier removal
        suggestionList = wordList;
        for (var i = 0; i < suggestionList.length; ++i) {
            suggestionListModel.append({
                    "name": suggestionList[i]
                });
        }
    }

    function replaceWord(word) {
        lineEditObj.remove(selectionStart, selectionEnd);
        lineEditObj.insert(lineEditObj.cursorPosition, word);
    }

    function openMenuAt(mouseEvent) {
        if (lineEditObj.selectedText.length === 0 && selectOnly)
            return;
        x = mouseEvent.x;
        y = mouseEvent.y;
        selectionStart = lineEditObj.selectionStart;
        selectionEnd = lineEditObj.selectionEnd;
        root.openMenu();
        lineEditObj.select(selectionStart, selectionEnd);
    }

    Connections {
        target: root.item
        enabled: root.status === Loader.Ready
        function onOpened() {
            lineEditObj.select(selectionStart, selectionEnd);
        }
        function onClosed() {
            if (!suggestionList || suggestionList.length === 0) {
                return;
            }
            removeItems();
        }
    }

    Component.onCompleted: menuItemsToLoad = menuItems
}
