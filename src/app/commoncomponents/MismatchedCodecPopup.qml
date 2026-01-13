/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import "../mainview/components"

BaseModalDialog {
    id: mismatchedCodecPopup

    button1Role: DialogButtonBox.AcceptRole

    popupContent: ColumnLayout {
        Label {
            id: titleText

            text: JamiStrings.mismatchedCodecTitle

            Layout.leftMargin: popupMargins
            Layout.rightMargin: popupMargins
            Layout.bottomMargin: 20
            Layout.topMargin: closeButtonVisible ? 0 : 30
            Layout.alignment: Qt.AlignLeft

            font.pointSize: JamiTheme.menuFontSize + 2
            color: JamiTheme.textColor
            font.bold: true

            visible: text.length > 0
        }

        Label {
            id: descriptionText

            text: JamiStrings.mismatchedCodecDescription

            Layout.leftMargin: popupMargins
            Layout.rightMargin: popupMargins
            Layout.bottomMargin: 15
            Layout.fillWidth: true
            Layout.maximumWidth: maximumPopupWidth - (2 * popupMargins)
            Layout.alignment: Qt.AlignCenter

            font.pointSize: JamiTheme.textFontSize + 2
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            textFormat: Text.RichText

            visible: text.length > 0
        }
    }
}
