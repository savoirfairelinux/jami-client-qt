/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

    // Layouts.preferredWidth: parent.preferredWidth * 0.6
    width: 400//parent.preferredWidth * 0.6
    height: 400
    // onWidthChanged: root.width = parent.implicitWidth

    popupContent: StackLayout {
        id: stackedWidget

        function setAskPage() {
            stackedWidget.currentIndex = askPage.pageIndex;
        }
        // function onCloseWizardView() {
        //     root.dismiss();
        //     viewCoordinator.present("WelcomePage");
        //     // viewCoordinator.present("SettingsPageBase");
        // }
        //
        function setUriPage() {
            stackedWidget.currentIndex = uriPage.pageIndex;
        }

        function setCameraPage() {
            // do camera stuff
            // if success update index to cam scan view
            stackedWidget.currentIndex = camPage.pageIndex;
            // else fail go to error & close page
        }

        function setFailurePage(status) {
            // // show the failure page and maybe pipe in the error and/or some logs
            // // show a close button + help link to jami docs
            stackedWidget.currentIndex = failPage.pageIndex;
            console.log("[LinkDevice] Encountered failure of type", status);
        }

        function setConnectingPage(/*uri TODO pipe from UI*/) {
            //     // // tells old device to start searching for the new device
            // // opens the spinner page and says connecting for now... can have some more interesting & relevant info & animations in the future
            stackedWidget.currentIndex = connectingPage.pageIndex// load the spinner index
        }

        // function setSuccessPage() {
        //     // // shows the avatar and a success screen + TODO anims
        //     // // make sure to tell the user to go to the other device and start using their account
        //     stackedWidget.currentIndex = successPage.pageIndex
        // }

        function setLocalAuthPage() {
            if (passwordEdit.length === 0 && CurrentAccount.hasArchivePassword) {
                // setExportPage(NameDirectory.ExportOnRingStatus.WRONG_PASSWORD, "");
                // setFailurePage()
                console.log("[LinkDevice] Encountered error during generation");
                stackedWidget.setFailurePage(DeviceAuthStatus.INVALID_CREDS);
                return;
            }
            stackedWidget.setAskPage();
            // stackedWidget.currentIndex = exportingSpinnerPage.pageIndex;
            // spinnerMovie.playing = true;
            // timerForExport.restart();
        }

        // function setExportPage(status, pin) {
        //     if (status === NameDirectory.ExportOnRingStatus.SUCCESS) {
        //         infoLabel.success = true;
        //         pinRectangle.visible = true
        //         exportedPIN.text = pin;
        //     } else {
        //         pinRectangle.success = false;
        //         infoLabel.visible = true;
        //         switch (status) {
        //         case NameDirectory.ExportOnRingStatus.WRONG_PASSWORD:
        //             infoLabel.text = JamiStrings.incorrectPassword;
        //             break;
        //         case NameDirectory.ExportOnRingStatus.NETWORK_ERROR:
        //             infoLabel.text = JamiStrings.linkDeviceNetWorkError;
        //             break;
        //         case NameDirectory.ExportOnRingStatus.INVALID:
        //             infoLabel.text = JamiStrings.somethingWentWrong;
        //             break;
        //         }
        //     }
        //     stackedWidget.currentIndex = exportingInfoPage.pageIndex;
        //     stackedWidget.height = exportingLayout.implicitHeight;
        // }
        //
        // Timer {
        //     id: timerForExport
        //
        //     repeat: false
        //     interval: 200
        //
        //     onTriggered: {
        //         // AccountAdapter.model.exportOnRing(LRCInstance.currentAccountId, passwordEdit.dynamicText);
        //     }
        // }

        // Connections {
        //     target: NameDirectory
        //
        //     function onExportOnRingEnded(status, pin) {
        //         stackedWidget.setExportPage(status, pin);
        //     }
        // }

        // KESS TODO
        // Connections {
        //     target: xxxx
        //
        //     function onDeviceAuthStateChanged {
        //         stackedWidget.updatewithinfo
        //     }
        // }

        onVisibleChanged: {
            // // test logic
            // console.log("[LinkDevice] Opening dialog.");
            // setLocalAuthPage();
            // setAskPage();
            // return;
            // prod logic
            if (visible) {
                if (CurrentAccount.hasArchivePassword) {
                    // stackedWidget.currentIndex = enterPasswordPage.pageIndex;
                    stackedWidget.setLocalAuthPage();
                } else {
                    stackedWidget.setAskPage();
                }
            }
        }

        // asks the user to enter the account password before proceeding
        // Index = 0
        Item {
            id: enterPasswordPage

            readonly property int pageIndex: 0

            Component.onCompleted: passwordEdit.forceActiveFocus()

            onHeightChanged: {
                stackedWidget.height = passwordLayout.implicitHeight
            }

            ColumnLayout {
                id: passwordLayout
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
                    Layout.topMargin: 10
                    Layout.leftMargin: JamiTheme.cornerIconSize
                    Layout.rightMargin: JamiTheme.cornerIconSize
                    spacing: JamiTheme.preferredMarginSize
                    Layout.bottomMargin: JamiTheme.preferredMarginSize

                    PasswordTextEdit {
                        id: passwordEdit

                        firstEntry: true
                        placeholderText: JamiStrings.password

                        Layout.alignment: Qt.AlignLeading
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
                        height: 36
                        width: 36

                        hoverEnabled: false
                        enabled: false

                        imageColor: JamiTheme.secondaryBackgroundColor
                        hoveredColor: JamiTheme.buttonTintedBlueHovered
                        source: JamiResources.check_black_24dp_svg
                        normalColor: JamiTheme.tintedBlue

                        onClicked: stackedWidget.setAskPage()
                        // TODO set page = 1 and proceed

                    }
                }
            }
        }

        Item {
            id: askPage

            readonly property int pageIndex: 1//1

            width: parent.width
            height: parent.height
            // Component.onCompleted: print(this, width, height)

            // // plan
            // Text JamiStrings.explainLinkDevice
            // Button1 -> setUriPage
            // Button2 -> setCameraPage

            ColumnLayout {
                id: askLayout

                spacing: JamiTheme.preferredMarginSize
                anchors.centerIn: parent

                Label {
                    Layout.alignment: Qt.AlignCenter

                    text: "choose your method"
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignLeading
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "Choose whether to use your camera to scan a link QR code or whether to enter the URL manually."
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true
                    Layout.preferredWidth: root.width * 0.75
                    // horizontalAlignment: Text.AlignHCenter
                    // verticalAlignment: Text.AlignVCenter
                    // wrapMode: Text.WordWrap
                    // width: parent.width
                }

                JamiPushButton {
                    id: btnChooseUri

                    Layout.alignment: Qt.AlignCenter
                    height: 36
                    width: 36

                    hoverEnabled: false
                    enabled: false

                    imageColor: JamiTheme.secondaryBackgroundColor
                    hoveredColor: JamiTheme.buttonTintedBlueHovered
                    source: JamiResources.check_black_24dp_svg
                    normalColor: JamiTheme.tintedBlue

                    onClicked: stackedWidget.setUriPage()
                }

                JamiPushButton {
                    id: btnChooseCam

                    Layout.alignment: Qt.AlignCenter
                    height: 36
                    width: 36

                    hoverEnabled: false
                    enabled: false

                    imageColor: JamiTheme.secondaryBackgroundColor
                    hoveredColor: JamiTheme.buttonTintedBlueHovered
                    source: JamiResources.check_black_24dp_svg
                    normalColor: JamiTheme.tintedBlue

                    onClicked: stackedWidget.setCameraPage()
                }

            }

            // ColumnLayout {
            //     anchors.centerIn: parent
            //     width: askPage.width * 0.75
            //
            //
            // }
        }

        Item {
            id: failPage

            readonly property int pageIndex: 2

            width: parent.width
            height: parent.height
            Component.onCompleted: console.log(this, width, height)

            // // plan
            // Text JamiStrings.explainLinkDevice
            // Button1 -> setUriPage
            // Button2 -> setCameraPage

            ColumnLayout {
                id: failLayout

                spacing: JamiTheme.preferredMarginSize
                anchors.centerIn: parent

                Label {
                    Layout.alignment: Qt.AlignCenter

                    text: "choose your method"
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignLeading
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "You encountered an error."
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true
                    Layout.preferredWidth: root.width * 0.75
                    // horizontalAlignment: Text.AlignHCenter
                    // verticalAlignment: Text.AlignVCenter
                    // wrapMode: Text.WordWrap
                    // width: parent.width
                }
            }
        }

        // says exporting account... needs to say generating qr code or something like that
        // Index = 1
        Item {
            id: connectingPage

            readonly property int pageIndex: 3

            onHeightChanged: {
                stackedWidget.height = spinnerLayout.implicitHeight
            }
            onWidthChanged: stackedWidget.width = exportingLayout.implicitWidth

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
                    horizontalAlignment: Text.AlignLeading
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
        // Item {
        //     id: linkInfoPage // exportingInfoPage
        //
        //     readonly property int pageIndex: 2
        //
        //     width: childrenRect.width
        //     height: childrenRect.height
        //
        //     onHeightChanged: {
        //         stackedWidget.height = exportingLayout.implicitHeight
        //     }
        //     onWidthChanged: stackedWidget.width = exportingLayout.implicitWidth
        //
        //     ColumnLayout {
        //         id: exportingLayout
        //
        //         spacing: JamiTheme.preferredMarginSize
        //
        //         Label {
        //             id: instructionLabel
        //
        //             Layout.maximumWidth: Math.min(root.maximumPopupWidth, root.width) - 2 * root.popupMargins
        //             Layout.alignment: Qt.AlignLeading
        //
        //             color: JamiTheme.textColor
        //
        //             wrapMode: Text.Wrap
        //             text: JamiStrings.linkingInstructions
        //             font.pointSize: JamiTheme.textFontSize
        //             font.kerning: true
        //             verticalAlignment: Text.AlignVCenter
        //
        //         }
        //
        //         RowLayout {
        //             spacing: 10
        //             Layout.maximumWidth: Math.min(root.maximumPopupWidth, root.width) - 2 * root.popupMargins
        //
        //             Rectangle {
        //                 Layout.alignment: Qt.AlignCenter
        //
        //                 radius: 5
        //                 color: JamiTheme.backgroundRectangleColor
        //                 width: 100
        //                 height: 100
        //
        //                 Rectangle {
        //                     width: qrImage.width + 4
        //                     height: qrImage.height + 4
        //                     anchors.centerIn: parent
        //                     radius: 5
        //                     color: JamiTheme.whiteColor
        //                     Image {
        //                          id: qrImage
        //                          anchors.centerIn: parent
        //                          mipmap: false
        //                          smooth: false
        //                          source: "image://qrImage/raw_" + exportedPIN.text
        //                          // source: "image://qrImage/raw_" + exportedPIN.text
        //                          sourceSize.width: 80
        //                          sourceSize.height: 80
        //                     }
        //                 }
        //
        //             }
        //
        //             //  TODO make this the URI backup
        //             Rectangle {
        //                 id: pinRectangle
        //
        //                 radius: 5
        //                 color: JamiTheme.backgroundRectangleColor
        //                 Layout.fillWidth: true
        //                 height: 100
        //                 Layout.minimumWidth: exportedPIN.width + 20
        //
        //                 Layout.alignment: Qt.AlignCenter
        //
        //                 MaterialLineEdit {
        //                     id: exportedPIN
        //
        //                     padding: 10
        //                     anchors.centerIn: parent
        //
        //                     text: JamiStrings.pin
        //                     wrapMode: Text.NoWrap
        //
        //                     backgroundColor: JamiTheme.backgroundRectangleColor
        //
        //                     color: darkTheme ? JamiTheme.editLineColor : JamiTheme.darkTintedBlue
        //                     selectByMouse: true
        //                     readOnly: true
        //                     font.pointSize: JamiTheme.tinyCreditsTextSize
        //                     font.kerning: true
        //                     horizontalAlignment: Text.AlignHCenter
        //                     verticalAlignment: Text.AlignVCenter
        //                 }
        //             }
        //         }
        //
        //         Rectangle {
        //             radius: 5
        //             color: JamiTheme.infoRectangleColor
        //             Layout.fillWidth: true
        //             Layout.preferredHeight: infoLabels.height + 38
        //
        //             RowLayout {
        //                 id: infoLayout
        //
        //                 anchors.centerIn: parent
        //                 anchors.fill: parent
        //                 anchors.margins: 14
        //                 spacing: 10
        //
        //                 ResponsiveImage{
        //                     Layout.fillWidth: true
        //
        //                     source: JamiResources.outline_info_24dp_svg
        //                     fillMode: Image.PreserveAspectFit
        //
        //                     color: darkTheme ? JamiTheme.editLineColor : JamiTheme.darkTintedBlue
        //                     Layout.fillHeight: true
        //                 }
        //
        //                 ColumnLayout{
        //                     id: infoLabels
        //
        //                     Layout.fillHeight: true
        //                     Layout.fillWidth: true
        //
        //                     Label {
        //                         id: otherDeviceLabel
        //
        //                         Layout.alignment: Qt.AlignLeading
        //                         color: JamiTheme.textColor
        //                         text: JamiStrings.onAnotherDevice
        //
        //                         font.pointSize: JamiTheme.smallFontSize
        //                         font.kerning: true
        //                         font.bold: true
        //                     }
        //
        //                     Label {
        //                         id: otherInstructionLabel
        //
        //                         Layout.fillWidth: true
        //                         Layout.alignment: Qt.AlignLeading
        //
        //                         wrapMode: Text.Wrap
        //                         color: JamiTheme.textColor
        //                         text: JamiStrings.onAnotherDeviceInstruction
        //
        //                         font.pointSize: JamiTheme.smallFontSize
        //                         font.kerning: true
        //                     }
        //                 }
        //             }
        //         }
        //
        //         // Displays error messages
        //         Label {
        //             id: infoLabel
        //
        //             visible: false
        //
        //             property bool success: false
        //             property int borderWidth: success ? 1 : 0
        //             property int borderRadius: success ? 15 : 0
        //             property string backgroundColor: success ? "whitesmoke" : "transparent"
        //             property string borderColor: success ? "lightgray" : "transparent"
        //
        //             Layout.maximumWidth: JamiTheme.preferredDialogWidth
        //             Layout.margins: JamiTheme.preferredMarginSize
        //
        //             Layout.alignment: Qt.AlignCenter
        //
        //             color: success ? JamiTheme.successLabelColor : JamiTheme.redColor
        //             padding: success ? 8 : 0
        //
        //             wrapMode: Text.Wrap
        //             font.pointSize: success ? JamiTheme.textFontSize : JamiTheme.textFontSize + 3
        //             font.kerning: true
        //             horizontalAlignment: Text.AlignHCenter
        //             verticalAlignment: Text.AlignVCenter
        //
        //             background: Rectangle {
        //                 id: infoLabelBackground
        //
        //                 border.width: infoLabel.borderWidth
        //                 border.color: infoLabel.borderColor
        //                 radius: infoLabel.borderRadius
        //                 color: JamiTheme.secondaryBackgroundColor
        //             }
        //         }
        //     }
        // }
    }
}
