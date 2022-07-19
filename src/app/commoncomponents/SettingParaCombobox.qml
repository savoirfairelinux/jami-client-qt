/*
 * Copyright (C) 2019-2022 Savoir-faire Linux Inc.
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls

import net.jami.Constants 1.1

ComboBox {
    id: root

    property alias tooltipText: toolTip.text
    property string placeholderText
    property string currentSelectionText: currentText

    MaterialToolTip {
        id: toolTip

        parent: root
        visible: hovered && (text.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    displayText: currentIndex !== -1 ?
                     currentSelectionText : (placeholderText !== "" ?
                                                 placeholderText :
                                                 JamiStrings.notAvailable)

    delegate: ItemDelegate {
        width: root.width

        contentItem: Text {

            text: {
                if (index >= 0) {
                    var currentItem = root.delegateModel.items.get(index)
                    return currentItem.model[root.textRole].toString()
                }
                return ""
            }

            color: hovered ? JamiTheme.comboboxTextColorHovered : JamiTheme.textColor
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter

        }

        background: Rectangle {
            color: hovered ? JamiTheme.tintedBlue : JamiTheme.transparentColor
            opacity: 0.1
        }

    }

    indicator: ResponsiveImage {

        containerHeight: 6
        containerWidth: 10
        width: 20
        height: 20

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 16

        source: popup.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg


    }

    contentItem: Text {

        leftPadding: 10
        rightPadding: root.indicator.width + leftPadding

        text: root.displayText
        color: JamiTheme.textColor

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight

    }

    background: Rectangle {

        color: JamiTheme.transparentColor
        implicitWidth: 120
        implicitHeight: 40
        border.color: popup.visible ? JamiTheme.comboboxBorderColorActive : JamiTheme.comboboxBorderColor
        border.width: root.visualFocus ? 2 : 1
        radius: 5

    }

    popup: Popup {
        id: popup

        y: root.height - 1
        width: root.width
        padding: 1
        height: Math.min(contentItem.implicitHeight,229)


        contentItem: JamiListView {
            id: listView

            implicitHeight: contentHeight
            model: root.delegateModel

        }

        background: Rectangle {

            color: JamiTheme.primaryBackgroundColor
            border.color: JamiTheme.comboboxBorderColorActive
            radius: 5
        }

    }

}
