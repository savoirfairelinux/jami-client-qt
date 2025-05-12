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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Item {
    id: cachedFile
    property string dictionaryPath: SpellCheckDictionaryManager.getDictionariesPath()
    property string downloadUrl: SpellCheckDictionaryManager.getDictionaryUrl()

    function updateDictionnary(languagePath) {
        var file = dictionaryPath + languagePath;
        SpellCheckHandler.updateDictionnary(file);
    }

    // Used on Windows and MacOS
    function downloadDictionary(languagePath) {
        if (downloadUrl === "") {
            return;
        }
        var file = dictionaryPath + languagePath;
        if (Qt.platform.os.toString() !== "linux") {
            console.warn("Download url: " + url);
            console.warn("Download file: " + file);
            if (url && url !== "" && file !== "") {
                FileDownloader.downloadFile(url + ".aff", file + ".aff");
                FileDownloader.downloadFile(url + ".dic", file + ".dic");
            }
        }
        MessagesAdapter.updateDictionary(file);
    }
}
