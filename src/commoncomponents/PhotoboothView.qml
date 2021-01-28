import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Styles 1.4
import Qt.labs.platform 1.0
import QtGraphicalEffects 1.0
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

ColumnLayout {
    property int photoState: 0
    property bool avatarSet: false
    // saveToConfig is to specify whether the image should be saved to account config
    property alias saveToConfig: avatarImg.saveToConfig
    property string fileName: ""

    property int boothWidth: 224

    readonly property int size: boothWidth +
                                buttonsRowLayout.height +
                                JamiTheme.preferredMarginSize / 2

    function initUI(useDefaultAvatar) {
        photoState = 0
        avatarSet = false
        if (useDefaultAvatar === undefined || useDefaultAvatar)
            setAvatarImage(6, "")
    }

    function startBooth() {
        AccountAdapter.startPreviewing(false)
        photoState = 1
    }

    function stopBooth() {
        try{
            if(!AccountAdapter.hasVideoCall()) {
                AccountAdapter.stopPreviewing()
            }
        } catch(erro){console.log("Exception: " +  erro.message)}
    }

    function setAvatarImage(mode, imageId) {
        if (mode === undefined)
            mode = 0
        if (imageId === undefined)
            imageId = AccountAdapter.currentAccountId
        if (mode !== 4)
            avatarImg.enableAnimation = true
        else
            avatarImg.enableAnimation = false

        avatarImg.mode = mode

        if (mode === 6) {
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
            avatarSet = true
            photoState = 0

            fileName = file
            if (fileName.length === 0) {
                SettingsAdapter.clearCurrentAvatar()
                setAvatarImage()
                return
            }

            setAvatarImage(1,
                           UtilsAdapter.getAbsPath(fileName))
        }
    }

    Label {
        id: avatarLabel

        visible: photoState !== 1

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
                    if (mode === 4)
                        photoState = 2

                    if (photoState === 2) {
                        avatarImg.state = ""
                        avatarImg.state = "flashIn"
                    }
                }

                onOpacityChanged: {
                    if (avatarImg.state === "flashIn" && opacity === 0)
                        avatarImg.state = "flashOut"
                }

                states: [
                    State {
                        name: "flashIn"
                        PropertyChanges { target: avatarImg; opacity: 0}
                    }, State {
                        name: "flashOut"
                        PropertyChanges { target: avatarImg; opacity: 1}
                    }]

                transitions: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        easing.type: Easing.Linear
                        duration: 100
                    }
                }
            }
        }
    }

    PhotoboothPreviewRender {
        id:previewWidget

        onHideBooth: stopBooth()

        visible: photoState === 1
        focus: visible

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: boothWidth
        Layout.preferredHeight: boothWidth

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: previewWidget.width
                height: previewWidget.height
                radius: {
                    var size = ((previewWidget.width <= previewWidget.height) ?
                                    previewWidget.width:previewWidget.height)
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
            //font.kerning: true
            imageColor: JamiTheme.textColor

            toolTipText: JamiStrings.takePhoto

            radius: height / 6
            source: {
                if(photoState === 0) {
                    toolTipText = qsTr("Take photo")
                    return cameraAltIconUrl
                }

                if(photoState === 2){
                    toolTipText = qsTr("Retake photo")
                    return refreshIconUrl
                } else {
                    toolTipText = qsTr("Take photo")
                    return addPhotoIconUrl
                }
            }

            onClicked: {
                if(photoState !== 1){
                    startBooth()
                    return
                } else {
                    setAvatarImage(4,
                                   previewWidget.takePhoto(boothWidth))

                    avatarSet = true
                    stopBooth()
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
            //font.kerning: true

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
