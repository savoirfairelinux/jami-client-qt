/*
 * Copyright (C) 2025-2026 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import SortFilterProxyModel 0.2
import "../../commoncomponents"
import "../../mainview/components"

SettingsComboBox {
    id: root
    height: JamiTheme.preferredFieldHeight
    labelText: JamiStrings.textLanguage
    tipText: JamiStrings.textLanguage
    comboModel: SortFilterProxyModel {
        id: installedDictionariesModel
        sourceModel: SpellCheckAdapter.getDictionaryListModel()

        // Filter to show only installed dictionaries
        filters: ValueFilter {
            roleName: "Installed"
            value: true
        }

        // Sort alphabetically by native name
        sorters: RoleSorter {
            roleName: "NativeName"
            sortOrder: Qt.AscendingOrder
        }
        Component.onCompleted: {
            // Ensure the model is updated with the latest dictionaries
            root.enabled = Qt.binding(function () {
                    return installedDictionariesModel.count > 0;
                });
        }
    }
    role: "NativeName"

    // Show placeholder when disabled
    placeholderText: JamiStrings.none

    function getCurrentLocaleIndex() {
        var currentLang = UtilsAdapter.getAppValue(Settings.Key.SpellLang);
        for (var i = 0; i < comboModel.count; i++) {
            var item = comboModel.get(i);
            if (item.Locale === currentLang)
                return i;
        }
        return -1;
    }

    // Set initial selection based on current spell language setting
    Component.onCompleted: modelIndex = getCurrentLocaleIndex()

    property string locale
    function setForIndex(index) {
        var selectedDict = comboModel.get(index);
        if (selectedDict && selectedDict.Locale && selectedDict.Installed) {
            locale = selectedDict.Locale;
        }
    }
    onLocaleChanged: SpellCheckAdapter.setDictionary(locale)

    // When the count changes, we might need to update the model index
    readonly property int count: installedDictionariesModel.count
    onCountChanged: {
        modelIndex = getCurrentLocaleIndex();
        // If the new index is -1 and we still have dictionaries, use the first one
        if (modelIndex === -1 && installedDictionariesModel.count > 0) {
            modelIndex = 0;
        }
    }

    // If the model index changes programmatically, we need to update the dictionary path
    onModelIndexChanged: setForIndex(modelIndex)
}
