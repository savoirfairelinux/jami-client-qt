/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

    property alias titleField: title.text
    property string staticText
    property string placeholderText
    property string dynamicText

    property bool isPassword: false

    property int itemWidth

    signal editFinished
    signal accepted

    Text {
        id: title

        Layout.fillWidth: true
        Layout.rightMargin: JamiTheme.preferredMarginSize / 2
        font.pointSize: JamiTheme.settingsFontSize
        font.kerning: true
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter

        color: JamiTheme.textColor
    }

    ModalTextEdit {
        id: modalTextEdit

        TextMetrics {
            id: modalTextEditTextSize
            text: root.staticText
            elide: Text.ElideRight
            elideWidth: itemWidth - 40
            font.pixelSize: JamiTheme.materialLineEditPixelSize
        }

        visible: !root.isPassword
        focus: visible
        isSettings: true

        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: itemWidth
        staticText: root.staticText
        placeholderText: root.placeholderText ? root.placeholderText : root.titleField
        elidedText: modalTextEditTextSize.elidedText

        onAccepted: {
            root.dynamicText = dynamicText;
            root.editFinished();
        }

        editMode: false

        onActiveFocusChanged: {
            if (!activeFocus) {
                root.dynamicText = dynamicText;
                root.editFinished();
                modalTextEdit.editMode = false;
            } else {
                modalTextEdit.editMode = true;
            }
        }
    }

    PasswordTextEdit {
        id: passwordTextEdit

        visible: root.isPassword
        focus: visible
        isSettings: true

        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: itemWidth
        staticText: root.staticText
        placeholderText: root.placeholderText ? root.placeholderText : root.titleField

        onAccepted: {
            root.dynamicText = dynamicText;
            root.editFinished();
            echoMode = TextInput.Password;
        }

        onActiveFocusChanged: {
            if (!activeFocus) {
                root.dynamicText = dynamicText;
                root.editFinished();
                echoMode = TextInput.Password;
            }
        }
    }
}
