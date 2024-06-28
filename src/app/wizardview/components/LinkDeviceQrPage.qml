/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import QtQuick.Layouts
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root

    property string errorText: ""
    property int preferredHeight: importFromDevicePageColumnLayout.implicitHeight + 2 * JamiTheme.preferredMarginSize

    property string authUri: ""
    property string authQrImage: ""

    signal showThisPage

    function initializeOnShowUp() {
        clearAllTextFields();
    }

    // debug
    // function dummyQr() {
    //     // var fakeCode = "jami-auth://fakejamiid/123456"
    //     var fakeCode = "hello there"
    //     updateUri(fakeCode)
    // }


    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: importFromDevicePageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        width: Math.max(508, root.width - 100)

        // title
        // TODO make a unified title type in ImportFromDevicePage
        // TODO use QFont::Capitalize and lowercase the string
        Text {
            text: JamiStrings.ldQrPageTitle
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.preferredMarginSize
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            wrapMode: Text.WordWrap
        }

        // desc
        // TODO make a unified description and title type in ImportFromDevicePage?
        Text {
            text: JamiStrings.ldLoginInstructionsInfo
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            font.weight: Font.Medium
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }

        // debug
        // MaterialButton {
        //     id: debugWizardBtn
        //
        //     preferredWidth: 250
        //
        //     primary: true
        //     Layout.alignment: Qt.AlignCenter
        //
        //     text: "debug wz -> wait"
        //     enabled: true // TODO KESS make visible only when in testing mode OR just remove them all when done
        //     onClicked: {
        //         console.warn("[LinkDevice] LinkDeviceQrPage: debug WizardViewStepModel")
        //         WizardViewStepModel.previousStep()
        //     }
        // }

        // loads a scalable qr image
        JamiAuthQr {
            id: uriQrImage
            imagePath: root.authQrImage
            // visible: root.authUri != ""

            Layout.alignment: Qt.AlignHCenter

            opacity: root.authQrImage == "" ? 0.0 : 1.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }
        }

        // alternative instructions aka no camera
        MaterialButton {
            id: linkDeviceAltBtn

            TextMetrics {
                id: linkDeviceAltBtnTextSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                text: "linkDeviceBtn.text"// TODOlinkDeviceBtn.text
            }

            preferredWidth: linkDeviceOldBtnTextSize.width + 2 * JamiTheme.buttontextWizzardPadding

            primary: true
            Layout.alignment: Qt.AlignCenter

            toolTipText: JamiStrings.tipLinkNewDevice
            text: JamiStrings.askDeviceHasNoCamera

            onClicked: viewCoordinator.presentDialog(appWindow, "settingsview/components/LinkDeviceAltLoginPopup.qml", { authUri: root.authUri })

            KeyNavigation.tab: backButton
            KeyNavigation.backtab: backButton
            KeyNavigation.up: backButton
            KeyNavigation.down: backButton
        }

        Label {
            id: errorLabel

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

            visible: errorText.length !== 0

            text: errorText

            font.pixelSize: JamiTheme.textEditError
            color: JamiTheme.redColor
        }
    }

    BackButton {
        id: backButton

        objectName: "importFromDevicePageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        visible: !uriQrImage.visible //!connectBtn.spinnerTriggered

        KeyNavigation.tab: linkDeviceAltBtn
        KeyNavigation.backtab: linkDeviceAltBtn
        KeyNavigation.up: linkDeviceAltBtn
        KeyNavigation.down: linkDeviceAltBtn

        onClicked: WizardViewStepModel.previousStep()
    }
}
