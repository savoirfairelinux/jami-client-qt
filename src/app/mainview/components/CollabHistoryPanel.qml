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

    color: JamiTheme.globalIslandColor
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
            return JamiStrings.versionHistoryToday.arg(d.toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
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
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: JamiStrings.versionHistory
                font.pointSize: JamiTheme.textFontSize
                font.bold: true
                color: JamiTheme.textColor
                elide: Text.ElideRight
            }
            NewIconButton {
                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.refresh_24dp_svg
                toolTipText: JamiStrings.sharedServicesRefresh
                onClicked: root.refresh()
            }
        }

        Text {
            Layout.fillWidth: true
            visible: versionsModel.count === 0
            text: JamiStrings.noDocumentVersionsSaved
            wrapMode: Text.WordWrap
            font.pointSize: JamiTheme.tinyFontSize
            color: JamiTheme.faddedFontColor
        }

        // "Current version" row: leaves the preview and returns to editing.
        ItemDelegate {
            id: currentVersionItem

            Layout.fillWidth: true
            visible: versionsModel.count > 0
            Layout.preferredHeight: Math.max(48, implicitContentHeight + topPadding + bottomPadding)
            padding: 8
            highlighted: root.selectedCommitId === ""
            onClicked: root.clearPreview()

            background: Rectangle {
                radius: height / 2
                color: currentVersionItem.highlighted ? JamiTheme.smartListSelectedColor
                       : currentVersionItem.hovered || currentVersionItem.activeFocus ? JamiTheme.hoveredButtonColor : "transparent"
                border.width: currentVersionItem.highlighted ? 1 : 0
                border.color: JamiTheme.comboboxBorderColorActive
            }

            contentItem: ColumnLayout {
                spacing: 0
                Text {
                    text: JamiStrings.currentVersion
                    font.pointSize: JamiTheme.smallFontSize
                    font.bold: true
                    color: JamiTheme.textColor
                }
                Text {
                    text: JamiStrings.editable
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
            spacing: 4
            ScrollBar.vertical: JamiScrollBar {
                attachedFlickableMoving: versionsView.moving
            }

            delegate: ItemDelegate {
                id: savedVersionItem

                width: versionsView.width
                height: Math.max(48, implicitContentHeight + topPadding + bottomPadding)
                padding: 8
                highlighted: root.selectedCommitId === commitId
                onClicked: root.preview(commitId)

                background: Rectangle {
                    radius: height / 2
                    color: savedVersionItem.highlighted ? JamiTheme.smartListSelectedColor
                           : savedVersionItem.hovered || savedVersionItem.activeFocus ? JamiTheme.hoveredButtonColor : "transparent"
                    border.width: savedVersionItem.highlighted ? 1 : 0
                    border.color: JamiTheme.comboboxBorderColorActive
                }

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
                                who = JamiStrings.someone;
                            return who + " · " + JamiStrings.documentChangeCount(deltas);
                        }
                        font.pointSize: JamiTheme.tinyFontSize
                        color: JamiTheme.faddedFontColor
                        elide: Text.ElideRight
                    }
                }
            }
        }

        NewMaterialButton {
            Layout.fillWidth: true
            visible: root.selectedCommitId !== ""
            iconSource: JamiResources.bidirectional_settings_backup_restore_24dp_svg
            text: JamiStrings.restoreThisVersion
            toolTipText: JamiStrings.restoreDocumentVersionTooltip
            onClicked: {
                if (CollaborativeAdapter.restore(root.accountId, root.conversationId, root.documentId, root.selectedCommitId)) {
                    restoreError.visible = false;
                    root.clearPreview();
                    root.restored();
                } else {
                    // A restore fails when the version can no longer be read, or
                    // when the document was closed meanwhile. Saying nothing would
                    // look exactly like a button that does not work.
                    restoreError.visible = true;
                }
            }
        }

        Text {
            id: restoreError

            Layout.fillWidth: true
            visible: false
            text: JamiStrings.documentVersionRestoreFailed
            font.pointSize: JamiTheme.tinyFontSize
            color: JamiTheme.redColor
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
        }
    }
}
