import QtQuick 2.14
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.15
import QtQuick.Window 2.15

Image {
    id: root

    property real containerWidth
    property real containerHeight

    property var baseColor: null
    property string baseImage

    property bool checked: false
    property bool checkable: false
    property var checkedColor: null
    property string checkedImage

    property int margin: 4

    property real pixelDensity: Screen.pixelDensity
    property real isSvg: {
        var match = /[^.]+$/.exec(source)
        return match.length > 0 && match[0] === 'svg'
    }

    anchors.centerIn: parent

    width: Math.trunc(containerWidth * Math.sqrt(2) * 0.5) + 2
    height: Math.trunc(containerHeight * Math.sqrt(2) * 0.5) + 2

    fillMode: Image.PreserveAspectFit
    mipmap: true
    asynchronous: true

    function setSourceSize() {
        if (isSvg) {
            sourceSize.width = width
            sourceSize.height = height
        } else
            sourceSize = undefined
    }

    onPixelDensityChanged: setSourceSize()
    Component.onCompleted: {
        setSourceSize()
        console.log(isSvg, width, containerWidth, sourceSize)
    }

    source: {
        if (checkable && checkedImage)
            return checked ? checkedImage : baseImage
        else
            return {}
    }

//    layer {
//        enabled: true
//        effect: ColorOverlay {
//            id: overlay
//            color: checked && checkedColor ?
//                       checkedColor : (baseColor ? baseColor : "transparent")
//        }
//    }
}
