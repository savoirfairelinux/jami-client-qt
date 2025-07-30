/*
 * Copyright (C) 2024-2025 Savoir-faire Linux Inc.
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

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        RowLayout {
            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: JamiTheme.preferredMarginSize
                wrapMode: Text.WordWrap
                color: JamiTheme.textColor
                text: JamiStrings.fps
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            JamiComboBox {
                id: screenSharingFPSComboBoxSetting

                visible: screenSharingFPSComboBoxSetting.count > 0

                width: itemWidth
                height: JamiTheme.preferredFieldHeight

                accessibilityName: JamiStrings.screenSharingFPS
                accessibilityDescription: JamiStrings.screenSharingFPSDescription
                comboBoxPointSize: JamiTheme.settingsFontSize

                textRole: "FPS"
                model: ListModel {
                    id: screenSharingFPSModel
                    Component.onCompleted: {
                        var elements = VideoDevices.sharingFpsSourceModel;
                        var defaultFps = VideoDevices.screenSharingDefaultFps;
                        for (var item in elements) {
                            screenSharingFPSModel.append({
                                "FPS": elements[item]
                            });
                            if (elements[item] === defaultFps) {
                                screenSharingFPSComboBoxSetting.currentIndex = screenSharingFPSModel.count - 1;
                            }
                        }
                    }
                }

                onActivated: VideoDevices.setDisplayFPS(screenSharingFPSModel.get(screenSharingFPSComboBoxSetting.currentIndex).FPS)
            }
        }
    }
}
