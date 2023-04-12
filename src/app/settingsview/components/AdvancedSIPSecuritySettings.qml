/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
        color: JamiTheme.textColor
        font.kerning: true
        font.pixelSize: JamiTheme.settingsTitlePixelSize
        horizontalAlignment: Text.AlignLeft
        text: JamiStrings.security
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 5

        ToggleSwitch {
            id: enableSDESToggle
            checked: CurrentAccount.keyExchange_SRTP
            labelText: JamiStrings.enableSDES

            onSwitchToggled: CurrentAccount.keyExchange_SRTP = Number(checked)
        }
        ToggleSwitch {
            id: fallbackRTPToggle
            checked: CurrentAccount.rtpFallback_SRTP
            labelText: JamiStrings.fallbackRTP

            onSwitchToggled: CurrentAccount.rtpFallback_SRTP = checked
        }
        ToggleSwitch {
            id: encryptNegotitationToggle
            checked: CurrentAccount.enable_TLS
            labelText: JamiStrings.encryptNegotiation

            onSwitchToggled: CurrentAccount.enable_TLS = checked
        }
        SettingMaterialButton {
            id: btnSIPCACert
            Layout.fillWidth: true
            enabled: CurrentAccount.enable_TLS
            itemWidth: root.itemWidth
            textField: UtilsAdapter.toFileInfoName(CurrentAccount.certificateListFile_TLS) !== "" ? UtilsAdapter.toFileInfoName(CurrentAccount.certificateListFile_TLS) : JamiStrings.selectCACertDefault
            titleField: JamiStrings.caCertificate

            onClick: openFileDialog(JamiStrings.selectCACert, CurrentAccount.certificateListFile_TLS, JamiStrings.certificateFile, function (file) {
                    CurrentAccount.certificateListFile_TLS = UtilsAdapter.getAbsPath(file.toString());
                })
        }
        SettingMaterialButton {
            id: btnSIPUserCert
            Layout.fillWidth: true
            enabled: CurrentAccount.enable_TLS
            itemWidth: root.itemWidth
            textField: UtilsAdapter.toFileInfoName(CurrentAccount.certificateFile_TLS) !== "" ? UtilsAdapter.toFileInfoName(CurrentAccount.certificateFile_TLS) : JamiStrings.selectCACertDefault
            titleField: JamiStrings.userCertificate

            onClick: openFileDialog(JamiStrings.selectUserCert, CurrentAccount.certificateFile_TLS, JamiStrings.certificateFile, function (file) {
                    CurrentAccount.certificateFile_TLS = UtilsAdapter.getAbsPath(file.toString());
                })
        }
        SettingMaterialButton {
            id: btnSIPPrivateKey
            Layout.fillWidth: true
            enabled: CurrentAccount.enable_TLS
            itemWidth: root.itemWidth
            textField: UtilsAdapter.toFileInfoName(CurrentAccount.privateKeyFile_TLS) !== "" ? UtilsAdapter.toFileInfoName(CurrentAccount.privateKeyFile_TLS) : JamiStrings.selectCACertDefault
            titleField: JamiStrings.privateKey

            onClick: openFileDialog(JamiStrings.selectPrivateKey, CurrentAccount.privateKeyFile_TLS, JamiStrings.keyFile, function (file) {
                    CurrentAccount.privateKeyFile_TLS = UtilsAdapter.getAbsPath(file.toString());
                })
        }

        // Private key password
        SettingsMaterialTextEdit {
            id: lineEditSIPCertPassword
            Layout.fillWidth: true
            enabled: CurrentAccount.enable_TLS
            isPassword: true
            itemWidth: root.itemWidth
            staticText: CurrentAccount.password_TLS
            titleField: JamiStrings.privateKeyPassword

            onEditFinished: CurrentAccount.password_TLS = dynamicText
        }
        ToggleSwitch {
            id: verifyIncomingCertificatesServerToggle
            checked: CurrentAccount.verifyServer_TLS
            labelText: JamiStrings.verifyCertificatesServer

            onSwitchToggled: CurrentAccount.verifyServer_TLS = checked
        }
        ToggleSwitch {
            id: verifyIncomingCertificatesClientToggle
            checked: CurrentAccount.verifyClient_TLS
            labelText: JamiStrings.verifyCertificatesClient

            onSwitchToggled: CurrentAccount.verifyClient_TLS = checked
        }
        ToggleSwitch {
            id: requireCeritificateForTLSIncomingToggle
            checked: CurrentAccount.requireClientCertificate_TLS
            labelText: JamiStrings.tlsRequireConnections

            onSwitchToggled: CurrentAccount.requireClientCertificate_TLS = checked
        }
        ToggleSwitch {
            id: disableSecureDlgCheckToggle
            checked: CurrentAccount.disableSecureDlgCheck_TLS
            labelText: JamiStrings.disableSecureDlgCheck

            onSwitchToggled: CurrentAccount.disableSecureDlgCheck_TLS = checked
        }
        SettingsComboBox {
            id: tlsProtocolComboBox
            Layout.fillWidth: true
            labelText: JamiStrings.tlsProtocol
            modelIndex: CurrentAccount.method_TLS
            role: "textDisplay"
            tipText: JamiStrings.audioDeviceSelector
            widthOfComboBox: root.itemWidth

            onActivated: CurrentAccount.method_TLS = parseInt(comboModel.get(modelIndex).secondArg)

            comboModel: ListModel {
                ListElement {
                    firstArg: "Default"
                    secondArg: 0
                    textDisplay: "Default"
                }
                ListElement {
                    firstArg: "TLSv1"
                    secondArg: 1
                    textDisplay: "TLSv1"
                }
                ListElement {
                    firstArg: "TLSv1.1"
                    secondArg: 2
                    textDisplay: "TLSv1.1"
                }
                ListElement {
                    firstArg: "TLSv1.2"
                    secondArg: 3
                    textDisplay: "TLSv1.2"
                }
            }
        }
        SettingsMaterialTextEdit {
            id: outgoingTLSServerNameLineEdit
            Layout.fillWidth: true
            itemWidth: root.itemWidth
            staticText: CurrentAccount.serverName_TLS
            titleField: JamiStrings.tlsServerName

            onEditFinished: CurrentAccount.serverName_TLS = dynamicText
        }
        SettingSpinBox {
            id: negotiationTimeoutSpinBox
            Layout.fillWidth: true
            bottomValue: 0
            itemWidth: root.itemWidth
            title: JamiStrings.negotiationTimeOut
            topValue: 3000
            valueField: CurrentAccount.negotiationTimeoutSec_TLS

            onNewValue: CurrentAccount.negotiationTimeoutSec_TLS = valueField
        }
    }
}
