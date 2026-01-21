/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
    color: showVideoJoin ? "transparent" : (darkTheme ? JamiTheme.blackColor : JamiTheme.backgroundColor)
    implicitWidth: activeCalls ? 80 : (showVideoJoin ? 82 : 36)

    property bool darkTheme: UtilsAdapter.useApplicationTheme()
    property bool isDropDownOpen: false
    property bool uniqueActiveCall: CurrentConversation.activeCalls.length === 1
    property bool activeCalls: CurrentConversation.activeCalls.length > 1
    property bool showVideoJoin: uniqueActiveCall && CurrentAccount.videoEnabled_Video

    RowLayout {

        anchors.fill: parent
        Layout.fillWidth: false
        spacing: showVideoJoin ? 10 : 0
        visible: uniqueActiveCall || activeCalls

        Item {
            id: activeCallButton

            implicitWidth: 36

            JamiPushButton {
                id: callButton
                source: JamiResources.start_audiocall_24dp_svg
                normalColor: JamiTheme.buttonCallLightGreen
                hoveredColor: JamiTheme.buttonCallDarkGreen
                imageColor: hovered ? JamiTheme.buttonCallLightGreen : JamiTheme.blackColor
                radius: 35
                preferredSize: 36
                imagePadding: 4
                anchors.verticalCenter: parent.verticalCenter
                toolTipText: JamiStrings.joinWithAudio
                onClicked: {
                    if (root.uniqueActiveCall && CurrentConversation.activeCalls.length > 0) {
                        var call = CurrentConversation.activeCalls[0];
                        MessagesAdapter.joinCall(call.uri, call.device, call.id, true);
                    } else {
                        CallAdapter.startAudioOnlyCall();
                    }
                }
            }

            SpinningAnimation {
                id: animation
                anchors.fill: callButton
                mode: SpinningAnimation.Mode.Radial
                color: callButton.hovered ? JamiTheme.buttonCallLightGreen : JamiTheme.buttonCallDarkGreen
                spinningAnimationWidth: 2
            }
        }

        Item {
            id: videoCallButton

            implicitWidth: 36
            visible: showVideoJoin

            JamiPushButton {
                id: vCallButton
                source: JamiResources.videocam_24dp_svg
                normalColor: JamiTheme.buttonCallLightGreen
                hoveredColor: JamiTheme.buttonCallDarkGreen
                imageColor: hovered ? JamiTheme.buttonCallLightGreen : JamiTheme.blackColor
                radius: 35
                preferredSize: 36
                imagePadding: 4
                anchors.verticalCenter: parent.verticalCenter
                toolTipText: JamiStrings.joinWithVideo
                onClicked: {
                    if (root.uniqueActiveCall && CurrentConversation.activeCalls.length > 0) {
                        var call = CurrentConversation.activeCalls[0];
                        MessagesAdapter.joinCall(call.uri, call.device, call.id, false);
                    }
                }
            }

            SpinningAnimation {
                id: vAnimation
                anchors.fill: vCallButton
                mode: SpinningAnimation.Mode.Radial
                color: vCallButton.hovered ? JamiTheme.buttonCallLightGreen : JamiTheme.buttonCallDarkGreen
                spinningAnimationWidth: 2
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
            enabled: !dropdownPopup.visible
            source: dropdownPopup.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg
            normalColor: JamiTheme.transparentColor
            imageColor: !darkTheme ? JamiTheme.blackColor : JamiTheme.whiteColor
            preferredSize: 20
            hoveredColor: normalColor
            Layout.rightMargin: 5

            onClicked: {
                dropdownPopup.open();
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
                color: JamiTheme.transparentColor
                property bool isHovered: false

                Rectangle {
                    anchors.fill: parent
                    color: isHovered ? (darkTheme ? Qt.lighter(JamiTheme.darkGreyColor, 1.2) : Qt.darker(JamiTheme.lightGrey_, 1.1)) : JamiTheme.transparentColor
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
                            font.pixelSize: JamiTheme.headerFontSize
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: modelData.uri
                            color: darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    JamiPushButton {
                        Layout.preferredWidth: 35
                        Layout.preferredHeight: 35
                        source: JamiResources.start_audiocall_24dp_svg
                        normalColor: JamiTheme.buttonCallLightGreen
                        imageColor: darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor
                        radius: 35
                        onClicked: {
                            MessagesAdapter.joinCall(modelData.uri, modelData.device, modelData.id, true); //CurrentCall.isAudioOnly
                            dropdownPopup.close();
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
