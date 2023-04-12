/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Sébastien blin <sebastien.blin@savoirfairelinux.com>
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
import QtMultimedia
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../mainview/components"

Rectangle {
    id: root
    property int preferredHeight: welcomePageColumnLayout.implicitHeight + 2 * JamiTheme.wizardViewPageBackButtonMargins + JamiTheme.wizardViewPageBackButtonSize
    property bool showAdvanced: false
    property bool showAlreadyHave: false
    property bool showTab: false

    KeyNavigation.down: KeyNavigation.tab
    KeyNavigation.tab: newAccountButton
    KeyNavigation.up: newAccountButton
    color: JamiTheme.secondaryBackgroundColor

    signal showThisPage

    // Make sure that welcomePage grab activeFocus initially (when there is no account)
    onVisibleChanged: {
        if (visible)
            forceActiveFocus();
    }

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.Initial)
                root.showThisPage();
        }
    }
    ColumnLayout {
        id: welcomePageColumnLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: JamiTheme.wizardViewPageLayoutSpacing
        width: Math.max(508, root.width - 100)

        Item {
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            Layout.preferredHeight: JamiTheme.welcomeLogoHeight
            Layout.preferredWidth: JamiTheme.welcomeLogoWidth

            Loader {
                id: videoPlayer
                property var mediaInfo: UtilsAdapter.getVideoPlayer(JamiTheme.darkTheme ? JamiResources.logo_dark_webm : JamiResources.logo_light_webm, JamiTheme.secondaryBackgroundColor)

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
                        Component.onCompleted: {
                            mediaPlayer.play();
                        }

                        // NOTE: Seems to crash on snap for whatever reason. For now use VideoPreview in priority
                        MediaPlayer {
                            id: mediaPlayer
                            loops: MediaPlayer.Infinite
                            source: JamiTheme.darkTheme ? JamiResources.logo_dark_webm : JamiResources.logo_light_webm
                            videoOutput: videoOutput
                        }
                        VideoOutput {
                            id: videoOutput
                            anchors.fill: parent
                        }
                    }
                }
            }
        }
        Text {
            id: introduction
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
            color: JamiTheme.textColor
            font.kerning: true
            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            horizontalAlignment: Text.AlignHCenter
            lineHeight: JamiTheme.wizardViewTextLineHeight
            text: JamiStrings.introductionJami
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        Text {
            id: description
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
            color: JamiTheme.textColor
            font.kerning: true
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            horizontalAlignment: Text.AlignHCenter
            lineHeight: JamiTheme.wizardViewTextLineHeight
            text: JamiStrings.description
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        MaterialButton {
            id: newAccountButton
            KeyNavigation.down: KeyNavigation.tab
            KeyNavigation.tab: alreadyHaveAccount
            KeyNavigation.up: backButton.visible ? backButton : (showAdvancedButton.showAdvanced ? newSIPAccountButton : showAdvancedButton)
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            objectName: "newAccountButton"
            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
            primary: true
            text: JamiStrings.joinJami
            toolTipText: JamiStrings.createNewJamiAccount

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.CreateJamiAccount)
        }
        MaterialButton {
            id: alreadyHaveAccount
            KeyNavigation.down: KeyNavigation.tab
            KeyNavigation.tab: showAlreadyHave ? fromDeviceButton : showAdvancedButton
            KeyNavigation.up: newAccountButton
            Layout.alignment: Qt.AlignCenter
            font.bold: true
            hoverEnabled: true
            objectName: "alreadyHaveAccount"
            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
            primary: true
            text: JamiStrings.alreadyHaveAccount
            toolTipText: JamiStrings.useExistingAccount

            onClicked: {
                boldFont = !boldFont;
                showAlreadyHave = !showAlreadyHave;
                showAdvanced = false;
                fromDeviceButton.visible = showAlreadyHave;
                fromBackupButton.visible = showAlreadyHave;
                newRdvButton.visible = showAdvanced;
                connectAccountManagerButton.visible = showAdvanced;
                newSIPAccountButton.visible = showAdvanced;
            }
        }
        MaterialButton {
            id: fromDeviceButton
            KeyNavigation.down: KeyNavigation.tab
            KeyNavigation.tab: fromBackupButton
            KeyNavigation.up: alreadyHaveAccount
            Layout.alignment: Qt.AlignCenter
            color: JamiTheme.secAndTertiTextColor
            objectName: "fromDeviceButton"
            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
            secondary: true
            text: JamiStrings.importAccountFromAnotherDevice
            toolTipText: JamiStrings.linkFromAnotherDevice
            visible: false

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.ImportFromDevice)
        }
        MaterialButton {
            id: fromBackupButton
            KeyNavigation.down: KeyNavigation.tab
            KeyNavigation.tab: showAdvancedButton
            KeyNavigation.up: fromDeviceButton
            Layout.alignment: Qt.AlignCenter
            color: JamiTheme.secAndTertiTextColor
            objectName: "fromBackupButton"
            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
            secondary: true
            text: JamiStrings.importAccountFromBackup
            toolTipText: JamiStrings.connectFromBackup
            visible: false

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.ImportFromBackup)
        }
        MaterialButton {
            id: showAdvancedButton
            KeyNavigation.down: KeyNavigation.tab
            KeyNavigation.tab: showAdvanced ? newRdvButton : btnAboutPopUp
            KeyNavigation.up: showAlreadyHave ? fromBackupButton : alreadyHaveAccount
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: newSIPAccountButton.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins
            objectName: "showAdvancedButton"
            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
            tertiary: true
            text: JamiStrings.advancedFeatures
            toolTipText: showAdvanced ? JamiStrings.hideAdvancedFeatures : JamiStrings.showAdvancedFeatures

            onClicked: {
                boldFont = !boldFont;
                showAdvanced = !showAdvanced;
                showAlreadyHave = false;
                newRdvButton.visible = showAdvanced;
                connectAccountManagerButton.visible = showAdvanced;
                newSIPAccountButton.visible = showAdvanced;
                fromDeviceButton.visible = showAlreadyHave;
                fromBackupButton.visible = showAlreadyHave;
            }
        }
        MaterialButton {
            id: newRdvButton
            KeyNavigation.down: connectAccountManagerButton
            KeyNavigation.tab: connectAccountManagerButton
            KeyNavigation.up: showAdvancedButton
            Layout.alignment: Qt.AlignCenter
            color: JamiTheme.secAndTertiTextColor
            objectName: "newRdvButton"
            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
            secondary: true
            text: JamiStrings.createNewRV
            toolTipText: JamiStrings.createNewRV
            visible: false

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.CreateRendezVous)
        }
        MaterialButton {
            id: connectAccountManagerButton
            KeyNavigation.down: newSIPAccountButton
            KeyNavigation.tab: newSIPAccountButton
            KeyNavigation.up: newRdvButton
            Layout.alignment: Qt.AlignCenter
            color: JamiTheme.secAndTertiTextColor
            objectName: "connectAccountManagerButton"
            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
            secondary: true
            text: JamiStrings.connectJAMSServer
            toolTipText: JamiStrings.createFromJAMS
            visible: false

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.ConnectToAccountManager)
        }
        MaterialButton {
            id: newSIPAccountButton
            KeyNavigation.down: KeyNavigation.tab
            KeyNavigation.tab: btnAboutPopUp
            KeyNavigation.up: connectAccountManagerButton
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
            color: JamiTheme.secAndTertiTextColor
            objectName: "newSIPAccountButton"
            preferredWidth: Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)
            pressedColor: JamiTheme.buttonTintedBluePressed
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
            secondary: true
            text: JamiStrings.addSIPAccount
            toolTipText: JamiStrings.createNewSipAccount
            visible: false

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.CreateSipAccount)
        }
        MaterialButton {
            id: btnAboutPopUp
            KeyNavigation.down: KeyNavigation.tab
            KeyNavigation.tab: backButton.visible ? backButton : newAccountButton
            KeyNavigation.up: connectAccountManagerButton
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Layout.bottomMargin: JamiTheme.preferredMarginSize
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            fontSize: JamiTheme.wizardViewAboutJamiFontPixelSize
            preferredWidth: JamiTheme.aboutButtonPreferredWidth
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
            tertiary: true
            text: JamiStrings.aboutJami

            onClicked: viewCoordinator.presentDialog(parent, "mainview/components/AboutPopUp.qml")
        }
    }
    BackButton {
        id: backButton
        KeyNavigation.down: KeyNavigation.tab
        KeyNavigation.tab: newAccountButton
        KeyNavigation.up: showAdvanced ? newSIPAccountButton : showAdvancedButton
        anchors.left: parent.left
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins
        anchors.top: parent.top
        objectName: "welcomePageBackButton"
        visible: UtilsAdapter.getAccountListSize()

        onClicked: WizardViewStepModel.previousStep()

        Connections {
            target: LRCInstance

            function onAccountListChanged() {
                backButton.visible = UtilsAdapter.getAccountListSize();
            }
        }
    }
}
