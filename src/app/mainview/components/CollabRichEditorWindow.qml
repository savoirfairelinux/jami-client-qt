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

    property string conversationId: ""
    property string documentId: ""
    property string documentName: ""
    property string peerName: ""

    // Cached formatting state of the current selection, driving the toolbar.
    property var fmt: ({})
    // Editor base font size (local view preference; headings scale relative to it).
    property int baseFontSize: JamiTheme.textFontSize

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

    function upsertCursor(peerId, pos) {
        for (var i = 0; i < remoteCursorsModel.count; ++i) {
            if (remoteCursorsModel.get(i).peerId === peerId) {
                remoteCursorsModel.setProperty(i, "position", pos);
                return;
            }
        }
        remoteCursorsModel.append({
            "peerId": peerId,
            "name": UtilsAdapter.getBestNameForUri(CurrentAccount.id, peerId),
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
        onTriggered: CollaborativeAdapter.setCursor(root.conversationId, root.documentId,
                                                    editor.cursorPosition, editor.selectionStart)
    }

    // Toolbar button: a small toggleable glyph button.
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
        CollaborativeAdapter.openDocument(conversationId, documentId);
        richBinding.loadContentDelta(CollaborativeAdapter.contentDelta(conversationId, documentId));
        refreshFormatState();
    }
    onClosing: CollaborativeAdapter.closeDocument(conversationId, documentId)

    function focusEditor() {
        editor.forceActiveFocus();
        Qt.callLater(function () {
            editor.forceActiveFocus();
        });
    }

    Connections {
        target: CollaborativeAdapter

        function onDocumentDelta(convId, docId, deltaJson) {
            if (convId !== root.conversationId || docId !== root.documentId)
                return;
            richBinding.applyRemoteDelta(deltaJson);
            root.refreshFormatState();
        }

        function onDocumentRenamed(convId, docId, name) {
            if (convId === root.conversationId && docId === root.documentId)
                root.documentName = name;
        }

        function onCursorChanged(convId, docId, peerId, pos, anchor) {
            if (convId === root.conversationId && docId === root.documentId)
                root.upsertCursor(peerId, pos);
        }

        function onParticipantLeft(convId, docId, peerId) {
            if (convId === root.conversationId && docId === root.documentId)
                root.removeCursor(peerId);
        }
    }

    // Bridges the editor's QTextDocument to the collaborative CRDT.
    CollabRichBinding {
        id: richBinding
        textDocument: editor.textDocument
        onLocalDelta: function (deltaJson) {
            CollaborativeAdapter.applyDelta(root.conversationId, root.documentId, deltaJson);
        }
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
                        CollaborativeAdapter.setName(root.conversationId, root.documentId, newName);
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
                glyph: "B"
                active: root.fmt.b === true
                onClicked: {
                    richBinding.toggleInline("b", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
                glyph: "I"
                active: root.fmt.i === true
                onClicked: {
                    richBinding.toggleInline("i", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
                glyph: "U"
                active: root.fmt.u === true
                onClicked: {
                    richBinding.toggleInline("u", editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
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
                glyph: "H1"
                active: root.fmt.header === 1
                onClicked: {
                    richBinding.setHeading(root.fmt.header === 1 ? 0 : 1, editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
                glyph: "H2"
                active: root.fmt.header === 2
                onClicked: {
                    richBinding.setHeading(root.fmt.header === 2 ? 0 : 2, editor.selectionStart, editor.selectionEnd);
                    root.refreshFormatState();
                    editor.forceActiveFocus();
                }
            }
            FormatButton {
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

            FormatButton {
                glyph: "🔗"
                active: root.fmt.link !== undefined && root.fmt.link !== ""
                onClicked: {
                    linkField.text = (root.fmt.link !== undefined ? root.fmt.link : "");
                    linkPopup.open();
                }
            }
            FormatButton {
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
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: editor

                padding: 10
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

                onSelectionStartChanged: root.refreshFormatState()
                onSelectionEndChanged: root.refreshFormatState()
                onCursorPositionChanged: {
                    root.refreshFormatState();
                    cursorBroadcast.restart();
                }

                // Intercept paste so it inserts sanitized plain text (rich
                // clipboard styling would otherwise render only locally and diverge
                // from what peers receive).
                Keys.onPressed: function (event) {
                    if (event.matches(StandardKey.Paste)) {
                        richBinding.pasteText(editor.selectionStart, editor.selectionEnd);
                        event.accepted = true;
                    }
                }

                // Right-click opens the context menu (declared at window root to
                // avoid nesting a Menu inside the TextArea/Flickable content).
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: editorMenu.popup()
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
            enabled: editor.canPaste
            onTriggered: richBinding.pasteText(editor.selectionStart, editor.selectionEnd)
        }
        MenuItem {
            text: qsTr("Delete")
            enabled: editor.selectedText.length > 0
            onTriggered: editor.remove(editor.selectionStart, editor.selectionEnd)
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
