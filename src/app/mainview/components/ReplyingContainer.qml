/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    property var author: {
        if (MessagesAdapter.replyToId === "")
            return "";
        var author = MessagesAdapter.dataForInteraction(MessagesAdapter.replyToId, MessageList.Author);
        isSelf = author === "" || author === undefined;
        if (isSelf) {
            avatar.mode = Avatar.Mode.Account;
            avatar.imageId = CurrentAccount.id;
        } else {
            avatar.mode = Avatar.Mode.Contact;
            avatar.imageId = author;
        }
        return isSelf ? CurrentAccount.uri : author;
    }
    property var isSelf: false

    color: JamiTheme.messageOutBgColor

    RowLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            Label {
                id: replyTo
                Layout.leftMargin: JamiTheme.preferredMarginSize
                color: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                font.bold: true
                font.kerning: true
                font.pointSize: JamiTheme.textFontSize
                text: JamiStrings.replyTo
            }
            Avatar {
                id: avatar
                Layout.preferredHeight: JamiTheme.avatarReadReceiptSize
                Layout.preferredWidth: JamiTheme.avatarReadReceiptSize
                imageId: ""
                mode: Avatar.Mode.Account
                showPresenceIndicator: false
            }
            Label {
                id: username
                color: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                font.bold: true
                font.kerning: true
                font.pointSize: JamiTheme.textFontSize
                text: author === CurrentAccount.uri ? CurrentAccount.bestName : UtilsAdapter.getBestNameForUri(CurrentAccount.id, author)
            }
        }
        PushButton {
            id: closeReply
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.rightMargin: JamiTheme.preferredMarginSize
            imageColor: JamiTheme.chatviewButtonColor
            normalColor: JamiTheme.chatviewBgColor
            preferredSize: 24
            source: JamiResources.round_close_24dp_svg

            onClicked: MessagesAdapter.replyToId = ""
        }
    }
}
