/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import net.jami.Adapters 1.0
import net.jami.Enums 1.0
import net.jami.Models 1.0
import "../../commoncomponents"

ColumnLayout {
    id: root

    Label {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        text: JamiStrings.updatesTitle
        font.pointSize: JamiTheme.headerFontSize
        font.kerning: true

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    ToggleSwitch {
        id: autoUpdateCheckBox

        checked: SettingsAdapter.getAppValue(Settings.Key.AutoUpdate)
        fontPointSize: JamiTheme.settingsFontSize

        labelText: JamiStrings.autoUpdate
        tooltipText: JamiStrings.tipAutoUpdate

        onSwitchToggled: SettingsAdapter.setAppValue(Settings.Key.AutoUpdate, checked)
    }

    MaterialButton {
        id: checkUpdateButton

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: JamiTheme.preferredFieldWidth
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        color: enabled? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
        hoveredColor: JamiTheme.buttonTintedBlackHovered
        pressedColor: JamiTheme.buttonTintedBlackPressed
        outlined: true

        toolTipText: JamiStrings.checkForUpdates
        text: JamiStrings.checkForUpdates

        onClicked: UpdateManager.checkForUpdates()
    }

    MaterialButton {
        id: installBetaButton

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: JamiTheme.preferredFieldWidth
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        color: enabled? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
        hoveredColor: JamiTheme.buttonTintedBlackHovered
        pressedColor: JamiTheme.buttonTintedBlackPressed
        outlined: true

        toolTipText: JamiStrings.betaInstall
        text: JamiStrings.betaInstall

        onClicked: UpdateManager.applyUpdates(true)
    }

    Connections {
        target: UpdateManager

        function onUpdateCheckReplyReceived(ok, found) {

            if (!ok) {
                updateIssueDialog.openWithParameters(JamiStrings.updateDialogTitle,
                                                     JamiStrings.updateCheckError)
                return
            }
            if (!found) {
                updateIssueDialog.openWithParameters(JamiStrings.updateDialogTitle,
                                                     JamiStrings.updateNotFound)
            } else {
                updateConfirmInstallDialog.openWithParameters(JamiStrings.updateDialogTitle,
                                                              JamiStrings.updateFound)
            }
        }

        function onUpdateCheckErrorOccurred(error) {
            console.log("onUpdateCheckErrorOccurred " + error)
        }

        function onUpdateDownloadStarted() {
            updateDownloadDialog.progress = 0
            updateDownloadDialog.open(JamiStrings.updateDialogTitle)
            console.log("onUpdateDownloadStarted")
        }

        function onUpdateDownloadProgressChanged(bytesRead, totalBytes) {
            updateDownloadDialog.progress = ( bytesRead / totalBytes );
            console.log("onUpdateDownloadProgressChanged", bytesRead, totalBytes)
        }

        function onUpdateDownloadErrorOccurred(error) {
            updateDownloadDialog.close()
            var msg
            switch(error){
            case NetWorkManager.NETWORK_ERROR:
            case NetWorkManager.ACCESS_DENIED:
            case NetWorkManager.SSL_ERROR:
                msg = JamiStrings.updateDownloadNetworkError
                break
            case NetWorkManager.CANCELED:
                msg = JamiStrings.updateDownloadCanceled
                break
            default: break
            }
            updateIssueDialog.openWithParameters(JamiStrings.updateDialogTitle, msg)
        }

        function onUpdateDownloadFinished() {
            updateDownloadDialog.close()
            console.log("onUpdateDownloadFinished")
        }

        // move this to MainView
        function onAppCloseRequested() {
            console.log("onAppCloseRequested")
        }
    }

    SimpleMessageDialog {
        id: updateConfirmInstallDialog

        buttonTitles: [JamiStrings.optionOk, JamiStrings.optionCancel]
        buttonStyles: [
            SimpleMessageDialog.ButtonStyle.TintedBlue,
            SimpleMessageDialog.ButtonStyle.TintedBlue
        ]
        buttonCallBacks: [function() {UpdateManager.applyUpdates(false)}]
    }

    SimpleMessageDialog {
        id: updateIssueDialog

        buttonTitles: [JamiStrings.optionOk]
        buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue]
        buttonCallBacks: []
    }

    UpdateDownloadDialog {
        id: updateDownloadDialog
        property alias progress: progressBar.value

        innerContentData: ProgressBar {
            id: progressBar

            value: 0.0

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: JamiTheme.preferredMarginSize
        }

        buttonTitles: [JamiStrings.optionCancel]
        buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue]
        buttonCallBacks: [function() {UpdateManager.cancelUpdate()}]
    }
}
