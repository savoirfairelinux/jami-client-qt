/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

    AnimatedImage {
        id: image
        objectName: "image"
        anchors.fill: parent
        fillMode: imageFillMode
        smooth: true
        antialiasing: true
        property bool isGif: getIsGif(this)

        Image {
            id: default_img
            objectName: "default_img"
            anchors.fill: parent
            source: defaultImage
            visible: image.status != Image.Ready
            smooth: true
            antialiasing: true
            property bool isGif: getIsGif(this)
        }
    }

    function getIsGif(img) {
        if (img.source && img.source != "") {
            var localPath = img.source.toString();
            if (localPath.startsWith("file://")) {
                localPath = localPath.substring(7);
            }
            return UtilsAdapter.getMimeName(localPath).startsWith("image/gif");
        }
        return false;
    }

    Connections {
        target: ImageDownloader
        function onDownloadImageSuccessful(localPath) {
            if (localPath === cachedImage.localPath) {
                image.source = "file://" + localPath;
                print("onDownloadImageSuccessful", localPath);
            }
        }
        function onDownloadImageFailed(localPath) {
            if (localPath === cachedImage.localPath) {
                print("Failed to download image: " + downloadUrl);
                image.source = defaultImage;
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
                print("ImageDownloader.downloadImage", downloadUrl, localPath);
                ImageDownloader.downloadImage(downloadUrl, localPath);
            } else {
                image.source = "file://" + localPath;
                if (image.isGif) {
                    image.playing = true;
                }
            }
        }
    }
}
