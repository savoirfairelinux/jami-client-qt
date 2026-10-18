/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

// The Boards (Feeds) of the account: those it publishes, and those it follows.
BaseModalDialog {
    id: root
    objectName: "boardsDialog"

    property var feedService: FeedAdapter

    readonly property var ownedBoards: (feedService.feeds || []).filter(f => f.owned && !f.feedClosed)
    readonly property var followedBoards: (feedService.followed || []).filter(f => !f.owned)

    signal boardPicked(string feedId)
    signal createRequested
    signal manageRequested(string feedId)
    signal catalogueRequested

    titleText: JamiStrings.targetBoards

    popupContent: ColumnLayout {
        width: 440
        spacing: 10

        FeedList {
            objectName: "ownedBoards"

            Layout.fillWidth: true
            sectionTitle: JamiStrings.myBoards
            showCatalogue: false
            feeds: root.ownedBoards
            onOpenRequested: function (id) {
                root.boardPicked(id);
                root.close();
            }
            onCreateRequested: {
                root.createRequested();
                root.close();
            }
            onManageRequested: function (id) {
                root.manageRequested(id);
                root.close();
            }
        }

        FeedList {
            objectName: "followedBoards"

            Layout.fillWidth: true
            sectionTitle: JamiStrings.followedBoards
            showCreate: false
            feeds: root.followedBoards
            onOpenRequested: function (id) {
                root.boardPicked(id);
                root.close();
            }
            onCatalogueRequested: {
                root.catalogueRequested();
                root.close();
            }
        }
    }
}
