import QtQuick
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Item {
    id: root

    property var emojiReaction
    property var emojiReactionsSortedEmojis
//    width : bubble.width
//    height: bubble.right
//    Component.onCompleted: {
//        for (const reactions of Object.entries(emojiReaction) ) {
//            console.warn(reactions)
//            for (var j = 0; j < reactions.length; j ++) {
//               console.warn(reactions[j])
//            }
//        }
//        console.warn("end")
//    }

    Rectangle {
        id: bubble

        color: JamiTheme.chatviewBgColor
        width: textEmojis.width + 6
        height: textEmojis.height + 6
        radius: 10

        Text {
            id: textEmojis
            anchors.margins: 10
            text: {
                var cur = ""
                for (const reactions of Object.entries(emojiReactionsSortedEmojis) ) {
                    cur = cur + reactions[0] + reactions[1] + " "
                    console.warn (reactions)
                }
                return cur
            }
            anchors.centerIn: bubble
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



