/*
* Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
    width: 640
    height: 480

    AccountComboBox {
        id: uut

        function loadMockData() {
            return JSON.parse('[\
                {"Alias":"Foo","ID":"a2d724d18a943e6c","NotificationCount":0,"Status":5,"Type":1,"Username":"foo"}, \
                {"Alias":"Bar","ID":"8a22b7d0176327db","NotificationCount":0,"Status":5,"Type":1,"Username":"bar"}, \
                {"Alias":"TEST JAMI","ID":"3b7d2b9e2af83a47","NotificationCount":0,"Status":5,"Type":2,"Username":"696"}, \
                {"Alias":"Whatever","ID":"131ad59045a9a146","NotificationCount":0,"Status":5,"Type":1,"Username":"whatever"}]');
        }

        TestCase {
            name: "Check model size"
            function test_checkModelSize() {
                var accountComboBox = findChild(uut, "accountComboBox");
                accountComboBox.model = uut.loadMockData();
                compare(accountComboBox.model.length, 4);
            }
        }

        TestCase {
            name: "AllDocuments"
            when: windowShown

            property string firstConversation
            property string secondConversation
            property string firstDocument
            property string secondDocument

            function cleanup() {
                if (firstConversation)
                    LRCInstance.selectConversation(firstConversation, CurrentAccount.id);
                if (firstDocument)
                    CollaborativeAdapter.removeDocument(CurrentAccount.id, firstConversation, firstDocument);
                if (secondConversation)
                    MessagesAdapter.removeConversation(secondConversation);
            }

            AllDocumentDialog {
                id: documentsDialog
                parent: uut
            }

            function test_listsSearchesAndOpensConversation() {
                firstConversation = CurrentConversation.id;
                secondConversation = ConversationsAdapter.createSwarm("Other documents", "", "", []);
                verify(secondConversation.length > 0 && secondConversation !== firstConversation);

                firstDocument = CollaborativeAdapter.createDocument(firstConversation, "Notes");
                secondDocument = CollaborativeAdapter.createDocument(secondConversation, "Notes");
                verify(firstDocument.length > 0 && secondDocument.length > 0);

                tryVerify(function () {
                    return ConversationsAdapter.getConvInfoMap(secondConversation).title === "Other documents";
                });
                documentsDialog.open();
                tryCompare(documentsDialog, "loading", false);
                const list = findChild(documentsDialog.contentItem, "documentsList");
                const documents = list.model;
                const second = documents.find(doc => doc.documentId === secondDocument);
                compare(documents.find(doc => doc.documentId === firstDocument).conversationId, firstConversation);
                compare(second.conversationId, secondConversation);
                compare(second.conversationTitle, "Other documents");
                for (let i = 1; i < documents.length; ++i)
                    verify(documents[i - 1].timestamp >= documents[i].timestamp);

                findChild(documentsDialog.contentItem, "documentsSearch").text = "other DOCUMENTS ";
                compare(list.count, 1);
                compare(list.model[0].documentId, secondDocument);

                tryVerify(() => list.itemAtIndex(0) !== null);
                const button = findChild(list.itemAtIndex(0), "documentConversationButton");
                verify(waitForRendering(button));
                mouseClick(button);
                tryCompare(documentsDialog, "visible", false);
                tryCompare(CurrentConversation, "id", secondConversation);
            }
        }
    }
}
