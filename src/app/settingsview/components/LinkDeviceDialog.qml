/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root
    height: Math.min(appWindow.height - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogHeight)
    title: JamiStrings.addDevice
    width: Math.min(appWindow.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogWidth)

    signal accepted

    popupContent: StackLayout {
        id: stackedWidget
        function setExportPage(status, pin) {
            if (status === NameDirectory.ExportOnRingStatus.SUCCESS) {
                infoLabel.success = true;
                infoLabelsRowLayout.visible = true;
                infoLabel.text = JamiStrings.pinTimerInfos;
                exportedPIN.text = pin;
            } else {
                infoLabel.success = false;
                infoLabelsRowLayout.visible = false;
                switch (status) {
                case NameDirectory.ExportOnRingStatus.WRONG_PASSWORD:
                    infoLabel.text = JamiStrings.incorrectPassword;
                    break;
                case NameDirectory.ExportOnRingStatus.NETWORK_ERROR:
                    infoLabel.text = JamiStrings.linkDeviceNetWorkError;
                    break;
                case NameDirectory.ExportOnRingStatus.INVALID:
                    infoLabel.text = JamiStrings.somethingWentWrong;
                    break;
                }
            }
            stackedWidget.currentIndex = exportingInfoPage.pageIndex;
        }
        function setGeneratingPage() {
            if (passwordEdit.length === 0 && CurrentAccount.hasArchivePassword) {
                setExportPage(NameDirectory.ExportOnRingStatus.WRONG_PASSWORD, "");
                return;
            }
            stackedWidget.currentIndex = exportingSpinnerPage.pageIndex;
            spinnerMovie.playing = true;
            timerForExport.restart();
        }

        onVisibleChanged: {
            if (visible) {
                infoLabel.text = JamiStrings.pinTimerInfos;
                if (CurrentAccount.hasArchivePassword) {
                    stackedWidget.currentIndex = enterPasswordPage.pageIndex;
                    passwordEdit.forceActiveFocus();
                } else {
                    setGeneratingPage();
                }
            }
        }

        Timer {
            id: timerForExport
            interval: 200
            repeat: false

            onTriggered: {
                AccountAdapter.model.exportOnRing(LRCInstance.currentAccountId, passwordEdit.dynamicText);
            }
        }
        Connections {
            target: NameDirectory

            function onExportOnRingEnded(status, pin) {
                stackedWidget.setExportPage(status, pin);
            }
        }

        // Index = 0
        Item {
            id: enterPasswordPage
            readonly property int pageIndex: 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pointSize: JamiTheme.textFontSize
                    horizontalAlignment: Text.AlignHCenter
                    text: JamiStrings.enterAccountPassword
                    verticalAlignment: Text.AlignVCenter
                }
                PasswordTextEdit {
                    id: passwordEdit
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: 48
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth
                    placeholderText: JamiStrings.enterCurrentPassword

                    onAccepted: btnConfirm.clicked()
                    onDynamicTextChanged: {
                        btnConfirm.enabled = dynamicText.length > 0;
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    spacing: 16

                    MaterialButton {
                        id: btnConfirm
                        Layout.alignment: Qt.AlignHCenter
                        autoAccelerator: true
                        buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                        color: enabled ? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                        enabled: false
                        hoveredColor: JamiTheme.buttonTintedBlackHovered
                        preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        pressedColor: JamiTheme.buttonTintedBlackPressed
                        secondary: true
                        text: JamiStrings.exportAccount

                        onClicked: stackedWidget.setGeneratingPage()
                    }
                    MaterialButton {
                        id: btnCancel
                        Layout.alignment: Qt.AlignHCenter
                        autoAccelerator: true
                        buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                        color: JamiTheme.buttonTintedBlack
                        enabled: true
                        hoveredColor: JamiTheme.buttonTintedBlackHovered
                        preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                        pressedColor: JamiTheme.buttonTintedBlackPressed
                        secondary: true
                        text: JamiStrings.optionCancel

                        onClicked: close()
                    }
                }
            }
        }

        // Index = 1
        Item {
            id: exportingSpinnerPage
            readonly property int pageIndex: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                Label {
                    Layout.alignment: Qt.AlignCenter
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pointSize: JamiTheme.headerFontSize
                    horizontalAlignment: Text.AlignLeft
                    text: JamiStrings.linkNewDevice
                    verticalAlignment: Text.AlignVCenter
                }
                AnimatedImage {
                    id: spinnerMovie
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: 30
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    playing: visible
                    source: JamiResources.jami_rolling_spinner_gif
                }
            }
        }

        // Index = 2
        Item {
            id: exportingInfoPage
            readonly property int pageIndex: 2

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                Item {
                    id: infoLabelsRowLayout
                    Layout.alignment: Qt.AlignCenter
                    Layout.margins: JamiTheme.preferredMarginSize
                    Layout.preferredWidth: yourPinLabel.contentWidth + exportedPIN.contentWidth + 5

                    Label {
                        id: yourPinLabel
                        anchors.left: infoLabelsRowLayout.left
                        anchors.verticalCenter: infoLabelsRowLayout.verticalCenter
                        color: JamiTheme.textColor
                        font.kerning: true
                        font.pointSize: JamiTheme.headerFontSize
                        horizontalAlignment: Text.AlignHCenter
                        text: JamiStrings.yourPinIs
                        verticalAlignment: Text.AlignVCenter
                    }
                    MaterialLineEdit {
                        id: exportedPIN
                        anchors.left: yourPinLabel.right
                        anchors.leftMargin: 5
                        anchors.verticalCenter: infoLabelsRowLayout.verticalCenter
                        color: JamiTheme.textColor
                        font.kerning: true
                        font.pointSize: JamiTheme.headerFontSize
                        horizontalAlignment: Text.AlignHCenter
                        padding: 0
                        readOnly: true
                        selectByMouse: true
                        text: JamiStrings.pin
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.NoWrap
                    }
                }
                Label {
                    id: infoLabel
                    property string backgroundColor: success ? "whitesmoke" : "transparent"
                    property string borderColor: success ? "lightgray" : "transparent"
                    property int borderRadius: success ? 15 : 0
                    property int borderWidth: success ? 1 : 0
                    property bool success: false

                    Layout.alignment: Qt.AlignCenter
                    Layout.maximumWidth: stackedWidget.width - JamiTheme.preferredMarginSize * 2
                    color: success ? JamiTheme.successLabelColor : JamiTheme.redColor
                    font.kerning: true
                    font.pointSize: success ? JamiTheme.textFontSize : JamiTheme.textFontSize + 3
                    horizontalAlignment: Text.AlignHCenter
                    padding: success ? 8 : 0
                    text: JamiStrings.pinTimerInfos
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap

                    background: Rectangle {
                        id: infoLabelBackground
                        border.color: infoLabel.borderColor
                        border.width: infoLabel.borderWidth
                        color: JamiTheme.secondaryBackgroundColor
                        radius: infoLabel.borderRadius
                    }
                }
                MaterialButton {
                    id: btnCloseExportDialog
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    color: enabled ? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                    enabled: true
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    secondary: true
                    text: JamiStrings.close

                    onClicked: {
                        if (infoLabel.success)
                            accepted();
                        close();
                    }
                }
            }
        }
    }
}
