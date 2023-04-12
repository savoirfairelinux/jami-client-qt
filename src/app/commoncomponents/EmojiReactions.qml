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
    property real contentHeight: bubble.height
    property real contentWidth: bubble.width
    property var emojiReaction
    property var emojiTexts: ownEmojiList
    property string emojis: {
        var space = "";
        var emojiList = [];
        var emojiNumberList = [];
        for (const reactions of Object.entries(emojiReaction)) {
            var authorEmojiList = reactions[1];
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
        var cur = "";
        for (var i in emojiList) {
            if (emojiNumberList[i] !== 1)
                cur = cur + space + emojiList[i] + emojiNumberList[i] + "";
            else
                cur = cur + space + emojiList[i] + "";
            space = "  ";
        }
        return cur;
    }
    property var ownEmojiList: {
        var list = [];
        var index = 0;
        for (const reactions of Object.entries(emojiReaction)) {
            var authorUri = reactions[0];
            var authorEmojiList = reactions[1];
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

    visible: emojis.length && Body !== ""

    Rectangle {
        id: bubble
        color: JamiTheme.emojiReactBubbleBgColor
        height: textEmojis.height + 6
        radius: 10
        width: textEmojis.width + 6

        Text {
            id: textEmojis
            anchors.centerIn: bubble
            anchors.margins: 10
            color: JamiTheme.chatviewTextColor
            font.pointSize: JamiTheme.emojiReactSize
            text: root.emojis
        }
    }
    DropShadow {
        color: JamiTheme.shadowColor
        height: bubble.height
        horizontalOffset: 3.0
        radius: bubble.radius * 4
        source: bubble
        transparentBorder: true
        verticalOffset: 3.0
        width: bubble.width
        z: -1
    }
}
