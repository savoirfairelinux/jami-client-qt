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
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../../src/app/"
import "../../../src/app/mainview"
import "../../../src/app/mainview/components"
import "../../../src/app/commoncomponents"

ListView {
    id: uut

    width: 400
    height: 400

    model: ListModel {
        id: messageModel
    }

    delegate: TextMessageDelegate {}

    TestCase {
        name: "Link preview images are cached"
        when: windowShown

        function cleanup() {
            messageModel.clear()
        }

        // Adds a text message with the given link preview and returns the
        // link preview image once it has been created.
        function addMessageWithPreview(linkPreviewInfo) {
            messageModel.append({
                ActionUri: "",
                Author: "",
                Body: linkPreviewInfo.url,
                ConfId: "",
                ContactAction: "",
                DeviceId: "",
                Duration: 0,
                FileExtension: "",
                Id: "text-message-delegate-test",
                Index: 0,
                OriginalBody: "",
                ParsedOriginalBody: "",
                IsEmojiOnly: false,
                IsLastSent: false,
                IsRead: true,
                LinkPreviewInfo: linkPreviewInfo,
                ParsedBody: linkPreviewInfo.url,
                PreviousBodies: [],
                Reactions: {},
                Readers: [],
                ReplyTo: "",
                ReplyToAuthor: "",
                ReplyToBody: "",
                Status: 4,
                Timestamp: 0,
                TotalSize: 0,
                TransferName: "",
                Type: Interaction.Type.TEXT
            })
            uut.currentIndex = uut.count - 1
            const delegate = uut.currentItem
            let image = null
            tryVerify(function () {
                image = findChild(delegate, "linkPreviewImage")
                return image !== null
            }, 5000, "The link preview image is created")
            return image
        }

        // Remote images are read from sequential network devices that QMovie
        // cannot rewind, so their frames must be cached to loop safely.
        function test_remoteImageLinkIsCached() {
            const image = addMessageWithPreview({
                url: "https://jami.invalid/animated.gif",
                title: "",
                description: "",
                image: null,
                domain: "jami.invalid"
            })
            verify(image.cache)
        }

        function test_pagePreviewImageIsCached() {
            const image = addMessageWithPreview({
                url: "https://jami.invalid/page",
                title: "title",
                description: "description",
                image: "https://jami.invalid/preview.gif",
                domain: "jami.invalid"
            })
            compare(image.source.toString(), "https://jami.invalid/preview.gif")
            verify(image.cache)
        }
    }
}
