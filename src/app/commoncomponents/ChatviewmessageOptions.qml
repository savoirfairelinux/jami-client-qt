import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Popup {
    id: root

    width: emojiColumn.width + JamiTheme.emojiMargins
    height: emojiColumn.height + JamiTheme.emojiMargins
    padding: 0

    property string msgId
    property string msg
    property string emojiReplied
    property bool out

    Rectangle {
        id: bubble

        color: JamiTheme.chatviewBgColor
        anchors.fill: parent
        radius: JamiTheme.modalPopupRadius

        ColumnLayout {
            id: emojiColumn

            anchors.centerIn: parent

            RowLayout {
                id: emojiRow

                Repeater {
                    // thumbsUp,face-with-tears-of-joy, angry-face
                    model: ["👍", "😂", "😠" ]

                    delegate:Button {
                        id: curButton

                        height: 50
                        width: 50
                        text: modelData
                        font.pointSize: JamiTheme.emojiBubbleSize

                        Text {
                            visible: curButton.hovered
                            anchors.centerIn: parent
                            text: modelData
                            font.pointSize: JamiTheme.emojiBubbleSizeBig
                            z: 1
                        }

                        background: Rectangle {
                            anchors.fill: parent
                            opacity: emojiReplied.includes(modelData) ? 1 : 0
                            color: JamiTheme.emojiReactPushButtonColor
                            radius: 10
                        }

                        onClicked: {
                            MessagesAdapter.reactMessage(CurrentConversation.id,text,msgId)
                        }
                    }
                }
            }

            Rectangle {
                Layout.topMargin: 5
                color: JamiTheme.timestampColor
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                radius: width * 0.5
            }

            RowLayout {
                PushButton {
                    id: copy

                    imageColor: JamiTheme.emojiReactPushButtonColor
                    normalColor: JamiTheme.transparentColor
                    source: JamiResources.copy_svg
                    onClicked: {
                        UtilsAdapter.setClipboardText(msg)
                    }
                }

                Text {
                    text: JamiStrings.copy
                    color: JamiTheme.chatviewTextColor
                }
            }

            RowLayout {
                visible: out

                PushButton {
                    id: edit

                    imageColor: JamiTheme.emojiReactPushButtonColor
                    normalColor: JamiTheme.transparentColor
                    source: JamiResources.edit_svg
                    onClicked: {
                        MessagesAdapter.replyToId = ""
                        MessagesAdapter.editId = root.msgId
                    }
                }

                Text {
                    text: JamiStrings.editMessage
                    color: JamiTheme.chatviewTextColor
                }
            }

            RowLayout {
                visible: out

                PushButton {
                    id: deleteMessage

                    imageColor: JamiTheme.emojiReactPushButtonColor
                    normalColor: JamiTheme.transparentColor
                    source: JamiResources.delete_svg
                    onClicked: {
                        MessagesAdapter.editMessage(CurrentConversation.id, "", root.msgId)
                    }
                }

                Text {
                    text: JamiStrings.deleteMessage
                    color: JamiTheme.chatviewTextColor
                }
            }
        }
    }

    background: Rectangle {
        color: JamiTheme.transparentColor
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
        // Color animation for overlay when pop up is shown.
        ColorAnimation on color {
            to: JamiTheme.popupOverlayColor
            duration: 500
        }
    }

    DropShadow {
        z: -1

        width: bubble.width
        height: bubble.height
        horizontalOffset: 3.0
        verticalOffset: 3.0
        radius: bubble.radius * 4
        color: JamiTheme.shadowColor
        source: bubble
        transparentBorder: true
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"; from: 0.0; to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }

    exit: Transition {
        NumberAnimation {
            properties: "opacity"; from: 1.0; to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}





