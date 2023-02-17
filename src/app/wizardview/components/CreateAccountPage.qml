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
                anchors.top: parent.top
                anchors.topMargin: JamiTheme.wizardViewLayoutTopMargin

                width: Math.max(508, root.width - 100)

                Text {
                    id: joinJami

                    text: JamiStrings.joinJami
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 15
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
                    Layout.topMargin: 15
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor

                    font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                    wrapMode: Text.WordWrap
                }

                UsernameTextEdit {
                    id: usernameEdit

                    objectName: "usernameEdit"

                    Layout.topMargin: 15
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    placeholderText: root.isRendezVous ? JamiStrings.chooseAName :
                                                         JamiStrings.chooseYourUserName
                    staticText: ""
                    editMode: true
                    focus: visible

                    KeyNavigation.tab: chooseUsernameButton
                    KeyNavigation.up: backButton
                    KeyNavigation.down: chooseUsernameButton

                    onAccepted: {
                        if (chooseUsernameButton.enabled)
                            chooseUsernameButton.clicked()
                        else
                            skipButton.clicked()
                    }
                }


                Label {

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    visible: text.length !==0 || usernameEdit.selected
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

                    text: {
                        switch(usernameEdit.nameRegistrationState){
                        case UsernameLineEdit.NameRegistrationState.BLANK:
                            return " "
                        case UsernameLineEdit.NameRegistrationState.SEARCHING:
                            return " "
                        case UsernameLineEdit.NameRegistrationState.FREE:
                            return " "
                        case UsernameLineEdit.NameRegistrationState.INVALID:
                            return root.isRendezVous ? JamiStrings.invalidName :
                                                       JamiStrings.invalidUsername
                        case UsernameLineEdit.NameRegistrationState.TAKEN:
                            return root.isRendezVous ? JamiStrings.nameAlreadyTaken :
                                                       JamiStrings.usernameAlreadyTaken
                        }
                    }
                    font.pointSize: JamiTheme.textFontSize
                    color: "#CC0022"
                }

                MaterialButton {
                    id: chooseUsernameButton

                    objectName: "chooseUsernameButton"

                    Layout.alignment: Qt.AlignCenter
                    primary: true

                    preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

                    font.capitalization: Font.AllUppercase
                    color: enabled? JamiTheme.buttonTintedBlue : JamiTheme.buttonTintedGrey
                    text: !enabled ? JamiStrings.creatingAccount :
                                     root.isRendezVous ? JamiStrings.chooseName : JamiStrings.joinJami
                    enabled: usernameEdit.nameRegistrationState === UsernameLineEdit.NameRegistrationState.FREE
                             || usernameEdit.nameRegistrationState === UsernameLineEdit.NameRegistrationState.BLANK


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
                        if (usernameEdit.nameRegistrationState === UsernameLineEdit.NameRegistrationState.FREE) {
                            enabled = false
                            showAdvancedButton.enabled = false
                            WizardViewStepModel.nextStep()
                        }

                        if(usernameEdit.nameRegistrationState === UsernameLineEdit.NameRegistrationState.BLANK)
                            popup.visible = true

                    }
                }

                MaterialButton {
                    id: showAdvancedButton

                    objectName: "showAdvancedButton"
                    tertiary: true
                    secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor

                    Layout.alignment: Qt.AlignCenter
                    preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

                    text: JamiStrings.advancedAccountSettings
                    toolTipText: JamiStrings.showAdvancedFeatures

                    KeyNavigation.tab: backButton
                    KeyNavigation.up: chooseUsernameButton
                    KeyNavigation.down: backButton

                    onClicked: createAccountStack.currentIndex++
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

        id: infoBox
        z:1

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        normalColor: JamiTheme.backgroundColor
        imageColor: JamiTheme.primaryForegroundColor

        source: JamiResources.outline_info_24dp_svg

        onHoveredChanged: {

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

        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins + infoBox.preferredSize*2/5

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
            anchors.fill: boxInfo
            horizontalOffset: 3.0
            verticalOffset: 3.0
            radius: boxInfo.radius * 4
            color: JamiTheme.shadowColor
            source: boxInfo
            transparentBorder: true
        }

        Rectangle {

            id: boxInfo

            z: 0
            anchors.fill: parent
            radius: 30
            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {

                id: infoContainer

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
                    Layout.topMargin: 15
                    Layout.alignment: Qt.AlignCenter | Qt.AlignTop

                    font.pixelSize: JamiTheme.title2FontSize
                    font.kerning: true
                }

                Flow {
                    id: flow
                    spacing: 25
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: JamiTheme.preferredMarginSize * 2
                    Layout.preferredWidth: helpOpened ? Math.min(root.width - 2 * JamiTheme.preferredMarginSize, 452) : 0
                    Layout.fillWidth: true

                    InfoBox {
                        id: info
                        icoSource: JamiResources.laptop_black_24dp_svg
                        title: JamiStrings.local
                        description: JamiStrings.localAccount
                    }

                    InfoBox {
                        icoSource: JamiResources.person_24dp_svg
                        title: JamiStrings.username
                        description: JamiStrings.usernameRecommened
                    }

                    InfoBox {
                        icoSource: JamiResources.lock_svg
                        title: JamiStrings.encrypt
                        description: JamiStrings.passwordOptional
                    }

                    InfoBox {
                        icoSource: JamiResources.noun_paint_svg
                        title: JamiStrings.customize
                        description: JamiStrings.customizeOptional
                    }
                }
            }
        }
    }
}
