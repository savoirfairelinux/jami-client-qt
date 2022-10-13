import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import QtWebEngine

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../settingsview/components"

Component {
    id: localMediaMsgComp

    Rectangle {
        id: localMediaRect

        width: (documents.width - spacingLength) /  numberElementsPerRow
        height: width
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins

            Text {
                id: myText

                text: TransferName
                color: JamiTheme.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.preferredHeight: parent.height - myText.height - JamiTheme.swarmDetailsPageDocumentsMargins
                Layout.preferredWidth: parent.width
                Layout.rightMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                Layout.bottomMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                color: "transparent"

                Rectangle {
                    id: rectContent

                    anchors.fill: parent
                    anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins
                    color: CurrentConversation.color
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Item {
                            width: localMediaCompLoader.width
                            height: localMediaCompLoader.height
                            Rectangle {
                                anchors.centerIn: parent
                                width:  localMediaCompLoader.width
                                height: localMediaCompLoader.height
                                radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                            }
                        }
                    }

                    Loader {
                        id: localMediaCompLoader

                        property var mediaInfo: MessagesAdapter.getMediaInfo(Body)
                        anchors.fill: parent
                        anchors.margins: 2
                        sourceComponent: {
                            if (mediaInfo.isImage || mediaInfo.isAnimatedImage )
                                return imageMediaComp
                            else if (WITH_WEBENGINE)
                                return avMediaComp
                        }
                        Component {
                            id: avMediaComp

                            Loader {
                                property real msgRadius: 20

                                Rectangle {
                                    id: videoAudioRect
                                    color: JamiTheme.secondaryBackgroundColor
                                    anchors.fill: parent

                                    WebEngineView {
                                        id: wev

                                        property bool isVideo: mediaInfo.isVideo
                                        property string html: mediaInfo.html

                                        anchors.fill: parent
                                        anchors.verticalCenter: videoAudioRect.verticalCenter
                                        backgroundColor: JamiTheme.secondaryBackgroundColor
                                        anchors.topMargin: isVideo? 0 :  wev.implicitHeight / 2
                                        settings.fullScreenSupportEnabled: isVideo
                                        settings.javascriptCanOpenWindows: false
                                        Component.onCompleted: loadHtml(html, 'file://')
                                        onFullScreenRequested: function(request) {
                                            if (request.toggleOn) {
                                                layoutManager.pushFullScreenItem(
                                                            this,
                                                            videoAudioRect,
                                                            null,
                                                            function() { wev.fullScreenCancelled() })
                                            } else if (!request.toggleOn) {
                                                layoutManager.removeFullScreenItem(this)
                                            }
                                            request.accept()
                                        }
                                    }

                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Item {
                                            width: videoAudioRect.width
                                            height: videoAudioRect.height
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width:  videoAudioRect.width
                                                height: videoAudioRect.height
                                                radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Component {
                            id: imageMediaComp

                            Image {
                                id: fileImage

                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: "file:///" + Body
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Item {
                                        width: fileImage.width
                                        height: fileImage.height
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width:  fileImage.width
                                            height: fileImage.height
                                            radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                                    onEntered: {
                                        cursorShape = Qt.PointingHandCursor
                                    }

                                    onClicked: function(mouse)  {
                                        if (mouse.button === Qt.RightButton) {
                                            ctxMenu.x = mouse.x
                                            ctxMenu.y = mouse.y
                                            ctxMenu.openMenu()
                                        } else {
                                            MessagesAdapter.openUrl(fileImage.source)
                                        }
                                    }
                                }

                                SBSContextMenu {
                                    id: ctxMenu

                                    msgId: Id
                                    location: Body
                                    transferId: Id
                                    transferName: TransferName
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
