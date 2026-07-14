/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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
import QtQml
import Qt5Compat.GraphicalEffects
import QtQml.Models
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../settingsview/components"

JamiListView {
    id: root

    spacing: JamiTheme.preferredMarginSize

    property color themeColor: CurrentConversation.color
    property string textFilter: ""
    property string convId: CurrentConversation.id

    component MessageFilterData: QtObject {
        property int type
        property int status
    }

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

    // Empty placeholder used instead of a null source model. Assigning a
    // null model to a SortFilterProxyModel can crash Qt in
    // QSortFilterProxyModelHelper::proxy_to_source when delegates still
    // request data during the reset (NULL_POINTER_READ).
    ListModel {
        id: emptyModel
    }

    model: SortFilterProxyModel {
        id: proxyModel

        property var messageListModel: MessagesAdapter.mediaMessageListModel
        readonly property int documentType: Interaction.Type.DATA_TRANSFER
        readonly property int transferFinishedType: Interaction.TransferStatus.TRANSFER_FINISHED
        readonly property int transferSuccesType: Interaction.Status.SUCCESS

        onMessageListModelChanged: proxyModel.model = root.visible && messageListModel ? messageListModel : emptyModel

        sorters: RoleSorter {
            roleName: "Timestamp"
            sortOrder: Qt.DescendingOrder
        }

        filters: FunctionFilter {
            column: 0
            function filter(data: MessageFilterData): bool {
                return data.type === proxyModel.documentType
                        && (data.status === proxyModel.transferFinishedType
                            || data.status === proxyModel.transferSuccesType);
            }
        }
    }

    delegate: DocumentPreview {
        id: member
        width: root.width
        height: Math.max(JamiTheme.swarmDetailsPageDocumentsHeight, JamiTheme.swarmDetailsPageDocumentsMinHeight)
    }
}
