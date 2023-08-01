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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Item {
    id: root

    property var reactions
    property real contentHeight: bubble.height
    property real contentWidth: bubble.width
    property var borderColor: undefined

    visible: emojis.length && Body !== ""

    property var emojis: {
        if (reactions === undefined)
            return [];
        var space = "";
        var emojiList = [];
        var emojiNumberList = [];
        for (const reaction of Object.entries(reactions)) {
            var authorEmojiList = reaction[1];
            for (var emojiIndex in authorEmojiList) {
                var emoji = authorEmojiList[emojiIndex];
                if (emojiList.includes(emoji)) {
                    var findIndex = emojiList.indexOf(emoji);
                    if (findIndex != -1)
                        emojiNumberList[findIndex] += 1;
                } else {
                    emojiList.push(emoji);
                    emojiNumberList.push(1);
                }
            }
        }
        return emojiList;
    }

    property var ownEmojis: {
        if (reactions === undefined)
            return [];
        var list = [];
        var index = 0;
        for (const reaction of Object.entries(reactions)) {
            var authorUri = reaction[0];
            var authorEmojiList = reaction[1];
            if (CurrentAccount.uri === authorUri) {
                for (var emojiIndex in authorEmojiList) {
                    list[index] = authorEmojiList[emojiIndex];
                    index++;
                }
                return list;
            }
        }
        return [];
    }


    // TODO: 
    // -fix direction flow of the emojis, needs to be left to right and always on the right side of a message
    // -adapt the dimensions of the emoji reactions rectangle based on the number of emojis
    // -add padding at the bottom to avoid the emojis overlapping the message
    // -order emojis based on the timestamp of the reaction and/or the quantity of emojis
    
    Rectangle {
        id: bubble

        color: "cyan"
        // color: JamiTheme.emojiReactBubbleBgColor
        width: 200
        height: flow.contentHeight
        radius: 5
        border.color: root.borderColor
        border.width: 1

        Flow {
            id: flow
            spacing: 3
            clip: true
            width: parent.width
            bottomPadding: 20

            // TODO fix icon order
            // each team we build jami the order of the icons is randomized
            
            // flow: Flow.RightToLeft // lemon is first
            // flow: Flow.LeftToRight // watermelon is first, carrot is first

            Repeater {
                id: textEmojis
                model: root.emojis

                delegate: Text {
                    anchors.margins: 10
                    font.pointSize: JamiTheme.emojiReactSize
                    color: JamiTheme.chatviewTextColor
                    text: modelData
                }
            }
        }
    }
}
