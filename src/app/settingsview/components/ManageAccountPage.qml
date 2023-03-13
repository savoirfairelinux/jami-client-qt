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
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

import "../../commoncomponents"

SettingsPageBase {
    id: root

    property bool isSIP

    signal navigateToMainView
    signal navigateToNewWizardView
    title: JamiStrings.manageAccountSettingsTitle

    flickableContent: ColumnLayout {

        id: manageAccountColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {
            id: enableAccount

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing
            Layout.topMargin: JamiTheme.preferredSettingsContentMarginSize

            Text {
                id: enableAccountTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.enableAccount
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true

            }

            ToggleSwitch {
                id: accountEnableSwitch

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                labelText: JamiStrings.enableAccountDescription

                widthOfSwitch: 60
                heightOfSwitch: 30

                checked: CurrentAccount.enabled
                onSwitchToggled: CurrentAccount.enableAccount(checked)
            }

        }

        ColumnLayout {
            id: jamiIdentity

            width: parent.width
            visible: !isSIP
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: jamiIdentityTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                text: JamiStrings.jamiIdentity
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            JamiIdentifier {
                id: jamiIdentifier

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: 10
                Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredSettingsMarginSize * 2)
                backgroundColor: JamiTheme.jamiIdColor
            }

            Text {
                id: jamiIdentifierDescription

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.usernameAccountDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                font.kerning: true
                lineHeight: JamiTheme.wizardViewTextLineHeight
            }

        }

        ColumnLayout {
            id: encryptAccount

            width: parent.width
            visible: !isSIP && CurrentAccount.managerUri === ""
            spacing: JamiTheme.settingsCategorySpacing


            Text {
                id: encryptTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.encryptTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Text {
                id: encryptDescription

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.ecryptAccountDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                font.kerning: true
                lineHeight: JamiTheme.wizardViewTextLineHeight
            }

            MaterialButton {
                id: passwdPushButton

                primary: true
                Layout.alignment: Qt.AlignLeft

                preferredWidth: JamiTheme.preferredFieldWidth
                preferredHeight: JamiTheme.preferredButtonSettingsHeight

                toolTipText: CurrentAccount.hasArchivePassword ?
                                 JamiStrings.changeCurrentPassword :
                                 JamiStrings.setAPassword
                text: CurrentAccount.hasArchivePassword ?
                          JamiStrings.changePassword :
                          JamiStrings.setPassword

                onClicked: viewCoordinator.presentDialog(
                               appWindow,
                               "commoncomponents/PasswordDialog.qml",
                               { purpose: CurrentAccount.hasArchivePassword ?
                                              PasswordDialog.ChangePassword :
                                              PasswordDialog.SetPassword })
            }
        }

        ColumnLayout {

            id: saveAccount
            width: parent.width
            visible: !isSIP && CurrentAccount.managerUri === ""
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: saveTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.saveAccountTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Text {
                id: saveDescription

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.saveAccountDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                font.kerning: true
                lineHeight: JamiTheme.wizardViewTextLineHeight
            }


            MaterialButton {
                id: btnExportAccount

                primary: true
                Layout.alignment: Qt.AlignLeft

                preferredWidth: JamiTheme.preferredFieldWidth
                preferredHeight: JamiTheme.preferredButtonSettingsHeight

                toolTipText: JamiStrings.tipBackupAccount
                text: JamiStrings.saveAccountTitle

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

        }

        ColumnLayout {
            id: manageAccountDeleteColumnLayout
            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: deleteTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.deleteAccountTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Text {
                id: deleteDescription

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.deleteAccountDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                font.kerning: true
                lineHeight: JamiTheme.wizardViewTextLineHeight
            }


            MaterialButton {

                primary: true
                Layout.alignment: Qt.AlignLeft
                Layout.rightMargin: JamiTheme.preferredMarginSize
                Layout.bottomMargin: 30

                color: JamiTheme.buttonTintedRed
                hoveredColor: JamiTheme.buttonTintedRedHovered
                pressedColor: JamiTheme.buttonTintedRedPressed

                preferredWidth: JamiTheme.preferredFieldWidth
                preferredHeight: JamiTheme.preferredButtonSettingsHeight

                text: JamiStrings.deleteAccount

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

        }
    }
}
