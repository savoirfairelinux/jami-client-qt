/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Sébastien blin <sebastien.blin@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

import net.jami.Constants 1.1

RowLayout {
    id: root

    signal editingFinished

    property alias text: lineEdit.text
    property alias tooltipText: btnEdit.toolTipText
    property alias color: lineEdit.color
    property alias verticalAlignment: lineEdit.verticalAlignment
    property alias horizontalAlignment: lineEdit.horizontalAlignment
    property alias font: lineEdit.font
    property alias placeholderText: lineEdit.placeholderText
    property alias placeholderTextColor: lineEdit.placeholderTextColor
    property alias backgroundColor: lineEdit.backgroundColor

    property bool editable: false

    MaterialLineEdit {
        id: lineEdit

        readOnly: !editable
        underlined: true

        borderColor: JamiTheme.textColor

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: JamiTheme.preferredFieldWidth
        Layout.fillHeight: true

        onFocusChanged: function(focus) {
            if (!focus && editable) {
                editable = !editable
                root.editingFinished()
            } else if (focus && !editable) {
                editable = !editable
                lineEdit.forceActiveFocus()
            }
        }
    }

    PushButton {
        id: btnEdit

        Layout.alignment: Qt.AlignVCenter

        opacity: 0.8
        imageColor: JamiTheme.textColor
        normalColor: "transparent"
        hoveredColor: JamiTheme.hoveredButtonColor

        Layout.preferredWidth: preferredSize
        Layout.preferredHeight: preferredSize

        source: editable ?
                JamiResources.round_close_24dp_svg :
                JamiResources.round_edit_24dp_svg

        onClicked: {
            if (root.editable)
                root.editingFinished()
            root.editable = !root.editable
            lineEdit.forceActiveFocus()
        }
    }
}