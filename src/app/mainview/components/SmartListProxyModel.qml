/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

import SortFilterProxyModel 0.2

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

SortFilterProxyModel {
    id: root

    required property int type
    required property string filterPattern

    function selectItem(index) {
        sourceModel.selectItem(root.mapToSource(index))
    }

    sourceModel: SmartListModel {
        id: sourceModel
        Component.onCompleted: init(LRCInstance)
        listModelType: type
    }
    filters: [
        AnyOf {
            RegExpFilter {
                roleName: "Title"
                pattern: filterPattern
                caseSensitivity: Qt.CaseInsensitive
            }
            RegExpFilter {
                roleName: "RegisteredName"
                pattern: filterPattern
                caseSensitivity: Qt.CaseInsensitive
            }
            RegExpFilter {
                roleName: "URI"
                pattern: filterPattern
                caseSensitivity: Qt.CaseInsensitive
            }
        }
    ]
    sorters: ExpressionSorter {
        expression: modelLeft.LastInteractionTimeStamp <
                    modelRight.LastInteractionTimeStamp
    }
}
