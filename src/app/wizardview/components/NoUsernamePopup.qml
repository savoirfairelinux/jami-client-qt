/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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

BaseModalDialog {
    id: root
    width: 350
    height: 240

    signal joinClicked

    popupContent: Item {

        ColumnLayout {

            anchors.fill: parent
            anchors.bottomMargin: 30

            PushButton {
                id: btnClose
                Layout.alignment: Qt.AlignRight

                width: 30
                height: 30
                imageContainerWidth: 30
                imageContainerHeight : 30
                Layout.rightMargin: 8

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
                font.pixelSize: 15
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                color: JamiTheme.textColor
                text: JamiStrings.joinJamiNoPassword
            }

            RowLayout{

                Layout.alignment: Qt.AlignCenter

                MaterialButton {
                    preferredWidth: 96
                    Layout.alignment: Qt.AlignCenter
                    secondary: true
                    color: JamiTheme.secAndTertiTextColor
                    secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
                    text: JamiStrings.joinJami
                    fontPixelSize: JamiTheme.wizardViewNoUsernamePopupFontPixelSize
                    onClicked: {
                        root.joinClicked()
                        WizardViewStepModel.nextStep()
                        root.close()
                    }
                }

                MaterialButton {
                    preferredWidth: 170
                    Layout.alignment: Qt.AlignCenter
                    Layout.leftMargin: 20
                    primary:true
                    text:  JamiStrings.chooseAUsername
                    fontPixelSize: JamiTheme.wizardViewNoUsernamePopupFontPixelSize
                    onClicked: root.close()
                }
            }
        }
    }
}
