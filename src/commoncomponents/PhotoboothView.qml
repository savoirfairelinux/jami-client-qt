import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Styles 1.4
import Qt.labs.platform 1.1
import QtGraphicalEffects 1.14
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

ColumnLayout {
    property int photoState: PhotoboothView.PhotoState.Default
    property bool avatarSettled: false
    property bool photoOnBoarded: true
    // saveToConfig is to specify whether the image should be saved to account config
    property alias saveToConfig: avatarImg.saveToConfig
    property string fileName: ""

    property int boothWidth: 224

    enum PhotoState {
        Default = 0,
        CameraRendering,
        Taken
    }

    readonly property int size: boothWidth +
                                buttonsRowLayout.height +
                                JamiTheme.preferredMarginSize / 2

    function initUI(useDefaultAvatar = true) {
        photoState = PhotoboothView.PhotoState.Default
        photoOnBoarded = true
        avatarSettled = false
        if (useDefaultAvatar)
            setAvatarImage(AvatarImage.Mode.Default, "")
    }

    function startBooth() {
        AccountAdapter.startPreviewing(false)
        photoState = PhotoboothView.PhotoState.CameraRendering
    }

    function stopBooth(){
        try{
            if(!AccountAdapter.hasVideoCall()) {
                AccountAdapter.stopPreviewing()
            }
        } catch(erro){console.log("Exception: " +  erro.message)}
    }

    function setAvatarImage(mode = AvatarImage.Mode.FromAccount,
                            imageId = AccountAdapter.currentAccountId){
        if (mode !== AvatarImage.Mode.FromBase64)
            avatarImg.enableAnimation = true
        else
            avatarImg.enableAnimation = false

        avatarImg.mode = mode

        if (mode === AvatarImage.Mode.Default) {
            avatarImg.updateImage(imageId)
            return
        }

        if (imageId)
            avatarImg.updateImage(imageId)
    }

    function manualSaveToConfig() {
        avatarImg.saveAvatarToConfig()
    }

    onVisibleChanged: {
        if(!visible){
            stopBooth()
        }
    }

    spacing: 0

    JamiFileDialog{
        id: importFromFileToAvatar_Dialog

        mode: JamiFileDialog.OpenFile
        title: JamiStrings.chooseAvatarImage
        folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)

        nameFilters: [ qsTr("Image Files") + " (*.png *.jpg *.jpeg)",qsTr(
                "All files") + " (*)"]

        onAccepted: {
            avatarSettled = true
            photoState = PhotoboothView.PhotoState.Default

            fileName = file
            if (fileName.length === 0) {
                SettingsAdapter.clearCurrentAvatar()
                setAvatarImage()
                return
            }

            setAvatarImage(AvatarImage.Mode.FromFile,
                           UtilsAdapter.getAbsPath(fileName))
        }
    }

    Label {
        id: avatarLabel

        visible: photoState !== PhotoboothView.PhotoState.CameraRendering

        Layout.fillWidth: true
        Layout.maximumWidth: boothWidth
        Layout.preferredHeight: boothWidth
        Layout.alignment: Qt.AlignHCenter

        background: Rectangle {
            id: avatarLabelBackground

            anchors.fill: parent
            color: "white"
            radius: height / 2

            AvatarImage {
                id: avatarImg

                anchors.fill: parent

                showPresenceIndicator: false

                fillMode: Image.PreserveAspectCrop

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: avatarImg.width
                        height: avatarImg.height
                        radius: {
                            var size = ((avatarImg.width <= avatarImg.height) ?
                                            avatarImg.width:avatarImg.height)
                            return size / 2
                        }
                    }
                }

                onImageIsReady: {
                    if (mode === AvatarImage.Mode.FromBase64) {
                        photoState = PhotoboothView.PhotoState.Taken
                        photoOnBoarded = true
                        avatarSettled = true
                    }
                }
            }
        }
    }

    Rectangle {
        id: previewRect

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: boothWidth
        Layout.preferredHeight: boothWidth

        visible: photoState === PhotoboothView.PhotoState.CameraRendering
        focus: visible

        color: "white"

        VideoRenderingItemBase {
            id: previewWidget

            property var photoCache: ""

            anchors.centerIn: previewRect

            lrcInstance: LRCInstance
            expectedSize: Qt.size(boothWidth, boothWidth)
            renderingType: VideoRenderingItemBase.Type.PHOTO

            onPhotoIsReady: {
                photoCache = photoBase64
            }

            onOpacityChanged: {
                if (previewWidget.state === "flashIn" && opacity === 0)
                    previewWidget.state = "flashOut"
                else if (previewWidget.state === "flashOut" && opacity === 1) {
                    setAvatarImage(AvatarImage.Mode.FromBase64, photoCache)
                }
            }

            states: [
                State {
                    name: "flashIn"
                    PropertyChanges { target: previewWidget; opacity: 0}
                }, State {
                    name: "flashOut"
                    PropertyChanges { target: previewWidget; opacity: 1}
                }]

            transitions: Transition {
                NumberAnimation {
                    properties: "opacity"
                    easing.type: Easing.Linear
                    duration: 100
                }
            }
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: previewRect.width
                height: previewRect.height
                radius: {
                    var size = ((previewRect.width <= previewRect.height) ?
                                    previewRect.width : previewRect.height)
                    return size / 2
                }
            }
        }
    }

    RowLayout {
        id: buttonsRowLayout

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.topMargin: JamiTheme.preferredMarginSize / 2

        PushButton {
            id: takePhotoButton

            property string cameraAltIconUrl: "qrc:/images/icons/baseline-camera_alt-24px.svg"
            property string addPhotoIconUrl: "qrc:/images/icons/round-add_a_photo-24px.svg"
            property string refreshIconUrl: "qrc:/images/icons/baseline-refresh-24px.svg"

            Layout.alignment: Qt.AlignHCenter

            text: ""
            font.pointSize: 10
            font.kerning: true
            imageColor: JamiTheme.textColor

            toolTipText: JamiStrings.takePhoto

            radius: height / 6
            source: {
                if(photoState === PhotoboothView.PhotoState.Default) {
                    toolTipText = qsTr("Take photo")
                    return cameraAltIconUrl
                }

                if(photoState === PhotoboothView.PhotoState.Taken){
                    toolTipText = qsTr("Retake photo")
                    return refreshIconUrl
                } else {
                    toolTipText = qsTr("Take photo")
                    return addPhotoIconUrl
                }
            }

            onClicked: {
                if(photoState !== PhotoboothView.PhotoState.CameraRendering){
                    startBooth()
                    return
                } else if (photoOnBoarded) {
                    photoOnBoarded = false

                    stopBooth()

                    previewWidget.takePhoto()

                    previewWidget.state = ""
                    previewWidget.state = "flashIn"
                }
            }
        }

        PushButton {
            id: importButton

            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.alignment: Qt.AlignHCenter

            text: ""
            font.pointSize: 10
            font.kerning: true

            radius: height / 6
            source: "qrc:/images/icons/round-folder-24px.svg"

            toolTipText: JamiStrings.importFromFile
            imageColor: JamiTheme.textColor

            onClicked: {
                importFromFileToAvatar_Dialog.open()
            }
        }
    }
}
