/*
 * Copyright (C) 2021 by Savoir-faire Linux
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.14
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.14

import "../../commoncomponents"

ItemDelegate {
    id: wrapper

    action: ItemAction

    property bool isFirst: index === 0 ? true : false
    property bool isLast: index + 1 < ListView.view.count ? false : true
    property bool hasLast: ListView.view.centeredGroup !== undefined

    background: RoundedRectangle {
        property int r: 5
        fillColor: {
            if (HasBackground)
                return "#c4272727"
            return wrapper.down ?
                        "#c4777777" :
                        wrapper.hovered && !menuButton.hovered ?
                            "#c4444444" :
                            "#c4272727"
        }
        anchors.fill: parent
        radius: {
            if (wrapper.ListView.view.orientation === ListView.Vertical) {
                if (isFirst) {
                    return {"tl": r, "tr": r, "br": 0, "bl": 0}
                } else if (isLast && hasLast) {
                    return {"tl": 0, "tr": 0, "br": r, "bl": r}
                }
            } else {
                if (isFirst) {
                    return {"tl": r, "tr": 0, "br": 0, "bl": r}
                } else if (isLast && hasLast) {
                    return {"tl": 0, "tr": r, "br": r, "bl": 0}
                }
            }
        }
    }

    Rectangle {
        color: "#cc0022"

        visible: HasBackground
        anchors.fill: parent
        radius: width / 2
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 12
        horizontalAlignment: Text.AlignHCenter
        text: index + ":" + Name
        elide: Text.ElideRight
        color: "white"
    }

    ComboBox {
        id: menuButton

        indicator: null

        visible: MenuAction !== null && !BadgeCount
        anchors.horizontalCenter: parent.horizontalCenter
        width: 18
        height: width
        y: -4

        contentItem: Text {
            text: "^"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "white"
        }

        background: Rectangle {
            color: menuButton.down ?
                       "#aaaaaa" :
                       menuButton.hovered ?
                           "#777777" :
                           "#444444"
            radius: 4
        }

        popup: Popup {
            id: itemPopup

            y: -implicitHeight - 12
            x: -(implicitWidth - wrapper.width) / 2 - 18
            implicitWidth: contentItem.implicitWidth
            implicitHeight: contentItem.implicitHeight
            leftPadding: 0
            rightPadding: 0

            contentItem: ListView {
                id: itemListView
                orientation: ListView.Vertical
                implicitWidth: 145
                implicitHeight: contentHeight

                ScrollIndicator.vertical: ScrollIndicator {}

                clip: true

                model: 5
                delegate: ItemDelegate {
                    id: menuItem

                    width: 200
                    background: Rectangle {
                        anchors.fill: parent
                        color: menuItem.down ?
                                   "#c4aaaaaa" :
                                   menuItem.hovered ?
                                       "#c4777777" :
                                       "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignLeft
                        text: "device " + index
                        elide: Text.ElideRight
                        color: "white"
                    }
                }
            }

            background: Rectangle {
                anchors.fill: parent
                radius: 5
                color: "#c4272727"
            }
        }

        layer.enabled: true
        layer.effect: DropShadow {
            z: -1
            horizontalOffset: 0
            verticalOffset: 0
            radius: 8.0
            samples: 16
            color: "#80000000"
        }
    }

    BadgeNotifier {
        count: BadgeCount
        anchors.horizontalCenter: parent.horizontalCenter
        width: 18
        height: width
        radius: 4
        y: -4
    }
}
