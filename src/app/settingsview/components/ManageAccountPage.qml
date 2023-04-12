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
    property bool isSIP: CurrentAccount.type === Profile.Type.SIP
    property int itemWidth: 250

    title: JamiStrings.manageAccountSettingsTitle

    signal navigateToMainView

    onNavigateToMainView: viewNode.dismiss()

    flickableContent: ColumnLayout {
        id: manageAccountColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        ColumnLayout {
            id: enableAccount
            spacing: JamiTheme.settingsCategorySpacing
            width: parent.width

            Text {
                id: enableAccountTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.enableAccountSettingsTitle
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            ToggleSwitch {
                id: accountEnableSwitch
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                checked: CurrentAccount.enabled
                heightOfSwitch: 30
                labelText: JamiStrings.enableAccountDescription
                widthOfSwitch: 60

                onSwitchToggled: CurrentAccount.enableAccount(checked)
            }
        }
        ColumnLayout {
            id: userIdentity
            spacing: JamiTheme.settingsCategorySpacing
            visible: isSIP
            width: parent.width

            Text {
                id: userIdentityTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.identity
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            SIPUserIdentity {
                id: sipUserIdentity
                Layout.fillWidth: true
                itemWidth: root.itemWidth
            }
        }
        ColumnLayout {
            id: jamiIdentity
            spacing: JamiTheme.settingsCategorySpacing
            visible: !isSIP
            width: parent.width

            Text {
                id: jamiIdentityTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.jamiIdentity
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            JamiIdentifier {
                id: jamiIdentifier
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredSettingsMarginSize)
                Layout.topMargin: 10
                backgroundColor: JamiTheme.jamiIdColor
            }
            Text {
                id: jamiIdentifierDescription
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                horizontalAlignment: Text.AlignLeft
                lineHeight: JamiTheme.wizardViewTextLineHeight
                text: JamiStrings.usernameAccountDescription
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
        }
        ColumnLayout {
            id: encryptAccount
            spacing: JamiTheme.settingsCategorySpacing
            visible: !isSIP && CurrentAccount.managerUri === ""
            width: parent.width

            Text {
                id: encryptTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.encryptTitle
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            Text {
                id: encryptDescription
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                horizontalAlignment: Text.AlignLeft
                lineHeight: JamiTheme.wizardViewTextLineHeight
                text: JamiStrings.ecryptAccountDescription
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            MaterialButton {
                id: passwdPushButton
                Layout.alignment: Qt.AlignLeft
                preferredWidth: passwdPushButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
                primary: true
                text: CurrentAccount.hasArchivePassword ? JamiStrings.changePassword : JamiStrings.setPassword
                toolTipText: CurrentAccount.hasArchivePassword ? JamiStrings.changeCurrentPassword : JamiStrings.setAPassword

                onClicked: viewCoordinator.presentDialog(appWindow, "commoncomponents/PasswordDialog.qml", {
                        "purpose": CurrentAccount.hasArchivePassword ? PasswordDialog.ChangePassword : PasswordDialog.SetPassword
                    })

                TextMetrics {
                    id: passwdPushButtonTextSize
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.weight: Font.Bold
                    text: passwdPushButton.text
                }
            }
        }
        ColumnLayout {
            id: saveAccount
            spacing: JamiTheme.settingsCategorySpacing
            visible: !isSIP && CurrentAccount.managerUri === ""
            width: parent.width

            Text {
                id: saveTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.saveAccountTitle
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            Text {
                id: saveDescription
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                horizontalAlignment: Text.AlignLeft
                lineHeight: JamiTheme.wizardViewTextLineHeight
                text: JamiStrings.saveAccountDescription
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            MaterialButton {
                id: btnExportAccount
                Layout.alignment: Qt.AlignLeft
                preferredWidth: btnExportAccountTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
                primary: true
                text: JamiStrings.saveAccountTitle
                toolTipText: JamiStrings.tipBackupAccount

                onClicked: {
                    var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                            "title": JamiStrings.backupAccountHere,
                            "fileMode": FileDialog.SaveFile,
                            "folder": StandardPaths.writableLocation(StandardPaths.DesktopLocation),
                            "nameFilters": [JamiStrings.jamiArchiveFiles, JamiStrings.allFiles]
                        });
                    dlg.fileAccepted.connect(function (file) {
                            // is there password? If so, go to password dialog, else, go to following directly
                            var exportPath = UtilsAdapter.getAbsPath(file.toString());
                            if (CurrentAccount.hasArchivePassword) {
                                viewCoordinator.presentDialog(appWindow, "commoncomponents/PasswordDialog.qml", {
                                        "purpose": PasswordDialog.ExportAccount,
                                        "path": exportPath
                                    });
                                return;
                            } else if (exportPath.length > 0) {
                                var success = AccountAdapter.model.exportToFile(LRCInstance.currentAccountId, exportPath);
                                viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                                        "title": success ? JamiStrings.success : JamiStrings.error,
                                        "infoText": success ? JamiStrings.backupSuccessful : JamiStrings.backupFailed,
                                        "buttonTitles": [JamiStrings.optionOk],
                                        "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue]
                                    });
                            }
                        });
                }

                TextMetrics {
                    id: btnExportAccountTextSize
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.weight: Font.Bold
                    text: btnExportAccount.text
                }
            }
        }
        ColumnLayout {
            id: bannedAccount
            spacing: JamiTheme.settingsCategorySpacing
            visible: !isSIP && CurrentAccount.hasBannedContacts
            width: parent.width

            Text {
                id: bannedAccountTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.bannedContacts
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            BannedContacts {
                id: bannedContacts
                Layout.fillWidth: true
            }
        }
        ColumnLayout {
            id: manageAccountDeleteColumnLayout
            spacing: JamiTheme.settingsCategorySpacing
            width: parent.width

            Text {
                id: deleteTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.deleteAccountTitle
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            Text {
                id: deleteDescription
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                horizontalAlignment: Text.AlignLeft
                lineHeight: JamiTheme.wizardViewTextLineHeight
                text: JamiStrings.deleteAccountDescription
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            MaterialButton {
                id: deleteAccountPushButton
                Layout.alignment: Qt.AlignLeft
                Layout.rightMargin: JamiTheme.preferredMarginSize
                color: JamiTheme.buttonTintedRed
                hoveredColor: JamiTheme.buttonTintedRedHovered
                preferredWidth: deleteAccountPushButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
                pressedColor: JamiTheme.buttonTintedRedPressed
                primary: true
                text: JamiStrings.deleteAccount

                onClicked: {
                    var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/DeleteAccountDialog.qml", {
                            "isSIP": CurrentAccount.type === Profile.Type.SIP,
                            "bestName": CurrentAccount.bestName,
                            "accountId": CurrentAccount.uri
                        });
                    dlg.accepted.connect(navigateToMainView);
                }

                TextMetrics {
                    id: deleteAccountPushButtonTextSize
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.weight: Font.Bold
                    text: deleteAccountPushButton.text
                }
            }
        }
    }
}
