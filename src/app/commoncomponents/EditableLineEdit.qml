/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects

import net.jami.Constants 1.1
import net.jami.Adapters 1.1

Item {
    id: root

    signal editingFinished

    property alias text: lineEdit.text
    property alias color: lineEdit.color
    property alias verticalAlignment: lineEdit.verticalAlignment
    property alias horizontalAlignment: lineEdit.horizontalAlignment
    property alias font: lineEdit.font
    property alias placeholderText: lineEdit.placeholderText
    property alias placeholderTextColor: lineEdit.placeholderTextColor
    property alias backgroundColor: lineEdit.backgroundColor

    property string leftIcon: ""
    property string secondIcon: ""
    property string thirdIcon: ""

    property var editIconColor:  UtilsAdapter.luma(root.color) ? JamiTheme.editLineColor : "white"
    property var cancelIconColor: UtilsAdapter.luma(root.color) ? JamiTheme.buttonTintedBlue : "white"

    property bool readOnly: false
    property bool editable: false
    property bool hovered: false
    property bool identifier: false
    property bool password: false
    property bool nickname: false
    property bool description: true
    property string tooltipText: ""
    property int preferredWidth: JamiTheme.preferredFieldWidth

    height: lineEdit.height
    width: preferredWidth

    MaterialToolTip {
        parent: lineEdit
        visible: tooltipText != "" && hovered
        delay: Qt.styleHints.mousePressAndHoldInterval
        text: tooltipText
    }

    HoverHandler {
        target : parent
        onHoveredChanged: {
            root.hovered = hovered
        }
        cursorShape: Qt.PointingHandCursor
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        z: 1

        MaterialLineEdit {
            id: lineEdit

            readOnly: !editable || root.readOnly
            underlined: true

            borderColor: root.editIconColor
            fieldLayoutHeight: 24

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: root.preferredFieldWidth - lineEdit.height * 4 / 3
            Layout.fillHeight: true

            wrapMode: Text.NoWrap

            onFocusChanged: function(focus) {
                if (!focus && editable) {
                    editable = !editable
                    root.editingFinished()
                } else if (focus && !editable) {
                    editable = !editable
                    lineEdit.forceActiveFocus()
                }
            }
            onAccepted: {
                editable = !editable
                root.editingFinished()
            }
        }

    }

    Rectangle {
        anchors.fill: row
        radius: JamiTheme.primaryRadius

        visible: (root.editable || root.hovered)  && !root.readOnly && !description
        color: root.editIconColor

        Rectangle {
            visible: parent.visible
            anchors {
                fill: parent
                topMargin: 0
                rightMargin: 0
                bottomMargin: 1
                leftMargin: 0
            }
            color: root.backgroundColor
        }
    }
}
