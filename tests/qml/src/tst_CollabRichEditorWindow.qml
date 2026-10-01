import QtQuick
import QtTest
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import "../../../src/app/mainview/components"

Item {
    Component {
        id: editorWindowComponent
        CollabRichEditorWindow {}
    }

    TestCase {
        name: "CollabRichEditorWindow"
        when: windowShown

        property var editorWindow
        property var editor
        property var binding
        property var fontButton
        property var fontMenu
        property string accountId
        property string conversationId
        property string documentId

        function initTestCase() {
            accountId = CurrentAccount.id;
            conversationId = CurrentConversation.id;
            documentId = CollaborativeAdapter.createDocument(conversationId, "Font test");
            verify(documentId.length > 0);
        }

        function init() {
            editorWindow = createTemporaryObject(editorWindowComponent, null, {
                accountId: accountId,
                conversationId: conversationId,
                documentId: documentId,
                visible: true
            });
            verify(editorWindow);
            editor = findChild(editorWindow, "collabEditor");
            binding = findChild(editorWindow, "collabRichBinding");
            fontButton = findChild(editorWindow, "fontFamilyButton");
            fontMenu = findChild(editorWindow, "fontFamilyMenu");
            verify(editor && binding && fontButton && fontMenu);
            editor.remove(0, editor.length);
            binding.setFont("", 0, 0);
            editor.insert(0, "A report");
            editor.select(2, 8);
            editorWindow.refreshFormatState();
        }

        function cleanup() {
            if (editorWindow)
                editorWindow.close();
        }

        function cleanupTestCase() {
            CollaborativeAdapter.removeDocument(accountId, conversationId, documentId);
        }

        function content() {
            return JSON.parse(CollaborativeAdapter.contentDelta(accountId, conversationId, documentId));
        }

        function chooseFont(index) {
            mouseClick(fontButton);
            tryCompare(fontMenu, "opened", true);
            mouseClick(fontMenu.itemAt(index));
            tryCompare(fontMenu, "opened", false);
        }

        function test_pickerWritesCompatibleId() {
            compare(fontMenu.count, 5);
            chooseFont(2);
            compare(editorWindow.currentFont, "serif");
            compare(editorWindow.currentFontLabel, editorWindow.fontChoices[2].label);
            verify(fontMenu.itemAt(2).checked);
            const delta = JSON.parse(CollaborativeAdapter.contentDelta(editorWindow.accountId, editorWindow.conversationId, editorWindow.documentId));
            verify(delta.some(operation => operation.attributes && operation.attributes.font === "serif"));
            chooseFont(0);
            compare(editorWindow.currentFont, "");
            verify(fontMenu.itemAt(0).checked);
            verify(!fontMenu.itemAt(2).checked);
        }

        function test_sizePickerOnlyFormatsTheSelection() {
            const sizeButton = findChild(editorWindow, "textSizeButton");
            const sizeMenu = findChild(editorWindow, "textSizeMenu");
            verify(sizeButton && sizeMenu);
            const baseSize = editor.font.pointSize;
            mouseClick(sizeButton);
            tryCompare(sizeMenu, "opened", true);
            mouseClick(sizeMenu.itemAt(11));
            tryCompare(sizeMenu, "opened", false);
            compare(binding.selectionFormat(2, 8).size, 24);
            compare(binding.selectionFormat(0, 1).size, 0);
            compare(editor.font.pointSize, baseSize);
            const delta = JSON.parse(CollaborativeAdapter.contentDelta(accountId, conversationId, documentId));
            verify(delta.some(operation => operation.attributes && operation.attributes.size === 24));
        }

        function test_peerSizeUpdatesThePicker() {
            binding.applyRemoteDelta('[{"retain":2},{"retain":6,"attributes":{"size":24}}]');
            editorWindow.refreshFormatState();
            compare(editorWindow.currentFontSize, 24);
            const sizeMenu = findChild(editorWindow, "textSizeMenu");
            verify(sizeMenu);
            verify(sizeMenu.itemAt(11).checked);
        }

        function test_peerFontUpdatesThePicker() {
            binding.applyRemoteDelta('[{"retain":2},{"retain":6,"attributes":{"font":"cursive"}}]');
            editorWindow.refreshFormatState();
            compare(editorWindow.currentFont, "cursive");
            verify(fontMenu.itemAt(4).checked);
        }

        function test_fontChoiceAppliesToTyping() {
            editor.remove(0, editor.length);
            editor.cursorPosition = 0;
            chooseFont(3);
            compare(editorWindow.currentFont, "monospace");
            editor.forceActiveFocus();
            keyClick(Qt.Key_H);
            keyClick(Qt.Key_I);
            compare(binding.selectionFormat(0, 2).font, "monospace");
            const delta = JSON.parse(CollaborativeAdapter.contentDelta(accountId, conversationId, documentId));
            verify(delta.every(operation => operation.attributes && operation.attributes.font === "monospace"));
        }

        function test_pickerDisabledWhilePreviewing() {
            editorWindow.previewing = true;
            verify(!fontButton.enabled);
            verify(!findChild(editorWindow, "headingButton").enabled);
            verify(!findChild(editorWindow, "textSizeButton").enabled);
        }

        function test_onlyOneSizeSelector() {
            verify(findChild(editorWindow, "textSizeButton"));
            verify(findChild(editorWindow, "textSizeMenu"));
            verify(!findChild(editorWindow, "baseSizeButton"));
            verify(!findChild(editorWindow, "baseSizeMenu"));
        }

        function test_sizePickerCanRestoreTheBaseSize() {
            editorWindow.chooseTextSize(24);
            const sizeButton = findChild(editorWindow, "textSizeButton");
            const sizeMenu = findChild(editorWindow, "textSizeMenu");
            mouseClick(sizeButton);
            tryCompare(sizeMenu, "opened", true);
            mouseClick(sizeMenu.itemAt(0));
            tryCompare(sizeMenu, "opened", false);
            compare(binding.selectionFormat(2, 8).size, 0);
            verify(sizeMenu.itemAt(0).checked);
            verify(!sizeMenu.itemAt(11).checked);
            verify(content().every(operation => !operation.attributes
                                   || operation.attributes.size === undefined));
        }

        function test_headingPickerAppliesAndRemovesTheStyle() {
            const headingButton = findChild(editorWindow, "headingButton");
            const headingMenu = findChild(editorWindow, "headingMenu");
            verify(headingButton && headingMenu);
            editor.cursorPosition = 4;
            for (const level of [2, 0]) {
                mouseClick(headingButton);
                tryCompare(headingMenu, "opened", true);
                mouseClick(headingMenu.itemAt(level));
                tryCompare(headingMenu, "opened", false);
                compare(editorWindow.currentHeading, level);
                verify(headingMenu.itemAt(level).checked);
                compare(headingButton.label, editorWindow.headingLabel(level));
                compare(content()[0].attributes ? content()[0].attributes.header || 0 : 0, level);
            }
        }

        function test_pendingFormattingEndsOnNavigation_data() {
            return [
                {
                    tag: "caret",
                    selectText: false
                },
                {
                    tag: "selection",
                    selectText: true
                }
            ];
        }

        function test_pendingFormattingEndsOnNavigation(data) {
            editor.remove(0, editor.length);
            editor.insert(0, "A ");
            editor.cursorPosition = 2;
            binding.setFont("monospace", 2, 2);
            binding.setFontSize(24, 2, 2);
            if (data.selectText)
                editor.select(0, 2);
            else
                editor.cursorPosition = 1;
            editor.cursorPosition = 2;
            compare(binding.selectionFormat(2, 2).font, "");
            compare(binding.selectionFormat(2, 2).size, 0);
        }

        function test_remoteEditPreservesPendingFormatting() {
            editor.remove(0, editor.length);
            editor.insert(0, "A ");
            editor.cursorPosition = 2;
            binding.setFont("monospace", 2, 2);
            binding.setFontSize(24, 2, 2);
            binding.applyRemoteDelta('[{"insert":"Hello "}]');
            compare(editor.cursorPosition, 8);
            compare(binding.selectionFormat(8, 8).font, "monospace");
            compare(binding.selectionFormat(8, 8).size, 24);
        }

        function test_clearPendingFormatting() {
            editor.remove(0, editor.length);
            binding.setFont("monospace", 0, 0);
            binding.setFontSize(24, 0, 0);
            binding.clearFormat(0, 0);
            editor.forceActiveFocus();
            keyClick(Qt.Key_H);
            compare(binding.selectionFormat(0, 1).font, "");
            compare(binding.selectionFormat(0, 1).size, 0);
        }

        function test_toolbarUsesOneRowWhenItFits_data() {
            return [
                {tag: "default", width: 840},
                {tag: "wide", width: 1600}
            ];
        }

        function test_toolbarUsesOneRowWhenItFits(data) {
            editorWindow.documentName = "Report";
            editorWindow.width = data.width;
            const toolbar = findChild(editorWindow, "formattingToolbar");
            tryVerify(() => toolbar.width > 0 && toolbar.height > 0);
            tryVerify(() => toolbar.children.every(child => !child.visible || child.width === 0 || child.y === 0));
        }

        function test_toolbarFitsMinimumWidth() {
            editorWindow.width = editorWindow.minimumWidth;
            const toolbar = findChild(editorWindow, "formattingToolbar");
            tryVerify(() => toolbar.width > 0 && toolbar.height > 0);
            for (const child of toolbar.children) {
                if (!child.visible || child.width === 0)
                    continue;
                verify(child.x >= 0 && child.x + child.width <= toolbar.width + 1);
                verify(child.y >= 0 && child.y + child.height <= toolbar.height + 1);
            }
        }

        function test_fontMenuOffersEveryFamily() {
            compare(fontMenu.count, editorWindow.fontChoices.length);
            for (var index = 0; index < editorWindow.fontChoices.length; ++index) {
                compare(fontMenu.itemAt(index).text, editorWindow.fontChoices[index].label);
            }
        }

        function test_unknownFontIsNotShownAsTheDefault() {
            binding.applyRemoteDelta('[{"retain":8,"attributes":{"font":"some-future-font"}}]');
            editorWindow.refreshFormatState();
            compare(fontButton.label, "some-future-font");
            for (var index = 0; index < fontMenu.count; ++index)
                verify(!fontMenu.itemAt(index).checked);
        }

        function test_chosenFontReachesTheDocument() {
            editorWindow.chooseFont("sans-serif");
            compare(editorWindow.currentFont, "sans-serif");
            const ops = content();
            compare(ops[0].insert, "A ");
            verify(ops[0].attributes === undefined || ops[0].attributes.font === undefined);
            compare(ops[1].insert, "report");
            compare(ops[1].attributes.font, "sans-serif");
        }

        function test_formattingControlsComeInOrder() {
            const bar = findChild(editorWindow, "formattingToolbar");
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
            const expected = "headingButton fontFamilyButton textSizeButton"
                    + " | B I U S | alignButton • 1. | 🔗 🖼 ⌫";
            compare(order.join(" "), expected);
        }

        function test_chosenSizeReachesTheDocument() {
            editorWindow.chooseTextSize(18);

            compare(editorWindow.currentTextSize, 18);
            const ops = content();
            compare(ops[0].insert, "A ");
            verify(ops[0].attributes === undefined || ops[0].attributes.size === undefined);
            compare(ops[1].insert, "report");
            compare(ops[1].attributes.size, 18);
        }

        function test_chosenHeadingReachesTheDocument() {
            editor.cursorPosition = 2;
            editorWindow.chooseHeading(2);

            compare(editorWindow.currentHeading, 2);
            const ops = content();
            compare(ops[0].insert, "A report");
            compare(ops[0].attributes.header, 2);
        }
    }
}
