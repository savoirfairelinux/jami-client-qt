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

    signal accepted

    property string confirmLabel: ""
    property string textLabel: ""

    closeButtonVisible: false
    button1.text: confirmLabel
    button1.contentColorProvider: JamiTheme.redButtonColor
    button1.onClicked: {
        close();
        accepted();
    }
    button2.text: JamiStrings.optionCancel
    button2.onClicked: close()

    button1Role: DialogButtonBox.AcceptRole
    button2Role: DialogButtonBox.RejectRole

    popupContent: ColumnLayout {
        id: column

        Label {
            id: labelAction

            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width - JamiTheme.preferredMarginSize * 4

            color: JamiTheme.textColor
            text: root.textLabel

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
    }
}
