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
            print(this, "[LinkDevice] Encountered failure of type", status);
        }

        function setConnectingPage(/*uri TODO pipe from UI*/) {
            //     // // tells old device to start searching for the new device
            // // opens the spinner page and says connecting for now... can have some more interesting & relevant info & animations in the future
            stackedWidget.currentIndex = connectingPage.pageIndex// load the spinner index
        }

        function setSuccessPage() {
            // // shows the avatar and a success screen + TODO anims
            // // make sure to tell the user to go to the other device and start using their account
            stackedWidget.currentIndex = successPage.pageIndex
        }

        function setLocalAuthPage() {
            if (passwordEdit.length === 0 && CurrentAccount.hasArchivePassword) {
                // setExportPage(NameDirectory.ExportOnRingStatus.WRONG_PASSWORD, "");
                // setFailurePage()
                print(this, "[LinkDevice] Encountered error during generation");
                stackedWidget.setFailurePage(NameDirectory.DeviceAuthStatus.INVALID_CREDS);
                return;
            }
            stackedWidget.setAskPage();
        }

        // Connections {
        //     target: xxxx
        //
        //     function onDeviceAuthStateChanged {
        //         stackedWidget.updatewithinfo
        //     }
        // }

        onVisibleChanged: {
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

                    }
                }
            }
        }

        Item {
            id: askPage

            readonly property int pageIndex: 1//1

            width: parent.width
            height: parent.height

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

            ColumnLayout {
                id: failLayout

                spacing: JamiTheme.preferredMarginSize
                anchors.centerIn: parent

                Label {
                    Layout.alignment: Qt.AlignCenter

                    text: "linkdev fail page"
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
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }
        Item {
            id: successPage

            readonly property int pageIndex: 4

            width: parent.width
            height: parent.height
            Component.onCompleted: console.log(this, width, height)

            ColumnLayout {
                id: successLayout

                spacing: JamiTheme.preferredMarginSize
                anchors.centerIn: parent

                Label {
                    Layout.alignment: Qt.AlignCenter

                    text: "linkdev success page"
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignLeading
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: "You succeeded."
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true
                    Layout.preferredWidth: root.width * 0.75
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    width: parent.width
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

    }
}
