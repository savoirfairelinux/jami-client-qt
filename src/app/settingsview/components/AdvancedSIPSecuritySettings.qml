/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    property int itemWidth
    spacing: JamiTheme.settingsCategorySpacing

    function openFileDialog(title, oldPath, fileType, onAcceptedCb) {
        var openPath = oldPath === "" ? (UtilsAdapter.getCurrentPath() + "/ringtones/") : (UtilsAdapter.toFileAbsolutepath(oldPath));
        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                "title": title,
                "fileMode": JamiFileDialog.OpenFile,
                "folder": openPath,
                "nameFilters": [fileType, JamiStrings.allFiles]
            });
        dlg.fileAccepted.connect(onAcceptedCb);
    }

    Text {

        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

        text: JamiStrings.security
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap

        font.pixelSize: JamiTheme.settingsTitlePixelSize
        font.kerning: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 5

        ToggleSwitch {
            id: enableSDESToggle

            labelText: JamiStrings.enableSDES
            checked: CurrentAccount.keyExchange_SRTP
            onSwitchToggled: CurrentAccount.keyExchange_SRTP = Number(checked)
        }

        ToggleSwitch {
            id: encryptNegotitationToggle

            labelText: JamiStrings.encryptNegotiation
            checked: CurrentAccount.enable_TLS
            onSwitchToggled: CurrentAccount.enable_TLS = checked
        }

        SettingMaterialButton {
            id: btnSIPCACert

            Layout.fillWidth: true

            enabled: CurrentAccount.enable_TLS
            titleField: JamiStrings.caCertificate
            textField: UtilsAdapter.toFileInfoName(CurrentAccount.certificateListFile_TLS) !== "" ? UtilsAdapter.toFileInfoName(CurrentAccount.certificateListFile_TLS) : JamiStrings.selectCACertDefault
            itemWidth: root.itemWidth

            onClick: openFileDialog(JamiStrings.selectCACert, CurrentAccount.certificateListFile_TLS, JamiStrings.certificateFile, function (file) {
                    CurrentAccount.certificateListFile_TLS = UtilsAdapter.getAbsPath(file.toString());
                })
        }

        SettingMaterialButton {
            id: btnSIPUserCert

            Layout.fillWidth: true

            enabled: CurrentAccount.enable_TLS
            titleField: JamiStrings.userCertificate
            itemWidth: root.itemWidth
            textField: UtilsAdapter.toFileInfoName(CurrentAccount.certificateFile_TLS) !== "" ? UtilsAdapter.toFileInfoName(CurrentAccount.certificateFile_TLS) : JamiStrings.selectCACertDefault

            onClick: openFileDialog(JamiStrings.selectUserCert, CurrentAccount.certificateFile_TLS, JamiStrings.certificateFile, function (file) {
                    CurrentAccount.certificateFile_TLS = UtilsAdapter.getAbsPath(file.toString());
                })
        }

        SettingMaterialButton {
            id: btnSIPPrivateKey

            Layout.fillWidth: true

            enabled: CurrentAccount.enable_TLS
            titleField: JamiStrings.privateKey
            itemWidth: root.itemWidth
            textField: UtilsAdapter.toFileInfoName(CurrentAccount.privateKeyFile_TLS) !== "" ? UtilsAdapter.toFileInfoName(CurrentAccount.privateKeyFile_TLS) : JamiStrings.selectCACertDefault

            onClick: openFileDialog(JamiStrings.selectPrivateKey, CurrentAccount.privateKeyFile_TLS, JamiStrings.keyFile, function (file) {
                    CurrentAccount.privateKeyFile_TLS = UtilsAdapter.getAbsPath(file.toString());
                })
        }

        // Private key password
        SettingsMaterialTextEdit {
            id: lineEditSIPCertPassword

            Layout.fillWidth: true

            enabled: CurrentAccount.enable_TLS

            itemWidth: root.itemWidth
            titleField: JamiStrings.privateKeyPassword

            staticText: CurrentAccount.password_TLS
            isPassword: true

            onEditFinished: CurrentAccount.password_TLS = dynamicText
        }

        ToggleSwitch {
            id: verifyIncomingCertificatesServerToggle

            labelText: JamiStrings.verifyCertificatesServer
            checked: CurrentAccount.verifyServer_TLS
            onSwitchToggled: CurrentAccount.verifyServer_TLS = checked
        }

        ToggleSwitch {
            id: verifyIncomingCertificatesClientToggle

            labelText: JamiStrings.verifyCertificatesClient
            checked: CurrentAccount.verifyClient_TLS
            onSwitchToggled: CurrentAccount.verifyClient_TLS = checked
        }

        ToggleSwitch {
            id: requireCeritificateForTLSIncomingToggle

            labelText: JamiStrings.tlsRequireConnections
            checked: CurrentAccount.requireClientCertificate_TLS
            onSwitchToggled: CurrentAccount.requireClientCertificate_TLS = checked
        }

        ToggleSwitch {
            id: disableSecureDlgCheckToggle

            labelText: JamiStrings.disableSecureDlgCheck
            checked: CurrentAccount.disableSecureDlgCheck_TLS
            onSwitchToggled: CurrentAccount.disableSecureDlgCheck_TLS = checked
        }
    }
}
