/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
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
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                color: JamiTheme.textColor
                font.pixelSize: JamiTheme.popuptextSize
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                text: JamiStrings.stopSharingPopupBody
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.margins: JamiTheme.popupButtonsMargin

                MaterialButton {
                    color: JamiTheme.buttonTintedBlue
                    hoveredColor: JamiTheme.buttonTintedBlueHovered
                    preferredWidth: text.contentWidth
                    pressedColor: JamiTheme.buttonTintedBluePressed
                    text: JamiStrings.stopConvSharing.arg(PositionManager.getmapTitle(attachedAccountId, CurrentConversation.id))
                    textLeftPadding: JamiTheme.buttontextPadding
                    textRightPadding: JamiTheme.buttontextPadding

                    onClicked: {
                        PositionManager.stopSharingPosition(attachedAccountId, CurrentConversation.id);
                        root.close();
                    }
                }
                MaterialButton {
                    color: JamiTheme.buttonTintedRed
                    hoveredColor: JamiTheme.buttonTintedRedHovered
                    preferredWidth: text.contentWidth
                    pressedColor: JamiTheme.buttonTintedRedPressed
                    text: JamiStrings.stopAllSharings
                    textLeftPadding: JamiTheme.buttontextPadding
                    textRightPadding: JamiTheme.buttontextPadding

                    onClicked: {
                        PositionManager.stopSharingPosition();
                        root.close();
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
