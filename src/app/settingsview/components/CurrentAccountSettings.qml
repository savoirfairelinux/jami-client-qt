/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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
import Qt.labs.platform

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property bool isSIP

    property int contentWidth: currentAccountSettingsColumnLayout.width
    property int preferredHeight: currentAccountSettingsColumnLayout.implicitHeight
    property int preferredColumnWidth : Math.min(root.width / 2 - 50, 350)

    signal navigateToMainView
    signal navigateToNewWizardView
    signal advancedSettingsToggled(bool settingsVisible)

    function updateAccountInfoDisplayed() {
        bannedContacts.updateAndShowBannedContactsSlot()
    }

    function getAdvancedSettingsScrollPosition() {
        return advancedSettings.y
    }

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: currentAccountSettingsColumnLayout

        anchors.horizontalCenter: root.horizontalCenter

        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)

        ToggleSwitch {
            id: accountEnableCheckBox

            Layout.topMargin: JamiTheme.preferredMarginSize
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize

            labelText: JamiStrings.enableAccount
            fontPointSize: JamiTheme.headerFontSize

            checked: CurrentAccount.enabled

            onSwitchToggled: CurrentAccount.enableAccount(checked)
        }

        AccountProfile {
            id: accountProfile

            Layout.fillWidth: true
            Layout.topMargin: JamiTheme.preferredMarginSize
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
        }

        UserIdentity {
            id: userIdentity
            isSIP: root.isSIP

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize

            itemWidth: preferredColumnWidth
        }

        MaterialButton {
            id: passwdPushButton

            visible: !isSIP && CurrentAccount.managerUri === ""
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: JamiTheme.preferredMarginSize

            preferredWidth: JamiTheme.preferredFieldWidth
            preferredHeight: JamiTheme.preferredFieldHeight

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true

            toolTipText: CurrentAccount.hasArchivePassword ?
                             JamiStrings.changeCurrentPassword :
                             JamiStrings.setAPassword
            text: CurrentAccount.hasArchivePassword ?
                      JamiStrings.changePassword :
                      JamiStrings.setPassword

            iconSource: JamiResources.round_edit_24dp_svg

            onClicked: viewCoordinator.presentDialog(
                                   appWindow,
                                   "commoncomponents/PasswordDialog.qml",
                                   { purpose: CurrentAccount.hasArchivePassword ?
                                                  PasswordDialog.ChangePassword :
                                                  PasswordDialog.SetPassword })
        }

        MaterialButton {
            id: btnExportAccount

            visible: !isSIP && CurrentAccount.managerUri === ""
            Layout.alignment: Qt.AlignHCenter

            preferredWidth: JamiTheme.preferredFieldWidth
            preferredHeight: JamiTheme.preferredFieldHeight

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true

            toolTipText: JamiStrings.tipBackupAccount
            text: JamiStrings.backupAccountBtn

            iconSource: JamiResources.round_save_alt_24dp_svg

            onClicked: {
                var dlg = viewCoordinator.presentDialog(
                            appWindow,
                            "commoncomponents/JamiFileDialog.qml",
                            {
                                title: JamiStrings.backupAccountHere,
                                fileMode: FileDialog.SaveFile,
                                folder: StandardPaths.writableLocation(StandardPaths.DesktopLocation),
                                nameFilters: [JamiStrings.jamiArchiveFiles, JamiStrings.allFiles]
                            })
                dlg.fileAccepted.connect(function (file) {
                    // is there password? If so, go to password dialog, else, go to following directly
                    var exportPath = UtilsAdapter.getAbsPath(file.toString())
                    if (CurrentAccount.hasArchivePassword) {
                        viewCoordinator.presentDialog(
                                    appWindow,
                                    "commoncomponents/PasswordDialog.qml",
                                    {
                                        purpose: PasswordDialog.ExportAccount,
                                        path: exportPath
                                    })
                        return
                    } else if (exportPath.length > 0) {
                        var success = AccountAdapter.model.exportToFile(LRCInstance.currentAccountId, exportPath)
                        viewCoordinator.presentDialog(
                                    appWindow,
                                    "commoncomponents/SimpleMessageDialog.qml",
                                    {
                                        title: success ? JamiStrings.success : JamiStrings.error,
                                        infoText: success ? JamiStrings.backupSuccessful : JamiStrings.backupFailed,
                                        buttonTitles: [JamiStrings.optionOk],
                                        buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue]
                                    })
                    }
                })
            }
        }

        MaterialButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize

            preferredWidth: JamiTheme.preferredFieldWidth
            preferredHeight: JamiTheme.preferredFieldHeight

            color: JamiTheme.buttonTintedRed
            hoveredColor: JamiTheme.buttonTintedRedHovered
            pressedColor: JamiTheme.buttonTintedRedPressed

            text: JamiStrings.deleteAccount

            iconSource: JamiResources.delete_forever_24dp_svg

            onClicked: {
                var dlg = viewCoordinator.presentDialog(
                        appWindow,
                        "commoncomponents/DeleteAccountDialog.qml",
                        {
                            isSIP: CurrentAccount.type === Profile.Type.SIP,
                            bestName: CurrentAccount.bestName,
                            accountId: CurrentAccount.uri
                        })
                dlg.accepted.connect(navigateToMainView)
            }
        }

        LinkedDevices {
            id: linkedDevices
            visible: !isSIP

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
        }

        BannedContacts {
            id: bannedContacts
            isSIP: root.isSIP

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
        }

        AdvancedSettings {
            id: advancedSettings

            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.bottomMargin: 8

            itemWidth: preferredColumnWidth
            isSIP: root.isSIP

            onShowAdvancedSettingsRequest: {
                advancedSettingsToggled(settingsVisible)
            }
        }
    }
}
