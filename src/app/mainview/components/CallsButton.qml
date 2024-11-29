/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Rectangle {
    id: callButtonParent

    property bool darkTheme: UtilsAdapter.useApplicationTheme()
    property bool isDropDownOpen: false
    radius: 35
    color: darkTheme ? JamiTheme.blackColor : JamiTheme.whiteColor

    MouseArea {
        id: hoverArea

        z: 1
        anchors.fill: parent
        hoverEnabled: true
        enabled: CurrentConversation.activeCalls.length > 0
        onClicked: {
            isDropDownOpen = !isDropDownOpen;
        }
    }

    JamiPushButton {
        id: callButton

        source: JamiResources.place_audiocall_24dp_svg
        z: 2
        normalColor: "#20c68d"
        imageColor: "black"
        radius: 35
        preferredSize: 35
        hoveredColor: "#1fb983"

        anchors.left: callButtonParent.left
        anchors.verticalCenter: callButtonParent.verticalCenter

        onClicked: CallAdapter.placeCall()
    }

    Text {
        id: activeCallsText
        text: CurrentConversation.activeCalls.length > 0 ? CurrentConversation.activeCalls.length : qsTr("")
        color: JamiTheme.textColor
        font.pixelSize: 14
        anchors.right: expandArrow.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 3
    }

    JamiPushButton {
        id: expandArrow

        visible: true
        source: !isDropDownOpen ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg

        normalColor: "#00ffffff"
        imageColor: !darkTheme ? JamiTheme.blackColor : JamiTheme.whiteColor
        preferredSize: 25
        hoveredColor: normalColor
        anchors.right: callButtonParent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 3
    }

    Loader {
        id: dropdownLoader
        active: isDropDownOpen && CurrentConversation.activeCalls.length > 0
        sourceComponent: dropdownComponent
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height + 5
    }

    Loader {
        id: spinnerLoader
        active: CurrentConversation.activeCalls.length > 0
        sourceComponent: spinner
        anchors.centerIn: callButton
    }

    Component {
        id: dropdownComponent

        Rectangle {
            id: dropdownList
            width: 250
            height: listView.contentHeight + 10
            color: darkTheme ? JamiTheme.darkGreyColor : JamiTheme.lightGreyColor
            radius: 10

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 5
                model: CurrentConversation.activeCalls
                delegate: Rectangle {
                    id: delegateItem
                    width: listView.width
                    height: 50
                    color: "transparent"

                    property bool isHovered: false

                    Rectangle {
                        anchors.fill: parent
                        color: isHovered ? (darkTheme ? Qt.lighter(JamiTheme.darkGreyColor, 1.2) : Qt.darker(JamiTheme.lightGreyColor, 1.1)) : "transparent"
                        radius: 5
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 10

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                width: parent.width
                                text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, modelData.uri) + "'s call"
                                color: darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: "ID: " + modelData.id
                                color: darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }

                        JamiPushButton {
                            Layout.preferredWidth: 35
                            Layout.preferredHeight: 35
                            source: JamiResources.place_audiocall_24dp_svg
                            normalColor: "#20c68d"
                            imageColor: "black"
                            radius: 35
                            hoveredColor: normalColor
                            onClicked: {
                                console.log("Call button clicked for ID:", modelData.uri);
                                onClicked: MessagesAdapter.joinCall(ActionUri, DeviceId, root.confId, false)
                                // need to swithc between audio and video 
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            delegateItem.isHovered = true;
                        }
                        onExited: {
                            delegateItem.isHovered = false;
                        }
                    }
                }
            }
        }
    }

    Component {
        id: spinner

        Canvas {
            id: loadingWheel
            width: 39
            height: 39
            z: 1

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                const outerRadius = 19;
                const innerRadius = 17.5;
                const startAngle = animationAngle * Math.PI / 180;
                const endAngle = startAngle + Math.PI / 2;
                const gradient = ctx.createLinearGradient(width / 2 + outerRadius * Math.cos(startAngle), height / 2 + outerRadius * Math.sin(startAngle), width / 2 + outerRadius * Math.cos(endAngle), height / 2 + outerRadius * Math.sin(endAngle));
                gradient.addColorStop(0, "rgba(32, 198, 141, 0)");
                gradient.addColorStop(1, "rgba(32, 198, 141, 1)");
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, outerRadius, startAngle, endAngle, false);
                ctx.lineWidth = outerRadius - innerRadius;
                ctx.strokeStyle = gradient;
                ctx.stroke();
            }

            property real animationAngle: 0

            onAnimationAngleChanged: requestPaint()

            NumberAnimation on animationAngle {
                from: 0
                to: 360
                duration: 2000
                loops: Animation.Infinite
            }
        }
    }
}
