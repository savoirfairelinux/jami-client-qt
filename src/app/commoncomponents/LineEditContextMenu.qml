/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
    property var suggestionList
    property var menuItemsLength
    property var language

    signal contextMenuRequirePaste

    SpellLanguageContextMenu {
        id: spellLanguageContextMenu
        active: isSpellCheckActive()
    }

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: cut

            canTrigger: root.selectionStart !== root.selectionEnd && !root.selectOnly
            itemName: JamiStrings.cut
            iconSource: JamiResources.content_cut_24dp_svg
            onClicked: root.lineEditObj.cut()
        },
        GeneralMenuItem {
            id: copy

            canTrigger: root.selectionStart !== root.selectionEnd
            itemName: JamiStrings.copy
            iconSource: JamiResources.content_copy_24dp_svg
            onClicked: root.lineEditObj.copy()
        },
        GeneralMenuItem {
            id: paste

            canTrigger: !root.selectOnly && root.lineEditObj && root.lineEditObj.canPaste
            itemName: JamiStrings.paste
            iconSource: JamiResources.content_paste_24dp_svg
            onClicked: {
                if (root.customizePaste)
                    root.contextMenuRequirePaste();
                else
                    root.lineEditObj.paste();
            }
        },
        GeneralMenuItem {
            id: textLanguage
            canTrigger: isSpellCheckActive() && SpellCheckAdapter.installedDictionaryCount > 0 && !root.selectOnly
            itemName: JamiStrings.textLanguage
            iconSource: JamiResources.spellcheck_24dp_svg
            onClicked: {
                spellLanguageContextMenu.openMenu();
            }
        },
        GeneralMenuItem {
            id: manageLanguages
            itemName: JamiStrings.dictionaryManager
            canTrigger: isSpellCheckActive() && !root.selectOnly
            iconSource: JamiResources.dictionary_24dp_svg
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

                canTrigger: !root.selectOnly
                itemName: model.name
                bold: true
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

    function isSpellCheckActive() {
        return AppSettingsManager.getValue(Settings.EnableSpellCheck) && AppSettingsManager.getValue(Settings.SpellLang);
    }

    Connections {
        target: UtilsAdapter

        function onEnableSpellCheckChanged() {
            textLanguage.canTrigger = isSpellCheckActive() && SpellCheckAdapter.installedDictionaryCount > 0 && !root.selectOnly;
            manageLanguages.canTrigger = isSpellCheckActive() && !root.selectOnly;
        }

        function onSpellLanguageChanged() {
            textLanguage.canTrigger = isSpellCheckActive() && SpellCheckAdapter.installedDictionaryCount > 0 && !root.selectOnly;
            manageLanguages.canTrigger = isSpellCheckActive() && !root.selectOnly;
        }
    }

    Component.onCompleted: menuItemsToLoad = menuItems
}
