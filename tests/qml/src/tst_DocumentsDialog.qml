/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtTest
import net.jami.Constants 1.1
import "../../../src/app/mainview/components"

TestWrapper {
    width: 900
    height: 800

    QtObject {
        id: fakeService

        property var allDocuments: []
        property bool loadingAllDocuments: false
        property int refreshes: 0

        signal documentRenamed(string accountId, string convId, string documentId, string name)
        signal documentRemoved(string accountId, string convId, string documentId, bool everywhere)

        function refreshAllDocuments() {
            refreshes++;
        }
    }

    DocumentsDialog {
        id: uut
        service: fakeService

        SignalSpy { id: editSpy; target: uut; signalName: "editRequested" }
        SignalSpy { id: newSpy; target: uut; signalName: "newDocumentRequested" }
    }

    TestCase {
        name: "DocumentsDialog"
        when: windowShown

        readonly property var plan: ({"documentId": "plan", "name": "Plan", "convId": "alice-conv",
                                       "conversationTitle": "Alice", "isCoreDialog": true,
                                       "author": "alice", "authorName": "Alice", "authorIsSelf": false,
                                       "timestamp": 1790000000})
        readonly property var menu: ({"documentId": "menu", "name": "", "convId": "team-conv",
                                       "conversationTitle": "Team", "isCoreDialog": false,
                                       "author": "me", "authorName": "Me", "authorIsSelf": true,
                                       "timestamp": 1780000000})

        function init() {
            fakeService.allDocuments = [plan, menu];
            fakeService.loadingAllDocuments = false;
            editSpy.clear();
            newSpy.clear();
            uut.open();
            tryCompare(uut, "opened", true);
        }

        function cleanup() {
            uut.close();
            tryCompare(uut, "visible", false);
        }

        // findChild() does not walk into the dialog content nor the ListView contentItem.
        function find(item, name) {
            if (!item)
                return null;
            if (item.objectName === name)
                return item;
            const children = Array.from(item.children || []);
            if (item.contentItem && children.indexOf(item.contentItem) < 0)
                children.push(item.contentItem);
            for (const child of children) {
                const found = find(child, name);
                if (found)
                    return found;
            }
            return null;
        }

        function test_opening_reads_the_documents_again() {
            const before = fakeService.refreshes;
            uut.close();
            tryCompare(uut, "visible", false);
            const dialog = createTemporaryObject(Qt.createComponent("../../../src/app/mainview/components/DocumentsDialog.qml"),
                                                 parent, {"service": fakeService});
            verify(dialog !== null);
            compare(fakeService.refreshes, before + 1);
        }

        function test_each_document_tells_where_it_comes_from() {
            tryVerify(() => find(uut.contentItem, "document-plan") !== null);
            const fromAlice = find(uut.contentItem, "document-plan");
            compare(find(fromAlice, "documentConversation").text, "Alice");
            verify(find(fromAlice, "documentAuthor").text.startsWith(JamiStrings.documentCreatedBy.arg("Alice") + " · "));

            const fromTeam = find(uut.contentItem, "document-menu");
            compare(find(fromTeam, "documentConversation").text, "Team");
            verify(find(fromTeam, "documentAuthor").text.startsWith(JamiStrings.documentCreatedByYou + " · "));
            // A document without a name is still told apart.
            verify(fromTeam.Accessible.name.startsWith(JamiStrings.untitledDocument));
        }

        function test_a_document_opens_in_the_editor_from_its_button_or_its_row() {
            tryVerify(() => find(uut.contentItem, "document-plan") !== null);
            mouseClick(find(find(uut.contentItem, "document-plan"), "editDocument"));
            compare(editSpy.count, 1);
            compare(editSpy.signalArguments[0][0].documentId, "plan");
            compare(editSpy.signalArguments[0][0].convId, "alice-conv");
            tryCompare(uut, "visible", false);

            uut.open();
            tryCompare(uut, "opened", true);
            tryVerify(() => find(uut.contentItem, "document-menu") !== null);
            mouseClick(find(uut.contentItem, "document-menu"));
            compare(editSpy.count, 2);
            compare(editSpy.signalArguments[1][0].documentId, "menu");
        }

        function test_a_new_document_can_be_started() {
            mouseClick(find(uut.contentItem, "newDocumentButton"));
            compare(newSpy.count, 1);
            tryCompare(uut, "visible", false);
        }

        function test_nothing_to_list_says_so_once_read() {
            fakeService.allDocuments = [];
            fakeService.loadingAllDocuments = true;
            const noDocuments = find(uut.contentItem, "noDocuments");
            const loading = find(uut.contentItem, "documentsLoading");
            verify(loading.visible);
            verify(!noDocuments.visible);

            fakeService.loadingAllDocuments = false;
            verify(!loading.visible);
            verify(noDocuments.visible);
        }

        function test_a_renamed_or_removed_document_is_read_again() {
            const before = fakeService.refreshes;
            fakeService.documentRenamed("account", "team-conv", "menu", "Menu");
            compare(fakeService.refreshes, before + 1);
            fakeService.documentRemoved("account", "team-conv", "menu", true);
            compare(fakeService.refreshes, before + 2);
        }
    }
}
