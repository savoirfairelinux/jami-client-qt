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

// Lists the editable documents shared in a conversation. Clicking an entry opens
// its collaborative editor (reusing an already-open window if any).
BaseModalDialog {
    id: root

    property string conversationId: ""
    property string peerName: ""

    function refresh() {
        docsModel.clear();
        var docs = CollaborativeAdapter.documents(root.conversationId);
        for (var i = 0; i < docs.length; ++i)
            docsModel.append(docs[i]);
    }

    titleText: qsTr("Editable documents")

    button1.text: qsTr("Close")
    button1Role: DialogButtonBox.RejectRole
    button1.onClicked: close()

    onAboutToShow: refresh()

    // Keep the list current while the popup is open (live renames, new docs).
    Connections {
        target: CollaborativeAdapter
        enabled: root.opened
        function onDocumentRenamed(convId, docId, name) {
            if (convId === root.conversationId)
                root.refresh();
        }
        function onDocumentUpdateIndicatorChanged(convId) {
            if (convId === root.conversationId)
                root.refresh();
        }
    }

    ListModel {
        id: docsModel
    }

    popupContent: ColumnLayout {
        width: JamiTheme.preferredDialogWidth
        spacing: JamiTheme.preferredMarginSize

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            visible: docsModel.count === 0
            text: qsTr("No editable document in this conversation yet.")
            wrapMode: Text.WordWrap
            color: JamiTheme.faddedFontColor
            font.pointSize: JamiTheme.settingsFontSize
        }

        ListView {
            id: docsView
            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: Math.min(contentHeight, 320)
            visible: docsModel.count > 0
            clip: true
            spacing: 4
            model: docsModel

            delegate: ItemDelegate {
                width: docsView.width
                height: 48

                contentItem: RowLayout {
                    spacing: JamiTheme.preferredMarginSize

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 24

                        ResponsiveImage {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            source: JamiResources.round_edit_24dp_svg
                            width: 24
                            height: 24
                            color: JamiTheme.textColor
                        }

                        Rectangle {
                            visible: hasUpdate
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8
                            height: 8
                            radius: width / 2
                            border.color: JamiTheme.backgroundColor
                            border.width: 1
                            color: "#00B7FF"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: name !== "" ? name : qsTr("Untitled document")
                            elide: Text.ElideRight
                            font.pointSize: JamiTheme.textFontSize
                            font.bold: true
                            color: JamiTheme.textColor
                        }
                        Text {
                            Layout.fillWidth: true
                            text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, author)
                            elide: Text.ElideRight
                            font.pointSize: JamiTheme.tinyFontSize
                            color: JamiTheme.faddedFontColor
                        }
                    }
                }

                onClicked: {
                    CollabEditorWindows.openEditor(appWindow, root.conversationId, documentId, name,
                                                   root.peerName !== "" ? root.peerName : CurrentConversation.title,
                                                   kind);
                    root.close();
                }
            }
        }
    }
}
