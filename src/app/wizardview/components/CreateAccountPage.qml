/*
* Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
import "../../mainview/components"
import "../../commoncomponents/contextmenu"

Rectangle {
    id: root

    property bool isRendezVous: false
    property bool helpOpened: false
    property int preferredHeight: createAccountStack.implicitHeight
    property string chosenDisplayName: ""

    signal showThisPage

    function initializeOnShowUp(isRdv) {
        root.isRendezVous = isRdv;
        createAccountStack.currentIndex = 0;
        clearAllTextFields();
        usernameEdit.forceActiveFocus();
    }

    function clearAllTextFields() {
        joinJamiButton.enabled = true;
        encryptButton.enabled = true;
        usernameEdit.dynamicText = "";
    }

    color: JamiTheme.secondaryBackgroundColor

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            var currentMainStep = WizardViewStepModel.mainStep;
            if (currentMainStep === WizardViewStepModel.MainSteps.NameRegistration) {
                createAccountStack.currentIndex = nameRegistrationPage.stackIndex;
                initializeOnShowUp(WizardViewStepModel.accountCreationOption
                                   === WizardViewStepModel.AccountCreationOption.CreateRendezVous);
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
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize
                                                    * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
                    wrapMode: Text.WordWrap
                }

                Text {

                    text: root.isRendezVous ? JamiStrings.chooseUsernameForRV :
                                              JamiStrings.chooseUsernameForAccount
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize
                                                    * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor

                    font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
                    wrapMode: Text.WordWrap
                    lineHeight: JamiTheme.wizardViewTextLineHeight
                }

                UsernameTextEdit {
                    id: usernameEdit
                    accountId: ""

                    Accessible.role: Accessible.EditableText
                    Accessible.name: invalidLabel.text

                    icon: PushButton {
                        id: infoBox
                        z: 1

                        Accessible.role: Accessible.StaticText
                        Accessible.name: textInfo.text

                        normalColor: "transparent"
                        imageColor: infoBox.checked ? JamiTheme.inviteHoverColor :
                                                      JamiTheme.buttonTintedBlue
                        source: JamiResources.i_informations_black_24dp_svg
                        pressedColor: JamiTheme.tintedBlue
                        hoveredColor: JamiTheme.hoveredButtonColorWizard
                        border.color: {
                            if (infoBox.checked) {
                                return "transparent";
                            }
                            return JamiTheme.buttonTintedBlue;
                        }
                        checkable: true
                        onCheckedChanged: {
                            textBoxinfo.visible = !textBoxinfo.visible;
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
                                NumberAnimation {
                                    duration: JamiTheme.shortFadeDuration
                                }
                            }

                            Behavior on height {
                                NumberAnimation {
                                    duration: JamiTheme.shortFadeDuration
                                }
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
                                samples: radius + 1
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

                        KeyNavigation.tab: joinJamiButton
                        KeyNavigation.up: usernameEdit
                        KeyNavigation.down: joinJamiButton
                    }

                    objectName: "usernameEdit"

                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize
                                                    * 2)
                    placeholderText: root.isRendezVous ? JamiStrings.chooseAName :
                                                         JamiStrings.chooseUsername
                    staticText: ""
                    editMode: true

                    KeyNavigation.tab: infoBox
                    KeyNavigation.up: backButton
                    KeyNavigation.down: infoBox
                }

                Label {
                    id: invalidLabel

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
                    visible: text.length !== 0
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize
                                                    * 2)

                    text: {
                        switch (usernameEdit.nameRegistrationState) {
                        case UsernameTextEdit.NameRegistrationState.BLANK:
                            return "";
                        case UsernameTextEdit.NameRegistrationState.SEARCHING:
                            return "";
                        case UsernameTextEdit.NameRegistrationState.FREE:
                            return "";
                        case UsernameTextEdit.NameRegistrationState.INVALID:
                            return root.isRendezVous ? JamiStrings.invalidName :
                                                       JamiStrings.invalidUsername;
                        case UsernameTextEdit.NameRegistrationState.TAKEN:
                            return root.isRendezVous ? JamiStrings.nameAlreadyTaken :
                                                       JamiStrings.usernameAlreadyTaken;
                        }
                    }
                    font.pixelSize: JamiTheme.textEditError
                    color: "#CC0022"
                }

                NewMaterialButton {
                    id: joinJamiButton

                    objectName: "joinJamiButton"

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

                    implicitHeight: JamiTheme.newMaterialButtonSetupHeight

                    z: -1

                    filledButton: true

                    font.capitalization: Font.AllUppercase
                    text: !enabled ? JamiStrings.creatingAccount : root.isRendezVous
                                     ? JamiStrings.chooseName : JamiStrings.joinJami
                    enabled: usernameEdit.nameRegistrationState
                             === UsernameTextEdit.NameRegistrationState.FREE
                             || usernameEdit.nameRegistrationState
                             === UsernameTextEdit.NameRegistrationState.BLANK

                    KeyNavigation.tab: encryptButton
                    KeyNavigation.up: usernameEdit
                    KeyNavigation.down: encryptButton

                    onClicked: {
                        WizardViewStepModel.accountCreationInfo
                                = JamiQmlUtils.setUpAccountCreationInputPara({
                                                                                 "registeredName":
                                                                                 usernameEdit.dynamicText,
                                                                                 "alias": root.chosenDisplayName,
                                                                                 "password":
                                                                                 advancedButtons.chosenPassword,
                                                                                 "avatar": UtilsAdapter.tempCreationImage(
                                                                                               ),
                                                                                 "isRendezVous":
                                                                                 root.isRendezVous
                                                                             });
                        if (usernameEdit.nameRegistrationState
                                === UsernameTextEdit.NameRegistrationState.FREE) {
                            enabled = false;
                            encryptButton.enabled = false;
                            WizardViewStepModel.nextStep();
                        }
                        if (usernameEdit.nameRegistrationState
                                === UsernameTextEdit.NameRegistrationState.BLANK)
                            popup.visible = true;
                        UtilsAdapter.setTempCreationImageFromString("", "temp");
                    }
                    Accessible.description: invalidLabel.text
                }

                RowLayout {
                    id: advancedButtons

                    Layout.alignment: Qt.AlignCenter

                    property string chosenPassword: ""

                    spacing: 5

                    NewMaterialButton {
                        id: encryptButton

                        Layout.alignment: Qt.AlignCenter
                        Layout.topMargin: 2 * JamiTheme.wizardViewBlocMarginSize

                        textButton: true
                        text: JamiStrings.setPassword
                        toolTipText: JamiStrings.encryptWithPassword

                        KeyNavigation.tab: backButton
                        KeyNavigation.up: joinJamiButton
                        KeyNavigation.down: backButton
                        KeyNavigation.right: backButton

                        onClicked: {
                            var dlg = viewCoordinator.presentDialog(appWindow,
                                                                    "wizardview/components/EncryptAccountPopup.qml");
                            dlg.accepted.connect(function (password) {
                                advancedButtons.chosenPassword = password;
                            });
                        }
                    }
                }

                NoUsernamePopup {
                    id: popup

                    objectName: "popup"

                    visible: false

                    onJoinClicked: {
                        joinJamiButton.enabled = false;
                        encryptButton.enabled = false;
                    }
                }
            }
        }
    }

    JamiPushButton {
        id: backButton
        QWKSetParentHitTestVisible {}

        objectName: "createAccountPageBackButton"

        preferredSize: 36
        imageContainerWidth: 20
        source: JamiResources.ic_arrow_back_24dp_svg

        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.backButton
        Accessible.description: JamiStrings.backButtonExplanation

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        KeyNavigation.tab: adviceBox
        KeyNavigation.down: KeyNavigation.tab

        onClicked: {
            adviceBox.checked = false;
            infoBox.checked = false;
            if (createAccountStack.currentIndex > 0) {
                createAccountStack.currentIndex--;
            } else {
                WizardViewStepModel.previousStep();
                helpOpened = false;
            }
        }
    }

    JamiPushButton {
        id: adviceBox
        z: 1

        preferredSize: 36
        checkedImageColor: JamiTheme.chatviewButtonColor

        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.adviceBox
        Accessible.description: JamiStrings.adviceBoxExplanation

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        source: JamiResources._black_24dp_svg

        checkable: true

        onClicked: {
            if (!helpOpened) {
                checked = true;
                helpOpened = true;
                var dlg = viewCoordinator.presentDialog(appWindow,
                                                        "wizardview/components/GoodToKnowPopup.qml");
                dlg.accepted.connect(function () {
                    checked = false;
                    helpOpened = false;
                });
            }
        }

        KeyNavigation.tab: !createAccountStack.currentIndex ? usernameEdit :
                                                              advancedAccountSettingsPage
        KeyNavigation.up: backButton
        KeyNavigation.down: KeyNavigation.tab
    }

    Component.onDestruction: UtilsAdapter.setTempCreationImageFromString("", "temp")
}
