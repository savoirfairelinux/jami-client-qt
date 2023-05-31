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
    // Close this overlay when the parent is no longer visible.
    readonly property bool parentVisible: root.parent.visible
    onParentVisibleChanged: {
        if (!parentVisible)
            close()
    }

    // Used to make the call info items selectable/copyable.
    // Note: parent should have a non-zero width.
    component SelectableTextItem: TextEdit {
        readOnly: true
        wrapMode: Text.WrapAnywhere
        selectByMouse: true
        font.pointSize: JamiTheme.textFontPointSize
        color: JamiTheme.callInfoColor
        width: parent.width
    }

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

        JamiPushButton {
            id: copyButton

            // Hacky positioning of the copy button to the left of the close button.
            // Accessibilty is lightly disrupted here, but this is primarily a dev tool.
            parent: JamiQmlUtils.findChildByName(root.content, "closeButton")
            width: parent.width
            height: parent.height
            x: -width - 4
            imageContainerWidth: width
            imageContainerHeight: height

            imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
            normalColor: "transparent"

            source: JamiResources.content_copy_24dp_svg
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
                toastManager.instantiate(JamiStrings.copiedToClipboard, callOverlay);
            }
        }

        ColumnLayout {
            spacing: JamiTheme.callInformationBlockSpacing
            Layout.preferredWidth: callInfoListview.width
            Layout.alignment: Qt.AlignTop

            Text {
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
                    width: callInfoListview.width

                    SelectableTextItem {
                        text: JamiStrings.callId + ": " + CALL_ID
                    }

                    SelectableTextItem {
                        function stringWithoutRing(peerNumber) {
                            return peerNumber.replace("@ring.dht", "");
                        }
                        text: JamiStrings.peerNumber + ": " + stringWithoutRing(PEER_NUMBER)
                    }

                    Column {
                        id: socketLayout

                        property bool showAll: false
                        width: callInfoListview.width
                        bottomPadding: JamiTheme.callInformationBlockSpacing
                        topPadding: JamiTheme.callInformationBlockSpacing

                        RowLayout {
                            width: socketLayout.width

                            SelectableTextItem {
                                text: JamiStrings.sockets
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

                        SelectableTextItem {
                            text: SOCKETS
                            visible: socketLayout.showAll
                        }
                    }

                    SelectableTextItem {
                        text: JamiStrings.videoCodec + ": " + VIDEO_CODEC
                    }

                    SelectableTextItem {
                        text: JamiStrings.audioCodec + ": " + AUDIO_CODEC + " " + AUDIO_SAMPLE_RATE + " Hz"
                    }

                    SelectableTextItem {
                        text: JamiStrings.hardwareAcceleration + ": " + HARDWARE_ACCELERATION
                    }

                    SelectableTextItem {
                        text: JamiStrings.videoBitrate + ": " + VIDEO_BITRATE + " bps"
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
                    width: renderersInfoListview.width
                    spacing: JamiTheme.callInformationElementsSpacing

                    SelectableTextItem {
                        text: JamiStrings.rendererId + ": " + RENDERER_ID
                    }

                    SelectableTextItem {
                        text: JamiStrings.fps_short + ": " + FPS
                    }

                    SelectableTextItem {
                        text: JamiStrings.resolution + ": " + RES
                    }
                }
            }
        }
    }
}
