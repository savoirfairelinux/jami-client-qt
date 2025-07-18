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
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview"
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

TestWrapper {
    ListSelectionView {
        id: viewNode
        objectName: "ConversationView"
        managed: false

        leftPaneItem: Rectangle {}

        rightPaneItem: ChatView {
            id: uut

            inCallView: false

            TestCase {
                name: "Check basic visibility for header buttons"
                function test_checkBasicVisibility() {
                    var chatviewHeader = findChild(uut, "chatViewHeader")
                    var detailsButton = findChild(chatviewHeader, "detailsButton")
                    compare(detailsButton.visible, true)

                    var chatViewFooter = findChild(uut, "chatViewFooter")
                    CurrentConversation.isTemporary = true
                    compare(chatViewFooter.visible, true)
                    CurrentConversation.isTemporary = false
                    CurrentConversation.isRequest = true
                    compare(chatViewFooter.visible, false)
                    CurrentConversation.isRequest = false
                    CurrentConversation.needsSyncing = true
                    compare(chatViewFooter.visible, false)
                }
            }
        }
    }
}
