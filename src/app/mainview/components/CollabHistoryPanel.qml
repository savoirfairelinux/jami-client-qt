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
import "../../commoncomponents"

// Side panel listing the saved versions of a collaborative document, newest
// first. Selecting one asks the host window to show it read-only; restoring one
// is an ordinary edit, so it reaches every member and can itself be undone.
Rectangle {
    id: root

    // Named explicitly rather than taken from CurrentAccount: the editor window
    // that owns this panel may not belong to the selected account.
    property string accountId: ""
    property string conversationId: ""
    property string documentId: ""
    // Checkpoint currently previewed, empty when the live document is shown.
    property string selectedCommitId: ""

    // The host window displays the content; the panel only picks a version.
    signal previewRequested(string commitId, string text)
    signal previewCleared
    signal restored

    color: JamiTheme.secondaryBackgroundColor
    radius: 8
    border.width: 1
    border.color: JamiTheme.tabbarBorderColor

    function refresh() {
        var current = root.selectedCommitId;
        versionsModel.clear();
        var entries = CollaborativeAdapter.history(accountId, conversationId, documentId, 0);
        for (var i = 0; i < entries.length; ++i) {
            var e = entries[i];
            versionsModel.append({
                "commitId": e.id,
                "author": e.author,
                "deviceId": e.device,
                "epoch": Number(e.timestamp),
                "deltas": Number(e.deltas)
            });
        }
        // A version list is append-only, so a previewed version stays valid.
        root.selectedCommitId = current;
    }

    function preview(commitId) {
        var text = CollaborativeAdapter.textAt(accountId, conversationId, documentId, commitId);
        root.selectedCommitId = commitId;
        root.previewRequested(commitId, text);
    }

    function clearPreview() {
        root.selectedCommitId = "";
        root.previewCleared();
    }

    function labelFor(epoch) {
        var d = new Date(epoch * 1000);
        var now = new Date();
        if (d.toDateString() === now.toDateString())
            return qsTr("Today %1").arg(d.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
        return d.toLocaleString(Qt.locale(), Locale.ShortFormat);
    }

    onVisibleChanged: if (visible)
        refresh()

    ListModel {
        id: versionsModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: qsTr("Version history")
                font.pointSize: JamiTheme.textFontSize
                font.bold: true
                color: JamiTheme.textColor
                elide: Text.ElideRight
            }
            PushButton {
                preferredSize: 20
                imageContainerWidth: 14
                imageContainerHeight: 14
                source: JamiResources.refresh_24dp_svg
                toolTipText: qsTr("Refresh")
                normalColor: "transparent"
                imageColor: JamiTheme.textColor
                onClicked: root.refresh()
            }
        }

        Text {
            Layout.fillWidth: true
            visible: versionsModel.count === 0
            text: qsTr("No version saved yet. Versions are saved as you stop typing.")
            wrapMode: Text.WordWrap
            font.pointSize: JamiTheme.tinyFontSize
            color: JamiTheme.faddedFontColor
        }

        // "Current version" row: leaves the preview and returns to editing.
        ItemDelegate {
            Layout.fillWidth: true
            visible: versionsModel.count > 0
            Layout.preferredHeight: 40
            highlighted: root.selectedCommitId === ""
            onClicked: root.clearPreview()

            contentItem: ColumnLayout {
                spacing: 0
                Text {
                    text: qsTr("Current version")
                    font.pointSize: JamiTheme.smallFontSize
                    font.bold: true
                    color: JamiTheme.textColor
                }
                Text {
                    text: qsTr("Editable")
                    font.pointSize: JamiTheme.tinyFontSize
                    color: JamiTheme.faddedFontColor
                }
            }
        }

        ListView {
            id: versionsView

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: versionsModel
            spacing: 2
            ScrollBar.vertical: ScrollBar {}

            delegate: ItemDelegate {
                width: versionsView.width
                height: 46
                highlighted: root.selectedCommitId === commitId
                onClicked: root.preview(commitId)

                contentItem: ColumnLayout {
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: root.labelFor(epoch)
                        font.pointSize: JamiTheme.smallFontSize
                        color: JamiTheme.textColor
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var who = UtilsAdapter.getBestNameForUri(root.accountId, author);
                            if (who === "")
                                who = qsTr("Someone");
                            return who + " · " + qsTr("%n change(s)", "", deltas);
                        }
                        font.pointSize: JamiTheme.tinyFontSize
                        color: JamiTheme.faddedFontColor
                        elide: Text.ElideRight
                    }
                }
            }
        }

        MaterialButton {
            Layout.fillWidth: true
            visible: root.selectedCommitId !== ""
            primary: true
            iconSource: JamiResources.bidirectional_settings_backup_restore_24dp_svg
            text: qsTr("Restore this version")
            toolTipText: qsTr("Brings the document back to this content for everyone. Reversible.")
            onClicked: {
                if (CollaborativeAdapter.restore(root.accountId, root.conversationId, root.documentId, root.selectedCommitId)) {
                    root.clearPreview();
                    root.restored();
                }
            }
        }
    }
}
