import QtQuick
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Item {
    id: root

    property var emojiReaction
    property real contentHeight: bubble.height
    property real contentWidth: bubble.width
    property string emojiTexts: textEmojis.text

    Rectangle {
        id: bubble

        color: JamiTheme.chatviewBgColor
        width: textEmojis.width + 6
        height: textEmojis.height + 6
        radius: 10

        Text {
            id: textEmojis

            anchors.margins: 10
            anchors.centerIn: bubble
            font.pointSize: JamiTheme.emojiReactSize
            text: {
                var space = ""
                var emojiList = []
                var emojiNumberList = []
                for (const reactions of Object.entries(emojiReaction)) {
                    for (var emojiIndex in reactions[1]) {
                        var emoji = reactions[1][emojiIndex]
                        if (emojiList.includes(emoji)) {
                            var findIndex = emojiList.indexOf(emoji)
                            if (findIndex != -1)
                                emojiNumberList[findIndex] += 1
                        } else {
                            emojiList.push(emoji)
                            emojiNumberList.push(1)
                        }
                    }
                }
                var cur = ""
                for (var i in emojiList) {
                    if (emojiNumberList[i] !== 1)
                        cur = cur + space + emojiList[i] + emojiNumberList[i] + ""
                    else
                        cur = cur + space + emojiList[i] + ""
                    space = "  "
                }
                return cur
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
