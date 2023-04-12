/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
    property var advancedList
    property var fps
    property real maxHeight: parent.height * 40 / 100
    property real maxTextWidth: parent.width * 30 / 100

    closePolicy: Popup.NoAutoClosed
    height: container.height
    width: container.width

    onClosed: {
        CallAdapter.stopTimerInformation();
    }
    onOpened: {
        AvAdapter.resetRendererInfo();
        CallAdapter.resetCallInfo();
        CallAdapter.setCallInfo();
        AvAdapter.setRendererInfo();
    }

    Rectangle {
        id: container
        color: JamiTheme.blackColor
        height: windowContent.height
        opacity: 0.85
        radius: 10
        width: windowContent.width

        PushButton {
            id: closeButton
            anchors.right: container.right
            anchors.rightMargin: 5
            anchors.top: container.top
            anchors.topMargin: 5
            circled: false
            imageColor: JamiTheme.callInfoColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.round_close_24dp_svg
            toolTipText: JamiStrings.close

            onClicked: {
                root.close();
            }
        }
        RowLayout {
            id: windowContent
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.margins: JamiTheme.callInformationlayoutMargins
                Layout.preferredWidth: callInfoListview.width
                spacing: JamiTheme.callInformationBlockSpacing

                Text {
                    id: textTest
                    color: JamiTheme.callInfoColor
                    font.pointSize: JamiTheme.titleFontPointSize
                    text: JamiStrings.callInformation
                }
                ListView {
                    id: callInfoListview
                    Layout.preferredHeight: contentItem.childrenRect.height < root.maxHeight ? contentItem.childrenRect.height : root.maxHeight
                    Layout.preferredWidth: root.maxTextWidth
                    clip: true
                    model: advancedList
                    spacing: JamiTheme.callInformationBlockSpacing

                    delegate: Column {
                        spacing: JamiTheme.callInformationElementsSpacing

                        Text {
                            color: JamiTheme.callInfoColor
                            font.pointSize: JamiTheme.textFontPointSize
                            text: JamiStrings.callId + ": " + CALL_ID
                            width: callInfoListview.width
                            wrapMode: Text.WrapAnywhere
                        }
                        Text {
                            color: JamiTheme.callInfoColor
                            font.pointSize: JamiTheme.textFontPointSize
                            text: JamiStrings.peerNumber + ": " + stringWithoutRing(PEER_NUMBER)
                            width: callInfoListview.width
                            wrapMode: Text.WrapAnywhere

                            function stringWithoutRing(peerNumber) {
                                return peerNumber.replace("@ring.dht", "");
                            }
                        }
                        Column {
                            id: socketLayout
                            property bool showAll: false

                            width: callInfoListview.width

                            RowLayout {
                                Text {
                                    color: JamiTheme.callInfoColor
                                    font.pointSize: JamiTheme.textFontPointSize
                                    text: JamiStrings.sockets
                                    width: socketLayout.width
                                    wrapMode: Text.WrapAnywhere
                                }
                                PushButton {
                                    Layout.preferredHeight: 20
                                    Layout.preferredWidth: 20
                                    imageColor: JamiTheme.callInfoColor
                                    normalColor: JamiTheme.transparentColor
                                    source: socketLayout.showAll ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg

                                    onClicked: {
                                        socketLayout.showAll = !socketLayout.showAll;
                                    }
                                }
                            }
                            Text {
                                color: JamiTheme.callInfoColor
                                font.pointSize: JamiTheme.textFontPointSize
                                text: SOCKETS
                                visible: socketLayout.showAll
                                width: socketLayout.width
                                wrapMode: Text.WrapAnywhere
                            }
                        }
                        Text {
                            color: JamiTheme.callInfoColor
                            font.pointSize: JamiTheme.textFontPointSize
                            text: JamiStrings.videoCodec + ": " + VIDEO_CODEC
                            width: callInfoListview.width
                            wrapMode: Text.WrapAnywhere
                        }
                        Text {
                            color: JamiTheme.callInfoColor
                            font.pointSize: JamiTheme.textFontPointSize
                            text: JamiStrings.audioCodec + ": " + AUDIO_CODEC + " " + AUDIO_SAMPLE_RATE + " Hz"
                            width: callInfoListview.width
                            wrapMode: Text.WrapAnywhere
                        }
                        Text {
                            color: JamiTheme.callInfoColor
                            font.pointSize: JamiTheme.textFontPointSize
                            text: JamiStrings.hardwareAcceleration + ": " + HARDWARE_ACCELERATION
                            width: callInfoListview.width
                            wrapMode: Text.WrapAnywhere
                        }
                        Text {
                            color: JamiTheme.callInfoColor
                            font.pointSize: JamiTheme.textFontPointSize
                            text: JamiStrings.videoBitrate + ": " + VIDEO_BITRATE + " bps"
                            width: callInfoListview.width
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.margins: JamiTheme.callInformationlayoutMargins
                Layout.preferredWidth: renderersInfoListview.width
                spacing: JamiTheme.callInformationBlockSpacing

                Text {
                    color: JamiTheme.callInfoColor
                    font.pointSize: JamiTheme.titleFontPointSize
                    text: JamiStrings.renderersInformation
                }
                ListView {
                    id: renderersInfoListview
                    Layout.preferredHeight: contentItem.childrenRect.height < root.maxHeight ? contentItem.childrenRect.height : root.maxHeight
                    Layout.preferredWidth: root.maxTextWidth
                    clip: true
                    model: fps
                    spacing: JamiTheme.callInformationBlockSpacing

                    delegate: Column {
                        spacing: JamiTheme.callInformationElementsSpacing

                        Text {
                            color: JamiTheme.callInfoColor
                            font.pointSize: JamiTheme.textFontPointSize
                            text: JamiStrings.rendererId + ": " + RENDERER_ID
                            width: renderersInfoListview.width
                            wrapMode: Text.WrapAnywhere
                        }
                        Text {
                            id: testText
                            color: JamiTheme.callInfoColor
                            font.pointSize: JamiTheme.textFontPointSize
                            text: JamiStrings.fps_short + ": " + FPS
                            width: renderersInfoListview.width
                            wrapMode: Text.WrapAnywhere
                        }
                        Text {
                            color: JamiTheme.callInfoColor
                            font.pointSize: JamiTheme.textFontPointSize
                            text: JamiStrings.resolution + ": " + RES
                            width: renderersInfoListview.width
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }
        }
    }

    background: Rectangle {
        color: JamiTheme.transparentColor
    }
}
