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

Window {
    id: root

    width: parent.width * 2 / 3
    height: parent.height * 2 / 3
    property var advancedList
    property var fps

    onClosing: {
        CallAdapter.stopTimerInformation()
    }

    Rectangle {
        id: container

        anchors.fill: parent
        color: JamiTheme.secondaryBackgroundColor

        RowLayout {
            id:  windowContent

            anchors.fill: parent

            ColumnLayout {
                spacing: JamiTheme.callInformationBlockSpacing

                Text{
                    color: JamiTheme.callInfoColor
                    text: "Call information"
                    font.pointSize: JamiTheme.titleFontPointSize
                }

                Item {
                    id: itemCallInformation

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    clip: true

                    ListView {
                        model: advancedList
                        width: parent.width
                        height: root.height
                        spacing: JamiTheme.callInformationBlockSpacing

                        delegate: Column {
                            spacing: JamiTheme.callInformationElementsSpacing

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Call id: " + modelData.CALL_ID
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Video codec: " + modelData.VIDEO_CODEC
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Audio codec: " + modelData.AUDIO_CODEC
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                function stringWithoutRing(peerNumber){
                                    return peerNumber.replace("@ring.dht","") ;
                                }
                                color: JamiTheme.callInfoColor
                                text: "PEER_NUMBER: " + stringWithoutRing(modelData.PEER_NUMBER)
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Hardware acceleration: " + modelData.HARDWARE_ACCELERATION
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Video min bitrate: " + modelData.VIDEO_MIN_BITRATE
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Video max bitrate: " + modelData.VIDEO_MAX_BITRATE
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Video bitrate: " + modelData.VIDEO_BITRATE
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemCallInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Sockets: " + modelData.SOCKETS
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

                Text {
                    color: JamiTheme.callInfoColor
                    text: "Renderers information"
                    font.pointSize: JamiTheme.titleFontPointSize
                }

                Item {
                    id: itemParticipantInformation

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    clip: true


                    ListView {
                        width: parent.width
                        height: root.height
                        spacing: JamiTheme.callInformationBlockSpacing
                        model: fps

                        delegate: Column {
                            spacing: JamiTheme.callInformationElementsSpacing

                            Text{
                                color: JamiTheme.callInfoColor
                                text: "Renderer id: " + modelData.ID
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemParticipantInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Fps: " + modelData.FPS
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemParticipantInformation.width
                            }

                            Text {
                                color: JamiTheme.callInfoColor
                                text: "Resolution: " + modelData.RES
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: itemParticipantInformation.width
                            }

                        }
                    }
                }
            }
        }
    }
}
