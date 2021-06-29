/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import Qt.labs.platform 1.1
import QtGraphicalEffects 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

ColumnLayout {
    id: root

    property int photoState: PhotoboothView.PhotoState.Default
    property string fileName: ""

    property int size: 224

    enum PhotoState {
        Default = 0,
        CameraRendering,
        Taken
    }

    function initUI(useDefaultAvatar = true) {
        photoState = PhotoboothView.PhotoState.Default
    }

    function startBooth() {
        AccountAdapter.startPreviewing(false)
        photoState = PhotoboothView.PhotoState.CameraRendering
    }

    function stopBooth(){
        if (!AccountAdapter.hasVideoCall()) {
            AccountAdapter.stopPreviewing()
        }
    }

    function setAvatarImage(mode = AvatarImage.AvatarMode.FromAccount,
                            imageId = LRCInstance.currentAccountId){
        avatar.imageId = imageId
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

    JamiFileDialog {
        id: importFromFileDialog

        mode: JamiFileDialog.OpenFile
        title: JamiStrings.chooseAvatarImage
        folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)

        nameFilters: [
            qsTr("Image Files") + " (*.png *.jpg *.jpeg)",
            qsTr("All files") + " (*)"
        ]

        onAccepted: {
            photoState = PhotoboothView.PhotoState.Default
            AccountAdapter.setCurrentAccountAvatarFile(UtilsAdapter.getAbsPath(file))

//            if (file.length === 0) {
//                AccountAdapter.setCurrentAccountAvatar()
//                return
//            }

//            var path = UtilsAdapter.getAbsPath(file)
//            AccountAdapter.setCurrentAccountAvatar(path)
        }
    }

    Item {
        id: imageLayer

        Layout.fillWidth: true
        Layout.maximumWidth: size
        Layout.preferredHeight: size
        Layout.alignment: Qt.AlignHCenter

        Avatar {
            id: avatar

            anchors.fill: parent

            visible: !preview.visible

            fillMode: Image.PreserveAspectCrop
            showPresenceIndicator: false
            imageId: LRCInstance.currentAccountId
        }

        PhotoboothPreviewRender {
            id: preview

            anchors.fill: parent

            visible: photoState === PhotoboothView.PhotoState.CameraRendering

            onHideBooth: stopBooth()
            lrcInstance: LRCInstance

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: size
                    height: size
                    radius: size / 2
                }
            }
        }
    }

    RowLayout {
        id: buttonsRowLayout

        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.topMargin: JamiTheme.preferredMarginSize / 2
        Layout.alignment: Qt.AlignHCenter

        PushButton {
            id: takePhotoButton

            Layout.alignment: Qt.AlignHCenter
            radius: height / 6

            imageColor: JamiTheme.textColor
            toolTipText: JamiStrings.takePhoto

            source: {
                if (photoState === PhotoboothView.PhotoState.Default) {
                    toolTipText = qsTr("Take photo")
                    return "qrc:/images/icons/baseline-camera_alt-24px.svg"
                }

                if (photoState === PhotoboothView.PhotoState.Taken) {
                    toolTipText = qsTr("Retake photo")
                    return "qrc:/images/icons/baseline-refresh-24px.svg"
                }

                toolTipText = qsTr("Take photo")
                return "qrc:/images/icons/round-add_a_photo-24px.svg"
            }

            onClicked: {
                if(photoState !== PhotoboothView.PhotoState.CameraRendering) {
                    startBooth()
                } else {
                    AccountAdapter.setCurrentAccountAvatarBase64(preview.takePhoto(size))
                    stopBooth()
                }
            }
        }

        PushButton {
            id: importButton

            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.alignment: Qt.AlignHCenter

            radius: height / 6
            source: "qrc:/images/icons/round-folder-24px.svg"

            toolTipText: JamiStrings.importFromFile
            imageColor: JamiTheme.textColor

            onClicked: importFromFileDialog.open()
        }
    }
}
