/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root
    property string dynamicText
    property bool isPassword: false
    property int itemWidth
    property string placeholderText
    property string staticText
    property alias titleField: title.text

    signal accepted
    signal editFinished

    Text {
        id: title
        Layout.fillWidth: true
        Layout.rightMargin: JamiTheme.preferredMarginSize / 2
        color: JamiTheme.textColor
        font.kerning: true
        font.pointSize: JamiTheme.settingsFontSize
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    ModalTextEdit {
        id: modalTextEdit
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: itemWidth
        isSettings: true
        placeholderText: root.placeholderText ? root.placeholderText : root.titleField
        staticText: root.staticText
        visible: !root.isPassword

        onAccepted: {
            root.dynamicText = dynamicText;
            editFinished();
        }
        onKeyPressed: {
            debounceTimer.restart();
        }

        Timer {
            id: debounceTimer
            interval: 500

            onTriggered: {
                root.dynamicText = modalTextEdit.dynamicText;
                editFinished();
            }
        }
    }
    PasswordTextEdit {
        id: passwordTextEdit
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: itemWidth
        isSettings: true
        placeholderText: root.placeholderText ? root.placeholderText : root.titleField
        staticText: root.staticText
        visible: root.isPassword

        onAccepted: {
            root.dynamicText = dynamicText;
            editFinished();
            echoMode = TextInput.Password;
        }
    }
}
