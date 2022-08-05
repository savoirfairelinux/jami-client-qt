/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls

import SortFilterProxyModel 0.2

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

SortFilterProxyModel {
    id: root

    required property int type
    required property string filterPattern

    onFilterPatternChanged: {
        if (type === ContactList.CONFERENCE) {
            smartListModel.setConferenceableFilter(filterPattern)
        }
    }

    function selectItem(index) {
        smartListModel.selectItem(root.mapToSource(index))
    }

    sourceModel: SmartListModel {
        id: smartListModel

        listModelType: type
        Component.onCompleted: lrcInstance = LRCInstance
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
