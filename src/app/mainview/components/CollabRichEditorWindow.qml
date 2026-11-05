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
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"
import "../../commoncomponents/contextmenu"
import "../../settingsview/components"

// Independent top-level window for real-time collaborative WYSIWYG (rich-text)
// editing. The user selects text with the mouse and applies formatting from the
// top toolbar; every edit is a CRDT delta, so formatting converges across all
// participants in real time.
Window {
    id: root

    // The account this window belongs to. Editor windows are top-level and stay
    // open across account switches, and two local accounts in the same swarm see
    // the same conversation and document ids, so every call and every signal has
    // to name the account explicitly.
    property string accountId: ""
    property string conversationId: ""
    property string documentId: ""
    // Non-empty while a failed image insertion is being reported.
    property string attachmentError: ""
    property string documentName: ""
    property string documentAuthor: ""
    // This is captured with accountId when the window opens, so a later account
    // switch cannot change who may rename this document in the open window.
    property string accountUri: ""
    property string peerName: ""
    readonly property bool canRename: documentAuthor !== "" && documentAuthor === accountUri

    // Cached formatting state of the current selection, driving the toolbar.
    property var fmt: ({})
    // Editor base font size (local view preference; headings scale relative to it).
    property int baseFontSize: JamiTheme.textFontSize
    readonly property var fontChoices: [
        {
            "id": "",
            "label": JamiStrings.defaultOption
        },
        {
            "id": "sans-serif",
            "label": JamiStrings.fontSansSerif
        },
        {
            "id": "serif",
            "label": JamiStrings.fontSerif
        },
        {
            "id": "monospace",
            "label": JamiStrings.fontMonospace
        },
        {
            "id": "cursive",
            "label": JamiStrings.fontCursive
        }
    ]
    readonly property string currentFont: root.fmt.font || ""
    readonly property real currentFontSize: root.fmt.size || root.baseFontSize
    readonly property string currentFontLabel: {
        for (var index = 0; index < fontChoices.length; ++index) {
            if (fontChoices[index].id === currentFont)
                return fontChoices[index].label;
        }
        return currentFont;
    }

    // Read-only review of a past version. Only the text is replayed: character
    // formatting is not part of what a checkpoint restores.
    property bool previewing: false
    property string previewText: ""

    // Debug builds only: shows the document as the peers exchange it.
    property bool showingRaw: false

    title: (documentName !== "" ? documentName : JamiStrings.editableDocument) + (peerName !== "" ? " — " + peerName : "") + " — " + JamiStrings.appTitle
    width: 840
    height: 560
    minimumWidth: 420
    minimumHeight: 320
    color: JamiTheme.backgroundColor

    function refreshFormatState() {
        root.fmt = richBinding.selectionFormat(editor.selectionStart, editor.selectionEnd);
    }

    // Stable per-participant colour derived from their id.
    function colorForPeer(peerId) {
        var h = 0;
        for (var i = 0; i < peerId.length; ++i)
            h = (h * 31 + peerId.charCodeAt(i)) % 360;
        return Qt.hsla(h / 360, 0.65, 0.5, 1.0);
    }

    // The name server is queried asynchronously, so the first lookup for a peer
    // often returns its raw URI. Re-resolve until a real name comes back instead
    // of freezing whatever was available when the cursor first appeared.
    function displayNameFor(peerId, current) {
        if (current && current !== peerId)
            return current;
        var name = UtilsAdapter.getBestNameForUri(root.accountId, peerId);
        return name && name.length > 0 ? name : peerId;
    }

    // Keyed on the client id alone, which the daemon guarantees is enough.
    //
    // It is safe as a Number: a client id is drawn in [1, 2^53-1] and the
    // decoder refuses anything above that, so it never leaves the range
    // JavaScript represents exactly -- the same bound yjs itself relies on to
    // carry these ids through JSON.
    //
    // It is also unambiguous on its own: the daemon records the account that
    // first announced a client id in a document and drops any later claim on it
    // from someone else, so no two peers can share one here.
    function upsertCursor(clientId, peerId, pos) {
        for (var i = 0; i < remoteCursorsModel.count; ++i) {
            var entry = remoteCursorsModel.get(i);
            if (entry.clientId === clientId) {
                remoteCursorsModel.setProperty(i, "position", pos);
                remoteCursorsModel.setProperty(i, "name", root.displayNameFor(peerId, entry.name));
                return;
            }
        }
        remoteCursorsModel.append({
            "clientId": clientId,
            "peerId": peerId,
            "name": root.displayNameFor(peerId, ""),
            "pColor": colorForPeer(peerId),
            "position": pos
        });
    }

    // Keyed on the editing device, not on the person: someone editing from two
    // devices has two cursors, and the colour they share is what says so.
    function removeCursor(clientId) {
        for (var i = 0; i < remoteCursorsModel.count; ++i) {
            if (remoteCursorsModel.get(i).clientId === clientId) {
                remoteCursorsModel.remove(i);
                return;
            }
        }
    }

    ListModel {
        id: remoteCursorsModel
    }

    // Carries every peer's caret along with an edit that has just arrived.
    //
    // A peer announces where its caret is on a timer of its own, so between its
    // edit and its next announcement the index it last gave points at what the
    // text used to be: its caret is drawn back where it was typing a moment ago,
    // then jumps once the announcement catches up. Moving it with the text is
    // what keeps it still.
    function shiftCursors(deltaJson) {
        if (remoteCursorsModel.count === 0)
            return;
        var positions = [];
        for (var i = 0; i < remoteCursorsModel.count; ++i)
            positions.push(remoteCursorsModel.get(i).position);
        var moved = richBinding.transformPositions(deltaJson, positions);
        for (var j = 0; j < remoteCursorsModel.count && j < moved.length; ++j)
            remoteCursorsModel.setProperty(j, "position", moved[j]);
    }

    // Coalesce rapid local cursor moves into a single broadcast.
    Timer {
        id: cursorBroadcast
        interval: 120
        repeat: false
        onTriggered: CollaborativeAdapter.setCursor(root.accountId, root.conversationId, root.documentId, editor.cursorPosition, editor.selectionStart)
    }

    // Match the icon button height so dividers stay centered in the toolbar.
    component ToolbarSeparator: Item {
        width: 1
        height: JamiTheme.iconButtonMedium * 1.5
        Rectangle {
            anchors.centerIn: parent
            width: 1
            height: parent.height - 8
            color: JamiTheme.tabbarBorderColor
        }
    }

    Component.onCompleted: {
        // Ensure the daemon session exists, then render the current content.
        CollaborativeAdapter.openDocument(accountId, conversationId, documentId);
        richBinding.loadContentDelta(CollaborativeAdapter.contentDelta(accountId, conversationId, documentId));
        refreshFormatState();
        scheduleSpellCheck();
    }
    onClosing: CollaborativeAdapter.closeDocument(accountId, conversationId, documentId)

    function focusEditor() {
        editor.forceActiveFocus();
        Qt.callLater(function () {
            editor.forceActiveFocus();
        });
    }

    Connections {
        target: CollaborativeAdapter

        function onDocumentDelta(accId, convId, docId, deltaJson) {
            if (accId !== root.accountId || convId !== root.conversationId || docId !== root.documentId)
                return;
            richBinding.applyRemoteDelta(deltaJson);
            root.shiftCursors(deltaJson);
            root.refreshFormatState();
            // A peer may have moved or resized the selected image.
            root.dropImageSelectionUnlessHeld();
            root.refreshImageGeom();
        }

        function onDocumentRenamed(accId, convId, docId, name) {
            if (accId === root.accountId && convId === root.conversationId && docId === root.documentId)
                root.documentName = name;
        }

        function onDocumentRemoved(accId, convId, docId, everywhere) {
            if (accId !== root.accountId || convId !== root.conversationId || docId !== root.documentId)
                return;
            // The daemon no longer holds this document, whichever removal took it.
            // Leaving the window open would let the user keep typing into
            // something not backed by anything, and every keystroke would be
            // dropped without a word. Say why before the window goes, or it just
            // vanishes mid-sentence -- and say which of the two happened, since
            // one of them can be walked back and the other cannot.
            viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                "titleText": everywhere ? JamiStrings.documentRemoved : JamiStrings.documentRemovedFromDevice,
                "infoText": everywhere ? JamiStrings.documentRemovedByAuthor.arg(root.documentName) : JamiStrings.documentRemovedLocallyInfo.arg(root.documentName),
                "buttonTitles": [JamiStrings.optionOk],
                "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue],
                "buttonRoles": [DialogButtonBox.AcceptRole]
            });
            root.close();
        }

        function onCursorChanged(accId, convId, docId, peerId, clientId, pos, anchor) {
            if (accId === root.accountId && convId === root.conversationId && docId === root.documentId)
                root.upsertCursor(clientId, peerId, pos);
        }

        function onAttachmentAdded(accId, convId, docId, attachmentId) {
            if (accId === root.accountId && convId === root.conversationId && docId === root.documentId && richBinding.referencesAttachment(attachmentId))
                CollaborativeAdapter.deliverAttachment(accId, convId, docId, attachmentId, richBinding);
        }

        function onParticipantLeft(accId, convId, docId, peerId, clientId) {
            if (accId === root.accountId && convId === root.conversationId && docId === root.documentId)
                root.removeCursor(clientId);
        }
    }

    // Store the picked file with the document, then place it where the caret is.
    // The bytes are registered before the image exists in the document so the
    // layout measures it on the first pass instead of drawing a broken box.
    // Alignment of the paragraph under the caret. Left is stored as no attribute
    // at all, so an empty answer means left.
    readonly property string currentAlign: (root.fmt.align !== undefined && root.fmt.align !== "") ? root.fmt.align : "left"

    // Direction of the paragraph under the caret. Left-to-right is stored as no
    // attribute at all.
    readonly property string currentDirection: root.fmt.dir === "rtl" ? "rtl" : "ltr"

    function toggleDirection() {
        richBinding.setDirection(root.currentDirection === "rtl" ? "ltr" : "rtl", editor.selectionStart, editor.selectionEnd);
        root.refreshFormatState();
        editor.forceActiveFocus();
    }

    // Spelling language of the selection, or of what the caret will type: "" for
    // the application's own, "zxx" for none.
    readonly property string noSpellLanguage: "zxx"
    readonly property string currentLanguage: root.fmt.lang !== undefined ? root.fmt.lang : ""
    readonly property var spellLanguages: {
        SpellCheckAdapter.installedDictionaryCount;
        return SpellCheckAdapter.getInstalledDictionaries();
    }
    readonly property var spellLanguageChoices: {
        var choices = [
            {
                "id": "",
                "label": JamiStrings.defaultOption
            },
            {
                "id": root.noSpellLanguage,
                "label": JamiStrings.noSpellCheck
            }
        ];
        var locales = Object.keys(root.spellLanguages);
        for (var i = 0; i < locales.length; ++i)
            choices.push({
                    "id": locales[i],
                    "label": root.spellLanguages[locales[i]]
                });
        return choices;
    }

    function languageLabel(lang) {
        if (lang === "")
            return JamiStrings.defaultOption;
        if (lang === root.noSpellLanguage)
            return JamiStrings.noSpellCheck;
        return root.spellLanguages[lang] !== undefined ? root.spellLanguages[lang] : lang;
    }

    function chooseLanguage(lang) {
        richBinding.setLanguage(lang, editor.selectionStart, editor.selectionEnd);
        root.refreshFormatState();
        root.scheduleSpellCheck();
        editor.forceActiveFocus();
    }

    // Words the dictionary of their language does not know: {start, end, word,
    // lang}, in document positions. Underlined in the editor.
    property var misspellings: []
    // Suggestions for the word under the context menu, and where it is.
    property var spellSuggestions: []
    property var spellTarget: null

    function spellCheckActive() {
        return AppSettingsManager.getValue(Settings.EnableSpellCheck) && !root.previewing;
    }

    function scheduleSpellCheck() {
        spellTimer.restart();
    }

    function recheckSpelling() {
        var found = [];
        if (root.spellCheckActive()) {
            const appLang = AppSettingsManager.getValue(Settings.SpellLang);
            const runs = richBinding.languageRuns();
            for (var r = 0; r < runs.length; ++r) {
                const lang = runs[r].lang !== "" ? runs[r].lang : appLang;
                if (lang === "" || lang === root.noSpellLanguage)
                    continue;
                const words = SpellCheckAdapter.findWords(runs[r].text);
                for (var w = 0; w < words.length; ++w) {
                    if (!SpellCheckAdapter.spellIn(lang, words[w].word))
                        found.push({
                                "start": runs[r].start + words[w].position,
                                "end": runs[r].start + words[w].position + words[w].length,
                                "word": words[w].word,
                                "lang": lang
                            });
                }
            }
        }
        root.misspellings = found;
    }

    function prepareSpellMenu(point) {
        root.spellSuggestions = [];
        root.spellTarget = null;
        const pos = editor.positionAt(point.x, point.y);
        for (var i = 0; i < root.misspellings.length; ++i) {
            const m = root.misspellings[i];
            if (pos >= m.start && pos < m.end) {
                root.spellTarget = m;
                root.spellSuggestions = SpellCheckAdapter.spellSuggestionsIn(m.lang, m.word);
                return;
            }
        }
    }

    Timer {
        id: spellTimer
        interval: 300
        onTriggered: root.recheckSpelling()
    }

    Connections {
        target: SpellCheckAdapter
        function onDictionaryChanged() {
            root.scheduleSpellCheck();
        }
        function onInstalledDictionaryCountChanged() {
            root.scheduleSpellCheck();
        }
    }

    Connections {
        target: UtilsAdapter
        function onEnableSpellCheckChanged() {
            root.scheduleSpellCheck();
        }
    }

    onPreviewingChanged: root.scheduleSpellCheck()

    function chooseFont(id) {
        richBinding.setFont(id, editor.selectionStart, editor.selectionEnd);
        root.refreshFormatState();
        editor.forceActiveFocus();
    }

    // Heading level of the paragraph under the caret, 0 for normal text.
    readonly property int currentHeading: root.fmt.header !== undefined ? root.fmt.header : 0

    function headingLabel(level) {
        if (level === 1)
            return JamiStrings.heading1;
        if (level === 2)
            return JamiStrings.heading2;
        if (level === 3)
            return JamiStrings.heading3;
        return JamiStrings.normalText;
    }

    // How much larger than the text a heading is drawn: the size adjustment of
    // the HTML <h1>..<h3> tags that headings are drawn with.
    function headingScale(level) {
        if (level === 1)
            return 2.0;
        if (level === 2)
            return 1.5;
        if (level === 3)
            return 1.2;
        return 1.0;
    }

    function chooseHeading(level) {
        richBinding.setHeading(level, editor.selectionStart, editor.selectionEnd);
        root.refreshFormatState();
        editor.forceActiveFocus();
    }

    // Size of the selection, or of what the caret will type, in points. 0 when
    // the text has none of its own and is at the base size.
    readonly property real currentTextSize: root.fmt.size !== undefined ? root.fmt.size : 0

    function chooseTextSize(size) {
        richBinding.setFontSize(size, editor.selectionStart, editor.selectionEnd);
        root.refreshFormatState();
        editor.forceActiveFocus();
    }

    // Unit holding the image the resize handles are attached to, -1 when none is
    // selected. Set by clicking an image, dropped as soon as the selection is
    // anything else -- typing, clicking away, or selecting text.
    property int selectedImage: -1

    // Where that image is drawn and how far it may be dragged. Kept as plain
    // data rather than recomputed by a binding: it also has to follow a drag in
    // progress, which changes nothing a binding would be watching.
    property var imageGeom: null

    function refreshImageGeom() {
        root.imageGeom = root.selectedImage >= 0 ? richBinding.imageInfoAt(root.selectedImage) : null;
        if (root.imageGeom && !(root.imageGeom.width > 0))
            root.imageGeom = null;
    }

    // Raised while we are the ones moving the selection: select() reports its
    // two ends one after the other, and the half-moved state in between does not
    // match the image -- which would drop the selection we are busy making.
    property bool holdingImageSelection: false

    function selectImageAt(unit) {
        root.holdingImageSelection = true;
        root.selectedImage = unit;
        if (unit >= 0)
            editor.select(unit, unit + 1);
        root.holdingImageSelection = false;
        root.refreshImageGeom();
    }

    // Dropped unless the selection is still exactly that one image.
    function dropImageSelectionUnlessHeld() {
        if (root.holdingImageSelection || root.selectedImage < 0)
            return;
        if (editor.selectionStart !== root.selectedImage || editor.selectionEnd !== root.selectedImage + 1)
            root.selectImageAt(-1);
    }

    property var dialogCoordinator: null

    function coordinator() {
        if (root.dialogCoordinator)
            return root.dialogCoordinator;
        return typeof viewCoordinator !== "undefined" ? viewCoordinator : null;
    }

    function openDictionaryManager() {
        const coord = root.coordinator();
        if (coord)
            coord.presentDialog(root.contentItem, "commoncomponents/DictionaryManagerDialog.qml");
    }

    function activateEditorWindow() {
        root.raise();
        root.requestActivate();
        root.focusEditor();
        Qt.callLater(function () {
            root.raise();
            root.requestActivate();
            root.focusEditor();
        });
    }

    // The picker is built on demand, never declared here: JamiFileDialog counts
    // its instances from Component.onCompleted, and the main window veils itself
    // while that count is above zero. A picker standing by in this window would
    // hold the main window hostage for as long as the document stays open.
    function pickImage() {
        const coord = root.coordinator();
        if (!coord)
            return;
        var dlg = coord.presentDialog(root.contentItem, "commoncomponents/JamiFileDialog.qml", {
            "title": JamiStrings.insertImage,
            "mode": JamiFileDialog.Mode.OpenFile,
            "nameFilters": [JamiStrings.images + " (*.png *.jpg *.jpeg *.gif *.bmp *.webp)"]
        }, true);
        dlg.fileAccepted.connect(function (file) {
            root.insertImageFromFile(file);
            root.activateEditorWindow();
        });
        if (dlg.rejected !== undefined) {
            dlg.rejected.connect(function () {
                root.activateEditorWindow();
            });
        }
    }

    function insertImageFromFile(file) {
        const info = CollaborativeAdapter.addAttachment(root.accountId, root.conversationId, root.documentId, file);
        if (!info || !info.id) {
            root.attachmentError = JamiStrings.documentImageInsertError;
            attachmentErrorTimer.restart();
            return;
        }
        root.attachmentError = "";
        CollaborativeAdapter.deliverAttachment(root.accountId, root.conversationId, root.documentId, info.id, richBinding);
        richBinding.insertImage(editor.cursorPosition, info.id, info.width !== undefined ? info.width : 0, 0);
        editor.forceActiveFocus();
    }

    // Writes a local copy of the document. The pictures live in the document as
    // resources under a collab-attachment: URL, which nothing outside Jami can
    // resolve, so a format either carries their bytes with it or leaves the
    // pictures out.
    function exportDocument(suffix, filterLabel) {
        const coord = root.coordinator();
        if (!coord)
            return;
        // Plain text holds no picture either way, so one that has not arrived
        // changes nothing about what gets written.
        const missing = suffix === "txt" ? 0 : richBinding.unresolvedImageCount();
        if (missing > 0) {
            var confirmDlg = coord.presentDialog(root.contentItem, "commoncomponents/ConfirmDialog.qml", {
                "titleText": JamiStrings.exportDocument,
                "textLabel": JamiStrings.missingDocumentPictures(missing),
                "confirmLabel": JamiStrings.exportAnyway,
                "rejectLabel": JamiStrings.optionCancel
            });
            confirmDlg.accepted.connect(function () {
                root.pickExportPath(suffix, filterLabel);
            });
            if (confirmDlg.rejected !== undefined) {
                confirmDlg.rejected.connect(function () {
                    root.activateEditorWindow();
                });
            }
            return;
        }
        root.pickExportPath(suffix, filterLabel);
    }

    function pickExportPath(suffix, filterLabel) {
        const coord = root.coordinator();
        if (!coord)
            return;
        const folder = UtilsAdapter.getDirDocument();
        // The name is written by whoever renamed the document, this device or a
        // peer, so it is never allowed to carry the path anywhere.
        const base = (root.documentName !== "" ? root.documentName : JamiStrings.documentExportBaseName).replace(/[\/\\:*?"<>|]/g, "_");
        var dlg = coord.presentDialog(root.contentItem, "commoncomponents/JamiFileDialog.qml", {
            "title": JamiStrings.exportDocument,
            "mode": JamiFileDialog.Mode.SaveFile,
            "folder": UtilsAdapter.urlFromLocalPath(folder),
            // currentFile, not file: the latter only ever holds what the
            // user finally accepted, and setting it preselects nothing.
            "currentFile": UtilsAdapter.urlFromLocalPath(folder + "/" + base + "." + suffix),
            "nameFilters": [filterLabel + " (*." + suffix + ")"],
            "defaultSuffix": suffix
        }, true);
        if (dlg.rejected !== undefined) {
            dlg.rejected.connect(function () {
                root.activateEditorWindow();
            });
        }
        dlg.fileAccepted.connect(function (file) {
            const ok = richBinding.exportToFile(file, root.documentName);
            var msgDlg = coord.presentDialog(root.contentItem, "commoncomponents/SimpleMessageDialog.qml", {
                "titleText": ok ? JamiStrings.documentExported : JamiStrings.exportFailed,
                "infoText": ok ? UtilsAdapter.getAbsPath(file.toString()) : JamiStrings.documentExportWriteError,
                "buttonTitles": [JamiStrings.optionOk],
                "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue],
                "buttonRoles": [DialogButtonBox.AcceptRole]
            });
            if (msgDlg && msgDlg.closed !== undefined) {
                msgDlg.closed.connect(function () {
                    root.activateEditorWindow();
                });
            } else {
                root.activateEditorWindow();
            }
        });
    }

    function copySelection() {
        if (!richBinding.copySelection(editor.selectionStart, editor.selectionEnd))
            editor.copy();
    }

    // Pasting inserts whatever the clipboard holds: a picture if there is one,
    // sanitized plain text otherwise.
    function pasteFromClipboard() {
        if (root.previewing)
            return;
        if (!richBinding.clipboardHasImage) {
            richBinding.pasteText(editor.selectionStart, editor.selectionEnd);
            return;
        }
        const info = CollaborativeAdapter.addAttachmentFromClipboard(root.accountId, root.conversationId, root.documentId);
        if (!info || !info.id) {
            root.attachmentError = JamiStrings.documentImageInsertError;
            attachmentErrorTimer.restart();
            return;
        }
        // A paste replaces the selection, as it does for text.
        if (editor.selectionStart !== editor.selectionEnd)
            editor.remove(editor.selectionStart, editor.selectionEnd);
        root.attachmentError = "";
        CollaborativeAdapter.deliverAttachment(root.accountId, root.conversationId, root.documentId, info.id, richBinding);
        richBinding.insertImage(editor.cursorPosition, info.id, info.width !== undefined ? info.width : 0, 0);
        editor.forceActiveFocus();
    }

    // Dropping follows the same rule as pasting: a picture if the drop carries
    // one, text otherwise. Only the transcription of the event happens here; what
    // counts as a picture is decided in C++, once, for both.
    function insertDrop(drop, position) {
        if (root.previewing)
            return;
        var payload = {};
        for (var i = 0; i < drop.formats.length; ++i) {
            var format = drop.formats[i];
            if (format.indexOf("image/") === 0)
                payload[format] = drop.getDataAsArrayBuffer(format);
        }
        if (drop.hasText)
            payload["text"] = drop.text;
        if (drop.hasUrls)
            payload["urls"] = drop.urls;

        const info = CollaborativeAdapter.addAttachmentFromDrop(root.accountId, root.conversationId, root.documentId, payload);
        if (info && info.id) {
            root.attachmentError = "";
            CollaborativeAdapter.deliverAttachment(root.accountId, root.conversationId, root.documentId, info.id, richBinding);
            richBinding.insertImage(position, info.id, info.width !== undefined ? info.width : 0, 0);
            editor.forceActiveFocus();
            return;
        }
        if (richBinding.dropCarriesLocalFile(payload)) {
            // A file was dropped and it is not a picture. Inserting its path as
            // text would be a strange answer to the gesture. A link dragged from
            // a browser is a different matter entirely: it carries a URL too, but
            // it is text, and inserting it is what was meant.
            root.attachmentError = JamiStrings.documentImageInsertError;
            attachmentErrorTimer.restart();
            return;
        }
        if (drop.hasText && drop.text.length > 0) {
            richBinding.insertText(position, position, drop.text);
            editor.forceActiveFocus();
            return;
        }
        // A remote URL dropped without any text of its own: the address is the
        // only thing there is to insert, and it is what was dropped.
        if (drop.hasUrls && drop.urls.length > 0) {
            richBinding.insertText(position, position, String(drop.urls[0]));
            editor.forceActiveFocus();
        }
    }

    // Bridges the editor's QTextDocument to the collaborative CRDT.
    CollabRichBinding {
        id: richBinding
        objectName: "collabRichBinding"

        // How wide an image may be dragged. Read from the editor rather than
        // from the document: the document's own text width follows its
        // contents, so it would shrink around a narrow document and refuse to
        // let any image be made wider than the text already is.
        viewWidth: editor.width - editor.leftPadding - editor.rightPadding
        textDocument: editor.textDocument
        onLocalDelta: function (deltaJson) {
            // Peers' carets are indices into the shared document, so they move
            // for what is typed here exactly as they move for what arrives:
            // otherwise a caret stays at an index that has meanwhile come to
            // mean somewhere else, and slides through the text as it is typed --
            // until that peer happens to move, or forever if it does not.
            root.shiftCursors(deltaJson);
            CollaborativeAdapter.applyDelta(root.accountId, root.conversationId, root.documentId, deltaJson);
        }
        // The document refers to an image whose bytes are not loaded. They are
        // there whenever the reference came from this replica or the repository
        // has already synchronized; otherwise onAttachmentAdded picks it up.
        onAttachmentNeeded: function (attachmentId) {
            CollaborativeAdapter.deliverAttachment(root.accountId, root.conversationId, root.documentId, attachmentId, richBinding);
        }
    }

    Timer {
        id: attachmentErrorTimer
        interval: 5000
        onTriggered: root.attachmentError = ""
    }

    ColumnLayout {
        anchors.fill: parent
        // A third of the usual inset: this window is a writing surface, and the
        // editor is meant to reach close to its edges.
        anchors.margins: JamiTheme.preferredMarginSize / 3
        spacing: JamiTheme.preferredMarginSize / 3

        // The document name, with what applies to the whole document on its right.
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            NewMaterialTextField {
                id: nameField

                Layout.fillWidth: true
                readOnly: !root.canRename
                textFieldContent: root.documentName
                placeholderText: JamiStrings.documentName
                leadingIconSource: JamiResources.description_24dp_svg

                function commitRename() {
                    if (readOnly)
                        return;
                    var newName = nameField.modifiedTextFieldContent.trim();
                    if (newName !== "" && newName !== root.documentName) {
                        root.documentName = newName;
                        CollaborativeAdapter.setName(root.accountId, root.conversationId, root.documentId, newName);
                    }
                    modifiedTextFieldContent = root.documentName;
                }

                onAccepted: {
                    commitRename();
                    root.focusEditor();
                }
                onTextFieldActiveFocusChanged: {
                    if (!textFieldActiveFocus)
                        commitRename();
                }
                Keys.onEscapePressed: {
                    modifiedTextFieldContent = root.documentName;
                    root.focusEditor();
                }
            }

            NewIconButton {
                Layout.alignment: Qt.AlignVCenter
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.code_black_24dp_svg
                toolTipText: JamiStrings.showRawDocument
                // Debug builds only: this is the wire format, and it is of
                // interest to whoever is chasing two replicas that disagree.
                visible: LRCInstance.debugMode()
                checkable: true
                checked: root.showingRaw
                onClicked: root.showingRaw = !root.showingRaw
            }
        }

        // The formatting controls, on a row of their own under the title, in the
        // order they are reached for: the kind of paragraph, the typeface and its
        // sizes, the character styles, the paragraph's layout, then what is put
        // into the text. A window too narrow for them all wraps them onto another
        // line rather than cutting them off.
        Flow {
            id: formattingToolbar
            objectName: "formattingToolbar"
            Layout.fillWidth: true
            spacing: 4

            // A heading applies to whole paragraphs, so it needs no selection: the
            // caret is enough to say which one is meant.
            SettingParaCombobox {
                id: headingButton
                objectName: "headingButton"

                enabled: !root.previewing
                width: 184
                leadingIconSource: JamiResources.title_24dp_svg
                model: [0, 1, 2, 3].map(level => ({
                    "label": root.headingLabel(level),
                    "level": level
                }))
                textRole: "label"
                currentIndex: root.currentHeading
                currentSelectionText: root.headingLabel(root.currentHeading)
                tooltipText: JamiStrings.paragraphStyle
                onActivated: root.chooseHeading(model[currentIndex].level)
            }

            // Font of the selection.
            SettingParaCombobox {
                id: fontFamilyButton
                objectName: "fontFamilyButton"

                enabled: !root.previewing
                width: 184
                leadingIconSource: JamiResources.brand_family_24dp_svg
                model: root.fontChoices
                textRole: "label"
                fontFamilyForIndex: index => richBinding.fontFamilyForId(root.fontChoices[index].id) || editor.font.family
                currentIndex: root.fontChoices.findIndex(choice => choice.id === root.currentFont)
                currentSelectionText: root.currentFontLabel
                tooltipText: JamiStrings.fontFamily
                onActivated: root.chooseFont(model[currentIndex].id)
            }

            // Size of the selection, which every participant sees. Text without a
            // size of its own is at the base size, which is what it shows then.
            SettingSpinBox {
                id: textSizeButton
                objectName: "textSizeButton"

                enabled: !root.previewing
                width: 96
                itemWidth: 96
                buttonWidth: 32
                contentLeftPadding: buttonWidth
                contentRightPadding: buttonWidth
                backgroundColor: JamiTheme.globalBackgroundColor
                incrementIconSource: JamiResources.add_outline_24dp_svg
                decrementIconSource: JamiResources.remove_24dp_svg
                bottomValue: 8
                topValue: 72
                step: 1
                valueField: root.currentTextSize > 0 ? root.currentTextSize : root.baseFontSize
                tooltipText: JamiStrings.fontSize
                onValueModified: root.chooseTextSize(valueField)
            }

            ToolbarSeparator {}

            NewIconButton {
                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.bold_black_24dp_svg
                toolTipText: JamiStrings.bold
                toolTipShortcutKey: "Ctrl+B"
                checked: root.fmt.b === true
                onClicked: {
                    richBinding.toggleInline("b", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            NewIconButton {
                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.italic_black_24dp_svg
                toolTipText: JamiStrings.italic
                toolTipShortcutKey: "Ctrl+I"
                checked: root.fmt.i === true
                onClicked: {
                    richBinding.toggleInline("i", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            NewIconButton {
                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.underline_black_24dp_svg
                toolTipText: JamiStrings.underline
                toolTipShortcutKey: "Ctrl+U"
                checked: root.fmt.u === true
                onClicked: {
                    richBinding.toggleInline("u", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            NewIconButton {
                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.strikethrough_s_24dp_svg
                toolTipText: JamiStrings.strikethrough
                toolTipShortcutKey: "Shift+Alt+X"
                checked: root.fmt.s === true
                onClicked: {
                    richBinding.toggleInline("s", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }

            ToolbarSeparator {}

            // Alignment applies to whole paragraphs, so it needs no selection: the
            // caret is enough to say which one is meant.
            Repeater {
                model: [
                    {
                        "style": "left",
                        "label": JamiStrings.alignLeft,
                        "icon": JamiResources.format_align_left_24dp_svg
                    },
                    {
                        "style": "center",
                        "label": JamiStrings.alignCenter,
                        "icon": JamiResources.format_align_center_24dp_svg
                    },
                    {
                        "style": "right",
                        "label": JamiStrings.alignRight,
                        "icon": JamiResources.format_align_right_24dp_svg
                    },
                    {
                        "style": "justify",
                        "label": JamiStrings.justify,
                        "icon": JamiResources.format_align_justify_24dp_svg
                    }
                ]
                delegate: Row {
                    required property var modelData

                    spacing: formattingToolbar.spacing

                    NewIconButton {
                        objectName: "align-" + modelData.style
                        enabled: !root.previewing
                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: modelData.icon
                        toolTipText: modelData.label
                        checked: root.currentAlign === modelData.style
                        onClicked: {
                            richBinding.setAlign(modelData.style, editor.selectionStart, editor.selectionEnd);
                            root.refreshFormatState();
                            root.refreshImageGeom();
                            editor.forceActiveFocus();
                        }
                    }

                    ToolbarSeparator {
                        visible: modelData.style === "justify"
                    }
                }
            }
            NewIconButton {
                objectName: "directionButton"

                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: root.currentDirection === "rtl" ? JamiResources.text_direction_rtl_24dp_svg : JamiResources.text_direction_ltr_24dp_svg
                toolTipText: root.currentDirection === "rtl" ? JamiStrings.switchToLeftToRight : JamiStrings.switchToRightToLeft
                checked: root.currentDirection === "rtl"
                onClicked: root.toggleDirection()
            }
            NewIconButton {
                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.bidirectional_bullet_point_black_24dp_svg
                toolTipText: JamiStrings.bulletedList
                checked: root.fmt.list === "bullet"
                onClicked: {
                    richBinding.setList("bullet", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            NewIconButton {
                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.bidirectional_bullet_number_black_24dp_svg
                toolTipText: JamiStrings.numberedList
                checked: root.fmt.list === "ordered"
                onClicked: {
                    richBinding.setList("ordered", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }

            ToolbarSeparator {}

            NewIconButton {
                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.link_web_black_24dp_svg
                toolTipText: JamiStrings.link
                checked: root.fmt.link !== undefined && root.fmt.link !== ""
                onClicked: {
                    linkPopup.open();
                }
            }
            NewIconButton {
                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.add_photo_alternate_black_24dp_svg
                toolTipText: JamiStrings.insertImage
                onClicked: root.pickImage()
            }
            NewIconButton {
                enabled: !root.previewing
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.format_clear_24dp_svg
                toolTipText: JamiStrings.clearFormatting
                onClicked: {
                    richBinding.clearFormat(editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
        }

        // Why an image insertion did nothing. Silence would look like a bug.
        Text {
            Layout.fillWidth: true
            visible: root.attachmentError !== ""
            text: root.attachmentError
            font.pointSize: JamiTheme.smallFontSize
            color: JamiTheme.redColor
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: JamiTheme.preferredMarginSize / 3

            // The live editor stays mounted and visible to Qt at all times: a
            // TextArea whose text changes while it is hidden comes back with a
            // stale render. The preview is laid over it instead.
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ScrollView {
                    anchors.fill: parent
                    clip: true

                    TextArea {
                        id: editor
                        objectName: "collabEditor"

                        padding: 10
                        // Keystrokes must not reach a document the user cannot see.
                        readOnly: root.previewing
                        textFormat: TextEdit.RichText
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        persistentSelection: true
                        focus: true
                        font.pointSize: root.baseFontSize
                        color: JamiTheme.textColor
                        placeholderText: JamiStrings.startTyping
                        background: Rectangle {
                            color: JamiTheme.secondaryBackgroundColor
                            border.width: 1
                            border.color: JamiTheme.tabbarBorderColor
                            radius: 8
                        }

                        onSelectionStartChanged: {
                            richBinding.updateSelection(editor.selectionStart, editor.selectionEnd);
                            root.refreshFormatState();
                            root.dropImageSelectionUnlessHeld();
                        }
                        onSelectionEndChanged: {
                            richBinding.updateSelection(editor.selectionStart, editor.selectionEnd);
                            root.refreshFormatState();
                            root.dropImageSelectionUnlessHeld();
                        }
                        onCursorPositionChanged: {
                            richBinding.updateSelection(editor.selectionStart, editor.selectionEnd);
                            root.refreshFormatState();
                            cursorBroadcast.restart();
                        }
                        // The image may move when anything above it reflows.
                        onContentHeightChanged: {
                            root.refreshImageGeom();
                            root.scheduleSpellCheck();
                        }
                        onTextChanged: root.scheduleSpellCheck()
                        onWidthChanged: {
                            root.scheduleSpellCheck();
                            // An aligned image is placed from the room its
                            // paragraph has, which is what just changed.
                            richBinding.reflowAlignedImages();
                            root.refreshImageGeom();
                        }

                        Keys.onPressed: function (event) {
                            if (event.matches(StandardKey.Paste)) {
                                root.pasteFromClipboard();
                                event.accepted = true;
                            } else if (event.matches(StandardKey.Copy)) {
                                root.copySelection();
                                event.accepted = true;
                            } else if (event.matches(StandardKey.Cut)) {
                                root.copySelection();
                                if (!root.previewing)
                                    editor.remove(editor.selectionStart, editor.selectionEnd);
                                event.accepted = true;
                            } else if (event.matches(StandardKey.Bold) || event.matches(StandardKey.Italic)
                                       || event.matches(StandardKey.Underline)
                                       || (event.key === Qt.Key_X && event.modifiers === (Qt.ShiftModifier | Qt.AltModifier))) {
                                if (!root.previewing) {
                                    const attr = event.matches(StandardKey.Bold) ? "b"
                                               : event.matches(StandardKey.Italic) ? "i"
                                               : event.matches(StandardKey.Underline) ? "u" : "s";
                                    richBinding.toggleInline(attr, editor.selectionStart, editor.selectionEnd);
                                    root.refreshFormatState();
                                }
                                event.accepted = true;
                            }
                        }

                        // Dropping a picture, or a file holding one, inserts it where
                        // it was dropped rather than where the caret happens to be.
                        DropArea {
                            id: editorDropArea

                            anchors.fill: parent
                            enabled: !root.previewing
                            onEntered: function (drag) {
                                drag.accept(Qt.CopyAction);
                            }
                            onDropped: function (drop) {
                                root.insertDrop(drop, editor.positionAt(drop.x, drop.y));
                                drop.accept(Qt.CopyAction);
                            }
                        }

                        // Says where a drop would land, so it is not a leap of faith.
                        Rectangle {
                            anchors.fill: parent
                            visible: editorDropArea.containsDrag
                            color: "transparent"
                            border.width: 2
                            border.color: JamiTheme.tintedBlue
                            radius: 4
                        }

                        // Red underline under the words the spell checker rejects.
                        Repeater {
                            model: root.misspellings
                            delegate: Rectangle {
                                required property var modelData
                                readonly property rect from: editor.positionToRectangle(modelData.start)
                                readonly property rect to: editor.positionToRectangle(modelData.end)

                                x: Math.min(from.x, to.x)
                                y: from.y + from.height - 2
                                width: Math.max(4, Math.abs(to.x - from.x))
                                height: 2
                                color: JamiTheme.redColor
                            }
                        }

                        // Right-click opens the context menu (declared at window root to
                        // avoid nesting a Menu inside the TextArea/Flickable content).
                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: function (eventPoint) {
                                root.prepareSpellMenu(eventPoint.position);
                                editorMenu.popup(editor, eventPoint.position.x, eventPoint.position.y);
                            }
                        }

                        // Clicking an image selects it, so it can be resized. Any
                        // other press is handed straight back to the editor:
                        // refusing it here is what keeps selecting text, placing
                        // the caret and dragging a selection working as before.
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            propagateComposedEvents: true
                            onPressed: function (mouse) {
                                var unit = richBinding.imageAtPoint(mouse.x - editor.leftPadding, mouse.y - editor.topPadding);
                                if (unit < 0 || root.previewing) {
                                    root.selectImageAt(-1);
                                    mouse.accepted = false;
                                    return;
                                }
                                editor.forceActiveFocus();
                                root.selectImageAt(unit);
                                mouse.accepted = true;
                            }
                        }

                        // Frame and corner handles of the selected image.
                        Item {
                            id: imageHandles

                            visible: root.imageGeom !== null && !root.previewing
                            // Document coordinates plus the editor's padding: the
                            // document is laid out inside it.
                            x: (root.imageGeom ? root.imageGeom.x : 0) + editor.leftPadding
                            y: (root.imageGeom ? root.imageGeom.y : 0) + editor.topPadding
                            width: root.imageGeom ? root.imageGeom.width : 0
                            height: root.imageGeom ? root.imageGeom.height : 0

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.width: 1
                                border.color: JamiTheme.buttonTintedBlue
                            }

                            Repeater {
                                model: 4
                                delegate: Rectangle {
                                    // 0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right
                                    required property int index

                                    readonly property bool atRight: index === 1 || index === 3
                                    readonly property bool atBottom: index >= 2

                                    width: 9
                                    height: 9
                                    radius: 2
                                    color: JamiTheme.buttonTintedBlue
                                    border.width: 1
                                    border.color: "white"
                                    x: atRight ? imageHandles.width - width / 2 : -width / 2
                                    y: atBottom ? imageHandles.height - height / 2 : -height / 2

                                    MouseArea {
                                        anchors.fill: parent
                                        // Easier to catch than the 9 px square.
                                        anchors.margins: -6
                                        cursorShape: (parent.atRight === parent.atBottom) ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                                        preventStealing: true

                                        property real grabX: 0
                                        property real grabWidth: 0

                                        onPressed: function (mouse) {
                                            grabX = mapToItem(editor, mouse.x, mouse.y).x;
                                            grabWidth = imageHandles.width;
                                        }
                                        onPositionChanged: function (mouse) {
                                            if (!pressed || root.selectedImage < 0)
                                                return;
                                            var moved = mapToItem(editor, mouse.x, mouse.y).x - grabX;
                                            // Dragging a left handle outwards means leftwards.
                                            var wanted = grabWidth + (parent.atRight ? moved : -moved);
                                            // Shown at once, told to the others only
                                            // on release: a delta per pixel would
                                            // flood the swarm for nothing.
                                            richBinding.previewImageWidth(root.selectedImage, Math.round(wanted));
                                            root.refreshImageGeom();
                                        }
                                        onReleased: {
                                            if (root.selectedImage < 0 || !root.imageGeom)
                                                return;
                                            richBinding.setImageWidth(root.selectedImage, Math.round(root.imageGeom.width));
                                            root.refreshImageGeom();
                                        }
                                        // A grab can be taken away -- the window
                                        // loses focus, another item claims the
                                        // mouse -- and then no release ever comes.
                                        // The preview has already changed this
                                        // document, so leaving it there would be a
                                        // width only this replica knows about:
                                        // silent divergence, which is the one thing
                                        // this editor must never produce. Put it
                                        // back where the drag started.
                                        onCanceled: {
                                            if (root.selectedImage < 0)
                                                return;
                                            richBinding.previewImageWidth(root.selectedImage, Math.round(grabWidth));
                                            root.refreshImageGeom();
                                        }
                                    }
                                }
                            }
                        }

                        // Remote participants' carets, drawn over the text.
                        Repeater {
                            model: remoteCursorsModel
                            delegate: Item {
                                property rect caret: {
                                    richBinding.revision; // the text moved...
                                    editor.width;         // ...or the editor did
                                    var p = Math.max(0, Math.min(position, editor.length));
                                    return editor.positionToRectangle(p);
                                }
                                x: caret.x
                                y: caret.y
                                width: 2
                                height: caret.height > 0 ? caret.height : editor.font.pixelSize
                                Rectangle {
                                    anchors.fill: parent
                                    color: pColor
                                }
                                Rectangle {
                                    id: flag
                                    // Above the caret, except on the first line:
                                    // there the label would be laid out at a
                                    // negative y and clipped away, which is to
                                    // say the peer editing the first line was
                                    // the one peer whose name never showed.
                                    property bool above: parent.y >= height
                                    anchors.bottom: flag.above ? parent.top : undefined
                                    anchors.top: flag.above ? undefined : parent.bottom
                                    anchors.left: parent.left
                                    width: flagText.implicitWidth + 6
                                    height: flagText.implicitHeight + 2
                                    radius: 3
                                    color: pColor
                                    Text {
                                        id: flagText
                                        anchors.centerIn: parent
                                        text: name !== "" ? name : JamiStrings.someone
                                        color: "white"
                                        font.pointSize: JamiTheme.tinyFontSize
                                    }
                                }
                            }
                        }
                    }
                }

                // Read-only rendering of the selected past version, opaque so
                // the editor underneath is neither seen nor reachable.
                Rectangle {
                    anchors.fill: parent
                    visible: root.previewing
                    color: JamiTheme.backgroundColor

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        onWheel: function (wheel) {
                            wheel.accepted = false;
                        }
                    }

                    ScrollView {
                        anchors.fill: parent
                        clip: true

                        TextArea {
                            padding: 10
                            readOnly: true
                            // A checkpoint holds text, not markup: rendering it as
                            // rich text would obey tags a peer wrote, down to
                            // fetching an <img> from a URL of their choosing.
                            textFormat: TextEdit.PlainText
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            font.pointSize: root.baseFontSize
                            color: JamiTheme.faddedFontColor
                            text: root.previewText
                            background: Rectangle {
                                color: JamiTheme.secondaryBackgroundColor
                                border.width: 1
                                border.color: JamiTheme.tabbarBorderColor
                                radius: 8
                            }
                        }
                    }
                }

                // What the CRDT actually holds, as a Quill delta -- the text the
                // peers exchange, before any of it is turned into a
                // QTextDocument. This is where a document that looks different
                // on two machines says which of the two is wrong.
                Rectangle {
                    anchors.fill: parent
                    visible: root.showingRaw
                    color: JamiTheme.backgroundColor

                    ScrollView {
                        anchors.fill: parent
                        clip: true

                        TextArea {
                            padding: 10
                            readOnly: true
                            textFormat: TextEdit.PlainText
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            font.family: "monospace"
                            font.pointSize: JamiTheme.smallFontSize
                            color: JamiTheme.textColor
                            // Asked again after every change to the document, so
                            // it is watched live rather than sampled when opened.
                            text: {
                                richBinding.revision;
                                return root.showingRaw ? CollaborativeAdapter.contentDelta(root.accountId, root.conversationId, root.documentId) : "";
                            }
                            background: Rectangle {
                                color: JamiTheme.secondaryBackgroundColor
                                border.width: 1
                                border.color: JamiTheme.tabbarBorderColor
                                radius: 8
                            }
                        }
                    }
                }
            }

            CollabHistoryPanel {
                id: historyPanel

                Layout.preferredWidth: 220
                Layout.fillHeight: true
                visible: false
                accountId: root.accountId
                conversationId: root.conversationId
                documentId: root.documentId

                onPreviewRequested: function (commitId, text) {
                    root.previewText = text;
                    root.previewing = true;
                }
                onPreviewCleared: {
                    root.previewing = false;
                    root.previewText = "";
                    root.focusEditor();
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            SettingParaCombobox {
                id: languageButton
                objectName: "languageButton"

                Layout.preferredWidth: 204
                enabled: !root.previewing
                leadingIconSource: JamiResources.spellcheck_outline_24dp_svg
                model: root.spellLanguageChoices.concat([{
                    "label": JamiStrings.dictionaryManager
                }])
                textRole: "label"
                currentIndex: root.spellLanguageChoices.findIndex(choice => choice.id === root.currentLanguage)
                currentSelectionText: root.languageLabel(root.currentLanguage)
                tooltipText: JamiStrings.spellingLanguage
                onActivated: {
                    if (currentIndex === root.spellLanguageChoices.length) {
                        root.openDictionaryManager();
                        currentIndex = Qt.binding(function () {
                            return root.spellLanguageChoices.findIndex(choice => choice.id === root.currentLanguage);
                        });
                    } else {
                        root.chooseLanguage(model[currentIndex].id);
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            NewIconButton {
                id: exportButton

                Layout.alignment: Qt.AlignVCenter
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.file_export_24dp_svg
                toolTipText: JamiStrings.exportLocalCopy
                // Export writes the live document, not the preview on screen.
                enabled: !root.previewing
                opacity: enabled ? 1.0 : 0.4
                onClicked: exportMenu.popup(exportButton, 0, -exportMenu.height)
            }

            NewIconButton {
                Layout.alignment: Qt.AlignVCenter
                iconSize: JamiTheme.iconButtonSmall
                iconSource: JamiResources.time_clock_svg
                toolTipText: JamiStrings.versionHistory
                checkable: true
                checked: historyPanel.visible
                onClicked: {
                    historyPanel.visible = !historyPanel.visible;
                    if (!historyPanel.visible)
                        historyPanel.clearPreview();
                }
            }
        }
    }

    BaseModalDialog {
        id: linkPopup
        anchors.centerIn: Overlay.overlay

        property string linkUrl: ""
        property int savedStart: 0
        property int savedEnd: 0

        function applyLink(removeLink) {
            Qt.inputMethod.commit();
            Qt.inputMethod.reset();
            const url = removeLink ? "" : linkUrl.trim();
            if (!removeLink && url.length === 0)
                return;
            richBinding.setLink(url, savedStart, savedEnd);
            root.refreshFormatState();
            close();
        }

        titleText: JamiStrings.linkUrl
        button1.text: JamiStrings.apply
        button1Role: DialogButtonBox.AcceptRole
        button1.enabled: linkUrl.trim().length > 0
        button1.onClicked: applyLink(false)
        button2.text: root.fmt.link !== undefined && root.fmt.link !== "" ? JamiStrings.optionRemove : ""
        button2Role: DialogButtonBox.DestructiveRole
        button2.onClicked: applyLink(true)

        onAboutToShow: {
            savedStart = editor.selectionStart;
            savedEnd = editor.selectionEnd;
            linkUrl = root.fmt.link !== undefined ? root.fmt.link : "";
        }
        onClosed: root.focusEditor()

        popupContent: ColumnLayout {
            width: 320
            spacing: JamiTheme.preferredMarginSize

            Component.onCompleted: linkField.forceTextFieldActiveFocus()

            Connections {
                target: linkPopup
                function onOpened() {
                    linkField.forceTextFieldActiveFocus();
                }
            }

            NewMaterialTextField {
                id: linkField

                Layout.fillWidth: true
                leadingIconSource: JamiResources.link_web_black_24dp_svg
                textFieldContent: linkPopup.linkUrl
                placeholderText: "https://"
                onModifiedTextFieldContentChanged: linkPopup.linkUrl = modifiedTextFieldContent
                onAccepted: linkPopup.applyLink(false)
            }
        }
    }

    // Spelling language chooser (declared at the window root for the same reason
    // as editorMenu).
    BaseContextMenu {
        id: languageMenu
        objectName: "languageMenu"
        Instantiator {
            model: root.spellLanguageChoices
            delegate: GeneralMenuItem {
                id: languageItem
                required property var modelData
                objectName: "language-" + (modelData.id || "default")
                itemName: modelData.label
                parentMenu: languageMenu
                checkable: true
                checked: root.currentLanguage === modelData.id
                bold: checked
                onClicked: {
                    root.chooseLanguage(modelData.id);
                    languageItem.checked = Qt.binding(function () {
                        return root.currentLanguage === languageItem.modelData.id;
                    });
                }
            }
            onObjectAdded: (index, object) => languageMenu.insertItem(index, object)
            onObjectRemoved: (index, object) => languageMenu.removeItem(object)
        }
        GeneralMenuSeparator {}
        GeneralMenuItem {
            objectName: "installDictionaries"
            itemName: JamiStrings.dictionaryManager
            iconSource: JamiResources.dictionary_24dp_svg
            parentMenu: languageMenu
            onClicked: root.openDictionaryManager()
        }
    }

    // Context menu for the editor (declared at the window root, not nested inside
    // the TextArea, to avoid a QtQuick.Templates crash on popup).
    BaseContextMenu {
        id: editorMenu
        objectName: "editorContextMenu"

        Instantiator {
            model: root.spellSuggestions
            delegate: GeneralMenuItem {
                required property string modelData
                itemName: modelData
                bold: true
                isActif: !root.previewing
                parentMenu: editorMenu
                onClicked: {
                    richBinding.insertText(root.spellTarget.start, root.spellTarget.end, modelData);
                    root.scheduleSpellCheck();
                }
            }
            onObjectAdded: (index, object) => editorMenu.insertItem(index, object)
            onObjectRemoved: (index, object) => editorMenu.removeItem(object)
        }

        GeneralMenuSeparator {
            visible: root.spellSuggestions.length > 0
            height: visible ? implicitHeight : 0
        }

        property list<GeneralMenuItem> menuItems: [
            GeneralMenuItem {
                itemName: JamiStrings.spellingLanguageMenu
                iconSource: JamiResources.spellcheck_24dp_svg
                isActif: !root.previewing
                onClicked: Qt.callLater(function () {
                    languageMenu.popup();
                })
            },
            GeneralMenuItem {
                itemName: JamiStrings.cut
                iconSource: JamiResources.content_cut_24dp_svg
                isActif: !root.previewing && editor.selectedText.length > 0
                onClicked: {
                    root.copySelection();
                    editor.remove(editor.selectionStart, editor.selectionEnd);
                }
            },
            GeneralMenuItem {
                itemName: JamiStrings.copy
                iconSource: JamiResources.content_copy_24dp_svg
                isActif: editor.selectedText.length > 0
                onClicked: root.copySelection()
            },
            GeneralMenuItem {
                itemName: JamiStrings.paste
                iconSource: JamiResources.content_paste_24dp_svg
                isActif: !root.previewing && (editor.canPaste || richBinding.clipboardHasImage)
                onClicked: root.pasteFromClipboard()
            }
        ]

        Component.onCompleted: loadMenuItems(menuItems)
    }

    // Local export. Declared at the window root for the same reason as
    // editorMenu.
    BaseContextMenu {
        id: exportMenu

        property list<GeneralMenuItem> menuItems: [
            GeneralMenuItem {
                itemName: JamiStrings.exportAsPdf
                iconSource: JamiResources.pdf_24dp_svg
                text: itemName
                canTrigger: richBinding.canExportAs("pdf")
                onClicked: root.exportDocument("pdf", JamiStrings.pdfDocument)
            },
            GeneralMenuItem {
                itemName: JamiStrings.exportAsOdt
                iconSource: JamiResources.odt_24dp_svg
                text: itemName
                canTrigger: richBinding.canExportAs("odt")
                onClicked: root.exportDocument("odt", JamiStrings.openDocumentText)
            },
            GeneralMenuItem {
                itemName: JamiStrings.exportAsHtml
                iconSource: JamiResources.html_24dp_svg
                text: itemName
                canTrigger: richBinding.canExportAs("html")
                onClicked: root.exportDocument("html", JamiStrings.htmlDocument)
            },
            GeneralMenuItem {
                itemName: JamiStrings.exportAsMarkdown
                iconSource: JamiResources.markdown_24dp_svg
                text: itemName
                canTrigger: richBinding.canExportAs("md")
                onClicked: root.exportDocument("md", JamiStrings.markdownDocument)
            },
            GeneralMenuItem {
                itemName: JamiStrings.exportAsPlainText
                iconSource: JamiResources.abc_24dp_svg
                text: itemName
                canTrigger: richBinding.canExportAs("txt")
                onClicked: root.exportDocument("txt", JamiStrings.plainTextDocument)
            }
        ]

        Component.onCompleted: loadMenuItems(menuItems)
    }

}
