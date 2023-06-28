/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Matheo Joseph <matheo.joseph@savoirfairelinux.com>
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
import net.jami.Helpers 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Item {
    id: cachedImage
    property bool customLogo: false
    property alias source: image.source
    property string defaultImage: ""
    property string downloadUrl: ""
    property string fileExtension: downloadUrl.substring(downloadUrl.lastIndexOf("."), downloadUrl.length)
    property string localPath: ""
    property int imageFillMode: 0

    Image {
        id: image
        anchors.fill: parent
        fillMode: imageFillMode
        smooth: true
        antialiasing: true
        property bool isSvg: getIsSvg(this)

        Image {
            id: default_img
            anchors.fill: parent
            source: defaultImage
            visible: image.status != Image.Ready
            smooth: true
            antialiasing: true
            property bool isSvg: getIsSvg(this)

            Component.onCompleted: setSourceSize(default_img)
        }

        Component.onCompleted: setSourceSize(image)
    }

    function setSourceSize(img) {
        img.sourceSize = undefined;
        if (img.isSvg) {
            img.sourceSize = Qt.size(cachedImage.width, cachedImage.height);
        }
    }

    function getIsSvg(img) {
        var match = /[^.]+$/.exec(img.source);
        return match != null && match[0] === 'svg';
    }

    Connections {
        target: ImageDownloader
        function onDownloadImageSuccessfull(localPath) {
            if (localPath === cachedImage.localPath) {
                image.source = "file://" + localPath;
            }
        }
        function onDownloadImageFailed() {
            console.warning("Failed to download image: " + downloadUrl);
            image.source = defaultImage;
        }
    }

    Connections {
        target: cachedImage
        function onDownloadUrlChanged() {
            updateImageSource(downloadUrl, localPath, defaultImage);
        }
    }

    Component.onCompleted: {
        updateImageSource(downloadUrl, localPath, defaultImage);
    }

    Connections {
        target: CurrentScreenInfo

        function onDevicePixelRatioChanged() {
            setSourceSize(image);
            setSourceSize(default_img);
        }
    }

    function updateImageSource(downloadUrl, localPath, defaultImage) {
        if (downloadUrl === "") {
            image.source = defaultImage;
            return;
        }
        if (downloadUrl !== "" && localPath !== "") {
            if (!UtilsAdapter.fileExists(localPath)) {
                ImageDownloader.downloadImageToCache(downloadUrl, localPath);
            } else {
                image.source = "file://" + localPath;
            }
        }
    }
}
