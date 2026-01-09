/*
 * Copyright (C) 2022-2025 Savoir-faire Linux Inc.
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
    signal rejected

    property string confirmLabel: ""
    property string rejectLabel
    property string textLabel: ""
    property int textHAlign: Text.AlignHCenter
    property real textMaxWidth: width - JamiTheme.preferredMarginSize * 4

    autoClose: false
    closeButtonVisible: false
    button1.text: confirmLabel
    button1.contentColorProvider: JamiTheme.redButtonColor
    button1.onClicked: {
        close();
        accepted();
    }
    button2.text: rejectLabel ? rejectLabel : JamiStrings.optionCancel
    button2.onClicked: {
        close();
        rejected();
    }

    button1Role: DialogButtonBox.AcceptRole
    button2Role: DialogButtonBox.RejectRole

    dialogContent: ColumnLayout {
        id: column

        Label {
            id: labelAction

            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: textMaxWidth

            color: JamiTheme.textColor
            text: root.textLabel

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            horizontalAlignment: textHAlign
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
    }
}
