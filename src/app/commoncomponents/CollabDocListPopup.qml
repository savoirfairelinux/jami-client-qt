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

    // Removing a document takes it away from everyone, on every device, and
    // nothing brings it back: ask before, and say so plainly.
    function confirmRemoval(docId, docName) {
        if (docId === "")
            return;
        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                "titleText": qsTr("Remove document"),
                "textLabel": qsTr("\"%1\" will be removed for every member of this conversation. This cannot be undone.").arg(docName !== "" ? docName : qsTr("Untitled document")),
                "confirmLabel": qsTr("Remove"),
                "rejectLabel": qsTr("Cancel")
            });
        dlg.accepted.connect(function () {
                CollaborativeAdapter.removeDocument(CurrentAccount.id, root.conversationId, docId);
            });
    }

    // Removing it from this device alone leaves the others with it, and opening
    // it again brings it back: what is asked here is far less than above, and
    // saying which one is which is the whole point of asking twice.
    function confirmLocalRemoval(docId, docName) {
        if (docId === "")
            return;
        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                "titleText": qsTr("Remove from this device"),
                "textLabel": qsTr("\"%1\" will be removed from this device only. The other members keep it, and opening it again downloads it back.").arg(docName !== "" ? docName : qsTr("Untitled document")),
                "confirmLabel": qsTr("Remove"),
                "rejectLabel": qsTr("Cancel")
            });
        dlg.accepted.connect(function () {
                CollaborativeAdapter.removeDocumentLocally(CurrentAccount.id, root.conversationId, docId);
            });
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
        function onDocumentRenamed(accId, convId, docId, name) {
            if (accId === CurrentAccount.id && convId === root.conversationId)
                root.refresh();
        }
        function onDocumentUpdateIndicatorChanged(convId) {
            if (convId === root.conversationId)
                root.refresh();
        }
        function onDocumentRemoved(accId, convId, docId, everywhere) {
            if (accId === CurrentAccount.id && convId === root.conversationId)
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
                property string docId: model.documentId || ""
                property string docName: model.name || ""
                property string docAuthor: model.author || ""
                property bool docHasUpdate: model.hasUpdate === true
                property bool docStoredLocally: model.storedLocally !== false

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
                            visible: docHasUpdate
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
                            text: docName !== "" ? docName : qsTr("Untitled document")
                            // Both the document name and the peer's display name
                            // are remote input: never render them as markup.
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pointSize: JamiTheme.textFontSize
                            font.bold: true
                            color: JamiTheme.textColor
                        }
                        Text {
                            Layout.fillWidth: true
                            text: {
                                const author = UtilsAdapter.getBestNameForUri(CurrentAccount.id, docAuthor);
                                // Said on the entry rather than by greying it out:
                                // this one is still there to be opened, and opening
                                // it is exactly what brings it back.
                                return docStoredLocally ? author : qsTr("%1 - not on this device").arg(author);
                            }
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pointSize: JamiTheme.tinyFontSize
                            color: JamiTheme.faddedFontColor
                        }
                    }

                    PushButton {
                        Layout.alignment: Qt.AlignVCenter
                        // Anyone may stop holding a document, and there is nothing
                        // to offer for one this device is not holding already.
                        visible: docStoredLocally
                        preferredSize: 24
                        imageContainerWidth: 20
                        imageContainerHeight: 20
                        source: JamiResources.delete_24dp_svg
                        toolTipText: qsTr("Remove from this device")
                        normalColor: "transparent"
                        imageColor: JamiTheme.textColor

                        onClicked: root.confirmLocalRemoval(docId, docName)
                    }

                    PushButton {
                        Layout.alignment: Qt.AlignVCenter
                        // Only the author may remove a document for everyone, and
                        // the daemon refuses anyone else: offering the button to
                        // the others would only promise what cannot happen.
                        visible: docAuthor !== "" && docAuthor === CurrentAccount.uri
                        preferredSize: 24
                        imageContainerWidth: 20
                        imageContainerHeight: 20
                        source: JamiResources.delete_forever_24dp_svg
                        toolTipText: qsTr("Remove this document")
                        normalColor: "transparent"
                        imageColor: JamiTheme.textColor

                        onClicked: root.confirmRemoval(docId, docName)
                    }
                }

                onClicked: {
                    if (docId === "") {
                        console.log("Cannot open collaborative document: missing document id");
                        return;
                    }
                    appWindow.openCollabEditor(root.conversationId, docId, docName,
                                               root.peerName !== "" ? root.peerName : CurrentConversation.title,
                                               docAuthor);
                    root.close();
                }
            }
        }
    }
}
