/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
        ListElement {
            Author: ""
            IsLastSent: false
            Body: "/tmp/qml-data-transfer-test.txt"
            Id: ""
            IsEmojiOnly: false
            OriginalBody: ""
            ParsedOriginalBody: ""
            ReplyToBody: ""
            ReplyTo: ""
            ReplyToAuthor: ""
            Reactions: ""
            Timestamp: 0
            Readers: ""
            PreviousBodies: ""
            Value: 0
            Type: Interaction.Type.DATA_TRANSFER
            TotalSize: 4
            TransferName: "test"
            TransferStatus: Interaction.TransferStatus.TRANSFER_FINISHED
            TID: 0
        }
    }

    delegate: DataTransferMessageDelegate {
        timestamp: 0
        transferStatus: Interaction.TransferStatus.TRANSFER_FINISHED
        author: ""
    }

    TestCase {
        name: "Check basic visibility for header buttons"
        function test_checkBasicVisibility() {
            uut.currentIndex = 0
            const delegate = uut.currentItem
            const buttonsLoader = findChild(delegate, "buttonsLoader")
            delegate.transferStatus = Interaction.TransferStatus.TRANSFER_AWAITING_HOST
            compare(buttonsLoader.iconSource, JamiResources.download_black_24dp_svg)
            delegate.transferStatus = Interaction.TransferStatus.TRANSFER_FINISHED
            compare(buttonsLoader.iconSource, JamiResources.link_black_24dp_svg)
        }
    }

    TestCase {
        name: "Show a thumbnail for received videos"

        function cleanup() {
            uut.width = 400
            if (uut.count > 1)
                uut.model.remove(1, uut.count - 1)
        }

        // Adds a finished transfer of filePath and returns its delegate.
        function addFinishedTransfer(filePath) {
            uut.model.append({
                Author: "",
                IsLastSent: false,
                Body: filePath,
                Id: "",
                IsEmojiOnly: false,
                OriginalBody: "",
                ParsedOriginalBody: "",
                ReplyToBody: "",
                ReplyTo: "",
                ReplyToAuthor: "",
                Reactions: "",
                Timestamp: 0,
                Readers: "",
                PreviousBodies: "",
                Value: 0,
                Type: Interaction.Type.DATA_TRANSFER,
                TotalSize: 4,
                TransferName: "test",
                TransferStatus: Interaction.TransferStatus.TRANSFER_FINISHED,
                TID: 0
            })
            uut.currentIndex = uut.count - 1
            const delegate = uut.currentItem
            delegate.transferStatus = Interaction.TransferStatus.TRANSFER_AWAITING_HOST
            delegate.transferStatus = Interaction.TransferStatus.TRANSFER_FINISHED
            return delegate
        }

        function test_videoShowsAThumbnail() {
            if (!WITH_WEBENGINE)
                skip("Media previews require the web engine")
            const videoPath = UtilsAdapter.getAbsPath(Qt.resolvedUrl("resources/video_test.mp4").toString())
            const delegate = addFinishedTransfer(videoPath)
            tryVerify(function () {
                const playIndicator = findChild(delegate.item, "videoPlayIndicator")
                return playIndicator !== null && playIndicator.visible
            }, 10000, "The video thumbnail is shown with a play indicator")
            compare(findChild(delegate.item, "buttonsLoader"), null)
            const playIndicator = findChild(delegate.item, "videoPlayIndicator")
            compare(playIndicator.width, 36)
            compare(playIndicator.height, 36)
            compare(playIndicator.color, JamiTheme.whiteColor)
            compare(playIndicator.source.toString(), "qrc:/icons/play_arrow_24dp.svg")
            tryCompare(playIndicator, "status", Image.Ready, 10000)
            verify(playIndicator.layer.enabled)
            // layer.effect is a Component, not the effect itself: create an
            // instance of it to read the shadow parameters it declares.
            const shadow = createTemporaryObject(playIndicator.layer.effect, uut, {source: playIndicator})
            verify(shadow !== null)
            compare(shadow.horizontalOffset, 0)
            compare(shadow.verticalOffset, 1)
            compare(shadow.radius, 2)
            compare(shadow.samples, 5)
            compare(shadow.color, Qt.rgba(0, 0, 0, 0.2))
            verify(shadow.transparentBorder)
        }

        function test_mediaPreviewSize_data() {
            return [
                {tag: "landscape", file: "video_test.mp4", isVideo: true, viewWidth: 400},
                {tag: "landscape-wide", file: "video_test.mp4", isVideo: true, viewWidth: 1000},
                {tag: "large", file: "video_test_large.mp4", isVideo: true, viewWidth: 400},
                {tag: "large-wide", file: "video_test_large.mp4", isVideo: true, viewWidth: 1000},
                {tag: "portrait", file: "video_test_rotated.mp4", isVideo: true, viewWidth: 400},
                {tag: "portrait-wide", file: "video_test_rotated.mp4", isVideo: true, viewWidth: 1000},
                {tag: "image", file: "png_test.png", isVideo: false, viewWidth: 400},
                {tag: "image-wide", file: "png_test.png", isVideo: false, viewWidth: 1000}
            ]
        }

        function test_mediaPreviewSize(data) {
            if (!WITH_WEBENGINE)
                skip("Media previews require the web engine")
            uut.width = data.viewWidth
            const filePath = UtilsAdapter.getAbsPath(Qt.resolvedUrl("resources/" + data.file).toString())
            const delegate = addFinishedTransfer(filePath)
            tryVerify(function () {
                return delegate.item !== null && findChild(delegate.item, "videoPlayIndicator") !== null
            }, 10000, "The media preview is loaded")
            const playIndicator = findChild(delegate.item, "videoPlayIndicator")
            const preview = playIndicator.anchors.centerIn
            tryCompare(preview, "status", Image.Ready, 10000)
            compare(playIndicator.visible, data.isVideo)
            const fitScale = Math.min(1, (delegate.item.width - 170) / preview.sourceSize.width,
                                      JamiTheme.maxImageHeight / preview.sourceSize.height)
            const expectedScale = data.isVideo ? fitScale / 3 : fitScale
            fuzzyCompare(preview.width, preview.sourceSize.width * expectedScale, 0.01)
            fuzzyCompare(preview.height, preview.sourceSize.height * expectedScale, 0.01)
            if (data.isVideo)
                compare(playIndicator.width, 36)
        }

        function test_undecodableVideoIsShownAsAFile() {
            const delegate = addFinishedTransfer("/tmp/qml-data-transfer-test-missing.mp4")
            tryVerify(function () {
                return findChild(delegate.item, "buttonsLoader") !== null
            }, 10000, "The video is shown as a file transfer")
            compare(findChild(delegate.item, "videoPlayIndicator"), null)
        }
    }
}
