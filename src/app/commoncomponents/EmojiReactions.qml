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

    width: reactionBubble.width

    property var reactions
    property real contentHeight: reactionBubble.height
    property real contentWidth: reactionBubble.width
    property color borderColor: undefined
    property int maxWidth: JamiTheme.defaulMaxWidthReaction

    visible: emojis.length && Body !== ""

    property string emojis: {
        if (reactions === undefined)
            return [];
        var space = "";
        var emojiList = [];
        var emojiNumberList = [];
        for (const reaction of Object.entries(reactions)) {
            var authorEmojiList = reaction[1];
            for (var emojiIndex in authorEmojiList) {
                var emoji = authorEmojiList[emojiIndex].body;
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
                    list[index] = authorEmojiList[emojiIndex].body;
                    index++;
                }
                return list;
            }
        }
        return [];
    }

    // TODO:

    // -order emojis based on the timestamp of the reaction and/or the quantity of emojis
    Rectangle {
        id: reactionBubble

        color: JamiTheme.emojiReactBubbleBgColor
        width: textEmojis.width + 10
        height: textEmojis.height + 10
        anchors.centerIn: textEmojis
        radius: 5
        border.color: root.borderColor
        border.width: 1
    }

    Text {
        id: textEmojis
        anchors.margins: 10
        anchors.centerIn: root

        font.pointSize: JamiTheme.emojiReactSize
        color: JamiTheme.chatviewTextColor
        text: root.emojis
        width: Math.min(implicitWidth,root.maxWidth)
        wrapMode: Text.Wrap
    }
}
