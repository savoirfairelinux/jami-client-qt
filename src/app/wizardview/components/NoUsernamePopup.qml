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
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    height: popupContent.height
    modal: true
    padding: 0
    parent: Overlay.overlay
    visible: false
    width: popupContent.width

    // center in parent
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    signal joinClicked

    Rectangle {
        id: container
        anchors.fill: parent
        color: JamiTheme.secondaryBackgroundColor
        radius: JamiTheme.modalPopupRadius

        ColumnLayout {
            id: popupContent
            Layout.alignment: Qt.AlignCenter

            PushButton {
                id: btnClose
                Layout.alignment: Qt.AlignRight
                Layout.margins: 8
                height: 30
                imageColor: "grey"
                imageContainerHeight: 30
                imageContainerWidth: 30
                normalColor: JamiTheme.transparentColor
                radius: 5
                source: JamiResources.round_close_24dp_svg
                width: 30

                onClicked: {
                    root.visible = false;
                }
            }
            Text {
                Layout.alignment: Qt.AlignCenter
                Layout.leftMargin: 20
                Layout.preferredWidth: 280
                Layout.rightMargin: 20
                color: JamiTheme.textColor
                font.pixelSize: JamiTheme.popuptextSize
                horizontalAlignment: Text.AlignHCenter
                lineHeight: JamiTheme.wizardViewTextLineHeight
                text: JamiStrings.joinJamiNoPassword
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: JamiTheme.popupButtonsMargin
                Layout.topMargin: JamiTheme.popupButtonsMargin
                spacing: JamiTheme.popupButtonsMargin

                MaterialButton {
                    Layout.leftMargin: JamiTheme.popupButtonsMargin
                    objectName: "joinButton"
                    preferredWidth: joinJamiSize.width + 2 * (JamiTheme.buttontextWizzardPadding + 1)
                    secondary: true
                    text: JamiStrings.joinJami
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding

                    onClicked: {
                        root.joinClicked();
                        WizardViewStepModel.nextStep();
                        root.close();
                    }

                    TextMetrics {
                        id: joinJamiSize
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.weight: Font.Bold
                        text: JamiStrings.joinJami
                    }
                }
                MaterialButton {
                    Layout.rightMargin: JamiTheme.popupButtonsMargin
                    preferredWidth: chooseAUsernameSize.width + 2 * JamiTheme.buttontextWizzardPadding
                    primary: true
                    text: JamiStrings.chooseAUsername

                    onClicked: root.close()

                    TextMetrics {
                        id: chooseAUsernameSize
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.weight: Font.Bold
                        text: JamiStrings.chooseAUsername
                    }
                }
            }
        }
    }
    DropShadow {
        color: JamiTheme.shadowColor
        height: root.height
        horizontalOffset: 3.0
        radius: container.radius * 4
        source: container
        transparentBorder: true
        verticalOffset: 3.0
        width: root.width
        z: -1
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor

        // Color animation for overlay when pop up is shown.
        ColorAnimation on color  {
            duration: 500
            to: JamiTheme.popupOverlayColor
        }
    }
    background: Rectangle {
        color: JamiTheme.transparentColor
    }
    enter: Transition {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            from: 0.0
            properties: "opacity"
            to: 1.0
        }
    }
    exit: Transition {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            from: 1.0
            properties: "opacity"
            to: 0.0
        }
    }
}
