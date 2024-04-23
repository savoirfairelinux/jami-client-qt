/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
    property string downloadUrl: UtilsAdapter.getDictionaryUrl()
    property string localPath: UtilsAdapter.getDictionaryPath()

    function updateDictionnary(language) {
        if (downloadUrl === "") {
            return;
        }
        
        var aff_file = localPath + language + "/fr.aff";
        var dic_file = localPath + language + "/fr.dic";
        var aff_url = downloadUrl + language + "/fr.aff";
        var dic_url = downloadUrl + language + "/fr.dic";

        if (dic_url && dic_url !== "" && dic_file !== "") {
            FileDownloader.downloadFile(dic_url, dic_file);
        }
        if (aff_url && aff_url !== "" && aff_file !== "") {
            FileDownloader.downloadFile(aff_url, aff_file);
        }
    }
}
