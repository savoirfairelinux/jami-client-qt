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

BaseModalDialog {
    id: root

    property real maxHeight: parent.height * 40 / 100
    property real maxTextWidth: parent.width * 20 / 100

    property var advancedList
    property var fps
    maximumPopupWidth: popupContent.width + 2 * popupMargins

    // Allow user input elsewhere on the screen.
    modal: false
    // Keep the overlay open until the user closes it.
    autoClose: false
    // Override the Overlay parent so that the popup is positioned
    // relative to the call overlay when we disable the centering.
    parent: root.parent
    anchors.centerIn: undefined

    onClosed: CallAdapter.stopTimerInformation()
    onOpened: {
        AvAdapter.resetRendererInfo();
        CallAdapter.resetCallInfo();
        CallAdapter.setCallInfo();
        AvAdapter.setRendererInfo();
    }

    backgroundColor: JamiTheme.darkGreyColor
    backgroundOpacity: 0.77

    popupContent: RowLayout {
        id: windowContent
        spacing: JamiTheme.callInformationBlockSpacing

        ColumnLayout {
            spacing: JamiTheme.callInformationBlockSpacing
            Layout.preferredWidth: callInfoListview.width
            Layout.alignment: Qt.AlignTop

            Text {
                id: textTest
                color: JamiTheme.callInfoColor
                text: JamiStrings.callInformation
                font.pointSize: JamiTheme.menuFontSize
                font.bold: true
                Layout.maximumWidth: root.maxTextWidth
                elide: Text.ElideRight
            }

            ListView {
                id: callInfoListview

                model: advancedList
                Layout.preferredWidth: root.maxTextWidth
                Layout.preferredHeight: contentItem.childrenRect.height < root.maxHeight ? contentItem.childrenRect.height : root.maxHeight
                clip: true

                delegate: Column {

                    Text {
                        color: JamiTheme.callInfoColor
                        text: JamiStrings.callId + ": " + CALL_ID
                        font.pointSize: JamiTheme.textFontPointSize
                        wrapMode: Text.WrapAnywhere
                        width: callInfoListview.width
                    }

                    Text {
                        function stringWithoutRing(peerNumber) {
                            return peerNumber.replace("@ring.dht", "");
                        }
                        color: JamiTheme.callInfoColor
                        text: JamiStrings.peerNumber + ": " + stringWithoutRing(PEER_NUMBER)
                        font.pointSize: JamiTheme.textFontPointSize
                        wrapMode: Text.WrapAnywhere
                        width: callInfoListview.width
                    }
                    Column {
                        id: socketLayout

                        property bool showAll: false
                        width: callInfoListview.width
                        bottomPadding: JamiTheme.callInformationBlockSpacing
                        topPadding: JamiTheme.callInformationBlockSpacing

                        RowLayout {

                            Text {
                                color: JamiTheme.callInfoColor
                                text: JamiStrings.sockets
                                font.pointSize: JamiTheme.textFontPointSize
                                wrapMode: Text.WrapAnywhere
                                width: socketLayout.width
                            }

                            JamiPushButton {
                                source: socketLayout.showAll ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg
                                normalColor: JamiTheme.transparentColor
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                imageColor: JamiTheme.callInfoColor
                                onClicked: {
                                    socketLayout.showAll = !socketLayout.showAll;
                                }
                            }
                        }

                        Text {
                            color: JamiTheme.callInfoColor
                            text: SOCKETS
                            font.pointSize: JamiTheme.textFontPointSize
                            wrapMode: Text.WrapAnywhere
                            visible: socketLayout.showAll
                            width: socketLayout.width
                        }
                    }

                    Text {
                        color: JamiTheme.callInfoColor
                        text: JamiStrings.videoCodec + ": " + VIDEO_CODEC
                        font.pointSize: JamiTheme.textFontPointSize
                        wrapMode: Text.WrapAnywhere
                        width: callInfoListview.width
                    }

                    Text {
                        color: JamiTheme.callInfoColor
                        text: JamiStrings.audioCodec + ": " + AUDIO_CODEC + " " + AUDIO_SAMPLE_RATE + " Hz"
                        font.pointSize: JamiTheme.textFontPointSize
                        wrapMode: Text.WrapAnywhere
                        width: callInfoListview.width
                    }

                    Text {
                        color: JamiTheme.callInfoColor
                        text: JamiStrings.hardwareAcceleration + ": " + HARDWARE_ACCELERATION
                        font.pointSize: JamiTheme.textFontPointSize
                        wrapMode: Text.WrapAnywhere
                        width: callInfoListview.width
                    }

                    Text {
                        color: JamiTheme.callInfoColor
                        text: JamiStrings.videoBitrate + ": " + VIDEO_BITRATE + " bps"
                        font.pointSize: JamiTheme.textFontPointSize
                        wrapMode: Text.WrapAnywhere
                        width: callInfoListview.width
                    }
                }
            }
        }

        ColumnLayout {
            spacing: JamiTheme.callInformationBlockSpacing
            Layout.preferredWidth: renderersInfoListview.width
            Layout.alignment: Qt.AlignTop

            Text {
                color: JamiTheme.callInfoColor
                text: JamiStrings.renderersInformation
                font.pointSize: JamiTheme.menuFontSize
                font.bold: true
                elide: Text.ElideRight
                Layout.maximumWidth: root.maxTextWidth
            }

            ListView {
                id: renderersInfoListview

                Layout.preferredWidth: root.maxTextWidth
                Layout.preferredHeight: contentItem.childrenRect.height < root.maxHeight ? contentItem.childrenRect.height : root.maxHeight
                spacing: JamiTheme.callInformationBlockSpacing
                model: fps
                clip: true

                delegate: Column {
                    spacing: JamiTheme.callInformationElementsSpacing

                    Text {
                        color: JamiTheme.callInfoColor
                        text: JamiStrings.rendererId + ": " + RENDERER_ID
                        font.pointSize: JamiTheme.textFontPointSize
                        wrapMode: Text.WrapAnywhere
                        width: renderersInfoListview.width
                    }

                    Text {
                        id: testText
                        color: JamiTheme.callInfoColor
                        text: JamiStrings.fps_short + ": " + FPS
                        font.pointSize: JamiTheme.textFontPointSize
                        wrapMode: Text.WrapAnywhere
                        width: renderersInfoListview.width
                    }

                    Text {
                        color: JamiTheme.callInfoColor
                        text: JamiStrings.resolution + ": " + RES
                        font.pointSize: JamiTheme.textFontPointSize
                        wrapMode: Text.WrapAnywhere
                        width: renderersInfoListview.width
                    }
                }
            }
        }
    }
}
