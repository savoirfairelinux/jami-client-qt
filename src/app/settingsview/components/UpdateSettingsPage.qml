/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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

    function presentConfirmInstallDialog(infoText, beta) {
        viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                "title": JamiStrings.updateDialogTitle,
                "infoText": infoText,
                "buttonTitles": [JamiStrings.optionUpgrade, JamiStrings.optionLater],
                "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue, SimpleMessageDialog.ButtonStyle.TintedBlue],
                "buttonCallBacks": [function () {
                        UpdateManager.applyUpdates(beta);
                    }]
            });
    }
    function presentInfoDialog(infoText) {
        viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                "title": JamiStrings.updateDialogTitle,
                "infoText": infoText,
                "buttonTitles": [JamiStrings.optionOk],
                "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue],
                "buttonCallBacks": []
            });
    }

    flickableContent: ColumnLayout {
        id: manageAccountEnableColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        ToggleSwitch {
            id: autoUpdateCheckBox
            Layout.fillWidth: true
            checked: Qt.platform.os.toString() === "windows" ? UtilsAdapter.getAppValue(Settings.Key.AutoUpdate) : UpdateManager.isAutoUpdaterEnabled()
            labelText: JamiStrings.update
            tooltipText: JamiStrings.enableAutoUpdates

            onSwitchToggled: {
                UtilsAdapter.setAppValue(Settings.Key.AutoUpdate, checked);
                UpdateManager.setAutoUpdateCheck(checked);
            }
        }
        MaterialButton {
            id: checkUpdateButton
            Layout.alignment: Qt.AlignLeft
            autoAccelerator: true
            preferredWidth: checkUpdateButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
            primary: true
            text: JamiStrings.checkForUpdates
            toolTipText: JamiStrings.checkForUpdates

            onClicked: UpdateManager.checkForUpdates()

            TextMetrics {
                id: checkUpdateButtonTextSize
                font.capitalization: Font.AllUppercase
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.weight: Font.Bold
                text: checkUpdateButton.text
            }
        }
        MaterialButton {
            id: installBetaButton
            Layout.alignment: Qt.AlignHCenter
            autoAccelerator: true
            color: enabled ? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            preferredWidth: JamiTheme.preferredFieldWidth
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true
            text: JamiStrings.betaInstall
            toolTipText: JamiStrings.betaInstall
            visible: !UpdateManager.isCurrentVersionBeta() && Qt.platform.os.toString() === "windows"

            onClicked: viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                    "title": JamiStrings.updateDialogTitle,
                    "infoText": JamiStrings.confirmBeta,
                    "buttonTitles": [JamiStrings.optionUpgrade, JamiStrings.optionLater],
                    "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue, SimpleMessageDialog.ButtonStyle.TintedBlue],
                    "buttonCallBacks": [function () {
                            UpdateManager.applyUpdates(true);
                        }]
                })
        }
    }
}
