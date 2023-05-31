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
import "../../commoncomponents"

Popup {
    id: root

    property real maxHeight: parent.height * 40 / 100
    property real maxTextWidth: parent.width * 30 / 100

    property var advancedList
    property var fps

    width: container.width
    height: container.height
    closePolicy: Popup.NoAutoClosed

    onClosed: {
        CallAdapter.stopTimerInformation();
    }

    onOpened: {
        AvAdapter.resetRendererInfo();
        CallAdapter.resetCallInfo();
        CallAdapter.setCallInfo();
        AvAdapter.setRendererInfo();
    }

    background: Rectangle {
        color: JamiTheme.transparentColor
    }

    component SelectableTextItem: TextEdit {
        readOnly: true
        wrapMode: Text.WrapAnywhere
        selectByMouse: true
        font.pointSize: JamiTheme.textFontPointSize
        color: JamiTheme.callInfoColor
    }

    Rectangle {
        id: container

        color: JamiTheme.blackColor
        opacity: 0.85
        radius: 10
        width: windowContent.width
        height: windowContent.height

        // A copy-to-clipboard button to the left of the close button.
        PushButton {
            id: copyButton

            anchors.top: closeButton.top
            anchors.right: closeButton.left
            anchors.rightMargin: 5
            normalColor: JamiTheme.transparentColor
            imageColor: JamiTheme.callInfoColor
            source: JamiResources.content_copy_24dp_svg
            circled: false
            toolTipText: JamiStrings.copyToClipboard

            onClicked: {
                var text = "";
                function getSelectableText(parent) {
                    for (var i = 0; i < parent.children.length; i++)
                        if (parent.children[i] instanceof TextEdit)
                            text += parent.children[i].text + "\n";
                        else
                            getSelectableText(parent.children[i]);
                }
                getSelectableText(callInfoListview);
                text += "\n";
                getSelectableText(renderersInfoListview);
                UtilsAdapter.setClipboardText(text);
                toastManager.instantiate(JamiStrings.copiedToClipboard, container);
            }
        }

        PushButton {
            id: closeButton

            anchors.top: container.top
            anchors.topMargin: 5
            anchors.right: container.right
            anchors.rightMargin: 5
            normalColor: JamiTheme.transparentColor
            imageColor: JamiTheme.callInfoColor
            source: JamiResources.round_close_24dp_svg
            circled: false
            toolTipText: JamiStrings.close

            onClicked: {
                root.close();
            }
        }

        RowLayout {
            id: windowContent

            ColumnLayout {
                spacing: JamiTheme.callInformationBlockSpacing
                Layout.margins: JamiTheme.callInformationlayoutMargins
                Layout.preferredWidth: callInfoListview.width
                Layout.alignment: Qt.AlignTop

                Text {
                    color: JamiTheme.callInfoColor
                    text: JamiStrings.callInformation
                    font.pointSize: JamiTheme.titleFontPointSize
                }

                ListView {
                    id: callInfoListview

                    model: advancedList
                    Layout.preferredWidth: root.maxTextWidth
                    Layout.preferredHeight: contentItem.childrenRect.height < root.maxHeight ? contentItem.childrenRect.height : root.maxHeight
                    spacing: JamiTheme.callInformationBlockSpacing
                    clip: true

                    delegate: Column {
                        spacing: JamiTheme.callInformationElementsSpacing

                        SelectableTextItem {
                            text: JamiStrings.callId + ": " + CALL_ID
                            width: callInfoListview.width
                        }

                        SelectableTextItem {
                            text: JamiStrings.peerNumber + ": " + PEER_NUMBER.replace("@ring.dht", "")
                            width: callInfoListview.width
                        }
                        Column {
                            id: socketLayout

                            property bool showAll: false
                            width: callInfoListview.width

                            RowLayout {
                                SelectableTextItem {
                                    text: JamiStrings.sockets
                                    width: socketLayout.width
                                }

                                PushButton {
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

                            SelectableTextItem {
                                text: SOCKETS
                                visible: socketLayout.showAll
                                width: socketLayout.width
                            }
                        }

                        SelectableTextItem {
                            text: JamiStrings.videoCodec + ": " + VIDEO_CODEC
                            width: callInfoListview.width
                        }

                        SelectableTextItem {
                            text: JamiStrings.audioCodec + ": " + AUDIO_CODEC + " " + AUDIO_SAMPLE_RATE + " Hz"
                            width: callInfoListview.width
                        }

                        SelectableTextItem {
                            text: JamiStrings.hardwareAcceleration + ": " + HARDWARE_ACCELERATION
                            width: callInfoListview.width
                        }

                        SelectableTextItem {
                            text: JamiStrings.videoBitrate + ": " + VIDEO_BITRATE + " bps"
                            width: callInfoListview.width
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: JamiTheme.callInformationBlockSpacing
                Layout.margins: JamiTheme.callInformationlayoutMargins
                Layout.preferredWidth: renderersInfoListview.width
                Layout.alignment: Qt.AlignTop

                Text {
                    color: JamiTheme.callInfoColor
                    text: JamiStrings.renderersInformation
                    font.pointSize: JamiTheme.titleFontPointSize
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

                        SelectableTextItem {
                            text: JamiStrings.rendererId + ": " + RENDERER_ID
                            width: renderersInfoListview.width
                        }

                        SelectableTextItem {
                            text: JamiStrings.fps_short + ": " + FPS
                            width: renderersInfoListview.width
                        }

                        SelectableTextItem {
                            text: JamiStrings.resolution + ": " + RES
                            width: renderersInfoListview.width
                        }
                    }
                }
            }
        }
    }
}
