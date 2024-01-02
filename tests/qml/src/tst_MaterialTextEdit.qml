/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
 * Author: Franck Laurent <franck.laurent@savoirfairelinux.com>
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

import QtTest

import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../../src/app/"
import "../../../src/app/commoncomponents"

ColumnLayout {
    id: root

    spacing: 0

    width: 300
    height: 300

    MaterialTextField {
        id: textField

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: root.width
        Layout.maximumWidth: JamiTheme.chatViewMaximumWidth
        Layout.preferredHeight: root.height

        maxCharacters: 20

        TestCase {
            name: "Check maxCharacters for MaterialTextField"
            when: windowShown

            function test_maxCharacters_material_text_field() {
                compare(textField.maximumLength, 20)
                textField.text = "Small title"
                compare(textField.text, "Small title")
                textField.text = "Long title more than 20 characted"
                compare(textField.text, "Long title more than")
            }
        }
    }
}