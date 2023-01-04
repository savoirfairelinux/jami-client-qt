/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects

import "../../commoncomponents"

Popup {
    id: root

    property real maxHeight: parent.height * 40 / 100

    property real informationHeight: {
        return Math.max(callInfoListview.contentHeight,
                        renderersInfoListview.contentHeight)
    }

    width: parent.width * 60/ 100
    height: maxHeight

    closePolicy: Popup.NoAutoClosed

    property var advancedList
    property var fps

    onClosed: {
        CallAdapter.stopTimerInformation()
    }
    onOpened: {
        console.warn("opening")
        AvAdapter.resetRendererInfos()
        CallAdapter.resetCallInfos()

        CallAdapter.setCallInfos()
        AvAdapter.setRendererInfos()
    }

    background: Rectangle {
        color: JamiTheme.transparentColor
    }

    Rectangle {
        id: container

        anchors.fill: parent
        color: JamiTheme.blackColor
        opacity: 0.85
        radius: 10

        PushButton {
            id: closeButton

            anchors.top: container.top
            anchors.topMargin: 5
            anchors.right: container.right
            anchors.rightMargin: 5
            normalColor: JamiTheme.transparentColor
            imageColor: JamiTheme.callInfoColor
            source: JamiResources.close_svg
            circled: false
            toolTipText: JamiStrings.close

            onClicked: {
                root.close()
            }
        }

        RowLayout {
            id:  windowContent

            anchors.fill: parent

            ColumnLayout {
                spacing: JamiTheme.callInformationBlockSpacing
                Layout.margins: JamiTheme.callInformationlayoutMargins

                Text{
                    color: JamiTheme.callInfoColor
                    text: JamiStrings.callInformation
                    font.pointSize: JamiTheme.titleFontPointSize
                }

                Item {
                    id: itemCallInformation

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    clip: true

                    ListView {
                        id: callInfoListview

                        model: advancedList
                        width: parent.width
                        height: {return Math.min (informationHeight, maxHeight)}
                        spacing: JamiTheme.callInformationBlockSpacing

                        delegate: Column {
                            spacing: JamiTheme.callInformationElementsSpacing

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Call id: " + CALL_ID
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                function stringWithoutRing(peerNumber){
                                    return peerNumber.replace("@ring.dht","") ;
                                }
                                color: JamiTheme.callInfoColor
                                text: "Peer number: " + stringWithoutRing(PEER_NUMBER)
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }
                            Column {
                                id: socketLayout

                                property bool showAll: false
                                width: itemCallInformation.width

                                RowLayout {
                                   Text {
                                        color: JamiTheme.callInfoColor
                                        text: "Sockets"
                                        font.pointSize: JamiTheme.textFontPointSize
                                        wrapMode: Text.WrapAnywhere
                                        width: itemCallInformation.width
                                    }

                                    PushButton {
                                        source: socketLayout.showAll ? JamiResources.expand_more_24dp_svg : JamiResources.expand_less_24dp_svg
                                        normalColor: JamiTheme.transparentColor
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        imageColor: JamiTheme.callInfoColor
                                        onClicked: {
                                            socketLayout.showAll = !socketLayout.showAll
                                        }
                                    }
                                }

                                Text {
                                    color: JamiTheme.callInfoColor
                                    text: SOCKETS
                                    font.pointSize: JamiTheme.textFontPointSize
                                    wrapMode: Text.WrapAnywhere
                                    visible: socketLayout.showAll
                                    width: parent.width
                                }
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Video codec: " + VIDEO_CODEC
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Audio codec: " + AUDIO_CODEC
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Hardware acceleration: " + HARDWARE_ACCELERATION
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Video bitrate: " + VIDEO_BITRATE + " bps"
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: JamiTheme.callInformationBlockSpacing
                Layout.margins: JamiTheme.callInformationlayoutMargins

                Text {
                    color: JamiTheme.callInfoColor
                    text: JamiStrings.renderersInformation
                    font.pointSize: JamiTheme.titleFontPointSize
                }

                Item {
                    id: itemParticipantInformation

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    clip: true


                    ListView {
                        id: renderersInfoListview

                        width: parent.width
                        height: {return Math.min (informationHeight, maxHeight)}
                        spacing: JamiTheme.callInformationBlockSpacing
                        model: fps

                        delegate: Column {
                            spacing: JamiTheme.callInformationElementsSpacing

                            Text{
                                color: JamiTheme.callInfoColor
                                text: "Renderer id: " + RENDERER_ID
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Fps: " + FPS
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Resolution: " + RES
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }
                        }
                    }
                }
            }
        }
    }
}
