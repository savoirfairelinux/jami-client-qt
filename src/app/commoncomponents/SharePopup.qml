/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../mainview/components"

Popup {
    id: root
    padding: 0
    property list<Action> menuMoreButton

    height: 3 * JamiTheme.messageBarMarginSize + 3 * (JamiTheme.chatViewFooterRealButtonSize + 10)
    width: 150 + 2 * JamiTheme.messageBarMarginSize

    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    contentItem: ListView {
        id: listViewMoreButton

        width: contentWidth + leftMargin
        height: contentWidth + 2 * leftMargin
        orientation: ListView.Vertical
        interactive: false
        leftMargin: JamiTheme.messageBarMarginSize
        rightMargin: JamiTheme.messageBarMarginSize
        bottomMargin: JamiTheme.messageBarMarginSize
        topMargin: JamiTheme.messageBarMarginSize
        spacing: 5

        Rectangle {
            anchors.fill: parent
            color: JamiTheme.backgroundColor
            border.color: JamiTheme.chatViewFooterRectangleBorderColor
            border.width: 2
            radius: 5
            z: -1
        }

        model: menuMoreButton

        delegate: Item {

            height: JamiTheme.chatViewFooterRealButtonSize + JamiTheme.messageBarMarginSize
            width: JamiTheme.chatViewFooterRealButtonSize + 2 * JamiTheme.messageBarMarginSize + 100

            PushButton {

                anchors.fill: parent
                height: JamiTheme.chatViewFooterRealButtonSize
                width: imageContainerWidth + modelData.toolTip.length * 8
                imageContainerWidth: 25
                imageContainerHeight: 25
                radius: 5
                duration: 0

                source: modelData.iconSrc
                buttonText: modelData.toolTip
                focusPolicy: Qt.TabFocus

                normalColor: JamiTheme.transparentColor
                imageColor: hovered ? JamiTheme.chatViewFooterImgHoverColor : "#7f7f7f"
                buttonTextColor: imageColor
                hoveredColor: JamiTheme.showMoreButtonOpenColor
                pressedColor: hoveredColor

                action: modelData

                onClicked: {
                    root.close();
                }
            }
        }
    }

    background: Rectangle {
        anchors.fill: parent
        color: JamiTheme.transparentColor
        radius: 5
        z: -1
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 0.0
            to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }
    exit: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 1.0
            to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
