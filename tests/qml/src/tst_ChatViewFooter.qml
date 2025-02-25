/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1

import "../../../src/app/mainview/components"

ColumnLayout {
    id: root

    spacing: 0

    width: 300
    height: uut.implicitHeight

    ChatViewFooter {
        id: uut

        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: JamiTheme.chatViewMaximumWidth

        TestCase {
            name: "MessageWebViewFooter Send Message Button Visibility Test"
            when: windowShown

            function test_send_message_button_visibility() {
                var filesToSendContainer = findChild(uut, "dataTransferSendContainer")
                var sendMessageButton = findChild(uut, "sendMessageButton")
                var messageBarTextArea = findChild(uut, "messageBarTextArea")

                compare(sendMessageButton.enabled, false)

                // Text in messageBarTextArea will cause sendMessageButton to show
                messageBarTextArea.insertText("test")
                compare(sendMessageButton.enabled, true)

                // Text cleared in messageBarTextArea will cause sendMessageButton to hide
                messageBarTextArea.clearText()
                compare(sendMessageButton.enabled, false)

                // Both are cleared
                messageBarTextArea.clearText()
                compare(sendMessageButton.enabled, false)
            }
        }
    }
}
