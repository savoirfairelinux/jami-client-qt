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
import Qt.labs.platform // Jamifiledialog

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property int contentWidth: manageAccountEnableColumnLayout.width
    property int preferredHeight: manageAccountEnableColumnLayout.implicitHeight
    property int preferredColumnWidth : Math.min(root.width / 2 - 50, 350)
    property bool isSIP

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {

        id: manageAccountEnableColumnLayout
        anchors.left: root.left
        anchors.leftMargin: JamiTheme.preferredMarginSize * 2
        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        implicitHeight: manageAccount.height

        ColumnLayout {
            id: manageAccount
            Layout.fillWidth: true
            visible: !isSIP

            Text {
                id: usernameTitle

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.username
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.weight: Font.Medium
                font.pixelSize: 22
                font.kerning: true
            }

            JamiIdentifier {
                id: identifier

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                Layout.preferredWidth: Math.min(600, root.width - JamiTheme.preferredMarginSize * 2)
            }

            Text {
                id: serialIdentifier

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: "Serial Identifier"
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.weight: Font.Medium
                font.pixelSize: 13
                font.kerning: true
            }

            Text {
                id: usernameDescription

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: 20
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.usernameAccountDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: 15
                font.kerning: true
            }

            Rectangle {

                height: 1
                opacity: 0.3
                color: "black"
                Layout.preferredWidth: Math.min(515, root.width - JamiTheme.preferredMarginSize * 2)
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins

            }


            Text {
                id: encryptTitle

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.encryptTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.weight: Font.Medium
                font.pixelSize: 22
                font.kerning: true
            }

            Text {
                id: encryptDescription

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.ecryptAccountDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: 15
                font.kerning: true
            }

            MaterialButton {
                id: passwdPushButton

                primary: true
                visible: CurrentAccount.managerUri === ""
                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.preferredMarginSize

                preferredWidth: JamiTheme.preferredFieldWidth
                preferredHeight: JamiTheme.preferredFieldHeight

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

            Rectangle {

                height: 1
                opacity: 0.3
                color: "black"
                Layout.preferredWidth: Math.min(515, root.width - JamiTheme.preferredMarginSize * 2)
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins

            }

            Text {
                id: saveTitle

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.saveAccountTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.weight: Font.Medium
                font.pixelSize: 22
                font.kerning: true
            }

            Text {
                id: saveDescription

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.saveAccountDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: 15
                font.kerning: true
            }


            MaterialButton {
                id: btnExportAccount

                primary: true
                visible: CurrentAccount.managerUri === ""
                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.preferredMarginSize

                preferredWidth: JamiTheme.preferredFieldWidth
                preferredHeight: JamiTheme.preferredFieldHeight

                toolTipText: JamiStrings.tipBackupAccount
                text: JamiStrings.backupAccountBtn

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
            Layout.fillWidth: true

            Rectangle {

                height: 1
                opacity: 0.3
                color: "black"
                visible: !isSIP
                Layout.preferredWidth: Math.min(515, root.width - JamiTheme.preferredMarginSize * 2)
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins

            }

            Text {
                id: deleteTitle

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.deleteAccountTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.weight: Font.Medium
                font.pixelSize: 22
                font.kerning: true
            }

            Text {
                id: deleteDescription

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.deleteAccountDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: 15
                font.kerning: true
            }


            MaterialButton {

                primary: true
                Layout.alignment: Qt.AlignLeft
                Layout.rightMargin: JamiTheme.preferredMarginSize
                Layout.topMargin: JamiTheme.preferredMarginSize

                preferredWidth: JamiTheme.preferredFieldWidth
                preferredHeight: JamiTheme.preferredFieldHeight

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
