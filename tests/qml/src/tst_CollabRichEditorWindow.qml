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
import QtQuick.Controls
import QtTest

import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "../../../src/app/mainview/components"

TestWrapper {
    id: root

    Component {
        id: editorComponent

        CollabRichEditorWindow {}
    }

    TestCase {
        name: "CollabRichEditorWindow"
        when: windowShown

        property var editorWindow: null
        property string documentId: ""

        // One document for the whole case: two created in the same second by the
        // same device would get the same id, which the daemon refuses.
        function initTestCase() {
            documentId = CollaborativeAdapter.createDocument(CurrentConversation.id, "Fonts");
            verify(documentId.length > 0, "A document must be created in Alice's conversation");
        }

        function cleanupTestCase() {
            CollaborativeAdapter.removeDocument(CurrentAccount.id, CurrentConversation.id,
                                                documentId);
        }

        function init() {
            editorWindow = createTemporaryObject(editorComponent, root, {
                    "accountId": CurrentAccount.id,
                    "conversationId": CurrentConversation.id,
                    "documentId": documentId,
                    "documentName": "Fonts"
                });
            verify(editorWindow);
            editorWindow.show();
            // Every test starts from an empty document.
            findChild(editorWindow, "collabEditor").clear();
            compare(content().length, 0);
        }

        function content() {
            return JSON.parse(CollaborativeAdapter.contentDelta(CurrentAccount.id,
                                                                CurrentConversation.id,
                                                                documentId));
        }

        function cleanup() {
            // Closed before the document goes: an editor still showing it would
            // report the removal through dialogs this harness does not have.
            editorWindow.close();
        }

        // The editor's own font first, then every font the client ships, in
        // the order the binding gives them, each shown in itself.
        function test_fontMenuOffersEveryShippedFont() {
            const menu = findChild(editorWindow, "fontMenu");
            const binding = findChild(editorWindow, "richBinding");
            verify(menu);
            verify(binding);
            const fonts = binding.fonts;
            // The editor's own font and a separator come before the fonts.
            compare(menu.count, fonts.length + 2);
            for (var i = 0; i < fonts.length; ++i) {
                compare(menu.itemAt(i + 2).text, fonts[i].family);
                compare(menu.itemAt(i + 2).font.family, fonts[i].family);
            }
            // The one font asked for by name.
            verify(fonts.some(function (font) {
                return font.family === "Liberation Sans";
            }));
        }

        // A font this client does not ship is said to be one, rather than
        // passed off as the editor's own.
        function test_unshippedFontIsNotShownAsTheDefault() {
            const binding = findChild(editorWindow, "richBinding");
            const editor = findChild(editorWindow, "collabEditor");
            binding.applyRemoteDelta('[{"insert":"abc","attributes":{"font":"some-future-font"}}]');
            editor.select(0, 3);

            compare(findChild(editorWindow, "fontButton").label, "Unavailable font");
            verify(!findChild(editorWindow, "fontMenu").itemAt(0).checked);
        }

        // The selection takes the chosen font, the toolbar says which, and the
        // document every participant receives names it.
        function test_chosenFontReachesTheDocument() {
            const editor = findChild(editorWindow, "collabEditor");
            verify(editor);
            editor.insert(0, "Hello world");
            editor.select(0, 5);
            editorWindow.chooseFont("liberation-sans");

            compare(editorWindow.currentFontFamily, "Liberation Sans");
            const ops = content();
            compare(ops.length, 2);
            compare(ops[0].insert, "Hello");
            compare(ops[0].attributes.font, "liberation-sans");
            compare(ops[1].insert, " world");
            verify(ops[1].attributes === undefined || ops[1].attributes.font === undefined);
        }

        // Left to right: the paragraph style, the font, the base size and the
        // size, then the character styles, the paragraph's alignment and lists,
        // then links, pictures and the clearing of formatting.
        function test_formattingControlsComeInOrder() {
            const bar = findChild(editorWindow, "formatBar");
            verify(bar);
            var order = [];
            for (var i = 0; i < bar.children.length; ++i) {
                const control = bar.children[i];
                if (control.objectName !== "")
                    order.push(control.objectName);
                else if (control.glyph !== undefined)
                    order.push(control.glyph);
                else
                    order.push("|");
            }
            const expected = "headingButton fontButton baseSizeButton textSizeButton"
                    + " | B I U S | alignButton • 1. | 🔗 🖼 ⌫";
            compare(order.join(" "), expected);
        }

        // The size chosen for the selection is what every participant receives.
        function test_chosenSizeReachesTheDocument() {
            const editor = findChild(editorWindow, "collabEditor");
            editor.insert(0, "Hello world");
            editor.select(0, 5);
            editorWindow.chooseTextSize(18);

            compare(editorWindow.currentTextSize, 18);
            const ops = content();
            compare(ops[0].insert, "Hello");
            compare(ops[0].attributes.size, 18);
            verify(ops[1].attributes === undefined || ops[1].attributes.size === undefined);
        }

        // A paragraph style needs no selection: the line the caret is on takes
        // it, for every participant.
        function test_chosenHeadingReachesTheDocument() {
            const editor = findChild(editorWindow, "collabEditor");
            editor.insert(0, "Title");
            editor.cursorPosition = 2;
            editorWindow.chooseHeading(2);

            compare(editorWindow.currentHeading, 2);
            const ops = content();
            compare(ops[0].insert, "Title");
            compare(ops[0].attributes.header, 2);
        }
    }
}
