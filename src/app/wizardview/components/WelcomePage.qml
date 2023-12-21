/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
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

    KeyNavigation.tab: newAccountButton
    KeyNavigation.up: newAccountButton
    KeyNavigation.down: KeyNavigation.tab

    onWidthChanged: root.buttonSize = Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

    ColumnLayout {
        id: welcomePageColumnLayout

        spacing: JamiTheme.wizardViewPageLayoutSpacing

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 800

        Item {

            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            Layout.preferredWidth: JamiTheme.welcomeLogoWidth
            Layout.preferredHeight: JamiTheme.welcomeLogoHeight

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
                        // NOTE: Seems to crash on snap for whatever reason. For now use VideoPreview in priority
                        MediaPlayer {
                            id: mediaPlayer
                            source: JamiTheme.darkTheme ? JamiResources.logo_dark_webm : JamiResources.logo_light_webm
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

        MaterialButton {
            id: newAccountButton

            objectName: "newAccountButton"
            primary: true

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
            preferredWidth: root.buttonSize

            text: JamiStrings.joinJami
            toolTipText: JamiStrings.createNewJamiAccount

            KeyNavigation.tab: alreadyHaveAccount
            KeyNavigation.up: backButton.visible ? backButton : (showAdvancedButton.showAdvanced ? newSIPAccountButton : showAdvancedButton)
            KeyNavigation.down: KeyNavigation.tab

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.CreateJamiAccount)
        }

        MaterialButton {
            id: alreadyHaveAccount

            objectName: "alreadyHaveAccount"
            primary: true

            preferredWidth: root.buttonSize

            Layout.alignment: Qt.AlignCenter

            text: JamiStrings.alreadyHaveAccount
            toolTipText: JamiStrings.useExistingAccount

            font.bold: true

            hoverEnabled: true

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

        MaterialButton {
            id: fromDeviceButton

            objectName: "fromDeviceButton"
            secondary: true
            color: JamiTheme.secAndTertiTextColor
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor

            Layout.alignment: Qt.AlignCenter

            preferredWidth: root.buttonSize

            visible: false

            text: JamiStrings.importAccountFromAnotherDevice
            toolTipText: JamiStrings.linkFromAnotherDevice

            KeyNavigation.tab: fromBackupButton
            KeyNavigation.up: alreadyHaveAccount
            KeyNavigation.down: KeyNavigation.tab

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.ImportFromDevice)
        }

        MaterialButton {
            id: fromBackupButton

            objectName: "fromBackupButton"
            secondary: true
            color: JamiTheme.secAndTertiTextColor
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor

            visible: false

            Layout.alignment: Qt.AlignCenter
            preferredWidth: root.buttonSize

            text: JamiStrings.importAccountFromBackup
            toolTipText: JamiStrings.connectFromBackup

            KeyNavigation.tab: showAdvancedButton
            KeyNavigation.up: fromDeviceButton
            KeyNavigation.down: KeyNavigation.tab

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.ImportFromBackup)
        }

        MaterialButton {
            id: showAdvancedButton

            objectName: "showAdvancedButton"
            tertiary: true
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: newSIPAccountButton.visible ? 0 : JamiTheme.wizardViewPageBackButtonMargins

            preferredWidth: root.buttonSize
            text: JamiStrings.advancedFeatures
            toolTipText: showAdvanced ? JamiStrings.hideAdvancedFeatures : JamiStrings.showAdvancedFeatures

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

        MaterialButton {
            id: newRdvButton

            objectName: "newRdvButton"
            secondary: true
            color: JamiTheme.secAndTertiTextColor
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor

            Layout.alignment: Qt.AlignCenter

            preferredWidth: root.buttonSize
            visible: false

            text: JamiStrings.createNewRV
            toolTipText: JamiStrings.createNewRV

            KeyNavigation.tab: connectAccountManagerButton
            KeyNavigation.up: showAdvancedButton
            KeyNavigation.down: connectAccountManagerButton

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.CreateRendezVous)
        }

        MaterialButton {
            id: connectAccountManagerButton

            objectName: "connectAccountManagerButton"
            secondary: true
            color: JamiTheme.secAndTertiTextColor
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor

            Layout.alignment: Qt.AlignCenter

            preferredWidth: root.buttonSize
            visible: false

            text: JamiStrings.connectJAMSServer
            toolTipText: JamiStrings.createFromJAMS

            KeyNavigation.tab: newSIPAccountButton
            KeyNavigation.up: newRdvButton
            KeyNavigation.down: newSIPAccountButton

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.ConnectToAccountManager)
        }

        MaterialButton {
            id: newSIPAccountButton

            objectName: "newSIPAccountButton"
            secondary: true
            color: JamiTheme.secAndTertiTextColor
            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
            pressedColor: JamiTheme.buttonTintedBluePressed

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins

            preferredWidth: root.buttonSize
            visible: false

            text: JamiStrings.addSIPAccount
            toolTipText: JamiStrings.createNewSipAccount

            KeyNavigation.tab: btnAboutPopUp
            KeyNavigation.up: connectAccountManagerButton
            KeyNavigation.down: KeyNavigation.tab

            onClicked: WizardViewStepModel.startAccountCreationFlow(WizardViewStepModel.AccountCreationOption.CreateSipAccount)
        }

        MaterialButton {
            id: btnAboutPopUp

            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Layout.bottomMargin: JamiTheme.preferredMarginSize
            Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

            preferredWidth: JamiTheme.aboutButtonPreferredWidth

            secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
            tertiary: true

            fontSize: JamiTheme.wizardViewAboutJamiFontPixelSize

            KeyNavigation.tab: backButton.visible ? backButton : newAccountButton
            KeyNavigation.up: connectAccountManagerButton
            KeyNavigation.down: KeyNavigation.tab

            text: JamiStrings.aboutJami

            onClicked: viewCoordinator.presentDialog(parent, "mainview/components/AboutPopUp.qml")
        }
    }

    JamiPushButton { ParentHitTestVisible {}
        id: backButton

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

        KeyNavigation.tab: newAccountButton
        KeyNavigation.up: showAdvanced ? newSIPAccountButton : showAdvancedButton
        KeyNavigation.down: KeyNavigation.tab

        onClicked: WizardViewStepModel.previousStep()
    }
}
