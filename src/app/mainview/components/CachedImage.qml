/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
    property alias imageLayer: image.layer
    property string fileExtension: downloadUrl.substring(downloadUrl.lastIndexOf("."), downloadUrl.length)
    property string localPath: ""
    property int imageFillMode: 0
    property alias image: image

    AnimatedImage {
        id: image
        objectName: "image"
        anchors.fill: parent
        fillMode: imageFillMode
        smooth: true
        antialiasing: true
        property bool isGif: {
            // True only for local gifs.
            UtilsAdapter.getMimeNameForUrl(source).startsWith("image/gif");
        }

        source: defaultImage
        onStatusChanged: {
            if (status === Image.Error) {
                source = defaultImage;
            }
        }
    }

    Connections {
        target: ImageDownloader
        function onDownloadImageSuccessful(localPath) {
            if (localPath === cachedImage.localPath) {
                image.source = UtilsAdapter.urlFromLocalPath(localPath);
            }
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

    function updateImageSource(downloadUrl, localPath, defaultImage) {
        if (downloadUrl === "") {
            image.source = defaultImage;
            return;
        }
        if (downloadUrl && downloadUrl !== "" && localPath !== "") {
            if (!UtilsAdapter.fileExists(localPath)) {
                ImageDownloader.downloadImage(downloadUrl, localPath);
            } else {
                image.source = UtilsAdapter.urlFromLocalPath(localPath);
                if (image.isGif) {
                    image.playing = true;
                }
            }
        }
    }
}
