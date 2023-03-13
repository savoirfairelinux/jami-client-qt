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


Rectangle {
    id: root

    property int contentWidth: manageAccountEnableColumnLayout.width
    property int preferredHeight: manageAccountEnableColumnLayout.implicitHeight
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    function presentInfoDialog(infoText) {
        viewCoordinator.presentDialog(
                    appWindow,
                    "commoncomponents/SimpleMessageDialog.qml",
                    {
                        title: JamiStrings.updateDialogTitle,
                        infoText: infoText,
                        buttonTitles: [JamiStrings.optionOk],
                        buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue],
                        buttonCallBacks: []
                    })
    }

    function presentConfirmInstallDialog(infoText, beta) {
        viewCoordinator.presentDialog(
                    appWindow,
                    "commoncomponents/SimpleMessageDialog.qml",
                    {
                        title: JamiStrings.updateDialogTitle,
                        infoText: infoText,
                        buttonTitles: [JamiStrings.optionUpgrade, JamiStrings.optionLater],
                        buttonStyles: [
                            SimpleMessageDialog.ButtonStyle.TintedBlue,
                            SimpleMessageDialog.ButtonStyle.TintedBlue
                        ],
                        buttonCallBacks: [function() {UpdateManager.applyUpdates(beta)}]
                    })
    }

    ColumnLayout {

        id: manageAccountEnableColumnLayout
        anchors.left: root.left
        anchors.top: root.top
        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        spacing: JamiTheme.wizardViewPageBackButtonMargins *2
        anchors.topMargin: JamiTheme.wizardViewPageBackButtonSize



        ToggleSwitch {
            id: autoUpdateCheckBox

            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize

            checked: Qt.platform.os.toString() === "windows" ?
                         UtilsAdapter.getAppValue(Settings.Key.AutoUpdate) :
                         UpdateManager.isAutoUpdaterEnabled()

            labelText: JamiStrings.update
            tooltipText: JamiStrings.enableAutoUpdates
            fontPointSize: JamiTheme.settingsFontSize

            onSwitchToggled: {
                UtilsAdapter.setAppValue(Settings.Key.AutoUpdate, checked)
                UpdateManager.setAutoUpdateCheck(checked)
            }
        }

        MaterialButton {
            id: checkUpdateButton

            Layout.alignment: Qt.AlignLeft

            preferredWidth: JamiTheme.preferredFieldWidth
            preferredHeight: JamiTheme.preferredButtonSettingsHeight

            color: enabled? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
            primary: true
            autoAccelerator: true

            toolTipText: JamiStrings.checkForUpdates
            text: JamiStrings.checkForUpdates

            onClicked: UpdateManager.checkForUpdates()
        }

        MaterialButton {
            id: installBetaButton

            visible: !UpdateManager.isCurrentVersionBeta() && Qt.platform.os.toString()  === "windows"

            Layout.alignment: Qt.AlignHCenter

            preferredWidth: JamiTheme.preferredFieldWidth
            preferredHeight: JamiTheme.preferredButtonSettingsHeight

            color: enabled? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true
            autoAccelerator: true

            toolTipText: JamiStrings.betaInstall
            text: JamiStrings.betaInstall

            onClicked: presentConfirmInstallDialog(JamiStrings.confirmBeta, true)
        }

        Connections {
            target: UpdateManager

            function errorToString(error) {
                switch(error){
                case NetWorkManager.ACCESS_DENIED:
                    return JamiStrings.genericError
                case NetWorkManager.DISCONNECTED:
                    return JamiStrings.networkDisconnected
                case NetWorkManager.NETWORK_ERROR:
                    return JamiStrings.updateNetworkError
                case NetWorkManager.SSL_ERROR:
                    return JamiStrings.updateSSLError
                case NetWorkManager.CANCELED:
                    return JamiStrings.updateDownloadCanceled
                default: return {}
                }
            }

            function onUpdateDownloadStarted() {
                viewCoordinator.presentDialog(
                            appWindow,
                            "settingsview/components/UpdateDownloadDialog.qml",
                            {title: JamiStrings.updateDialogTitle})
            }

            function onUpdateCheckReplyReceived(ok, found) {
                if (!ok) {
                    presentInfoDialog(JamiStrings.updateCheckError)
                    return
                }
                if (!found) {
                    presentInfoDialog(JamiStrings.updateNotFound)
                } else {
                    presentConfirmInstallDialog(JamiStrings.updateFound, false)
                }
            }

            function onUpdateDownloadErrorOccurred(error) {
                presentInfoDialog(errorToString(error))
            }

            function onUpdateCheckErrorOccurred(error) {
                presentInfoDialog(errorToString(error))
            }
        }
    }
}
