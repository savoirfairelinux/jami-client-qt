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
    id: wrapper

    width: 640
    height: 480

    AccountComboBox {
        id: uut
        appContext: wrapper.appContext

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
                documentsDialog.close();
                if (firstConversation)
                    LRCInstance.selectConversation(firstConversation, CurrentAccount.id);
                if (firstDocument)
                    CollaborativeAdapter.removeDocument(CurrentAccount.id, firstConversation, firstDocument);
                if (secondConversation)
                    MessagesAdapter.removeConversation(secondConversation);
                firstConversation = secondConversation = firstDocument = secondDocument = "";
            }

            AllDocumentDialog {
                id: documentsDialog
                parent: wrapper
            }

            function test_listsAndSearchesDocuments() {
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
                const list = findChild(documentsDialog.contentItem, "documentsGrid");
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
            }

            function previewOf(documentId) {
                const list = findChild(documentsDialog.contentItem, "documentsGrid");
                const index = list.model.findIndex(doc => doc.documentId === documentId);
                const tile = list.itemAtIndex(index);
                return tile ? findChild(tile, "documentPreview") : null;
            }

            function test_previewsDocumentText() {
                firstConversation = CurrentConversation.id;
                secondConversation = ConversationsAdapter.createSwarm("Preview documents", "", "", []);
                verify(secondConversation.length > 0);
                secondDocument = CollaborativeAdapter.createDocument(secondConversation, "Preview");
                verify(secondDocument.length > 0);
                CollaborativeAdapter.openDocument(CurrentAccount.id, secondConversation, secondDocument);
                CollaborativeAdapter.edit(CurrentAccount.id, secondConversation, secondDocument, 0, 0, "Seen from afar");

                // While open, the preview comes from the live replica.
                documentsDialog.open();
                tryCompare(documentsDialog, "loading", false);
                tryVerify(() => previewOf(secondDocument)?.visible === true);
                compare(previewOf(secondDocument).children[0].text, "Seen from afar");
                documentsDialog.close();
                tryCompare(documentsDialog, "visible", false);

                // Once closed, it is rebuilt from the checkpoint written on close.
                CollaborativeAdapter.closeDocument(CurrentAccount.id, secondConversation, secondDocument);
                documentsDialog.open();
                tryCompare(documentsDialog, "loading", false);
                tryVerify(() => previewOf(secondDocument)?.visible === true);
                compare(previewOf(secondDocument).children[0].text, "Seen from afar");
            }
        }

        TestCase {
            name: "MediaLibrary"
            when: windowShown

            property string originalConversation
            property string firstConversation
            property string secondConversation

            function cleanup() {
                wrapper.viewManager.getView("MediaLibraryDialog")?.close();
                LRCInstance.selectConversation(originalConversation, CurrentAccount.id);
                MessagesAdapter.removeConversation(firstConversation);
                MessagesAdapter.removeConversation(secondConversation);
            }

            function sendFixture(conversationId, fileName) {
                LRCInstance.selectConversation(conversationId, CurrentAccount.id);
                tryCompare(CurrentConversation, "id", conversationId);
                const count = MessagesAdapter.messageListModel.count;
                MessagesAdapter.sendFile(UtilsAdapter.getAbsPath(Qt.resolvedUrl(fileName).toString()));
                tryVerify(() => MessagesAdapter.messageListModel.count > count);
            }

            function test_listsSearchesAndOpensConversation() {
                originalConversation = CurrentConversation.id;
                firstConversation = ConversationsAdapter.createSwarm("First attachments", "", "", []);
                secondConversation = ConversationsAdapter.createFeed("Second attachments", "", "", []);
                sendFixture(firstConversation, "../../../resources/images/default_plugin_background.jpg");
                sendFixture(secondConversation, "TestWrapper.qml");

                findChild(uut, "multimediaButton").click();
                findChild(uut, "mediaLibraryMenuItem").click();
                tryVerify(() => wrapper.viewManager.getView("MediaLibraryDialog") !== null);
                const dialog = wrapper.viewManager.getView("MediaLibraryDialog");
                tryCompare(dialog, "loading", false);
                const list = findChild(dialog, "mediaLibraryGrid");
                compare(list.count, 2);

                findChild(dialog, "mediaLibrarySearch").text = "second";
                tryCompare(list, "count", 1);
                compare(list.model[0].name, "TestWrapper.qml");

                tryVerify(() => list.itemAtIndex(0) !== null);
                const tile = list.itemAtIndex(0);
                verify(waitForRendering(tile));
                const menu = findChild(dialog, "mediaLibraryFileMenu");
                mouseClick(tile, tile.width / 2, tile.height / 2, Qt.RightButton);
                tryCompare(menu, "opened", true);
                mouseClick(list, list.width - 4, list.height - 4);
                tryCompare(menu, "visible", false);
                compare(list.currentIndex, -1);

                const source = UtilsAdapter.getAbsPath(Qt.resolvedUrl("TestWrapper.qml").toString());
                const file = list.model[0];
                verify(MessagesAdapter.mediaLibraryLocalFile(secondConversation, file.fileId) !== "");
                mouseClick(tile, tile.width / 2, tile.height / 2, Qt.RightButton);
                tryCompare(menu, "opened", true);
                findChild(menu, "mediaLibraryRemoveFile").triggered();
                const removeDialog = findChild(dialog, "mediaLibraryRemoveDialog");
                tryCompare(removeDialog, "opened", true);
                removeDialog.button1.clicked();
                compare(MessagesAdapter.mediaLibraryLocalFile(secondConversation, file.fileId), "");
                verify(UtilsAdapter.fileExists(source));

                list.currentIndex = 0;
                list.forceActiveFocus();
                keyClick(Qt.Key_F10, Qt.ShiftModifier);
                tryCompare(menu, "opened", true);
                verify(!findChild(menu, "mediaLibraryRemoveFile").visible);
                findChild(menu, "mediaLibraryGoToConversation").triggered();
                tryCompare(CurrentConversation, "id", secondConversation);
            }
        }
    }
}
