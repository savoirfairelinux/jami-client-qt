/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

BaseModalDialog {
    id: root

    signal accepted

    width: Math.min(appWindow.width - 2 * JamiTheme.preferredMarginSize,
                    JamiTheme.preferredDialogWidth)
    height: Math.min(appWindow.height - 2 * JamiTheme.preferredMarginSize,
                     JamiTheme.preferredDialogHeight)

    property string confirmLabel: ""
    property string textLabel: ""

    popupContent: ColumnLayout {
        id: column

        Label {
            id: labelAction

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: column.width -
                                   JamiTheme.preferredMarginSize * 2

            color: JamiTheme.textColor
            text: root.textLabel

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }

        RowLayout {
            spacing: 16
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            MaterialButton {
                id: primaryBtn

                Layout.alignment: Qt.AlignHCenter
                text: root.confirmLabel

                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                preferredHeight: JamiTheme.preferredFieldHeight

                color: JamiTheme.buttonTintedRed
                hoveredColor: JamiTheme.buttonTintedRedHovered
                pressedColor: JamiTheme.buttonTintedRedPressed
                secondary: true
                autoAccelerator: true

                onClicked: {
                    close()
                    accepted()
                }
            }

            MaterialButton {
                id: btnCancel

                Layout.alignment: Qt.AlignHCenter

                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                preferredHeight: JamiTheme.preferredFieldHeight

                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true
                autoAccelerator: true

                text: JamiStrings.optionCancel

                onClicked: close()
            }
        }
    }
}
