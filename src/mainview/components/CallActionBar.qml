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
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

Control {
    id: root

    property alias overflowOpen: overflowButton.popup.visible
    property real itemSpacing: 2

    Component {
        id: buttonDelegate

        CallButtonDelegate {
            width: root.height
            height: width
        }
    }

    Action {
        id: dummyControlAction
        onTriggered: print("dummyControlAction triggered")
    }
    Action {
        id: dummyMenuAction
        onTriggered: print("dummyMenuAction triggered")
    }

    property list<Action> menuActions: [
        Action {
            id: audioInputMenuAction
            onTriggered: print("audioInputMenuAction triggered")
        },
        Action {
            id: audioOutputMenuAction
            onTriggered: print("audioOutputMenuAction triggered")
        },
        Action {
            id: videoInputMenuAction
            onTriggered: print("videoInputMenuAction triggered")
        }
    ]

    property list<Action> primaryActions: [
        Action {
            id: muteAudioAction
            onTriggered: print("muteAudioAction triggered")
        },
        Action {
            id: hangupAction
            onTriggered: print("hangupAction triggered")
        },
        Action {
            id: muteVideoAction
            onTriggered: print("muteVideoAction triggered")
        }
    ]

    property var primaryControls: [
        {
            "ItemAction": muteAudioAction,
            "BadgeCount": 0,
            "HasBackground": false,
            "MenuAction": audioInputMenuAction,
            "Name" : "audio"
        },
        {
            "ItemAction": hangupAction,
            "BadgeCount": 0,
            "HasBackground": true,
            "MenuAction": null,
            "Name" : "hangup"
        },
        {
            "ItemAction": muteVideoAction,
            "HasBackground": false,
            "MenuAction": videoInputMenuAction,
            "Name" : "video"
        }
    ]

    property var secondaryControls: [
        {
            "ItemAction": dummyControlAction,
            "BadgeCount": 0,
            "HasBackground": false,
            "MenuAction": dummyMenuAction,
            "Name" : "0"
        },
        {
            "ItemAction": dummyControlAction,
            "BadgeCount": 0,
            "HasBackground": false,
            "MenuAction": null,
            "Name" : "1"
        },
        {
            "ItemAction": dummyControlAction,
            "BadgeCount": 0,
            "HasBackground": false,
            "MenuAction": null,
            "Name" : "2"
        },
        {
            "ItemAction": dummyControlAction,
            "BadgeCount": 0,
            "HasBackground": false,
            "MenuAction": null,
            "Name" : "3"
        },
        {
            "ItemAction": dummyControlAction,
            "BadgeCount": 0,
            "HasBackground": false,
            "MenuAction": null,
            "Name" : "4"
        }
    ]

    Component.onCompleted: {
        for (var control in primaryControls)
            CallOverlayModel.addPrimaryControl(primaryControls[control])
        for (control in secondaryControls)
            CallOverlayModel.addSecondaryControl(secondaryControls[control])
    }

    Item {
        id: centralControls
        anchors.centerIn: parent
        width: childrenRect.width
        height: root.height

        RowLayout {
            spacing: 0

            ListView {
                property bool centeredGroup: true

                orientation: ListView.Horizontal
                implicitWidth: contentWidth
                implicitHeight: contentHeight

                model: CallOverlayModel.primaryModel()
                delegate: buttonDelegate
            }
        }
    }
    Item {
        id: overflowRect
        property real remainingSpace: (root.width - centralControls.width) / 2
        anchors.right: parent.right
        width: childrenRect.width
        height: root.height

        RowLayout {
            spacing: itemSpacing

            ListView {
                id: overflowItemListView

                orientation: ListView.Horizontal
                implicitWidth: contentWidth
                implicitHeight: overflowRect.height

                spacing: itemSpacing

                property int overflowIndex: {
                    var maxItems = Math.floor((overflowRect.remainingSpace - 24) / root.height) - 1
                    return Math.min(secondaryControls.length, maxItems)
                }
                property int nOverflowItems: secondaryControls.length - overflowIndex
                onNOverflowItemsChanged: {
                    var diff = overflowItemListView.count - nOverflowItems
                    var effectiveOverflowIndex = overflowIndex
                    if (effectiveOverflowIndex === secondaryControls.length - 1)
                        effectiveOverflowIndex += diff

                    CallOverlayModel.overflowIndex = effectiveOverflowIndex
                }

                model: CallOverlayModel.overflowModel()
                delegate: buttonDelegate
            }
            ComboBox {
                id: overflowButton

                visible: CallOverlayModel.overflowIndex < secondaryControls.length
                width: root.height
                height: width

                model: CallOverlayModel.overflowHiddenModel()

                delegate: buttonDelegate

                indicator: null

                contentItem: Text {
                    text: "⋮"
                    color: "white"
                    font.pointSize: 18
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                background: Rectangle {
                    implicitWidth: root.height
                    implicitHeight: implicitWidth
                    color: overflowButton.down ?
                               "#80aaaaaa" :
                               overflowButton.hovered ?
                                   "#80777777" :
                                   "#80444444"
                }

                Item {
                    implicitHeight: children[0].contentHeight
                    width: overflowButton.width
                    anchors.bottom: parent.top
                    anchors.bottomMargin: itemSpacing
                    visible: !overflowButton.popup.visible
                    ListView {
                        spacing: itemSpacing
                        anchors.fill: parent
                        model: CallOverlayModel.overflowVisibleModel()
                        delegate: buttonDelegate
                        ScrollIndicator.vertical: ScrollIndicator {}

                        add: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 80 }
                            NumberAnimation { property: "scale"; from: 0; to: 1.0; duration: 80 }
                        }
                    }
                }

                popup: Popup {
                    y: overflowButton.height + itemSpacing
                    width: overflowButton.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 0

                    contentItem: ListView {
                        id: overflowListView
                        spacing: itemSpacing
                        implicitHeight: contentHeight
                        model: overflowButton.popup.visible ?
                                   overflowButton.delegateModel :
                                   null

                        ScrollIndicator.vertical: ScrollIndicator {}

                    }

                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }
    }
}
