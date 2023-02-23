/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1
import net.jami.Models 1.1
import Qt5Compat.GraphicalEffects

import "../"
import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root

    property bool isRendezVous: false
    property bool helpOpened: false
    property int preferredHeight: createAccountStack.implicitHeight

    signal showThisPage

    function initializeOnShowUp(isRdv) {
        root.isRendezVous = isRdv
        createAccountStack.currentIndex = 0
        clearAllTextFields()
    }

    function clearAllTextFields() {
        chooseUsernameButton.enabled = true
        showAdvancedButton.enabled = true
        usernameEdit.dynamicText = ""
        advancedAccountSettingsPage.clear()
    }

    color: JamiTheme.secondaryBackgroundColor

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            var currentMainStep = WizardViewStepModel.mainStep
            if (currentMainStep === WizardViewStepModel.MainSteps.NameRegistration) {
                createAccountStack.currentIndex = nameRegistrationPage.stackIndex
                initializeOnShowUp(WizardViewStepModel.accountCreationOption ===
                                   WizardViewStepModel.AccountCreationOption.CreateRendezVous)
                root.showThisPage()
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
            infoBox.checked = false
            adviceBox.checked = false
        }
    }

    StackLayout {
        id: createAccountStack

        objectName: "createAccountStack"
        anchors.fill: parent

        Rectangle {
            id: nameRegistrationPage

            objectName: "nameRegistrationPage"

            Layout.fillHeight: true
            Layout.fillWidth: true

            property int stackIndex: 0

            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {
                id: usernameColumnLayout

                spacing: JamiTheme.wizardViewPageLayoutSpacing

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(508, root.width - 100)

                Text {
                    id: joinJami

                    text: root.isRendezVous ? JamiStrings.createNewRV : JamiStrings.joinJami
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
                    wrapMode : Text.WordWrap
                }

                Text {

                    text: root.isRendezVous ? JamiStrings.chooseUsernameForRV :
                                              JamiStrings.chooseUsernameForAccount
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor

                    font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                    wrapMode: Text.WordWrap
                    lineHeight: JamiTheme.wizardViewTextLineHeight
                }

                UsernameTextEdit {
                    id: usernameEdit

                    icon: PushButton {

                        id: infoBox
                        z:1

                        normalColor: infoBox.hovered ? JamiTheme.hoveredButtonColor : "transparent"
                        imageColor: infoBox.checked ? "white" : JamiTheme.buttonTintedBlue
                        source: JamiResources.i_informations_black_24dp_svg
                        pressedColor: JamiTheme.switchHandleCheckedBorderColor
                        border.color: {
                            if(infoBox.checked){
                                return "transparent"
                            }
                            return JamiTheme.switchHandleCheckedBorderColor
                        }
                        checkable: true
                        onCheckedChanged: {
                            textBoxinfo.visible = !textBoxinfo.visible

                        }
                        preferredSize: 20

                        Item {
                            id: textBoxinfo
                            anchors.top: parent.bottom
                            anchors.right: parent.right
                            anchors.topMargin: 5
                            anchors.rightMargin: -40

                            width: textInfo.width + 2 * JamiTheme.preferredMarginSize
                            height: textInfo.height + 2 * JamiTheme.preferredMarginSize

                            visible: false

                            Behavior on width {
                                NumberAnimation { duration: JamiTheme.shortFadeDuration }
                            }

                            Behavior on height {
                                NumberAnimation { duration: JamiTheme.shortFadeDuration}
                            }

                            DropShadow {
                                z: -1
                                anchors.fill: boxInfo
                                horizontalOffset: 1.0
                                verticalOffset: 1.0
                                radius: boxInfo.radius
                                color: JamiTheme.shadowColor
                                source: boxInfo
                                transparentBorder: true
                            }

                            Rectangle {

                                id: boxInfo

                                z: 1
                                anchors.fill: parent
                                radius: 30
                                color: JamiTheme.secondaryBackgroundColor

                                Text {
                                    id: textInfo

                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: JamiTheme.preferredMarginSize

                                    text: JamiStrings.usernameToolTip
                                    color: JamiTheme.textColor

                                    font.kerning: true
                                    font.pixelSize: JamiTheme.infoBoxDescFontSize
                                    lineHeight: JamiTheme.wizardViewTextLineHeight
                                }

                            }
                        }
                    }

                    objectName: "usernameEdit"

                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    placeholderText: root.isRendezVous ? JamiStrings.chooseAName :
                                                         JamiStrings.chooseUsername
                    staticText: ""
                    editMode: true
                    focus: visible

                    KeyNavigation.tab: chooseUsernameButton
                    KeyNavigation.up: backButton
                    KeyNavigation.down: chooseUsernameButton
                }


                Label {
                    id: invalidLabel

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    visible: text.length !==0
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                    text: {
                        switch(usernameEdit.nameRegistrationState){
                        case UsernameTextEdit.NameRegistrationState.BLANK:
                            return ""
                        case UsernameTextEdit.NameRegistrationState.SEARCHING:
                            return ""
                        case UsernameTextEdit.NameRegistrationState.FREE:
                            return ""
                        case UsernameTextEdit.NameRegistrationState.INVALID:
                            return root.isRendezVous ? JamiStrings.invalidName :
                                                       JamiStrings.invalidUsername
                        case UsernameTextEdit.NameRegistrationState.TAKEN:
                            return root.isRendezVous ? JamiStrings.nameAlreadyTaken :
                                                       JamiStrings.usernameAlreadyTaken
                        }
                    }
                    font.pixelSize: JamiTheme.textEditError
                    color: "#CC0022"
                }

                MaterialButton {
                    id: chooseUsernameButton
                    z:-1

                    TextMetrics{
                        id: textSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.capitalization: Font.AllUppercase
                        text: chooseUsernameButton.text
                    }

                    objectName: "chooseUsernameButton"

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    primary: true
                    preferredWidth: textSize.width + 2*JamiTheme.buttontextWizzardPadding

                    font.capitalization: Font.AllUppercase
                    color: enabled? JamiTheme.buttonTintedBlue : JamiTheme.buttonTintedGrey
                    text: !enabled ? JamiStrings.creatingAccount :
                                     root.isRendezVous ? JamiStrings.chooseName : JamiStrings.joinJami
                    enabled: usernameEdit.nameRegistrationState === UsernameTextEdit.NameRegistrationState.FREE
                             || usernameEdit.nameRegistrationState === UsernameTextEdit.NameRegistrationState.BLANK


                    KeyNavigation.tab: showAdvancedButton
                    KeyNavigation.up: usernameEdit
                    KeyNavigation.down: showAdvancedButton

                    onClicked: {
                        WizardViewStepModel.accountCreationInfo =
                                JamiQmlUtils.setUpAccountCreationInputPara(
                                    {
                                        registeredName : usernameEdit.dynamicText,
                                        alias: advancedAccountSettingsPage.alias,
                                        password: advancedAccountSettingsPage.validatedPassword,
                                        avatar: UtilsAdapter.tempCreationImage(),
                                        isRendezVous: root.isRendezVous
                                    })
                        if (usernameEdit.nameRegistrationState === UsernameTextEdit.NameRegistrationState.FREE) {
                            enabled = false
                            showAdvancedButton.enabled = false
                            WizardViewStepModel.nextStep()
                        }

                        if(usernameEdit.nameRegistrationState === UsernameTextEdit.NameRegistrationState.BLANK)
                            popup.visible = true
                    }
                }

                MaterialButton {
                    id: showAdvancedButton

                    objectName: "showAdvancedButton"
                    tertiary: true
                    secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 2 * JamiTheme.wizardViewBlocMarginSize
                    preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

                    text: JamiStrings.advancedAccountSettings
                    toolTipText: JamiStrings.showAdvancedFeatures

                    KeyNavigation.tab: backButton
                    KeyNavigation.up: chooseUsernameButton
                    KeyNavigation.down: backButton

                    onClicked: {
                        adviceBox.checked = false
                        infoBox.checked = false
                        createAccountStack.currentIndex++
                    }
                }

                NoUsernamePopup {
                    id: popup

                    objectName: "popup"

                    visible: false

                    onJoinClicked: {
                        chooseUsernameButton.enabled = false
                        showAdvancedButton.enabled = false
                    }
                }
            }
        }

        AdvancedAccountSettings {
            id: advancedAccountSettingsPage
            objectName: "advancedAccountSettingsPage"

            Layout.fillHeight: true
            Layout.fillWidth: true

            property int stackIndex: 1

            onSaveButtonClicked: createAccountStack.currentIndex--
        }
    }

    BackButton {
        id: backButton

        objectName: "createAccountPageBackButton"

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        KeyNavigation.tab: usernameEdit
        KeyNavigation.up: advancedAccountSettingsPage

        KeyNavigation.down: usernameEdit

        onClicked: {
            adviceBox.checked = false
            infoBox.checked = false
            if (createAccountStack.currentIndex > 0) {
                createAccountStack.currentIndex--

            } else {
                WizardViewStepModel.previousStep()
                goodToKnow.visible = false
                helpOpened = false
            }
        }
    }

    PushButton {

        id: adviceBox
        z:1

        preferredSize: JamiTheme.wizardViewPageBackButtonSize
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        normalColor: adviceBox.hovered ? JamiTheme.hoveredButtonColor : "transparent"
        imageColor: adviceBox.checked ? "white" : JamiTheme.buttonTintedBlue
        source: goodToKnowLogo.visible ? "" : JamiResources._black_24dp_svg
        pressedColor: JamiTheme.switchHandleCheckedBorderColor
        border.color: {
            if(adviceBox.checked){
                return "transparent"
            }
            return JamiTheme.buttonTintedBlue
        }
        checkable: true

        //Have to wait for new design
        AnimatedImage {
            id: goodToKnowLogo

            z: 2
            visible: false//adviceBox.hovered && !adviceBox.checked
            anchors.fill: parent
            source: JamiResources.good_to_know_gif
            layer.enabled: true
            playing: true

            fillMode: Image.PreserveAspectFit
            mipmap: true
        }

        onCheckedChanged: {
            goodToKnow.visible = !goodToKnow.visible
            helpOpened = !helpOpened

            advancedAccountSettingsPage.openedPassword = false
            advancedAccountSettingsPage.openedNickname = false
        }
    }



    Item {
        id: goodToKnow
        anchors.top: parent.top
        anchors.right: parent.right

        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins + adviceBox.preferredWidth*2/5

        width: helpOpened ? Math.min(root.width - 2 * JamiTheme.preferredMarginSize, 452) : 0
        height: {
            if (!helpOpened)
                return 0
            var finalHeight = title.height + 3 * JamiTheme.preferredMarginSize
            finalHeight += flow.implicitHeight
            return finalHeight
        }

        visible: false

        Behavior on width {
            NumberAnimation { duration: JamiTheme.shortFadeDuration }
        }

        Behavior on height {
            NumberAnimation { duration: JamiTheme.shortFadeDuration}
        }

        DropShadow {
            z: -1
            anchors.fill: boxAdvice
            horizontalOffset: 2.0
            verticalOffset: 2.0
            radius: boxAdvice.radius
            color: JamiTheme.shadowColor
            source: boxAdvice
            transparentBorder: true
        }

        Rectangle {

            id: boxAdvice

            z: 0
            anchors.fill: parent
            radius: 30
            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {

                id: adviceContainer

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.top: parent.top
                visible: helpOpened ? 1 : 0

                Behavior on visible {
                    NumberAnimation {
                        from: 0
                        duration: JamiTheme.overlayFadeDuration
                    }
                }


                Text {
                    id: title
                    text: JamiStrings.goodToKnow
                    color: JamiTheme.textColor
                    font.weight: Font.Medium
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.alignment: Qt.AlignCenter | Qt.AlignTop

                    font.pixelSize: JamiTheme.title2FontSize
                    font.kerning: true
                }

                Flow {
                    id: flow
                    spacing: 25
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: JamiTheme.preferredMarginSize * 4
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.preferredWidth: helpOpened ? Math.min(root.width - 2 * JamiTheme.preferredMarginSize, 452) : 0
                    Layout.fillWidth: true

                    InfoBox {
                        id: info
                        icoSource: JamiResources.laptop_black_24dp_svg
                        title: JamiStrings.local
                        description: JamiStrings.localAccount
                        icoColor: JamiTheme.buttonTintedBlue
                    }

                    InfoBox {
                        icoSource: JamiResources.person_24dp_svg
                        title: JamiStrings.username
                        description: JamiStrings.usernameRecommened
                        icoColor: JamiTheme.buttonTintedBlue
                    }

                    InfoBox {
                        icoSource: JamiResources.lock_svg
                        title: JamiStrings.encrypt
                        description: JamiStrings.passwordOptional
                        icoColor: JamiTheme.buttonTintedBlue
                    }

                    InfoBox {
                        icoSource: JamiResources.noun_paint_svg
                        title: JamiStrings.customize
                        description: JamiStrings.customizeOptional
                        icoColor: JamiTheme.buttonTintedBlue
                    }
                }
            }
        }
    }
}
