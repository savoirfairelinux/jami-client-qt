/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import Qt5Compat.GraphicalEffects


import "../../commoncomponents"

Popup {
    id: root

    width: popupContent.width
    height: popupContent.height

    parent: Overlay.overlay

    // center in parent
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    signal joinClicked

    modal:true
    padding: 0

    visible: false
    closePolicy:  Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Rectangle {
        id: container

        anchors.fill: parent
        radius: JamiTheme.modalPopupRadius
        color: JamiTheme.secondaryBackgroundColor

        ColumnLayout {
            id:  popupContent

            Layout.alignment: Qt.AlignCenter

            PushButton {
                id: btnClose

                Layout.alignment: Qt.AlignRight
                width: 30
                height: 30
                imageContainerWidth: 30
                imageContainerHeight : 30
                Layout.margins: 8
                radius : 5
                imageColor: "grey"
                normalColor: JamiTheme.transparentColor
                source: JamiResources.round_close_24dp_svg
                onClicked: { root.visible = false }
            }

            Text {
                Layout.preferredWidth: 280
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.alignment: Qt.AlignCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: JamiTheme.popuptextSize
                lineHeight: JamiTheme.wizardViewTextLineHeight
                wrapMode: Text.WordWrap
                color: JamiTheme.textColor
                text: JamiStrings.joinJamiNoPassword
            }

            RowLayout{
                Layout.topMargin: JamiTheme.popupButtonsMargin
                Layout.bottomMargin: JamiTheme.popupButtonsMargin

                Layout.alignment: Qt.AlignCenter
                spacing: JamiTheme.popupButtonsMargin

                MaterialButton {

                    TextMetrics{
                        id: joinJamiSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        text: JamiStrings.joinJami
                    }

                    Layout.leftMargin: JamiTheme.popupButtonsMargin
                    objectName: "joinButton"
                    preferredWidth: joinJamiSize.width + 2*(JamiTheme.buttontextWizzardPadding + 1)
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding
                    secondary: true
                    text: JamiStrings.joinJami
                    onClicked: {
                        root.joinClicked()
                        WizardViewStepModel.nextStep()
                        root.close()
                    }
                }

                MaterialButton {

                    TextMetrics{
                        id: chooseAUsernameSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        text: JamiStrings.chooseAUsername
                    }

                    Layout.rightMargin: JamiTheme.popupButtonsMargin
                    preferredWidth: chooseAUsernameSize.width + 2*JamiTheme.buttontextWizzardPadding
                    primary: true
                    text: JamiStrings.chooseAUsername
                    onClicked: root.close()
                }
            }

        }
    }

    background: Rectangle {
        color: JamiTheme.transparentColor
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
        // Color animation for overlay when pop up is shown.
        ColorAnimation on color {
            to: JamiTheme.popupOverlayColor
            duration: 500
        }
    }

    DropShadow {
        z: -1
        width: root.width
        height: root.height
        horizontalOffset: 3.0
        verticalOffset: 3.0
        radius: container.radius * 4
        color: JamiTheme.shadowColor
        source: container
        transparentBorder: true
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"; from: 0.0; to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }

    exit: Transition {
        NumberAnimation {
            properties: "opacity"; from: 1.0; to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
