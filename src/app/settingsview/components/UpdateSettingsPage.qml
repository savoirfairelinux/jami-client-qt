/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import net.jami.Enums 1.1
import net.jami.Models 1.1
import net.jami.Helpers 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

SettingsPageBase {
    id: root

    title: JamiStrings.updatesTitle

    flickableContent: ColumnLayout {
        id: manageAccountEnableColumnLayout
        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ToggleSwitch {
            id: autoUpdateCheckBox

            Layout.fillWidth: true

            checked: Qt.platform.os.toString() === "windows" ? UtilsAdapter.getAppValue(Settings.Key.AutoUpdate) : AppVersionManager.isAutoUpdaterEnabled()

            labelText: JamiStrings.update
            tooltipText: JamiStrings.enableAutoUpdates

            onSwitchToggled: {
                UtilsAdapter.setAppValue(Settings.Key.AutoUpdate, checked);
                AppVersionManager.setAutoUpdateCheck(checked);
            }
        }

        MaterialButton {
            id: checkUpdateButton

            TextMetrics {
                id: checkUpdateButtonTextSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.capitalization: Font.AllUppercase
                text: checkUpdateButton.text
            }

            Layout.alignment: Qt.AlignLeft

            preferredWidth: checkUpdateButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding

            primary: true
            autoAccelerator: true

            toolTipText: JamiStrings.checkForUpdates
            text: JamiStrings.checkForUpdates

            onClicked: AppVersionManager.checkForUpdates()
        }

        MaterialButton {
            id: installBetaButton

            visible: !AppVersionManager.isCurrentVersionBeta() && Qt.platform.os.toString() === "windows"

            Layout.alignment: Qt.AlignHCenter

            preferredWidth: JamiTheme.preferredFieldWidth

            color: enabled ? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true
            autoAccelerator: true

            toolTipText: JamiStrings.betaInstall
            text: JamiStrings.betaInstall

            onClicked: appWindow.presentUpdateConfirmInstallDialog(true)
        }
    }
}
