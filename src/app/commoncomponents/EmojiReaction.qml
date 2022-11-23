import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1


Item {
    id: root
    width: bubble.width
    height: bubble.height

    property string msgId

    Rectangle {
        id: bubble

        width: emojiRow.implicitWidth + 20
        height: emojiRow.implicitHeight + 20

        color: "white"
        radius: 10

        RowLayout {
            id: emojiRow
            anchors.centerIn: parent

            Repeater {
                // thumbsUp, red-heart, face-with-tears-of-joy,
                // crying-face, angry-face, astonished-face
                model: ["👍", "❤️", "😂", "😢", "😠" , "😲"]

                delegate:Button {
                    id: curButton

                    hoverEnabled: true
                    text: modelData
                    font.pointSize: hovered
                                    ? JamiTheme.emojiBubbleSizeBig
                                    : JamiTheme.emojiBubbleSize

                    background: Rectangle {
                        opacity: 0
                    }

                    onClicked: {
                        MessagesAdapter.reactMessage(CurrentConversation.id,text,msgId)
                    }

                    onHoveredChanged: {
                        console.warn(curButton.hovered)
                    }
                }
            }

            PushButton {
                id: reply

                normalColor: "transparent"
                toolTipText: "Reply"
                source: JamiResources.reply_svg
            }

            PushButton {
                id: more

                normalColor: "transparent"
                toolTipText: "More"
                source: JamiResources.round_add_24dp_svg
            }
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
}





