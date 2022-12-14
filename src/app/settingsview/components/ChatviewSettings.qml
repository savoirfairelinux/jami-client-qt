/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

ColumnLayout {
    id:root

    property int itemWidth

    Label {
        Layout.fillWidth: true

        text: JamiStrings.chat
        font.pointSize: JamiTheme.headerFontSize
        font.kerning: true
        color: JamiTheme.textColor

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    ToggleSwitch {
        id: enableTypingIndicatorCheckbox

        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        checked: UtilsAdapter.getAppValue(Settings.EnableTypingIndicator)

        labelText: JamiStrings.enableTypingIndicator
        fontPointSize: JamiTheme.settingsFontSize

        tooltipText: JamiStrings.enableTypingIndicator

        onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.EnableTypingIndicator, checked)
    }

    ToggleSwitch {
        id: displayImagesCheckbox
        visible: WITH_WEBENGINE

        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        checked: UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews)

        labelText: JamiStrings.displayHyperlinkPreviews
        fontPointSize: JamiTheme.settingsFontSize

        tooltipText: JamiStrings.displayHyperlinkPreviews

        onSwitchToggled: {
            UtilsAdapter.setAppValue(Settings.Key.DisplayHyperlinkPreviews, checked)
        }
    }

    SettingsComboBox {
        id: outputComboBoxSetting

        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.leftMargin: JamiTheme.preferredMarginSize

        labelText: JamiStrings.layout
        tipText: JamiStrings.layout
        fontPointSize: JamiTheme.settingsFontSize
        comboModel: ListModel {
            id: layoutModel
            Component.onCompleted: {
                append({ textDisplay: JamiStrings.horizontalViewOpt })
                append({ textDisplay: JamiStrings.verticalViewOpt })
            }
        }
        widthOfComboBox: itemWidth
        role: "textDisplay"

        modelIndex: UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally) ? 1 : 0

        onActivated: {
            UtilsAdapter.setAppValue(
                Settings.Key.ShowChatviewHorizontally,
                comboModel.get(modelIndex).textDisplay === JamiStrings.verticalViewOpt
            )
        }

        Connections {
            target: UtilsAdapter

            function onChangeLanguage() {
                var idx = outputComboBoxSetting.modelIndex
                layoutModel.clear()
                layoutModel.append({ textDisplay: JamiStrings.horizontalViewOpt })
                layoutModel.append({ textDisplay: JamiStrings.verticalViewOpt })
                outputComboBoxSetting.modelIndex = idx
            }
        }
    }
}
