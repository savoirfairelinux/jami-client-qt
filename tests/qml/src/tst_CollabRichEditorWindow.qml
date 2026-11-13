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

    Component {
        id: pasteTargetComponent
        TextEdit { textFormat: TextEdit.RichText }
    }

    TestCase {
        name: "CollabRichEditorWindow"
        when: windowShown

        property var editorWindow
        property var editor
        property var binding
        property var fontButton
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
            editorWindow.requestActivate();
            waitForRendering(editorWindow.contentItem);
            editor = findChild(editorWindow, "collabEditor");
            binding = findChild(editorWindow, "collabRichBinding");
            fontButton = findChild(editorWindow, "fontFamilyButton");
            verify(editor && binding && fontButton);
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

        function choose(comboBox, index) {
            mouseClick(comboBox);
            tryCompare(comboBox.popup, "opened", true);
            const item = comboBox.popup.contentItem.itemAtIndex(index);
            verify(item);
            mouseClick(item);
            tryCompare(comboBox.popup, "visible", false);
        }

        function chooseFont(index) {
            choose(fontButton, index);
        }

        // The editable text field inside the size spin box.
        function sizeInput() {
            function findInput(item) {
                if (typeof item.selectAll === "function" && item.validator !== undefined)
                    return item;
                for (const child of item.children) {
                    const input = findInput(child);
                    if (input)
                        return input;
                }
                return null;
            }
            const sizeButton = findChild(editorWindow, "textSizeButton");
            verify(sizeButton);
            const input = findInput(sizeButton);
            verify(input);
            return input;
        }

        function typeTextSize(size) {
            const input = sizeInput();
            input.forceActiveFocus();
            input.selectAll();
            for (const digit of String(size))
                keyClick(digit);
            keyClick(Qt.Key_Return);
        }

        function test_pickerWritesCompatibleId() {
            compare(fontButton.count, 5);
            chooseFont(2);
            compare(editorWindow.currentFont, "serif");
            compare(editorWindow.currentFontLabel, editorWindow.fontChoices[2].label);
            compare(fontButton.currentIndex, 2);
            const delta = JSON.parse(CollaborativeAdapter.contentDelta(editorWindow.accountId, editorWindow.conversationId, editorWindow.documentId));
            verify(delta.some(operation => operation.attributes && operation.attributes.font === "serif"));
            chooseFont(0);
            compare(editorWindow.currentFont, "");
            compare(fontButton.currentIndex, 0);
        }

        function test_sizePickerOnlyFormatsTheSelection() {
            const baseSize = editor.font.pointSize;
            typeTextSize(24);
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
            compare(Number(sizeInput().text), 24);
        }

        function test_clearFormattingRestoresTheBaseSize() {
            typeTextSize(24);
            compare(binding.selectionFormat(2, 8).size, 24);
            const bar = findChild(editorWindow, "formattingToolbar");
            const clearButton = Array.from(bar.children).find(control => String(control.iconSource).includes("format_clear"));
            verify(clearButton);
            mouseClick(clearButton);
            compare(binding.selectionFormat(2, 8).size, 0);
            compare(Number(sizeInput().text), editorWindow.baseFontSize);
            verify(content().every(operation => !operation.attributes || operation.attributes.size === undefined));
        }

        function test_peerFontUpdatesThePicker() {
            binding.applyRemoteDelta('[{"retain":2},{"retain":6,"attributes":{"font":"cursive"}}]');
            editorWindow.refreshFormatState();
            compare(editorWindow.currentFont, "cursive");
            compare(fontButton.currentIndex, 4);
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
            verify(!findChild(editorWindow, "baseSizeButton"));
            verify(!findChild(editorWindow, "baseSizeMenu"));
        }

        function test_headingPickerAppliesAndRemovesTheStyle() {
            const headingButton = findChild(editorWindow, "headingButton");
            verify(headingButton);
            editor.cursorPosition = 4;
            for (const level of [2, 0]) {
                choose(headingButton, level);
                compare(editorWindow.currentHeading, level);
                compare(headingButton.currentIndex, level);
                compare(headingButton.displayText, editorWindow.headingLabel(level));
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
            compare(fontButton.count, editorWindow.fontChoices.length);
            for (var index = 0; index < editorWindow.fontChoices.length; ++index) {
                compare(fontButton.textAt(index), editorWindow.fontChoices[index].label);
            }
        }

        function test_unknownFontIsNotShownAsTheDefault() {
            binding.applyRemoteDelta('[{"retain":8,"attributes":{"font":"some-future-font"}}]');
            editorWindow.refreshFormatState();
            compare(fontButton.displayText, "some-future-font");
            compare(fontButton.currentIndex, -1);
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
            // Only the toolbar's own items and the Rows its alignment Repeater
            // creates are walked, never the internals of a control.
            function label(item) {
                if (item.objectName !== "")
                    return item.objectName;
                if (item.iconSource !== undefined)
                    return item.iconSource.split("/").pop().replace(/(_black)?(_24dp)?\.svg$/, "");
                return "|";
            }
            function names(container) {
                var order = [];
                for (const item of container.children) {
                    if (!item.visible || item.width === 0)
                        continue;
                    if (container === bar && item.objectName === "" && item.iconSource === undefined
                            && item.spacing !== undefined)
                        order = order.concat(names(item));
                    else
                        order.push(label(item));
                }
                return order;
            }
            const order = names(bar);
            const expected = "headingButton fontFamilyButton textSizeButton"
                    + " | bold italic underline strikethrough_s"
                    + " | align-left align-center align-right align-justify"
                    + " | directionButton bidirectional_bullet_point bidirectional_bullet_number"
                    + " | link_web add_photo_alternate format_clear";
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

        function test_directionToggleReachesTheDocument() {
            compare(editorWindow.currentDirection, "ltr");
            const button = findChild(editorWindow, "directionButton");
            verify(button);
            mouseClick(button);

            compare(editorWindow.currentDirection, "rtl");
            compare(content()[0].attributes.dir, "rtl");
            mouseClick(button);
            compare(editorWindow.currentDirection, "ltr");
            verify(content()[0].attributes === undefined || content()[0].attributes.dir === undefined);
        }

        function test_peerDirectionShowsInTheToolbar() {
            binding.applyRemoteDelta('[{"retain":8,"attributes":{"dir":"rtl"}}]');
            editorWindow.refreshFormatState();
            compare(editorWindow.currentDirection, "rtl");
        }

        function test_chosenLanguageReachesTheDocument() {
            editorWindow.chooseLanguage("fr_FR");

            compare(editorWindow.currentLanguage, "fr_FR");
            const ops = content();
            compare(ops[0].insert, "A ");
            verify(ops[0].attributes === undefined || ops[0].attributes.lang === undefined);
            compare(ops[1].insert, "report");
            compare(ops[1].attributes.lang, "fr_FR");
            const runs = binding.languageRuns();
            compare(runs.length, 2);
            compare(runs[1].start, 2);
            compare(runs[1].text, "report");
            compare(runs[1].lang, "fr_FR");

            editorWindow.chooseLanguage("");
            verify(content().every(operation => !operation.attributes || operation.attributes.lang === undefined));
        }

        function test_unsafeLanguageFromAPeerIsDropped() {
            binding.applyRemoteDelta('[{"retain":2},{"retain":6,"attributes":{"lang":"../../etc"}}]');
            editorWindow.refreshFormatState();
            compare(editorWindow.currentLanguage, "");
        }

        function test_exportDialogUsesEditorWindowAsParentAndRestoresFocus() {
            var capturedParent = null;
            var capturedDialog = null;
            editorWindow.dialogCoordinator = {
                presentDialog: function (parent, path, props, singleInstance) {
                    capturedParent = parent;
                    capturedDialog = {
                        path: path,
                        props: props,
                        fileAccepted: { connect: function () {} },
                        accepted: { connect: function () {} },
                        rejected: {
                            _cb: null,
                            connect: function (cb) { this._cb = cb; }
                        }
                    };
                    return capturedDialog;
                }
            };
            const headingButton = findChild(editorWindow, "headingButton");
            verify(headingButton);
            headingButton.forceActiveFocus();
            editorWindow.exportDocument("pdf", "PDF document");
            compare(capturedParent, editorWindow.contentItem);
            verify(capturedDialog && capturedDialog.rejected._cb !== null);
            capturedDialog.rejected._cb();
            tryCompare(editor, "activeFocus", true);
        }

        function test_orderedListStaysActiveAfterEnter() {
            editor.remove(0, editor.length);
            editor.cursorPosition = 0;
            binding.setList("ordered", 0, 0);
            editorWindow.refreshFormatState();
            compare(editorWindow.fmt.list, "ordered");

            editor.forceActiveFocus();
            keyClick(Qt.Key_A);
            keyClick(Qt.Key_B);
            compare(editorWindow.fmt.list, "ordered");

            keyClick(Qt.Key_Return);
            compare(editorWindow.fmt.list, "ordered");
        }

        function test_alignmentChangesOnEmptyLine() {
            editor.remove(0, editor.length);
            editor.cursorPosition = 0;
            binding.setAlign("center", 0, 0);
            editorWindow.refreshFormatState();
            compare(editorWindow.currentAlign, "center");

            editor.forceActiveFocus();
            keyClick(Qt.Key_H);
            keyClick(Qt.Key_I);
            compare(editorWindow.currentAlign, "center");
            compare(content()[0].attributes.align, "center");
        }

        function test_inlineFormattingShortcuts_data() {
            return [
                {tag: "bold", key: Qt.Key_B, modifiers: Qt.ControlModifier, attribute: "b", icon: "bold_black"},
                {tag: "italic", key: Qt.Key_I, modifiers: Qt.ControlModifier, attribute: "i", icon: "italic_black"},
                {tag: "underline", key: Qt.Key_U, modifiers: Qt.ControlModifier, attribute: "u", icon: "underline_black"},
                {tag: "strikethrough", key: Qt.Key_X, modifiers: Qt.ShiftModifier | Qt.AltModifier, attribute: "s", icon: "strikethrough_s"}
            ];
        }

        function test_inlineFormattingShortcuts(data) {
            editor.forceActiveFocus();
            keyClick(data.key, data.modifiers);
            compare(binding.selectionFormat(2, 8)[data.attribute], true);
            verify(content().some(op => op.attributes && op.attributes[data.attribute] === true));
            keyClick(data.key, data.modifiers);
            compare(binding.selectionFormat(2, 8)[data.attribute], false);
            const toolbar = findChild(editorWindow, "formattingToolbar");
            const button = toolbar.children.find(child => child.iconSource
                                                  && String(child.iconSource).indexOf(data.icon) >= 0);
            verify(button);
            editor.remove(0, editor.length);
            editor.cursorPosition = 0;
            keyClick(data.key, data.modifiers);
            compare(editorWindow.fmt[data.attribute], true);
            keyClick(data.key, data.modifiers);
            compare(editorWindow.fmt[data.attribute], false);
            compare(content().length, 0);
            mouseClick(button);
            keyClick(Qt.Key_H);
            compare(binding.selectionFormat(0, 1)[data.attribute], true);
            keyClick(data.key, data.modifiers);
            verify(!button.checked);
            keyClick(Qt.Key_I);
            compare(binding.selectionFormat(0, 1)[data.attribute], true);
            compare(binding.selectionFormat(1, 2)[data.attribute], false);
            compare(editor.getText(0, editor.length), "hi");
            verify(content().some(op => op.insert === "h" && op.attributes
                                 && op.attributes[data.attribute] === true), JSON.stringify(content()));
            verify(content().some(op => op.insert === "i" && (!op.attributes
                                 || op.attributes[data.attribute] === undefined)));
            editor.cursorPosition = 1;
            keyClick(data.key, data.modifiers);
            compare(binding.selectionFormat(1, 2)[data.attribute], true);
            mouseClick(button);
            compare(binding.selectionFormat(0, 2)[data.attribute], false);
            verify(content().every(op => !op.attributes || op.attributes[data.attribute] === undefined));
        }

        function test_copyAndPasteWordInListDoesNotInsertNewline() {
            binding.setList("bullet", 0, editor.length);
            editor.forceActiveFocus();
            editor.select(2, 8);
            keyClick(Qt.Key_C, Qt.ControlModifier);
            editor.cursorPosition = editor.length;
            keyClick(Qt.Key_V, Qt.ControlModifier);
            compare(editor.getText(0, editor.length), "A reportreport");
            verify(content().every(op => op.attributes && op.attributes.list === "bullet"));
        }

        function test_cutAndPasteWordInListDoesNotInsertNewline() {
            binding.setList("bullet", 0, editor.length);
            editor.forceActiveFocus();
            keyClick(Qt.Key_X, Qt.ControlModifier);
            compare(editor.getText(0, editor.length), "A ");
            keyClick(Qt.Key_V, Qt.ControlModifier);
            compare(editor.getText(0, editor.length), "A report");
        }

        function test_copyAndCutMixedImagesUseNativeClipboard_data() {
            return [{tag: "copy", key: Qt.Key_C}, {tag: "cut", key: Qt.Key_X}];
        }

        function test_copyAndCutMixedImagesUseNativeClipboard(data) {
            binding.insertImage(2, "0123456789abcdef0123456789abcdef01234567", 20, 20);
            const original = editor.getText(0, editor.length);
            verify(original.indexOf("\uFFFC") >= 0);
            editor.selectAll();
            editor.forceActiveFocus();
            keyClick(data.key, Qt.ControlModifier);
            const target = createTemporaryObject(pasteTargetComponent, this);
            target.paste();
            compare(target.getText(0, target.length), original);
            if (data.key === Qt.Key_X)
                compare(editor.length, 0);
        }

        function test_shortcutsDoNotChangeHistoryPreview() {
            const original = JSON.stringify(content());
            editorWindow.previewing = true;
            editor.forceActiveFocus();
            for (const key of [Qt.Key_B, Qt.Key_I, Qt.Key_U, Qt.Key_X])
                keyClick(key, Qt.ControlModifier);
            keyClick(Qt.Key_X, Qt.ShiftModifier | Qt.AltModifier);
            compare(editor.getText(0, editor.length), "A report");
            compare(JSON.stringify(content()), original);
        }
    }
}
