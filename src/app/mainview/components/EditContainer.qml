/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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

    color: JamiTheme.messageOutBgColor

    property var body: {
        if (MessagesAdapter.editId === "")
            return "";
        return MessagesAdapter.dataForInteraction(MessagesAdapter.editId, MessageList.ParsedBody);
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

            Label {
                id: editLbl

                text: JamiStrings.edit

                color: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                font.pointSize: JamiTheme.textFontSize
                font.kerning: true
                font.bold: true
                Layout.leftMargin: JamiTheme.preferredMarginSize
            }

            Label {
                id: bodyLbl

                TextMetrics {
                    id: metrics
                    elide: Text.ElideRight
                    elideWidth: root.width - 100
                    text: UtilsAdapter.getOneline(root.body)
                }

                text: metrics.elidedText
                textFormat: Text.MarkdownText
                color: UtilsAdapter.luma(root.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                font.pointSize: JamiTheme.textFontSize
                font.kerning: true
                font.bold: true
            }
        }

        PushButton {
            id: closeReply

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.rightMargin: JamiTheme.preferredMarginSize

            preferredSize: 24

            source: JamiResources.round_close_24dp_svg

            normalColor: JamiTheme.chatviewBgColor
            imageColor: JamiTheme.chatviewButtonColor

            onClicked: MessagesAdapter.editId = ""
        }
    }
}
