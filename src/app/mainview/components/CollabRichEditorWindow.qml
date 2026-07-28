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
import "../../commoncomponents"

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
    property string peerName: ""

    // Cached formatting state of the current selection, driving the toolbar.
    property var fmt: ({})
    // Editor base font size (local view preference; headings scale relative to it).
    property int baseFontSize: JamiTheme.textFontSize

    // Read-only review of a past version. Only the text is replayed: character
    // formatting is not part of what a checkpoint restores.
    property bool previewing: false
    property string previewText: ""

    title: (documentName !== "" ? documentName : qsTr("Editable document"))
           + (peerName !== "" ? " — " + peerName : "")
           + " — " + JamiStrings.appTitle
    width: 720
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

    function upsertCursor(peerId, pos) {
        for (var i = 0; i < remoteCursorsModel.count; ++i) {
            var entry = remoteCursorsModel.get(i);
            if (entry.peerId === peerId) {
                remoteCursorsModel.setProperty(i, "position", pos);
                remoteCursorsModel.setProperty(i, "name", root.displayNameFor(peerId, entry.name));
                return;
            }
        }
        remoteCursorsModel.append({
            "peerId": peerId,
            "name": root.displayNameFor(peerId, ""),
            "pColor": colorForPeer(peerId),
            "position": pos
        });
    }

    function removeCursor(peerId) {
        for (var i = 0; i < remoteCursorsModel.count; ++i) {
            if (remoteCursorsModel.get(i).peerId === peerId) {
                remoteCursorsModel.remove(i);
                return;
            }
        }
    }

    ListModel {
        id: remoteCursorsModel
    }

    // Coalesce rapid local cursor moves into a single broadcast.
    Timer {
        id: cursorBroadcast
        interval: 120
        repeat: false
        onTriggered: CollaborativeAdapter.setCursor(root.accountId, root.conversationId, root.documentId,
                                                    editor.cursorPosition, editor.selectionStart)
    }

    // Toolbar button: a small toggleable glyph button.
    // Alignment has no letter to stand for it, and the client ships no icon for
    // it, so it is drawn: four lines of text, set the way the paragraph would be.
    // Justified is the one with every line full.
    component AlignGlyph: Item {
        id: alignGlyph

        property int align: Qt.AlignLeft
        property color lineColor: JamiTheme.textColor

        implicitWidth: 16
        implicitHeight: 17

        Column {
            anchors.centerIn: parent
            width: 16
            spacing: 3
            Repeater {
                model: [0, 1, 2, 3]
                delegate: Rectangle {
                    required property int index

                    // Justified text is flush on both sides, save for the last line.
                    readonly property real ratio: alignGlyph.align === Qt.AlignJustify ? (index === 3 ? 0.6 : 1.0) : (index % 2 === 0 ? 1.0 : 0.6)

                    width: 16 * ratio
                    height: 2
                    radius: 1
                    color: alignGlyph.lineColor
                    x: alignGlyph.align === Qt.AlignRight ? 16 - width : (alignGlyph.align === Qt.AlignHCenter ? (16 - width) / 2 : 0)
                }
            }
        }
    }

    component FormatButton: AbstractButton {
        id: fmtBtn
        property string glyph: ""
        property bool active: false
        implicitWidth: 34
        implicitHeight: 30
        background: Rectangle {
            radius: 6
            color: fmtBtn.active ? JamiTheme.tintedBlue
                                 : (fmtBtn.hovered ? JamiTheme.hoveredButtonColor : "transparent")
            border.width: 1
            border.color: JamiTheme.tabbarBorderColor
        }
        contentItem: Text {
            text: fmtBtn.glyph
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: fmtBtn.active ? "white" : JamiTheme.textColor
            font.pointSize: JamiTheme.textFontSize
            font.bold: fmtBtn.glyph === "B"
            font.italic: fmtBtn.glyph === "I"
            font.underline: fmtBtn.glyph === "U"
            font.strikeout: fmtBtn.glyph === "S"
        }
    }

    Component.onCompleted: {
        // Ensure the daemon session exists, then render the current content.
        CollaborativeAdapter.openDocument(accountId, conversationId, documentId);
        richBinding.loadContentDelta(CollaborativeAdapter.contentDelta(accountId, conversationId, documentId));
        refreshFormatState();
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
            root.refreshFormatState();
            // A peer may have moved or resized the selected image.
            root.dropImageSelectionUnlessHeld();
            root.refreshImageGeom();
        }

        function onDocumentRenamed(accId, convId, docId, name) {
            if (accId === root.accountId && convId === root.conversationId && docId === root.documentId)
                root.documentName = name;
        }

        function onCursorChanged(accId, convId, docId, peerId, pos, anchor) {
            if (accId === root.accountId && convId === root.conversationId && docId === root.documentId)
                root.upsertCursor(peerId, pos);
        }

        function onAttachmentAdded(accId, convId, docId, attachmentId) {
            if (accId === root.accountId && convId === root.conversationId && docId === root.documentId && richBinding.referencesAttachment(attachmentId))
                CollaborativeAdapter.deliverAttachment(accId, convId, docId, attachmentId, richBinding);
        }

        function onParticipantLeft(accId, convId, docId, peerId) {
            if (accId === root.accountId && convId === root.conversationId && docId === root.documentId)
                root.removeCursor(peerId);
        }
    }

    // Store the picked file with the document, then place it where the caret is.
    // The bytes are registered before the image exists in the document so the
    // layout measures it on the first pass instead of drawing a broken box.
    // Alignment of the paragraph under the caret. Left is stored as no attribute
    // at all, so an empty answer means left.
    readonly property string currentAlign: (root.fmt.align !== undefined && root.fmt.align !== "") ? root.fmt.align : "left"

    function alignmentOf(style) {
        if (style === "center")
            return Qt.AlignHCenter;
        if (style === "right")
            return Qt.AlignRight;
        if (style === "justify")
            return Qt.AlignJustify;
        return Qt.AlignLeft;
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

    // The picker is built on demand, never declared here: JamiFileDialog counts
    // its instances from Component.onCompleted, and the main window veils itself
    // while that count is above zero. A picker standing by in this window would
    // hold the main window hostage for as long as the document stays open.
    function pickImage() {
        if (typeof viewCoordinator === "undefined")
            return;
        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                "title": qsTr("Insert image"),
                "mode": JamiFileDialog.Mode.OpenFile,
                "nameFilters": [qsTr("Images") + " (*.png *.jpg *.jpeg *.gif *.bmp *.webp)"]
            }, true);
        dlg.fileAccepted.connect(function (file) {
                root.insertImageFromFile(file);
            });
    }

    function insertImageFromFile(file) {
        const info = CollaborativeAdapter.addAttachment(root.accountId, root.conversationId, root.documentId, file);
        if (!info || !info.id) {
            root.attachmentError = qsTr("This image could not be added. It has to be an image of at most 16 MB.");
            attachmentErrorTimer.restart();
            return;
        }
        root.attachmentError = "";
        CollaborativeAdapter.deliverAttachment(root.accountId, root.conversationId, root.documentId, info.id, richBinding);
        richBinding.insertImage(editor.cursorPosition, info.id, info.width !== undefined ? info.width : 0, 0);
        editor.forceActiveFocus();
    }

    // Pasting inserts whatever the clipboard holds: a picture if there is one,
    // sanitized plain text otherwise.
    function pasteFromClipboard() {
        if (root.previewing)
            return;
        if (!richBinding.clipboardHasImage()) {
            richBinding.pasteText(editor.selectionStart, editor.selectionEnd);
            return;
        }
        const info = CollaborativeAdapter.addAttachmentFromClipboard(root.accountId, root.conversationId, root.documentId);
        if (!info || !info.id) {
            root.attachmentError = qsTr("This image could not be added. It has to be an image of at most 16 MB.");
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
        if (drop.hasUrls) {
            // A file was dropped and it is not a picture. Inserting its path as
            // text would be a strange answer to the gesture.
            root.attachmentError = qsTr("This image could not be added. It has to be an image of at most 16 MB.");
            attachmentErrorTimer.restart();
            return;
        }
        if (drop.hasText && drop.text.length > 0) {
            richBinding.insertText(position, position, drop.text);
            editor.forceActiveFocus();
        }
    }

    // Bridges the editor's QTextDocument to the collaborative CRDT.
    CollabRichBinding {
        id: richBinding

        // How wide an image may be dragged. Read from the editor rather than
        // from the document: the document's own text width follows its
        // contents, so it would shrink around a narrow document and refuse to
        // let any image be made wider than the text already is.
        viewWidth: editor.width - editor.leftPadding - editor.rightPadding
        textDocument: editor.textDocument
        onLocalDelta: function (deltaJson) {
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
        anchors.margins: JamiTheme.preferredMarginSize
        spacing: JamiTheme.preferredMarginSize

        // Title and formatting controls on one row: the editable document name on
        // the left (click to rename), the formatting controls on the right.
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Item {
                id: titleContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 30

                property bool editing: false

                function commitRename() {
                    var newName = nameField.text.trim();
                    if (newName !== "" && newName !== root.documentName) {
                        root.documentName = newName;
                        CollaborativeAdapter.setName(root.accountId, root.conversationId, root.documentId, newName);
                    }
                    titleContainer.editing = false;
                }

                Text {
                    anchors.fill: parent
                    visible: !titleContainer.editing
                    verticalAlignment: Text.AlignVCenter
                    text: root.documentName !== "" ? root.documentName : qsTr("Untitled document")
                    elide: Text.ElideRight
                    font.pointSize: JamiTheme.title2FontSize
                    font.bold: true
                    color: JamiTheme.textColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        ToolTip.visible: containsMouse
                        ToolTip.text: qsTr("Click to rename")
                        onClicked: {
                            nameField.text = root.documentName;
                            titleContainer.editing = true;
                            nameField.forceActiveFocus();
                            nameField.selectAll();
                        }
                    }
                }

                TextField {
                    id: nameField
                    anchors.fill: parent
                    visible: titleContainer.editing
                    font.pointSize: JamiTheme.title2FontSize
                    font.bold: true
                    color: JamiTheme.textColor
                    placeholderText: qsTr("Document name")
                    onAccepted: titleContainer.commitRename()
                    onActiveFocusChanged: {
                        if (!activeFocus && titleContainer.editing)
                            titleContainer.commitRename();
                    }
                    Keys.onEscapePressed: titleContainer.editing = false
                }
            }

            FormatButton {
                enabled: !root.previewing
                glyph: "B"
                active: root.fmt.b === true
                onClicked: {
                    richBinding.toggleInline("b", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
                enabled: !root.previewing
                glyph: "I"
                active: root.fmt.i === true
                onClicked: {
                    richBinding.toggleInline("i", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
                enabled: !root.previewing
                glyph: "U"
                active: root.fmt.u === true
                onClicked: {
                    richBinding.toggleInline("u", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
                enabled: !root.previewing
                glyph: "S"
                active: root.fmt.s === true
                onClicked: {
                    richBinding.toggleInline("s", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                color: JamiTheme.tabbarBorderColor
            }

            FormatButton {
                enabled: !root.previewing
                glyph: "H1"
                active: root.fmt.header === 1
                onClicked: {
                    richBinding.setHeading(root.fmt.header === 1 ? 0 : 1, editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
                enabled: !root.previewing
                glyph: "H2"
                active: root.fmt.header === 2
                onClicked: {
                    richBinding.setHeading(root.fmt.header === 2 ? 0 : 2, editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
                enabled: !root.previewing
                glyph: "H3"
                active: root.fmt.header === 3
                onClicked: {
                    richBinding.setHeading(root.fmt.header === 3 ? 0 : 3, editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                color: JamiTheme.tabbarBorderColor
            }

            FormatButton {
                enabled: !root.previewing
                glyph: "•"
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Bulleted list")
                active: root.fmt.list === "bullet"
                onClicked: {
                    richBinding.setList("bullet", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
                enabled: !root.previewing
                glyph: "1."
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Numbered list")
                active: root.fmt.list === "ordered"
                onClicked: {
                    richBinding.setList("ordered", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                color: JamiTheme.tabbarBorderColor
            }

            // Alignment applies to whole paragraphs, so it needs no selection: the
            // caret is enough to say which one is meant. Opens a root-level Menu,
            // for the same reason as the font size chooser.
            AbstractButton {
                id: alignButton

                enabled: !root.previewing
                Layout.preferredWidth: 46
                Layout.preferredHeight: 30
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Paragraph alignment")
                background: Rectangle {
                    radius: 6
                    color: alignButton.hovered ? JamiTheme.hoveredButtonColor : "transparent"
                    border.width: 1
                    border.color: JamiTheme.tabbarBorderColor
                }
                contentItem: Row {
                    spacing: 3
                    AlignGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        // Shows what the paragraph under the caret is doing.
                        align: root.alignmentOf(root.currentAlign)
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "▾"
                        color: JamiTheme.textColor
                        font.pointSize: JamiTheme.textFontSize
                    }
                }
                onClicked: alignMenu.popup(alignButton, 0, alignButton.height)
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                color: JamiTheme.tabbarBorderColor
            }

            FormatButton {
                enabled: !root.previewing
                glyph: "🔗"
                active: root.fmt.link !== undefined && root.fmt.link !== ""
                onClicked: {
                    linkField.text = (root.fmt.link !== undefined ? root.fmt.link : "");
                    linkPopup.open();
                }
            }
            FormatButton {
                enabled: !root.previewing
                glyph: "🖼"
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Insert image")
                onClicked: root.pickImage()
            }
            FormatButton {
                enabled: !root.previewing
                glyph: "⌫"
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Clear formatting")
                onClicked: {
                    richBinding.clearFormat(editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                color: JamiTheme.tabbarBorderColor
            }

            // Base font size of the editor (a local view preference). Opens a
            // root-level Menu (a ComboBox's deferred popup crashes in this Window).
            AbstractButton {
                id: fontSizeButton
                Layout.preferredWidth: 56
                Layout.preferredHeight: 30
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Base font size")
                background: Rectangle {
                    radius: 6
                    color: fontSizeButton.hovered ? JamiTheme.hoveredButtonColor : "transparent"
                    border.width: 1
                    border.color: JamiTheme.tabbarBorderColor
                }
                contentItem: Text {
                    text: root.baseFontSize + " ▾"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                }
                onClicked: fontSizeMenu.popup(fontSizeButton, 0, fontSizeButton.height)
            }

            PushButton {
                Layout.alignment: Qt.AlignVCenter
                preferredSize: 26
                imageContainerWidth: 18
                imageContainerHeight: 18
                source: JamiResources.time_clock_svg
                toolTipText: qsTr("Version history")
                checkable: true
                checked: historyPanel.visible
                normalColor: "transparent"
                imageColor: JamiTheme.textColor
                onClicked: {
                    historyPanel.visible = !historyPanel.visible;
                    if (!historyPanel.visible)
                        historyPanel.clearPreview();
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

        // Banner shown while reviewing a past version.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            visible: root.previewing
            radius: 6
            color: JamiTheme.secondaryBackgroundColor
            border.width: 1
            border.color: JamiTheme.buttonTintedBlue

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Viewing a past version — read only, without formatting")
                    font.pointSize: JamiTheme.smallFontSize
                    color: JamiTheme.textColor
                    elide: Text.ElideRight
                }
                MaterialButton {
                    secondary: true
                    text: qsTr("Back to current")
                    onClicked: historyPanel.clearPreview()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: JamiTheme.preferredMarginSize

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
                        placeholderText: qsTr("Start typing…")
                        background: Rectangle {
                            color: JamiTheme.secondaryBackgroundColor
                            border.width: 1
                            border.color: JamiTheme.tabbarBorderColor
                            radius: 8
                        }

                        onSelectionStartChanged: {
                            root.refreshFormatState();
                            root.dropImageSelectionUnlessHeld();
                        }
                        onSelectionEndChanged: {
                            root.refreshFormatState();
                            root.dropImageSelectionUnlessHeld();
                        }
                        onCursorPositionChanged: {
                            root.refreshFormatState();
                            cursorBroadcast.restart();
                        }
                        // The image may move when anything above it reflows.
                        onContentHeightChanged: root.refreshImageGeom()
                        onWidthChanged: root.refreshImageGeom()

                        // Intercept paste: a picture is stored with the document and
                        // referenced, and text is inserted sanitized (rich clipboard
                        // styling would otherwise render only locally and diverge from
                        // what peers receive).
                        Keys.onPressed: function (event) {
                            if (event.matches(StandardKey.Paste)) {
                                root.pasteFromClipboard();
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

                        // Right-click opens the context menu (declared at window root to
                        // avoid nesting a Menu inside the TextArea/Flickable content).
                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: editorMenu.popup()
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
                                var unit = richBinding.imageAtPoint(mouse.x - editor.leftPadding,
                                                                    mouse.y - editor.topPadding);
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
                                    }
                                }
                            }
                        }

                        // Remote participants' carets, drawn over the text.
                        Repeater {
                            model: remoteCursorsModel
                            delegate: Item {
                                property rect caret: {
                                    editor.text;
                                    editor.width;
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
                                    anchors.bottom: parent.top
                                    anchors.left: parent.left
                                    width: flagText.implicitWidth + 6
                                    height: flagText.implicitHeight + 2
                                    radius: 3
                                    color: pColor
                                    Text {
                                        id: flagText
                                        anchors.centerIn: parent
                                        text: name !== "" ? name : qsTr("Someone")
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
    }

    // Minimal URL entry for the link button.
    Popup {
        id: linkPopup
        anchors.centerIn: Overlay.overlay
        modal: true
        focus: true
        padding: JamiTheme.preferredMarginSize
        background: Rectangle {
            color: JamiTheme.backgroundColor
            border.width: 1
            border.color: JamiTheme.tabbarBorderColor
            radius: 8
        }

        property int savedStart: 0
        property int savedEnd: 0
        onAboutToShow: {
            savedStart = editor.selectionStart;
            savedEnd = editor.selectionEnd;
        }

        ColumnLayout {
            spacing: JamiTheme.preferredMarginSize

            Text {
                text: qsTr("Link URL")
                color: JamiTheme.textColor
                font.pointSize: JamiTheme.settingsFontSize
            }
            TextField {
                id: linkField
                Layout.preferredWidth: 320
                placeholderText: "https://"
                color: JamiTheme.textColor
                onAccepted: applyLinkButton.clicked()
                Component.onCompleted: forceActiveFocus()
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 6
                Button {
                    text: qsTr("Remove")
                    visible: root.fmt.link !== undefined && root.fmt.link !== ""
                    onClicked: {
                        richBinding.setLink("", linkPopup.savedStart, linkPopup.savedEnd);
                        root.refreshFormatState();
                        linkPopup.close();
                        editor.forceActiveFocus();
                    }
                }
                Button {
                    id: applyLinkButton
                    text: qsTr("Apply")
                    enabled: linkField.text.trim().length > 0
                    onClicked: {
                        richBinding.setLink(linkField.text.trim(), linkPopup.savedStart, linkPopup.savedEnd);
                        root.refreshFormatState();
                        linkPopup.close();
                        editor.forceActiveFocus();
                    }
                }
            }
        }
    }

    // Context menu for the editor (declared at the window root, not nested inside
    // the TextArea, to avoid a QtQuick.Templates crash on popup).
    Menu {
        id: editorMenu
        MenuItem {
            text: qsTr("Copy")
            enabled: editor.selectedText.length > 0
            onTriggered: editor.copy()
        }
        MenuItem {
            text: qsTr("Paste")
            // canPaste only knows about text, and a clipboard holding just a
            // picture would leave the entry greyed out.
            enabled: editor.canPaste || richBinding.clipboardHasImage()
            onTriggered: root.pasteFromClipboard()
        }
        MenuItem {
            text: qsTr("Delete")
            enabled: editor.selectedText.length > 0
            onTriggered: editor.remove(editor.selectionStart, editor.selectionEnd)
        }
    }

    // Paragraph alignment (declared at the window root for the same reason as
    // editorMenu: a nested/deferred popup crashes in this Window).
    Menu {
        id: alignMenu

        Repeater {
            model: [
                {
                    "style": "left",
                    "label": qsTr("Align left")
                },
                {
                    "style": "center",
                    "label": qsTr("Centre")
                },
                {
                    "style": "right",
                    "label": qsTr("Align right")
                },
                {
                    "style": "justify",
                    "label": qsTr("Justify")
                }
            ]
            delegate: MenuItem {
                required property var modelData

                text: modelData.label
                checkable: true
                checked: root.currentAlign === modelData.style
                onTriggered: {
                    richBinding.setAlign(modelData.style, editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
        }
    }

    // Base font size chooser (declared at the window root for the same reason as
    // editorMenu: a nested/deferred popup crashes in this Window).
    Menu {
        id: fontSizeMenu
        Repeater {
            model: [8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32]
            delegate: MenuItem {
                text: modelData
                checkable: true
                checked: root.baseFontSize === modelData
                onTriggered: root.baseFontSize = modelData
            }
        }
    }
}
