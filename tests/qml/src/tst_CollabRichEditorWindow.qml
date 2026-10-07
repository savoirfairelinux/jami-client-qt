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
            const delta = JSON.parse(CollaborativeAdapter.contentDelta(editorWindow.accountId,
                                                                       editorWindow.conversationId,
                                                                       editorWindow.documentId));
            verify(delta.some(operation => operation.attributes && operation.attributes.font
                              === "serif"));
            chooseFont(0);
            compare(editorWindow.currentFont, "");
            verify(fontMenu.itemAt(0).checked);
            verify(!fontMenu.itemAt(2).checked);
        }

        function test_sizePickerOnlyFormatsTheSelection() {
            const sizeButton = findChild(editorWindow, "fontSizeButton");
            const sizeMenu = findChild(editorWindow, "fontSizeMenu");
            verify(sizeButton && sizeMenu);
            const baseSize = editor.font.pointSize;
            mouseClick(sizeButton);
            tryCompare(sizeMenu, "opened", true);
            mouseClick(sizeMenu.itemAt(9));
            tryCompare(sizeMenu, "opened", false);
            compare(binding.selectionFormat(2, 8).size, 24);
            compare(binding.selectionFormat(0, 1).size, 0);
            compare(editor.font.pointSize, baseSize);
            const delta = JSON.parse(CollaborativeAdapter.contentDelta(accountId, conversationId,
                                                                       documentId));
            verify(delta.some(operation => operation.attributes && operation.attributes.size === 24));
        }

        function test_peerSizeUpdatesThePicker() {
            binding.applyRemoteDelta('[{"retain":2},{"retain":6,"attributes":{"size":24}}]');
            editorWindow.refreshFormatState();
            compare(editorWindow.currentFontSize, 24);
            const sizeMenu = findChild(editorWindow, "fontSizeMenu");
            verify(sizeMenu);
            verify(sizeMenu.itemAt(9).checked);
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
            const delta = JSON.parse(CollaborativeAdapter.contentDelta(accountId, conversationId,
                                                                       documentId));
            verify(delta.every(operation => operation.attributes && operation.attributes.font
                               === "monospace"));
        }

        function test_pickerDisabledWhilePreviewing() {
            editorWindow.previewing = true;
            verify(!fontButton.enabled);
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
    }
}
