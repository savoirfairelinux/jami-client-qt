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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../webengine/map"
import "../../commoncomponents"


Rectangle {
    id: root

    property string attachedAccountId: CurrentAccount.id

    color: imSharing ? CurrentConversation.color : JamiTheme.messageInBgColor
    height: mainGrid.height + 10
    width: parent ? parent.width : undefined
    property bool imSharing: true

    function getBaseColor() {
        var baseColor
        if (UtilsAdapter.luma(root.color))
            baseColor = JamiTheme.chatviewTextColorLight
        else
            baseColor = JamiTheme.chatviewTextColorDark

        return baseColor
    }

    property var locationColor: getBaseColor()

    GridLayout {
        id: mainGrid

        width: parent.width
        anchors.centerIn: parent

        columnSpacing: 0
        rowSpacing: 0

        // Use a threshold to determine when to switch a between
        // a row and column layout
        property bool isRowLayout: width > 600
        rows: isRowLayout ? 1 : 2
        columns: isRowLayout ? 2 : 1

        Item {
            Layout.fillWidth: true
            height: childrenRect.height

            RowLayout {
                id: iconRow

                anchors.left: parent.left
                spacing: 20

                BlinkingLocationIcon {
                    Layout.leftMargin: 20
                    isSharing: true
                    arrowTimerVisibility: locationIconTimer.showIconArrow
                    color: locationColor
                }

                Text {
                    text: uri === CurrentAccount.uri ? JamiStrings.youreSharingLocation : UtilsAdapter.getBestNameForUri(CurrentAccount.id, uri) + JamiStrings.areSharingLocation
                    font.pointSize: JamiTheme.textFontSize + 2
                    color: locationColor
                }
            }
        }

        Item {
            Layout.fillWidth: true
            height: childrenRect.height
            RowLayout {
                id: buttonsRow

                spacing: 20
                anchors.right: parent.right

                Item {
                    Layout.preferredWidth: textmetricShowLocation.width
                    Layout.preferredHeight: parent.height

                    TextMetrics {
                        id: textmetricShowLocation
                        text: JamiStrings.showLocation
                        font.pointSize: JamiTheme.textFontSize + 2
                        font.bold: true
                    }

                    Button {
                        anchors.centerIn: parent
                        contentItem: Text {
                            text: JamiStrings.showLocation
                            font.pointSize: JamiTheme.textFontSize + 2
                            color: locationColor
                            font.bold: parent.hovered ? true : false
                        }
                        background: Rectangle {
                            visible: false
                        }
                        onClicked: {
                            PositionManager.setMapActive(CurrentAccount.id)
                            PositionManager.showLocation(CurrentAccount.id, uri);
                        }
                    }
                }

                Rectangle {
                    visible: imSharing
                    height: 30
                    width: 2
                    color: locationColor
                }

                Item {
                    visible: imSharing
                    Layout.preferredWidth: textmetricStopSharing.width
                    Layout.preferredHeight: parent.height

                    TextMetrics {
                        id: textmetricStopSharing
                        text: JamiStrings.stopSharingLocation
                        font.pointSize: JamiTheme.textFontSize + 2
                        font.bold: true
                    }

                    Button {
                        anchors.centerIn: parent
                        property bool stopAllSharing: !(PositionManager.positionShareConvIdsCount >= 2
                                                        && PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId))
                        property string attachedAccountId: CurrentAccount.id

                        contentItem: Text {
                            text: JamiStrings.stopSharingLocation
                            font.pointSize: JamiTheme.textFontSize + 2
                            font.bold: parent.hovered ? true : false
                            color: locationColor
                        }

                        background: Rectangle {
                            visible: false
                        }

                        onClicked: {
                            if (stopAllSharing) {
                                PositionManager.stopSharingPosition();
                            } else {
                                var component = Qt.createComponent("../../webengine/map/StopSharingPositionPopup.qml");
                                var sprite = component.createObject(root);
                                sprite.open()
                            }
                        }
                    }
                }

                PushButton {
                    id: btnClose

                    Layout.rightMargin: 20
                    width: 30
                    height: 30
                    imageContainerWidth: 30
                    imageContainerHeight : 30
                    radius : 5
                    imageColor: locationColor
                    normalColor: JamiTheme.transparentColor
                    source: JamiResources.round_close_24dp_svg
                    onClicked: {
                        root.ListView.view.visible = false
                    }
                }
            }
        }
    }
}
