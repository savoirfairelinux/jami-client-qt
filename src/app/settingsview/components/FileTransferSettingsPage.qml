/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"

SettingsPageBase {
    id: root
    property int itemWidth: 164

    title: JamiStrings.fileTransfer

    flickableContent: ColumnLayout {
        id: callSettingsColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsCategorySpacing
        width: contentFlickableWidth

        ToggleSwitch {
            id: autoAcceptFilesCheckbox
            Layout.fillWidth: true
            checked: CurrentAccount.autoTransferFromTrusted
            labelText: JamiStrings.autoAcceptFiles
            tooltipText: JamiStrings.autoAcceptFiles

            onSwitchToggled: CurrentAccount.autoTransferFromTrusted = checked
        }
        SettingSpinBox {
            id: acceptTransferBelowSpinBox
            Layout.fillWidth: true
            bottomValue: 0
            itemWidth: root.itemWidth
            title: JamiStrings.acceptTransferBelow
            tooltipText: JamiStrings.acceptTransferTooltip
            valueField: CurrentAccount.autoTransferSizeThreshold

            onNewValue: CurrentAccount.autoTransferSizeThreshold = valueField
        }
        MaterialButton {
            id: defaultSettings
            preferredWidth: defaultSettingsTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
            secondary: true
            text: JamiStrings.defaultSettings

            onClicked: {
                autoAcceptFilesCheckbox.checked = UtilsAdapter.getDefault(Settings.Key.AutoAcceptFiles);
                acceptTransferBelowSpinBox.valueField = UtilsAdapter.getDefault(Settings.Key.AcceptTransferBelow);
                UtilsAdapter.setToDefault(Settings.Key.AutoAcceptFiles);
                UtilsAdapter.setToDefault(Settings.Key.AcceptTransferBelow);
            }

            TextMetrics {
                id: defaultSettingsTextSize
                font.capitalization: Font.AllUppercase
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.weight: Font.Bold
                text: defaultSettings.text
            }
        }
    }
}
