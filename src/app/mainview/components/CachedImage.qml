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
        asynchronous: true

        Image {
            id: default_img
            anchors.fill: parent
            source: (defaultImage !== "") ? defaultImage : ""
            visible: image.status != Image.Ready
            smooth: true
            antialiasing: true
            asynchronous: true
        }
    }

    Connections {
        target: ImageDownloader
        function onDownloadImageSuccessfull(localPath) {
            if (localPath === cachedImage.localPath) {
                image.source = "file://" + localPath;
            }
        }
        function onDownloadImageFailed() {
            console.debug("Failed to download image: " + downloadUrl);
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
