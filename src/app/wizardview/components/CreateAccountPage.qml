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
    property bool helpOpened: false
    property bool isRendezVous: false
    property int preferredHeight: createAccountStack.implicitHeight

    color: JamiTheme.secondaryBackgroundColor

    function clearAllTextFields() {
        chooseUsernameButton.enabled = true;
        showAdvancedButton.enabled = true;
        usernameEdit.dynamicText = "";
        advancedAccountSettingsPage.clear();
    }
    function initializeOnShowUp(isRdv) {
        root.isRendezVous = isRdv;
        createAccountStack.currentIndex = 0;
        clearAllTextFields();
        usernameEdit.forceActiveFocus();
    }
    signal showThisPage

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            var currentMainStep = WizardViewStepModel.mainStep;
            if (currentMainStep === WizardViewStepModel.MainSteps.NameRegistration) {
                createAccountStack.currentIndex = nameRegistrationPage.stackIndex;
                initializeOnShowUp(WizardViewStepModel.accountCreationOption === WizardViewStepModel.AccountCreationOption.CreateRendezVous);
                root.showThisPage();
            }
        }
    }
    MouseArea {
        anchors.fill: parent

        onClicked: {
            infoBox.checked = false;
            adviceBox.checked = false;
        }
    }
    StackLayout {
        id: createAccountStack
        anchors.fill: parent
        objectName: "createAccountStack"

        Rectangle {
            id: nameRegistrationPage
            property int stackIndex: 0

            Layout.fillHeight: true
            Layout.fillWidth: true
            color: JamiTheme.secondaryBackgroundColor
            objectName: "nameRegistrationPage"

            ColumnLayout {
                id: usernameColumnLayout
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: JamiTheme.wizardViewPageLayoutSpacing
                width: Math.max(508, root.width - 100)

                Text {
                    id: joinJami
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    text: root.isRendezVous ? JamiStrings.createNewRV : JamiStrings.joinJami
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                Text {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: JamiTheme.wizardViewTextLineHeight
                    text: root.isRendezVous ? JamiStrings.chooseUsernameForRV : JamiStrings.chooseUsernameForAccount
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                UsernameTextEdit {
                    id: usernameEdit
                    KeyNavigation.down: infoBox
                    KeyNavigation.tab: infoBox
                    KeyNavigation.up: backButton
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    editMode: true
                    objectName: "usernameEdit"
                    placeholderText: root.isRendezVous ? JamiStrings.chooseAName : JamiStrings.chooseUsername
                    staticText: ""

                    icon: PushButton {
                        id: infoBox
                        KeyNavigation.down: chooseUsernameButton
                        KeyNavigation.tab: chooseUsernameButton
                        KeyNavigation.up: usernameEdit
                        border.color: {
                            if (infoBox.checked) {
                                return "transparent";
                            }
                            return JamiTheme.buttonTintedBlue;
                        }
                        checkable: true
                        hoveredColor: JamiTheme.hoveredButtonColorWizard
                        imageColor: infoBox.checked ? JamiTheme.inviteHoverColor : JamiTheme.buttonTintedBlue
                        normalColor: "transparent"
                        preferredSize: 20
                        pressedColor: JamiTheme.tintedBlue
                        source: JamiResources.i_informations_black_24dp_svg
                        z: 1

                        onCheckedChanged: {
                            textBoxinfo.visible = !textBoxinfo.visible;
                        }

                        Item {
                            id: textBoxinfo
                            anchors.right: parent.right
                            anchors.rightMargin: -40
                            anchors.top: parent.bottom
                            anchors.topMargin: 5
                            height: textInfo.height + 2 * JamiTheme.preferredMarginSize
                            visible: false
                            width: textInfo.width + 2 * JamiTheme.preferredMarginSize

                            DropShadow {
                                anchors.fill: boxInfo
                                color: JamiTheme.shadowColor
                                horizontalOffset: 1.0
                                radius: boxInfo.radius
                                source: boxInfo
                                transparentBorder: true
                                verticalOffset: 1.0
                                z: -1
                            }
                            Rectangle {
                                id: boxInfo
                                anchors.fill: parent
                                color: JamiTheme.secondaryBackgroundColor
                                radius: 30
                                z: 1

                                Text {
                                    id: textInfo
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.margins: JamiTheme.preferredMarginSize
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: JamiTheme.textColor
                                    font.kerning: true
                                    font.pixelSize: JamiTheme.infoBoxDescFontSize
                                    lineHeight: JamiTheme.wizardViewTextLineHeight
                                    text: JamiStrings.usernameToolTip
                                }
                            }

                            Behavior on height  {
                                NumberAnimation {
                                    duration: JamiTheme.shortFadeDuration
                                }
                            }
                            Behavior on width  {
                                NumberAnimation {
                                    duration: JamiTheme.shortFadeDuration
                                }
                            }
                        }
                    }
                }
                Label {
                    id: invalidLabel
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
                    color: "#CC0022"
                    font.pixelSize: JamiTheme.textEditError
                    text: {
                        switch (usernameEdit.nameRegistrationState) {
                        case UsernameTextEdit.NameRegistrationState.BLANK:
                            return "";
                        case UsernameTextEdit.NameRegistrationState.SEARCHING:
                            return "";
                        case UsernameTextEdit.NameRegistrationState.FREE:
                            return "";
                        case UsernameTextEdit.NameRegistrationState.INVALID:
                            return root.isRendezVous ? JamiStrings.invalidName : JamiStrings.invalidUsername;
                        case UsernameTextEdit.NameRegistrationState.TAKEN:
                            return root.isRendezVous ? JamiStrings.nameAlreadyTaken : JamiStrings.usernameAlreadyTaken;
                        }
                    }
                    visible: text.length !== 0
                }
                MaterialButton {
                    id: chooseUsernameButton
                    KeyNavigation.down: showAdvancedButton
                    KeyNavigation.tab: showAdvancedButton
                    KeyNavigation.up: usernameEdit
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    color: enabled ? JamiTheme.buttonTintedBlue : JamiTheme.buttonTintedGrey
                    enabled: usernameEdit.nameRegistrationState === UsernameTextEdit.NameRegistrationState.FREE || usernameEdit.nameRegistrationState === UsernameTextEdit.NameRegistrationState.BLANK
                    font.capitalization: Font.AllUppercase
                    objectName: "chooseUsernameButton"
                    preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
                    primary: true
                    text: !enabled ? JamiStrings.creatingAccount : root.isRendezVous ? JamiStrings.chooseName : JamiStrings.joinJami
                    z: -1

                    onClicked: {
                        WizardViewStepModel.accountCreationInfo = JamiQmlUtils.setUpAccountCreationInputPara({
                                "registeredName": usernameEdit.dynamicText,
                                "alias": advancedAccountSettingsPage.alias,
                                "password": advancedAccountSettingsPage.validatedPassword,
                                "avatar": UtilsAdapter.tempCreationImage(),
                                "isRendezVous": root.isRendezVous
                            });
                        if (usernameEdit.nameRegistrationState === UsernameTextEdit.NameRegistrationState.FREE) {
                            enabled = false;
                            showAdvancedButton.enabled = false;
                            WizardViewStepModel.nextStep();
                        }
                        if (usernameEdit.nameRegistrationState === UsernameTextEdit.NameRegistrationState.BLANK)
                            popup.visible = true;
                    }

                    TextMetrics {
                        id: textSize
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.weight: Font.Bold
                        text: chooseUsernameButton.text
                    }
                }
                MaterialButton {
                    id: showAdvancedButton
                    KeyNavigation.down: backButton
                    KeyNavigation.tab: backButton
                    KeyNavigation.up: chooseUsernameButton
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 2 * JamiTheme.wizardViewBlocMarginSize
                    objectName: "showAdvancedButton"
                    preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
                    secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
                    tertiary: true
                    text: JamiStrings.advancedAccountSettings
                    toolTipText: JamiStrings.showAdvancedFeatures

                    onClicked: {
                        adviceBox.checked = false;
                        infoBox.checked = false;
                        createAccountStack.currentIndex++;
                    }
                }
                NoUsernamePopup {
                    id: popup
                    objectName: "popup"
                    visible: false

                    onJoinClicked: {
                        chooseUsernameButton.enabled = false;
                        showAdvancedButton.enabled = false;
                    }
                }
            }
        }
        AdvancedAccountSettings {
            id: advancedAccountSettingsPage
            property int stackIndex: 1

            Layout.fillHeight: true
            Layout.fillWidth: true
            objectName: "advancedAccountSettingsPage"

            onSaveButtonClicked: createAccountStack.currentIndex--
        }
    }
    BackButton {
        id: backButton
        KeyNavigation.down: usernameEdit
        KeyNavigation.tab: usernameEdit
        KeyNavigation.up: advancedAccountSettingsPage
        anchors.left: parent.left
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins
        anchors.top: parent.top
        objectName: "createAccountPageBackButton"
        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        onClicked: {
            adviceBox.checked = false;
            infoBox.checked = false;
            if (createAccountStack.currentIndex > 0) {
                createAccountStack.currentIndex--;
            } else {
                WizardViewStepModel.previousStep();
                goodToKnow.visible = false;
                helpOpened = false;
            }
        }
    }
    PushButton {
        id: adviceBox
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins
        anchors.right: parent.right
        anchors.top: parent.top
        border.color: {
            if (adviceBox.checked) {
                return "transparent";
            }
            return JamiTheme.buttonTintedBlue;
        }
        checkable: true
        hoveredColor: JamiTheme.hoveredButtonColorWizard
        imageColor: adviceBox.checked ? JamiTheme.inviteHoverColor : JamiTheme.buttonTintedBlue
        normalColor: "transparent"
        preferredSize: JamiTheme.wizardViewPageBackButtonSize
        pressedColor: JamiTheme.tintedBlue
        source: JamiResources._black_24dp_svg
        z: 1

        onCheckedChanged: {
            goodToKnow.visible = !goodToKnow.visible;
            helpOpened = !helpOpened;
            advancedAccountSettingsPage.openedPassword = false;
            advancedAccountSettingsPage.openedNickname = false;
        }
    }
    Item {
        id: goodToKnow
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins + adviceBox.preferredWidth * 2 / 5
        anchors.right: parent.right
        anchors.top: parent.top
        height: {
            if (!helpOpened)
                return 0;
            var finalHeight = title.height + 3 * JamiTheme.preferredMarginSize;
            finalHeight += flow.implicitHeight;
            return finalHeight;
        }
        visible: false
        width: helpOpened ? Math.min(root.width - 2 * JamiTheme.preferredMarginSize, 452) : 0

        DropShadow {
            anchors.fill: boxAdvice
            color: JamiTheme.shadowColor
            horizontalOffset: 2.0
            radius: boxAdvice.radius
            source: boxAdvice
            transparentBorder: true
            verticalOffset: 2.0
            z: -1
        }
        Rectangle {
            id: boxAdvice
            anchors.fill: parent
            color: JamiTheme.secondaryBackgroundColor
            radius: 30
            z: 0

            ColumnLayout {
                id: adviceContainer
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.verticalCenter: parent.verticalCenter
                visible: helpOpened ? 1 : 0

                Text {
                    id: title
                    Layout.alignment: Qt.AlignCenter | Qt.AlignTop
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pixelSize: JamiTheme.title2FontSize
                    font.weight: Font.Medium
                    text: JamiStrings.goodToKnow
                }
                Flow {
                    id: flow
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    Layout.leftMargin: JamiTheme.preferredMarginSize * 4
                    Layout.preferredWidth: helpOpened ? Math.min(root.width - 2 * JamiTheme.preferredMarginSize, 452) : 0
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    spacing: 25

                    InfoBox {
                        id: info
                        description: JamiStrings.localAccount
                        icoColor: JamiTheme.buttonTintedBlue
                        icoSource: JamiResources.laptop_black_24dp_svg
                        title: JamiStrings.local
                    }
                    InfoBox {
                        description: JamiStrings.usernameRecommened
                        icoColor: JamiTheme.buttonTintedBlue
                        icoSource: JamiResources.person_24dp_svg
                        title: JamiStrings.username
                    }
                    InfoBox {
                        description: JamiStrings.passwordOptional
                        icoColor: JamiTheme.buttonTintedBlue
                        icoSource: JamiResources.lock_svg
                        title: JamiStrings.encrypt
                    }
                    InfoBox {
                        description: JamiStrings.customizeOptional
                        icoColor: JamiTheme.buttonTintedBlue
                        icoSource: JamiResources.noun_paint_svg
                        title: JamiStrings.customize
                    }
                }

                Behavior on visible  {
                    NumberAnimation {
                        duration: JamiTheme.overlayFadeDuration
                        from: 0
                    }
                }
            }
        }

        Behavior on height  {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
        Behavior on width  {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
}
