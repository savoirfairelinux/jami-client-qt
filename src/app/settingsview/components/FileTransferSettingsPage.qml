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

    signal navigateToMainView
    signal navigateToNewWizardView
    title: JamiStrings.fileTransfer


    flickableContent: ColumnLayout {
        id: callSettingsColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ToggleSwitch {
            id: autoAcceptFilesCheckbox
            Layout.fillWidth: true
            Layout.topMargin: JamiTheme.preferredSettingsContentMarginSize

            checked: CurrentAccount.autoTransferFromTrusted

            labelText: JamiStrings.autoAcceptFiles
            fontPointSize: JamiTheme.settingsFontSize

            tooltipText: JamiStrings.autoAcceptFiles

            onSwitchToggled: CurrentAccount.autoTransferFromTrusted = checked
        }

        SettingSpinBox {
            id: acceptTransferBelowSpinBox
            Layout.fillWidth: true
            Layout.bottomMargin: JamiTheme.preferredSettingsContentMarginSize

            title: JamiStrings.acceptTransferBelow
            tooltipText: JamiStrings.acceptTransferTooltip
            itemWidth: root.itemWidth
            bottomValue: 0

            valueField: CurrentAccount.autoTransferSizeThreshold

            onNewValue: CurrentAccount.autoTransferSizeThreshold = valueField
        }
    }

    /* TO DO

    MaterialButton {
        id: defaultSettings

        TextMetrics{
            id: defaultSettingsTextSize
            font.weight: Font.Bold
            font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
            font.capitalization: Font.AllUppercase
            text: defaultSettings.text
        }

        secondary: true

        text: JamiStrings.defaultSettings
        preferredWidth: defaultSettingsTextSize.width + 2*JamiTheme.buttontextWizzardPadding
        preferredHeight: JamiTheme.preferredButtonSettingsHeight

        onClicked: {
        }

    }

    */

}
