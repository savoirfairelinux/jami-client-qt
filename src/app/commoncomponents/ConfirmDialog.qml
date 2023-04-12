/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
    property string confirmLabel: ""
    property string textLabel: ""

    height: Math.min(appWindow.height - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogHeight)
    width: Math.min(appWindow.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogWidth)

    signal accepted

    popupContent: ColumnLayout {
        id: column
        Label {
            id: labelAction
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: column.width - JamiTheme.preferredMarginSize * 2
            color: JamiTheme.textColor
            font.kerning: true
            font.pointSize: JamiTheme.textFontSize
            horizontalAlignment: Text.AlignHCenter
            text: root.textLabel
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            spacing: 16

            MaterialButton {
                id: primaryBtn
                Layout.alignment: Qt.AlignHCenter
                autoAccelerator: true
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                color: JamiTheme.buttonTintedRed
                hoveredColor: JamiTheme.buttonTintedRedHovered
                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                pressedColor: JamiTheme.buttonTintedRedPressed
                secondary: true
                text: root.confirmLabel

                onClicked: {
                    close();
                    accepted();
                }
            }
            MaterialButton {
                id: btnCancel
                Layout.alignment: Qt.AlignHCenter
                autoAccelerator: true
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true
                text: JamiStrings.optionCancel

                onClicked: close()
            }
        }
    }
}
