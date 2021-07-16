/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Sébastien blin <sebastien.blin@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Rectangle {
    id: root

    property int preferredHeight: welcomePageColumnLayout.implicitHeight

    signal scrollToBottom
    signal showThisPage

    color: "transparent"

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            if (WizardViewStepModel.mainStep === WizardViewStepModel.MainSteps.Initial)
                root.showThisPage()
        }
    }

    ColumnLayout {
        id: welcomePageColumnLayout

        anchors.centerIn: parent

        spacing: JamiTheme.wizardViewPageLayoutSpacing

        Text {
            id: welcomeLabel

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: JamiTheme.wizardViewPageBackButtonMargins
            Layout.preferredHeight: contentHeight

            text: qsTr("Welcome to")
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            font.pointSize: JamiTheme.welcomeLabelPointSize
            font.kerning: true
        }

        ResponsiveImage {
            id: welcomeLogo

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: JamiTheme.welcomeLogoWidth
            Layout.preferredHeight: JamiTheme.welcomeLogoHeight

            source: JamiTheme.darkTheme ?
                        "qrc:/images/logo-jami-standard-coul-white.svg" :
                        "qrc:/images/logo-jami-standard-coul.svg"
        }

        MaterialButton {
            id: newAccountButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: preferredWidth
            Layout.preferredHeight: preferredHeight

            text: JamiStrings.createNewJA
            fontCapitalization: Font.AllUppercase
            toolTipText: qsTr("Create new Jami account")
            source: "qrc:/images/default_avatar_overlay.svg"
            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: JamiTheme.buttonTintedBluePressed

            onClicked: WizardViewStepModel.nextStep(
                           WizardViewStepModel.AccountCreationOption.CreateJamiAccount)
        }

        MaterialButton {
            id: newRdvButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: preferredWidth
            Layout.preferredHeight: preferredHeight

            text: JamiStrings.createRV
            fontCapitalization: Font.AllUppercase
            toolTipText: JamiStrings.createNewRV
            source: "qrc:/images/icons/groups-24px.svg"
            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: JamiTheme.buttonTintedBluePressed

            onClicked: WizardViewStepModel.nextStep(
                           WizardViewStepModel.AccountCreationOption.CreateRendezVous)
        }

        MaterialButton {
            id: fromDeviceButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: preferredWidth
            Layout.preferredHeight: preferredHeight

            text: JamiStrings.linkFromAnotherDevice
            fontCapitalization: Font.AllUppercase
            toolTipText: qsTr("Import account from other device")
            source: "qrc:/images/icons/devices-24px.svg"
            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: JamiTheme.buttonTintedBluePressed

            onClicked: WizardViewStepModel.nextStep(
                           WizardViewStepModel.AccountCreationOption.ImportFromDevice)
        }

        MaterialButton {
            id: fromBackupButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: preferredWidth
            Layout.preferredHeight: preferredHeight

            text: JamiStrings.connectFromBackup
            fontCapitalization: Font.AllUppercase
            toolTipText: qsTr("Import account from backup file")
            source: "qrc:/images/icons/backup-24px.svg"
            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: JamiTheme.buttonTintedBluePressed

            onClicked: WizardViewStepModel.nextStep(
                           WizardViewStepModel.AccountCreationOption.ImportFromBackup)
        }

        MaterialButton {
            id: showAdvancedButton

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: newSIPAccountButton.visible ?
                                     0 : JamiTheme.wizardViewPageBackButtonMargins
            Layout.preferredWidth: preferredWidth
            Layout.preferredHeight: preferredHeight

            text: JamiStrings.advancedFeatures
            fontCapitalization: Font.AllUppercase
            toolTipText: JamiStrings.showAdvancedFeatures
            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: JamiTheme.buttonTintedBluePressed
            outlined: true

            hoverEnabled: true

            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.visible: hovered
            ToolTip.text: JamiStrings.showAdvancedFeatures

            onClicked: {
                connectAccountManagerButton.visible = !connectAccountManagerButton.visible
                newSIPAccountButton.visible = !newSIPAccountButton.visible
            }
        }

        MaterialButton {
            id: connectAccountManagerButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: preferredWidth
            Layout.preferredHeight: preferredHeight

            visible: false

            text: JamiStrings.connectJAMSServer
            fontCapitalization: Font.AllUppercase
            toolTipText: JamiStrings.createFromJAMS
            source: "qrc:/images/icons/router-24px.svg"
            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: JamiTheme.buttonTintedBluePressed

            onClicked: WizardViewStepModel.nextStep(
                           WizardViewStepModel.AccountCreationOption.ConnectToAccountManager)
        }

        MaterialButton {
            id: newSIPAccountButton

            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
            Layout.preferredWidth: preferredWidth
            Layout.preferredHeight: preferredHeight

            visible: false

            text: JamiStrings.addSIPAccount
            fontCapitalization: Font.AllUppercase
            toolTipText: qsTr("Create new SIP account")
            source: "qrc:/images/default_avatar_overlay.svg"
            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            pressedColor: JamiTheme.buttonTintedBluePressed

            onClicked: WizardViewStepModel.nextStep(
                           WizardViewStepModel.AccountCreationOption.CreateSipAccount)
        }

        onHeightChanged: scrollToBottom()
    }

    PushButton {
        id: backButton

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        Connections {
            target: LRCInstance

            function onAccountListChanged() {
                backButton.visible = UtilsAdapter.getAccountListSize()
            }
        }

        preferredSize: JamiTheme.wizardViewPageBackButtonSize

        visible: UtilsAdapter.getAccountListSize()

        normalColor: root.color
        imageColor: JamiTheme.primaryForegroundColor

        source: "qrc:/images/icons/ic_arrow_back_24px.svg"
        toolTipText: JamiStrings.back

        onClicked: WizardViewStepModel.previousStep()
    }
}
