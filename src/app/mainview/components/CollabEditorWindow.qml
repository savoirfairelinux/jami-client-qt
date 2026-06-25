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

// Independent top-level window for real-time collaborative editing. Being a
// separate window (not a modal dialog), the user can keep editing while
// navigating between conversations in the main window. Remote participants'
// carets and presence are shown live.
Window {
    id: root

    property string conversationId: ""
    property string documentId: ""
    property string documentName: ""
    // Display name of the conversation (contact for a 1:1, group title otherwise),
    // captured when the window is opened and shown in the title bar.
    property string peerName: ""

    // Guards against treating a programmatic (remote) text change as a local edit.
    property bool applyingRemote: false
    property string previousText: ""

    title: (documentName !== "" ? documentName : qsTr("Editable document"))
           + (peerName !== "" ? " — " + peerName : "")
           + " — " + JamiStrings.appTitle
    width: 640
    height: 520
    minimumWidth: 360
    minimumHeight: 280
    color: JamiTheme.backgroundColor

    // Stable per-participant color derived from their id.
    function colorForPeer(peerId) {
        var h = 0;
        for (var i = 0; i < peerId.length; ++i)
            h = (h * 31 + peerId.charCodeAt(i)) % 360;
        return Qt.hsla(h / 360, 0.65, 0.5, 1.0);
    }

    // Compute the single contiguous change between two strings (UTF-16 units).
    function computeDiff(oldStr, newStr) {
        var start = 0;
        var oldEnd = oldStr.length;
        var newEnd = newStr.length;
        while (start < oldEnd && start < newEnd && oldStr.charCodeAt(start) === newStr.charCodeAt(start))
            start++;
        while (oldEnd > start && newEnd > start && oldStr.charCodeAt(oldEnd - 1) === newStr.charCodeAt(newEnd - 1)) {
            oldEnd--;
            newEnd--;
        }
        return {
            "index": start,
            "deleteLen": oldEnd - start,
            "insert": newStr.substring(start, newEnd)
        };
    }

    function loadInitialContent() {
        var initial = CollaborativeAdapter.openDocument(conversationId, documentId);
        applyingRemote = true;
        editor.text = initial;
        previousText = initial;
        applyingRemote = false;
    }

    function focusEditor() {
        editor.forceActiveFocus();
        Qt.callLater(function () {
            editor.forceActiveFocus();
        });
    }

    function upsertCursor(peerId, position, anchor) {
        for (var i = 0; i < remoteCursorsModel.count; ++i) {
            if (remoteCursorsModel.get(i).peerId === peerId) {
                remoteCursorsModel.setProperty(i, "position", position);
                remoteCursorsModel.setProperty(i, "anchor", anchor);
                return;
            }
        }
        remoteCursorsModel.append({
            "peerId": peerId,
            "name": UtilsAdapter.getBestNameForUri(CurrentAccount.id, peerId),
            "pColor": colorForPeer(peerId),
            "position": position,
            "anchor": anchor
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

    Component.onCompleted: loadInitialContent()
    onClosing: CollaborativeAdapter.closeDocument(conversationId, documentId)

    ListModel {
        id: remoteCursorsModel
    }

    Connections {
        target: CollaborativeAdapter

        function onDocumentChanged(convId, docId, index, deleteLen, insert) {
            if (convId !== root.conversationId || docId !== root.documentId)
                return;
            var t = editor.text;
            var newText = t.substring(0, index) + insert + t.substring(index + deleteLen);
            var cursor = editor.cursorPosition;
            root.applyingRemote = true;
            editor.text = newText;
            root.previousText = newText;
            // Keep the local caret stable relative to the remote edit.
            if (cursor >= index + deleteLen)
                cursor += insert.length - deleteLen;
            else if (cursor > index)
                cursor = index + insert.length;
            editor.cursorPosition = Math.max(0, Math.min(cursor, newText.length));
            root.applyingRemote = false;
        }

        function onCursorChanged(convId, docId, peerId, position, anchor) {
            if (convId !== root.conversationId || docId !== root.documentId)
                return;
            root.upsertCursor(peerId, position, anchor);
        }

        function onParticipantLeft(convId, docId, peerId) {
            if (convId !== root.conversationId || docId !== root.documentId)
                return;
            root.removeCursor(peerId);
        }

        function onDocumentRenamed(convId, docId, name) {
            if (convId !== root.conversationId || docId !== root.documentId)
                return;
            root.documentName = name;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: JamiTheme.preferredMarginSize
        spacing: JamiTheme.preferredMarginSize

        // Header: document name + presence of who is currently editing.
        RowLayout {
            Layout.fillWidth: true
            spacing: JamiTheme.preferredMarginSize

            ResponsiveImage {
                Layout.alignment: Qt.AlignVCenter
                source: JamiResources.round_edit_24dp_svg
                width: 24
                height: 24
                color: JamiTheme.textColor
            }
            // Editable document title: click the name to rename it. The new name
            // is a CRDT field, so it syncs to every member and persists.
            Item {
                id: titleContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                property bool editing: false

                function commitRename() {
                    var newName = nameField.text.trim();
                    if (newName !== "" && newName !== root.documentName) {
                        root.documentName = newName; // optimistic; daemon echoes it back
                        CollaborativeAdapter.setName(root.conversationId, root.documentId, newName);
                    }
                    titleContainer.editing = false;
                }

                Text {
                    id: titleLabel
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

            // Presence badges of remote editors.
            Row {
                spacing: 6
                Repeater {
                    model: remoteCursorsModel
                    delegate: Row {
                        spacing: 3
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: pColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: name !== "" ? name : qsTr("Someone")
                            color: JamiTheme.faddedFontColor
                            font.pointSize: JamiTheme.tinyFontSize
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: editor

                padding: 10
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                focus: true
                font.pointSize: JamiTheme.textFontSize
                color: JamiTheme.textColor
                placeholderText: qsTr("Start typing…")
                background: Rectangle {
                    color: JamiTheme.secondaryBackgroundColor
                    border.width: 1
                    border.color: JamiTheme.tabbarBorderColor
                    radius: 8
                }

                onTextChanged: {
                    if (root.applyingRemote)
                        return;
                    var diff = root.computeDiff(root.previousText, text);
                    root.previousText = text;
                    if (diff.deleteLen > 0 || diff.insert.length > 0)
                        CollaborativeAdapter.edit(root.conversationId,
                                                  root.documentId,
                                                  diff.index,
                                                  diff.deleteLen,
                                                  diff.insert);
                }

                onCursorPositionChanged: cursorBroadcast.restart()
                onSelectionStartChanged: cursorBroadcast.restart()

                // Remote carets, drawn as children of the editor so they scroll
                // with the text content.
                Repeater {
                    model: remoteCursorsModel
                    delegate: Item {
                        // Recomputed when the text or width changes.
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
                        // Name flag above the caret.
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

    // Coalesce rapid cursor moves into a single broadcast.
    Timer {
        id: cursorBroadcast
        interval: 120
        repeat: false
        onTriggered: {
            if (root.applyingRemote)
                return;
            CollaborativeAdapter.setCursor(root.conversationId,
                                           root.documentId,
                                           editor.cursorPosition,
                                           editor.selectionStart);
        }
    }
}
