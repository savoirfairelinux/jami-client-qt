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
                model: emojiList

                delegate:Text {
                    text: String.fromCodePoint(codepoint,codepoint2)
                    font.pointSize: mouseAreaEmoji.containsMouse
                                    ? JamiTheme.emojiBubbleSizeBig
                                    : JamiTheme.emojiBubbleSize
                    MouseArea {
                        id: mouseAreaEmoji
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            console.warn("clicked")
                        }

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

    ListModel {
        id: emojiList

        ListElement {
            name: "thumbsUp"
            codepoint: 0x1F44D
        }
        ListElement {
            name: "redHeart"
            codepoint: 0x2764
            codepoint2: 0xFE0F
        }
        ListElement {
            name: "faceWithTearsOfJoy"
            codepoint: 0x1F602
        }
        ListElement {
            name: "cryingFace"
            codepoint: 0x1F622
        }
        ListElement {
            name: "angryFace"
            codepoint: 0x1F620
        }
        ListElement {
            name: "astonishedFace"
            codepoint: 0x1F632
        }
    }
}





