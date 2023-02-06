/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

import QtTest

import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../../src/app/mainview/components"

ColumnLayout {
    id: root

    spacing: 0

    width: 300
    height: 300

    NewSwarmPage {
        id: uut

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: root.width
        Layout.maximumWidth: JamiTheme.chatViewMaximumWidth
        Layout.preferredHeight: root.height

        TestCase {
            name: "Check Focus for NewSwarmPage"
            when: windowShown

            function test_focus_new_swarm_page() {
                // Add animated image file
                var title = findChild(uut, "titleLineEdit")
                var description = findChild(uut, "descriptionLineEdit")

                // Fill Title & Description
                title.text = "Title"
                description.text = "description"
                compare(title.text, "Title")
                compare(description.text, "description")

                // Hide & Show window
                uut.visible = false
                uut.visible = true

                compare(title.focus, false)
                compare(title.text, "")
                compare(description.focus, false)
                compare(description.text, "")

            }
        }
    }
}
