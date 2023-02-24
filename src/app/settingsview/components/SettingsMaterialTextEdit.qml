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

    property alias titleField: title.text
    property string staticText
    property string placeholderText
    property string dynamicText

    property bool isPassword: false

    property int itemWidth

    signal editFinished

    Text {
        id: title

        Layout.fillWidth: true
        Layout.rightMargin: JamiTheme.preferredMarginSize / 2

        font.pointSize: JamiTheme.settingsFontSize
        font.kerning: true

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter

        color: JamiTheme.textColor
        elide: Text.ElideRight
    }

    ModalTextEdit {
        id: modalTextEdit

        visible: !root.isPassword

        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: itemWidth
        Layout.maximumHeight: 40
        staticText: root.staticText
        placeholderText: root.placeholderText
        initialPlaceHolder: root.titleField

        onAccepted: {
            root.dynamicText = dynamicText
            editFinished()
        }

    }

    PasswordTextEdit {
        id: passwordTextEdit

        visible: root.isPassword

        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: itemWidth
        Layout.maximumHeight: 40
        staticText: root.staticText
        placeholderText: root.placeholderText
        initialPlaceHolder: root.titleField

        onAccepted: {
            root.dynamicText = dynamicText
            editFinished()
        }

    }
}
