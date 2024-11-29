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
    id: root

    radius: 35
    color: darkTheme ? JamiTheme.blackColor : JamiTheme.backgroundColor
    width: activeCalls ? 80 : 36

    property bool darkTheme: UtilsAdapter.useApplicationTheme()
    property bool isDropDownOpen: false
    property bool activeCalls: CurrentConversation.activeCalls.length > 0

    RowLayout {

        anchors.fill: parent
        Layout.fillWidth: false
        spacing: 0

        Item {

            implicitWidth: 36

            JamiPushButton {
                id: callButton
                source: JamiResources.place_audiocall_24dp_svg
                normalColor: "#20c68d"
                hoveredColor: "#00796B"
                imageColor: hovered ? "#20c68d" : "black"
                radius: 35
                preferredSize: 36
                anchors.verticalCenter: parent.verticalCenter
                onClicked: CallAdapter.placeCall()
            }

            Loader {
                id: spinnerLoader
                active: CurrentConversation.activeCalls.length > 0
                sourceComponent: spinner
                anchors.centerIn: callButton
            }

            Component {
                id: spinner

                Canvas {
                    id: loadingWheel
                    antialiasing: true
                    property real centerWidth: spinnerLoader.width / 2
                    property real centerHeight: spinnerLoader.height / 2
                    property real radius: Math.min(spinnerLoader.width, spinnerLoader.height) / 2
                    property real lineWidth: 2
                    width: 44
                    height: 44

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var radius = (Math.min(spinnerLoader.width, spinnerLoader.height) / 2) - 3;
                        const startAngle = animationAngle * Math.PI / 180;
                        const endAngle = startAngle + Math.PI / 2;
                        const gradient = ctx.createLinearGradient(width / 2 + radius * Math.cos(startAngle), height / 2 + radius * Math.sin(startAngle), width / 2 + radius * Math.cos(endAngle), height / 2 + radius * Math.sin(endAngle));
                        gradient.addColorStop(0, "rgba(32, 198, 141, 0)");
                        gradient.addColorStop(1, "rgba(32, 198, 141, 1)");
                        ctx.beginPath();
                        ctx.lineWidth = lineWidth;
                        ctx.strokeStyle = gradient;
                        ctx.arc(centerWidth, centerHeight, radius, startAngle, endAngle, false);
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

        Text {
            id: activeCallsText
            text: CurrentConversation.activeCalls.length
            color: JamiTheme.textColor
            font.pixelSize: 14
            visible: activeCalls
        }

        JamiPushButton {
            id: expandArrow
            visible: activeCalls

            source: dropdownPopup.visible ? JamiResources.expand_more_24dp_svg : JamiResources.expand_less_24dp_svg
            normalColor: "#00ffffff"
            imageColor: !darkTheme ? JamiTheme.blackColor : JamiTheme.whiteColor
            preferredSize: 20
            hoveredColor: normalColor
            Layout.rightMargin: 5

            onClicked: {
                if (dropdownPopup.visible) {
                    dropdownPopup.close();
                } else {
                    dropdownPopup.open();
                }
            }
        }
    }

    Popup {
        id: dropdownPopup

        y: root.height + 5
        x: -root.width

        width: 250
        height: Math.min(contentItem.implicitHeight + 10, 300)
        padding: 5
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: darkTheme ? JamiTheme.darkGreyColor : JamiTheme.lightGrey_
            radius: 10
        }
        contentItem: ListView {
            id: listView

            implicitHeight: contentHeight
            model: CurrentConversation.activeCalls
            clip: true
            spacing: 5

            delegate: Rectangle {
                id: delegateItem

                width: listView.width
                height: 50
                color: "transparent"
                property bool isHovered: false

                Rectangle {
                    anchors.fill: parent
                    color: isHovered ? (darkTheme ? Qt.lighter(JamiTheme.darkGreyColor, 1.2) : Qt.darker(JamiTheme.lightGrey_, 1.1)) : "transparent"
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
                            text: {
                                "text";

                                //console.info(modelData.id)
                                //console.info(CallAdapter.getCallDurationTime(currentAccountId, modelData.id)) //currentAccountId

                            }
                            color: darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    JamiPushButton {
                        Layout.preferredWidth: 35
                        Layout.preferredHeight: 35
                        source: CurrentCall.isAudioOnly ? JamiResources.place_audiocall_24dp_svg : JamiResources.videocam_24dp_svg
                        normalColor: "#20c68d"
                        imageColor: "black"
                        radius: 35
                        hoveredColor: "pink"

                        onClicked: {
                            console.info("Call button clicked for ID:", modelData.uri);
                            MessagesAdapter.joinCall(modalData.ActionUri, modalData.DeviceId, CurrentConversation.confId, CurrentCall.isAudioOnly);
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: delegateItem.isHovered = true
                    onExited: delegateItem.isHovered = false
                    acceptedButtons: Qt.NoButton
                }
            }
        }
    }
}
