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
import "../../mainview/components"

BaseModalDialog {
    id: root

    signal accepted

    title: JamiStrings.linkNewDevice

    property bool darkTheme: UtilsAdapter.useApplicationTheme()

    popupContent: StackLayout {
        id: stackedWidget

        function setGeneratingPage() {
            if (passwordEdit.length === 0 && CurrentAccount.hasArchivePassword) {
                setExportPage(NameDirectory.ExportOnRingStatus.WRONG_PASSWORD, "");
                return;
            }
            stackedWidget.currentIndex = exportingSpinnerPage.pageIndex;
            spinnerMovie.playing = true;
            timerForExport.restart();
        }

        function setExportPage(status, pin) {
            if (status === NameDirectory.ExportOnRingStatus.SUCCESS) {
                infoLabel.success = true;
                pinRectangle.visible = true
                exportedPIN.text = pin;
            } else {
                pinRectangle.success = false;
                infoLabel.visible = true;
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
            stackedWidget.height = exportingLayout.implicitHeight;
        }

        Timer {
            id: timerForExport

            repeat: false
            interval: 200

            onTriggered: {
                AccountAdapter.model.exportOnRing(LRCInstance.currentAccountId, passwordEdit.dynamicText);
            }
        }

        Connections {
            target: NameDirectory

            function onExportOnRingEnded(status, pin) {
                stackedWidget.setExportPage(status, pin);
                countdownTimer.start();
            }
        }

        onVisibleChanged: {
            if (visible) {
                if (CurrentAccount.hasArchivePassword) {
                    stackedWidget.currentIndex = enterPasswordPage.pageIndex;
                } else {
                    setGeneratingPage();
                }
            }
        }

        // Index = 0
        Item {
            id: enterPasswordPage

            readonly property int pageIndex: 0

            Component.onCompleted: passwordEdit.forceActiveFocus()

            ColumnLayout {
                spacing: JamiTheme.preferredMarginSize
                anchors.centerIn: parent

                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.maximumWidth: root.width - 4 * JamiTheme.preferredMarginSize
                    wrapMode: Text.Wrap

                    text: JamiStrings.enterPasswordPinCode
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                RowLayout {
                    id: passwordLayout
                    Layout.topMargin: 10
                    Layout.leftMargin: JamiTheme.cornerIconSize
                    Layout.rightMargin: JamiTheme.cornerIconSize
                    spacing: JamiTheme.preferredMarginSize

                    PasswordTextEdit {
                        id: passwordEdit

                        firstEntry: true
                        placeholderText: JamiStrings.password

                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true

                        KeyNavigation.up: btnConfirm
                        KeyNavigation.down: KeyNavigation.up

                        onDynamicTextChanged: {
                            btnConfirm.enabled = dynamicText.length > 0;
                            btnConfirm.hoverEnabled = dynamicText.length > 0;
                        }
                        onAccepted: btnConfirm.clicked()
                    }

                    JamiPushButton {
                        id: btnConfirm

                        Layout.alignment: Qt.AlignCenter
                        height: 40
                        width: 40
                        preferredSize: 60

                        hoverEnabled: false
                        enabled: false

                        imageColor: JamiTheme.tintedBlue
                        source: JamiResources.check_box_24dp_svg

                        onClicked: stackedWidget.setGeneratingPage()

                    }
                }
            }
        }

        // Index = 1
        Item {
            id: exportingSpinnerPage

            readonly property int pageIndex: 1

            onHeightChanged: {
                stackedWidget.height = spinnerLayout.implicitHeight
            }


            ColumnLayout {
                id: spinnerLayout

                spacing: JamiTheme.preferredMarginSize
                anchors.centerIn: parent

                Label {
                    Layout.alignment: Qt.AlignCenter

                    text: JamiStrings.linkDevice
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                AnimatedImage {
                    id: spinnerMovie

                    Layout.alignment: Qt.AlignCenter

                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30

                    source: JamiResources.jami_rolling_spinner_gif
                    playing: visible
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
            }
        }

        // Index = 2
        Item {
            id: exportingInfoPage

            readonly property int pageIndex: 2

            width: childrenRect.width
            height: childrenRect.height

            onHeightChanged: {
                stackedWidget.height = exportingLayout.implicitHeight
            }

            ColumnLayout {
                id: exportingLayout

                spacing: JamiTheme.preferredMarginSize

                Label {
                    id: instructionLabel

                    Layout.maximumWidth: JamiTheme.preferredDialogWidth
                    Layout.alignment: Qt.AlignCenter

                    color: JamiTheme.textColor
                    padding: 8

                    wrapMode: Text.Wrap
                    text: JamiStrings.linkingInstructions
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                }

                Rectangle {
                    Layout.alignment: Qt.AlignCenter

                    border.width: 3
                    border.color: JamiTheme.textColor
                    radius: JamiTheme.primaryRadius
                    color: darkTheme ? JamiTheme.textColor : JamiTheme.secondaryBackgroundColor
                    width: 170
                    height: 170

                    Image {
                         id: qrImage

                         anchors.fill: parent
                         anchors.margins: 10

                         mipmap: false
                         smooth: false

                         source: "image://qrImage/raw_" + exportedPIN.text
                         sourceSize.width: 150
                         sourceSize.height: 150
                    }
                }

                Rectangle {
                    id: pinRectangle

                    radius: 15
                    color: darkTheme ? JamiTheme.tintedBlue : JamiTheme.pinBackgroundColor

                    width: exportedPIN.implicitWidth + 4 * JamiTheme.preferredMarginSize
                    height: exportedPIN.implicitHeight + 2 * JamiTheme.preferredMarginSize

                    Layout.alignment: Qt.AlignCenter
                    Layout.margins: JamiTheme.preferredMarginSize

                    MaterialLineEdit {
                        id: exportedPIN

                        padding: 0
                        anchors.centerIn: parent

                        text: JamiStrings.pin
                        wrapMode: Text.NoWrap

                        backgroundColor: darkTheme ? JamiTheme.tintedBlue : JamiTheme.pinBackgroundColor

                        color: darkTheme ? JamiTheme.textColor : JamiTheme.tintedBlue
                        selectByMouse: true
                        readOnly: true
                        font.pointSize: JamiTheme.headerFontSize
                        font.kerning: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                RowLayout {

                    Layout.alignment: Qt.AlignCenter
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    spacing: 0

                    Label {
                        id: validityLabel

                        Layout.alignment: Qt.AlignRight

                        color: JamiTheme.textColor
                        text: JamiStrings.pinValidity
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true
                    }

                    Label {
                        id: countdownLabel

                        color: JamiTheme.textColor
                        Layout.alignment: Qt.AlignLeft
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true

                        text: "10:00"
                    }

                    Timer {
                         id: countdownTimer
                         interval: 1000
                         repeat: true

                         property int remainingTime: 600

                         onTriggered: {
                             remainingTime--

                             var minutes = Math.floor(remainingTime / 60)
                             var seconds = remainingTime % 60
                             countdownLabel.text = (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds

                             if (remainingTime <= 0) {
                                 validityLabel.visible = false
                                 countdownLabel.text = JamiStrings.pinExpired
                                 countdownLabel.color = JamiTheme.redColor
                                 countdownTimer.stop()
                              }
                          }
                     }

                }

                Label {
                    id: otherDeviceLabel

                    Layout.alignment: Qt.AlignCenter

                    color: JamiTheme.textColor
                    text: JamiStrings.onAnotherDevice
                    font.pointSize: JamiTheme.smallFontSize
                    font.kerning: true
                    font.bold: true
                }

                Label {
                    id: otherInstructionLabel

                    Layout.maximumWidth: JamiTheme.preferredDialogWidth
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    Layout.alignment: Qt.AlignCenter
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    color: JamiTheme.textColor
                    text: JamiStrings.onAnotherDeviceInstruction
                    font.pointSize: JamiTheme.smallFontSize
                    font.kerning: true
                }

                // Displays error messages
                Label {
                    id: infoLabel

                    visible: false

                    property bool success: false
                    property int borderWidth: success ? 1 : 0
                    property int borderRadius: success ? 15 : 0
                    property string backgroundColor: success ? "whitesmoke" : "transparent"
                    property string borderColor: success ? "lightgray" : "transparent"

                    Layout.maximumWidth: JamiTheme.preferredDialogWidth
                    Layout.margins: JamiTheme.preferredMarginSize

                    Layout.alignment: Qt.AlignCenter

                    color: success ? JamiTheme.successLabelColor : JamiTheme.redColor
                    padding: success ? 8 : 0

                    wrapMode: Text.Wrap
                    font.pointSize: success ? JamiTheme.textFontSize : JamiTheme.textFontSize + 3
                    font.kerning: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    background: Rectangle {
                        id: infoLabelBackground

                        border.width: infoLabel.borderWidth
                        border.color: infoLabel.borderColor
                        radius: infoLabel.borderRadius
                        color: JamiTheme.secondaryBackgroundColor
                    }
                }
            }
        }
    }
}
