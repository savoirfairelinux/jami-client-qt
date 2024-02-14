/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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

    title: JamiStrings.chooseAUsername
    closeButtonVisible: false

    signal joinClicked

    modal: true
    padding: 0

    visible: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    buttonsModel: [
        {
            text: JamiStrings.chooseAUsername,
            role: DialogButtonBox.NoRole,
            onClicked: function() {
                close();
            }
        },
        {
            text: JamiStrings.joinJami,
            role: DialogButtonBox.YesRole,
            objectName: "joinButton",
            onClicked: function() {
                root.joinClicked();
                WizardViewStepModel.nextStep();
                close();
            }
        }
    ]

    popupContent: Text {
                width: root.width - 2 * root.popupMargins
                font.pixelSize: JamiTheme.popuptextSize

                lineHeight: JamiTheme.wizardViewTextLineHeight
                wrapMode: Text.WordWrap

                color: JamiTheme.textColor
                text: JamiStrings.joinJamiNoPassword
        }
    }
