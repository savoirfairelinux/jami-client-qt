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
import QtMultimedia
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../../mainview/components"
import "../../settingsview/components"

Rectangle {
    id: root

    property int itemWidth: 188
    property int preferredHeight: welcomePageColumnLayout.implicitHeight + 2
                                  * JamiTheme.wizardViewPageBackButtonMargins
                                  + JamiTheme.wizardViewPageBackButtonSize
    property bool showTab: false
    property bool showAlreadyHave: false
    property bool showAdvanced: false
    property int buttonSize: JamiTheme.wizardButtonWidth

    signal showThisPage

    color: JamiTheme.secondaryBackgroundColor

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.Initial)
                root.showThisPage();
        }
    }

    // Make sure that welcomePage grab activeFocus initially (when there is no account)
    onVisibleChanged: {
        if (visible)
            forceActiveFocus();
    }
    Accessible.role: Accessible.Pane
    Accessible.name: introduction.text
    Accessible.description: JamiStrings.description

    KeyNavigation.tab: newAccountButton
    KeyNavigation.up: newAccountButton
    KeyNavigation.down: KeyNavigation.tab

    onWidthChanged: root.buttonSize = Math.min(JamiTheme.wizardButtonWidth, root.width
                                               - JamiTheme.preferredMarginSize * 2)

    ColumnLayout {
        id: welcomePageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 800

        Item {
            Accessible.name: introduction.text
            Accessible.description: JamiStrings.description

            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            Layout.preferredWidth: JamiTheme.welcomeLogoWidth
            Layout.preferredHeight: JamiTheme.welcomeLogoHeight

            Loader {
                id: videoPlayer

                property var mediaInfo: UtilsAdapter.getVideoPlayer(JamiTheme.darkTheme
                                                                    ? JamiResources.logo_dark_webm :
                                                                      JamiResources.logo_light_webm,
                                                                    JamiTheme.secondaryBackgroundColor)
                anchors.fill: parent
                anchors.margins: 2
                sourceComponent: WITH_WEBENGINE ? avMediaComp : basicPlayer

                Component {
                    id: avMediaComp
                    Loader {
                        Component.onCompleted: {
                            var qml = "qrc:/webengine/VideoPreview.qml";
                            setSource(qml, {
                                          "isVideo": mediaInfo.isVideo,
                                          "html": mediaInfo.html
                                      });
                        }
                    }
                }

                Component {
                    id: basicPlayer

                    Item {
                        // NOTE: Seems to crash on snap for whatever reason. For now use VideoPreview in priority
                        MediaPlayer {
                            id: mediaPlayer
                            source: JamiTheme.darkTheme ? JamiResources.logo_dark_webm :
                                                          JamiResources.logo_light_webm
                            videoOutput: videoOutput
                            loops: MediaPlayer.Infinite
                        }

                        VideoOutput {
                            id: videoOutput
                            anchors.fill: parent
                        }

                        Component.onCompleted: {
                            mediaPlayer.play();
                        }
                    }
                }
            }
        }

        Text {
            id: introduction

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
            Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

            text: JamiStrings.introductionJami
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            lineHeight: JamiTheme.wizardViewTextLineHeight

            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            font.kerning: true
        }

        Text {
            id: description

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)

            text: JamiStrings.description
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            lineHeight: JamiTheme.wizardViewTextLineHeight

            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            font.kerning: true
        }

        NewMaterialButton {
            id: newAccountButton

            objectName: "newAccountButton"

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

            implicitWidth: root.buttonSize

            filledButton: true
            text: JamiStrings.joinJami
            toolTipText: JamiStrings.createNewJamiAccount

            KeyNavigation.tab: alreadyHaveAccount
            KeyNavigation.up: backButton.visible ? backButton : (showAdvancedButton.showAdvanced
                                                                 ? newSIPAccountButton :
                                                                   showAdvancedButton)
            KeyNavigation.down: KeyNavigation.tab

            onClicked: WizardViewStepModel.startAccountCreationFlow(
                           WizardViewStepModel.AccountCreationOption.CreateJamiAccount)
        }

        NewMaterialButton {
            id: alreadyHaveAccount

            Layout.alignment: Qt.AlignCenter

            implicitWidth: root.buttonSize

            filledButton: true
            text: JamiStrings.alreadyHaveAccount
            toolTipText: JamiStrings.useExistingAccount

            KeyNavigation.tab: showAlreadyHave ? fromDeviceButton : showAdvancedButton

            KeyNavigation.up: newAccountButton
            KeyNavigation.down: KeyNavigation.tab

            onClicked: {
                showAlreadyHave = !showAlreadyHave;
                showAdvanced = false;
                fromDeviceButton.visible = showAlreadyHave;
                fromBackupButton.visible = showAlreadyHave;
                newRdvButton.visible = showAdvanced;
                connectAccountManagerButton.visible = showAdvanced;
                newSIPAccountButton.visible = showAdvanced;
            }
        }

        NewMaterialButton {
            id: fromDeviceButton

            objectName: "fromDeviceButton"

            Layout.alignment: Qt.AlignCenter

            implicitWidth: root.buttonSize

            outlinedButton: true
            text: JamiStrings.importAccountFromAnotherDevice
            toolTipText: JamiStrings.linkFromAnotherDevice

            visible: false

            KeyNavigation.tab: fromBackupButton
            KeyNavigation.up: alreadyHaveAccount
            KeyNavigation.down: KeyNavigation.tab

            onClicked: WizardViewStepModel.startAccountCreationFlow(
                           WizardViewStepModel.AccountCreationOption.ImportFromDevice)
        }

        NewMaterialButton {
            id: fromBackupButton

            objectName: "fromBackupButton"

            Layout.alignment: Qt.AlignCenter

            implicitWidth: root.buttonSize

            outlinedButton: true
            text: JamiStrings.importAccountFromBackup
            toolTipText: JamiStrings.connectFromBackup

            visible: false

            KeyNavigation.tab: showAdvancedButton
            KeyNavigation.up: fromDeviceButton
            KeyNavigation.down: KeyNavigation.tab

            onClicked: WizardViewStepModel.startAccountCreationFlow(
                           WizardViewStepModel.AccountCreationOption.ImportFromBackup)
        }

        NewMaterialButton {
            id: showAdvancedButton

            objectName: "showAdvancedButton"

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: newSIPAccountButton.visible ? 0 :
                                                               JamiTheme.wizardViewPageBackButtonMargins
            implicitWidth: root.buttonSize

            textButton: true
            text: JamiStrings.advancedFeatures
            toolTipText: showAdvanced ? JamiStrings.hideAdvancedFeatures :
                                        JamiStrings.showAdvancedFeatures

            KeyNavigation.tab: showAdvanced ? newRdvButton : btnAboutPopUp
            KeyNavigation.up: showAlreadyHave ? fromBackupButton : alreadyHaveAccount
            KeyNavigation.down: KeyNavigation.tab

            onClicked: {
                showAdvanced = !showAdvanced;
                showAlreadyHave = false;
                newRdvButton.visible = showAdvanced;
                connectAccountManagerButton.visible = showAdvanced;
                newSIPAccountButton.visible = showAdvanced;
                fromDeviceButton.visible = showAlreadyHave;
                fromBackupButton.visible = showAlreadyHave;
            }
        }

        NewMaterialButton {
            id: newRdvButton

            objectName: "newRdvButton"

            Layout.alignment: Qt.AlignCenter
            implicitWidth: root.buttonSize

            outlinedButton: true
            text: JamiStrings.createNewRV
            toolTipText: JamiStrings.createNewRV

            visible: false

            KeyNavigation.tab: connectAccountManagerButton
            KeyNavigation.up: showAdvancedButton
            KeyNavigation.down: connectAccountManagerButton

            onClicked: WizardViewStepModel.startAccountCreationFlow(
                           WizardViewStepModel.AccountCreationOption.CreateRendezVous)
        }

        NewMaterialButton {
            id: connectAccountManagerButton

            objectName: "connectAccountManagerButton"

            Layout.alignment: Qt.AlignCenter

            implicitWidth: root.buttonSize

            outlinedButton: true
            text: JamiStrings.connectJAMSServer
            toolTipText: JamiStrings.createFromJAMS

            visible: false

            KeyNavigation.tab: newSIPAccountButton
            KeyNavigation.up: newRdvButton
            KeyNavigation.down: newSIPAccountButton

            onClicked: WizardViewStepModel.startAccountCreationFlow(
                           WizardViewStepModel.AccountCreationOption.ConnectToAccountManager)
        }

        NewMaterialButton {
            id: newSIPAccountButton

            objectName: "newSIPAccountButton"

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

            implicitWidth: root.buttonSize

            outlinedButton: true
            text: JamiStrings.addSIPAccount
            toolTipText: JamiStrings.createNewSipAccount

            visible: false

            KeyNavigation.tab: btnAboutPopUp
            KeyNavigation.up: connectAccountManagerButton
            KeyNavigation.down: KeyNavigation.tab

            onClicked: WizardViewStepModel.startAccountCreationFlow(
                           WizardViewStepModel.AccountCreationOption.CreateSipAccount)
        }

        NewMaterialButton {
            id: btnAboutPopUp

            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Layout.bottomMargin: JamiTheme.preferredMarginSize * 3
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSizeutButtonPreferredWidth

            KeyNavigation.tab: backButton.visible ? backButton : newAccountButton
            KeyNavigation.up: showAdvanced ? newSIPAccountButton : showAdvancedButton
            KeyNavigation.down: KeyNavigation.tab
            KeyNavigation.backtab: KeyNavigation.up

            textButton: true
            text: JamiStrings.aboutJami

            onClicked: viewCoordinator.presentDialog(parent, "mainview/components/AboutPopUp.qml")
        }
    }

    JamiPushButton {
        id: backButton
        QWKSetParentHitTestVisible {}

        objectName: "welcomePageBackButton"

        preferredSize: 36
        imageContainerWidth: 20
        source: JamiResources.ic_arrow_back_24dp_svg

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        Connections {
            target: LRCInstance

            function onAccountListChanged() {
                backButton.visible = UtilsAdapter.getAccountListSize();
            }
        }

        visible: UtilsAdapter.getAccountListSize()
        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.backButton
        Accessible.description: JamiStrings.backButtonExplanation

        KeyNavigation.tab: newAccountButton
        KeyNavigation.up: showAdvanced ? newSIPAccountButton : showAdvancedButton
        KeyNavigation.down: KeyNavigation.tab

        onClicked: WizardViewStepModel.previousStep()
    }

    SettingsComboBox {
        id: langComboBoxSetting

        // This component is not yet accessible via keyboard navigation because our comboboxes
        // are currently broken from an accessibility standpoint. The fix would be to
        // refactor to use the base Qt ComboBox.

        height: JamiTheme.preferredFieldHeight + 20
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins
        Accessible.role: Accessible.ComboBox
        Accessible.name: JamiStrings.userInterfaceLanguage
        Accessible.description: JamiStrings.languageComboBoxExplanation

        labelText: JamiStrings.userInterfaceLanguage
        tipText: JamiStrings.userInterfaceLanguage
        comboModel: ListModel {
            id: langModel
            Component.onCompleted: {
                var supported = UtilsAdapter.supportedLang();
                var keys = Object.keys(supported);
                var currentKey = UtilsAdapter.getAppValue(Settings.Key.LANG);
                for (var i = 0; i < keys.length; ++i) {
                    append({
                               "textDisplay": supported[keys[i]],
                               "id": keys[i]
                           });
                    if (keys[i] === currentKey)
                        langComboBoxSetting.modelIndex = i;
                }
            }
        }

        widthOfComboBox: itemWidth
        role: "textDisplay"

        onActivated: {
            UtilsAdapter.setAppValue(Settings.Key.LANG, comboModel.get(modelIndex).id);
        }
    }
}
