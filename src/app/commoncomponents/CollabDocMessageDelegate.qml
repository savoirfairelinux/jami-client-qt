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
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import "../mainview/js/collabeditorwindowcreation.js" as CollabEditorWindows

// Chat bubble announcing a shared editable document. Clicking it opens the
// collaborative editor for everyone in the conversation.
Item {
    id: root

    property var convContext: CurrentConversation
    property string author: Author
    property string documentId: DocumentId
    property string docKind: (typeof DocumentKind !== "undefined" && DocumentKind !== "") ? DocumentKind : "text"
    // Displayed name: starts from the announcing commit (Body) but follows live
    // renames (CRDT name field) broadcast through CollaborativeAdapter.
    property string docName: Body

    function conversationIdOf() {
        return root.convContext ? root.convContext.id : CurrentConversation.id;
    }

    Component.onCompleted: {
        var current = CollaborativeAdapter.documentName(conversationIdOf(), root.documentId);
        if (current !== "")
            root.docName = current;
    }

    Connections {
        target: CollaborativeAdapter
        function onDocumentRenamed(convId, docId, name) {
            if (docId === root.documentId && convId === root.conversationIdOf())
                root.docName = name;
        }
    }

    // Properties assigned by MessageListView.computeChatview().
    property bool showTime: false
    property bool showDay: false
    property bool isReply: false
    property int seq: MsgSeq.single
    property int timestamp: Timestamp
    property string formattedDay: MessagesAdapter.getFormattedDay(timestamp)

    width: ListView.view ? ListView.view.width : 0
    height: bubble.height + 2 * JamiTheme.preferredMarginSize

    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Editable document") + ": " + root.docName

    Rectangle {
        id: bubble

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(root.width - 4 * JamiTheme.preferredMarginSize, content.implicitWidth + 2 * JamiTheme.preferredMarginSize)
        height: content.implicitHeight + 2 * JamiTheme.preferredMarginSize
        radius: 12
        color: JamiTheme.messageInBgColor
        border.width: 1
        border.color: JamiTheme.primaryBackgroundColor

        RowLayout {
            id: content

            anchors.centerIn: parent
            width: parent.width - 2 * JamiTheme.preferredMarginSize
            spacing: JamiTheme.preferredMarginSize

            ResponsiveImage {
                Layout.alignment: Qt.AlignVCenter
                source: JamiResources.round_edit_24dp_svg
                width: 28
                height: 28
                color: JamiTheme.textColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.docName !== "" ? root.docName : qsTr("Untitled document")
                    elide: Text.ElideRight
                    font.pointSize: JamiTheme.textFontSize
                    font.bold: true
                    color: JamiTheme.textColor
                }
                Text {
                    text: root.docKind === "rich" ? qsTr("Editable document · Rich text")
                                                   : qsTr("Editable document")
                    font.pointSize: JamiTheme.tinyFontSize
                    color: JamiTheme.faddedFontColor
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                CollabEditorWindows.openEditor(appWindow, root.conversationIdOf(), root.documentId, root.docName,
                                               root.convContext ? root.convContext.title : CurrentConversation.title,
                                               root.docKind);
            }
        }
    }
}
