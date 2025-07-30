/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"

JamiComboBox {
    id: root

    accessibilityName: JamiStrings.userInterfaceLanguage
    accessibilityDescription: JamiStrings.languageComboBoxExplanation
    comboBoxPointSize: JamiTheme.settingsFontSize

    textRole: "textDisplay"
    model: ListModel {
        id: langModel
        Component.onCompleted: {
            var supported = UtilsAdapter.supportedLang();
            var keys = Object.keys(supported);
            var currentKey = UtilsAdapter.getAppValue(Settings.Key.LANG);
            for (var i = 0; i < keys.length; ++i) {
                append({
                    "textDisplay": supported[keys[i]],
                    "id": keys[i]
                });
                if (keys[i] === currentKey)
                    root.currentIndex = i;
            }
        }
    }
    onActivated: {
        UtilsAdapter.setAppValue(Settings.Key.LANG, langModel.get(currentIndex).id);
    }
}
