/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
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
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"

SettingsPageBase {
    id: root
    property int itemWidth: 150

    title: JamiStrings.screenSharing

    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        SettingsComboBox {
            id: screenSharingFPSComboBoxSetting
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            currentSelectionText: VideoDevices.screenSharingDefaultFps.toString()
            fontPointSize: JamiTheme.settingsFontSize
            labelText: JamiStrings.fps
            placeholderText: VideoDevices.screenSharingDefaultFps.toString()
            role: "FPS"
            tipText: JamiStrings.selectScreenSharingFPS
            visible: modelSize > 0
            widthOfComboBox: itemWidth

            Component.onCompleted: {
                var elements = VideoDevices.sharingFpsSourceModel;
                for (var item in elements) {
                    screenSharingFpsModel.append({
                            "FPS": elements[item]
                        });
                }
            }
            onActivated: VideoDevices.setDisplayFPS(screenSharingFpsModel.get(modelIndex).FPS)

            comboModel: ListModel {
                id: screenSharingFpsModel
            }
        }
    }
}
