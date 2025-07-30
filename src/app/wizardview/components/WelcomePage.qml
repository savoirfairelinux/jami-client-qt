/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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
    Accessible.role: Accessible.Pane
    Accessible.name: introduction.text
    Accessible.description: JamiStrings.description

    onWidthChanged: root.buttonSize = Math.min(JamiTheme.wizardButtonWidth, root.width - JamiTheme.preferredMarginSize * 2)

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

            text: JamiStrings.aboutJami

            onClicked: viewCoordinator.presentDialog(parent, "mainview/components/AboutPopUp.qml")
        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins
        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: JamiTheme.preferredMarginSize
            wrapMode: Text.WordWrap
            color: JamiTheme.textColor
            text: JamiStrings.userInterfaceLanguage
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        JamiComboBox {
            id: langComboBoxSetting

            accessibilityName: JamiStrings.language
            accessibilityDescription: JamiStrings.languageComboBoxExplanation

            textRole: "textDisplay"
            model: ListModel {
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
                            langComboBoxSetting.currentIndex = i;
                    }
                }
            }
            width: itemWidth
            height: JamiTheme.preferredFieldHeight
            onActivated: {
                UtilsAdapter.setAppValue(Settings.Key.LANG, langModel.get(currentIndex).id);
            }
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

        onClicked: WizardViewStepModel.previousStep()
    }
}
