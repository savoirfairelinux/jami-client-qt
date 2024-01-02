/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import SortFilterProxyModel
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../settingsview/components"

JamiListView {
    id: root

    anchors.fill: parent
    topMargin: JamiTheme.preferredMarginSize
    bottomMargin: JamiTheme.preferredMarginSize
    spacing: JamiTheme.preferredMarginSize

    property color themeColor: CurrentConversation.color
    property string textFilter: ""
    property var convId: CurrentConversation.id

    onVisibleChanged: {
        if (visible) {
            MessagesAdapter.startSearch(textFilter, true);
        }
    }

    onConvIdChanged: {
        if (visible) {
            MessagesAdapter.startSearch(textFilter, true);
        }
    }

    onTextFilterChanged: {
        MessagesAdapter.startSearch(textFilter, true);
    }

    model: SortFilterProxyModel {
        id: proxyModel

        property var messageListModel: MessagesAdapter.mediaMessageListModel
        readonly property int documentType: Interaction.Type.DATA_TRANSFER
        readonly property int transferFinishedType: Interaction.Status.TRANSFER_FINISHED
        readonly property int transferSuccesType: Interaction.Status.SUCCESS

        onMessageListModelChanged: sourceModel = root.visible && messageListModel ? messageListModel : null

        sorters: RoleSorter {
            roleName: "Timestamp"
            sortOrder: Qt.DescendingOrder
        }

        filters: [
            ExpressionFilter {
                expression: Type === proxyModel.documentType
            },
            ExpressionFilter {
                expression: Status === proxyModel.transferFinishedType || Status === proxyModel.transferSuccesType
            }
        ]
    }

    delegate: DocumentPreview {
        id: member
        width: root.width
        height: Math.max(JamiTheme.swarmDetailsPageDocumentsHeight, JamiTheme.swarmDetailsPageDocumentsMinHeight)
    }
}
