/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

// A feed message's reactions as pills: each emoji with its count, checked when we reacted with it.
// Clicking a pill adds or removes our reaction; right-click or long-press shows who reacted.
Flow {
    id: root
    objectName: "feedReactions"

    // Author URI → list of reactions ({ body, … }).
    property var reactions
    property string msgId

    // Read by the message options menu.
    readonly property var ownEmojis: {
        const own = reactions ? reactions[CurrentAccount.uri] : undefined;
        return own ? Array.from(own, reaction => reaction.body) : [];
    }

    // One entry per emoji, in the order they were first used.
    readonly property var summary: {
        const byEmoji = new Map();
        for (const [author, list] of Object.entries(reactions ?? {})) {
            for (const reaction of list) {
                const entry = byEmoji.get(reaction.body) ?? {
                    "emoji": reaction.body,
                    "count": 0,
                    "mine": false
                };
                entry.count += 1;
                entry.mine = entry.mine || author === CurrentAccount.uri;
                byEmoji.set(reaction.body, entry);
            }
        }
        return Array.from(byEmoji.values());
    }

    function toggle(emoji, mine) {
        if (mine)
            MessagesAdapter.removeEmojiReaction(CurrentConversation.id, emoji, msgId);
        else
            MessagesAdapter.addEmojiReaction(CurrentConversation.id, emoji, msgId);
    }

    visible: summary.length > 0
    spacing: 6

    Repeater {
        model: root.summary

        AbstractButton {
            id: pill
            objectName: "feedReactionPill"

            readonly property string emoji: modelData.emoji
            readonly property int count: modelData.count

            // Bound, not checkable: the reaction list is the source of truth.
            checked: modelData.mine
            hoverEnabled: true
            padding: 4
            leftPadding: 10
            rightPadding: 10

            Accessible.role: Accessible.CheckBox
            Accessible.checkable: true
            Accessible.checked: checked
            Accessible.name: emoji + " " + count

            background: Rectangle {
                radius: height / 2
                color: pill.checked ? Qt.rgba(JamiTheme.tintedBlue.r, JamiTheme.tintedBlue.g, JamiTheme.tintedBlue.b, 0.18) : pill.hovered ? JamiTheme.hoveredButtonColor : JamiTheme.emojiReactBubbleBgColor
                Behavior on color {
                    ColorAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }
                border.width: 1
                border.color: pill.checked ? JamiTheme.tintedBlue : pill.visualFocus ? JamiTheme.chatviewSecondaryInformationColor : JamiTheme.feedPostBorderColor
                Behavior on border.color {
                    ColorAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }
            }

            contentItem: Row {
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: pill.emoji
                    font.pointSize: JamiTheme.emojiReactSize
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: pill.count
                    font.pointSize: JamiTheme.smallFontSize
                    font.bold: pill.checked
                    color: pill.checked ? JamiTheme.tintedBlue : JamiTheme.textColor
                }
            }

            onClicked: root.toggle(emoji, checked)
            onPressAndHold: reactionPopup.open()

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: reactionPopup.open()
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    EmojiReactionPopup {
        id: reactionPopup

        reactions: root.reactions
        msgId: root.msgId
    }
}
