/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../settingsview/components"

Component {
    id: root
    Rectangle {
        id: localMediaRect
        color: "transparent"
        height: width
        width: (flickableWidth - spacingLength) / numberElementsPerRow

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins

            Text {
                id: mediaName
                Layout.fillWidth: true
                color: JamiTheme.textColor
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: TransferName
            }
            Rectangle {
                Layout.bottomMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                Layout.preferredHeight: parent.height - mediaName.height - JamiTheme.swarmDetailsPageDocumentsMargins
                Layout.preferredWidth: parent.width
                Layout.rightMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                color: "transparent"

                Rectangle {
                    id: rectContent
                    anchors.fill: parent
                    anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins
                    color: themeColor
                    layer.enabled: true

                    Loader {
                        id: localMediaCompLoader
                        property var mediaInfo: MessagesAdapter.getMediaInfo(Body)

                        anchors.fill: parent
                        anchors.margins: 2
                        sourceComponent: {
                            if (mediaInfo.isImage || mediaInfo.isAnimatedImage)
                                return imageMediaComp;
                            else if (WITH_WEBENGINE)
                                return avMediaComp;
                        }

                        Component {
                            id: avMediaComp
                            Loader {
                                property real msgRadius: 20

                                Component.onCompleted: {
                                    var qml = WITH_WEBENGINE ? "qrc:/webengine/VideoPreview.qml" : "qrc:/nowebengine/VideoPreview.qml";
                                    setSource(qml, {
                                            "isVideo": mediaInfo.isVideo,
                                            "html": mediaInfo.html
                                        });
                                }
                            }
                        }
                        Component {
                            id: imageMediaComp
                            Image {
                                id: fileImage
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                layer.enabled: true
                                source: "file://" + Body

                                MouseArea {
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: function (mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            ctxMenu.x = mouse.x;
                                            ctxMenu.y = mouse.y;
                                            ctxMenu.openMenu();
                                        } else {
                                            MessagesAdapter.openUrl(fileImage.source);
                                        }
                                    }
                                    onEntered: {
                                        cursorShape = Qt.PointingHandCursor;
                                    }
                                }
                                SBSContextMenu {
                                    id: ctxMenu
                                    location: Body
                                    msgId: Id
                                    transferId: Id
                                    transferName: TransferName
                                }

                                layer.effect: OpacityMask {
                                    maskSource: Item {
                                        height: fileImage.height
                                        width: fileImage.width

                                        Rectangle {
                                            anchors.centerIn: parent
                                            height: fileImage.height
                                            radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                                            width: fileImage.width
                                        }
                                    }
                                }
                            }
                        }
                    }

                    layer.effect: OpacityMask {
                        maskSource: Item {
                            height: localMediaCompLoader.height
                            width: localMediaCompLoader.width

                            Rectangle {
                                anchors.centerIn: parent
                                height: localMediaCompLoader.height
                                radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                                width: localMediaCompLoader.width
                            }
                        }
                    }
                }
            }
        }
    }
}
