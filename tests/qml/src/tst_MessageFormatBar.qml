/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview"
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

ColumnLayout {
    id: root

    width: 600
    height: 200

    MessageFormatBar {
        id: uut

        width: root.width
        height: 60

        TestCase {
            name: "Message format bar document scan"
            when: windowShown

            // Looking for editable documents asks the daemon to read the whole
            // conversation history off disk. The model emits countChanged from
            // rowsInserted, so scanning straight from that handler runs the scan
            // inside endInsertRows(), once per message, on the GUI thread - and
            // history is paged in twenty messages at a time.
            function test_scanIsDeferredOffTheInsertPath() {
                wait(200);
                const convId = CurrentConversation.id;
                verify(convId !== "");
                // Wire MessagesAdapter's proxy to this conversation's interactions.
                LRCInstance.deselectConversation();
                LRCInstance.selectConversation(convId);
                wait(300);
                verify(CollaborativeAdapter.createDocument(convId, "scan probe") !== "");
                tryVerify(function () {
                    return CollaborativeAdapter.documents(convId).length > 0;
                }, 5000);

                // Arm the flag so that a scan, whenever it happens, flips it.
                uut.hasEditableDocuments = false;

                // countChanged is emitted from rowsInserted, i.e. from inside the
                // model's endInsertRows(). Scanning from there blocks the GUI thread
                // once per message, and history is paged in twenty at a time.
                MessageListStub.insertOlder(20);
                compare(uut.hasEditableDocuments, false);

                // The scan still has to happen, just not on the insert path.
                tryVerify(function () {
                    return uut.hasEditableDocuments;
                }, 5000);
            }
        }
    }
}
