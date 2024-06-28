/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
 * Author: Franck Laurent <nicolas.vengeon@savoirfairelinux.com>
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
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../mainview/components"

// KESS
BaseModalDialog {
    id: root

    property string imageId
    property bool newItem
    property real buttonSize: 36
    property real imageSize: 25


    // KESS this function can be used to automatically show the camera with a fade in animation on the preview dialog
    // there should also be two buttons overlayed...
    // 1. list to change the camera
    // 2. button to open manual entry of qr image below the scanner and pause the preview
    property bool deviceHasCamerasAvail: VideoDevices.listSize !== 0
    function startPreviewing(force = false) {
        if (!deviceHasCamerasAvail) {
            startAlternativeEntry();
            return;
        }
        previewWidget.startWithId(VideoDevices.getDefaultDevice(), force);
    }

        // Connections {
        //     target: VideoDevices
        //
        //     function onDefaultResChanged() {
        //         rootLayout.startPreviewing(true);
        //     }
        //
        //     function onDefaultFpsChanged() {
        //         rootLayout.startPreviewing(true);
        //     }
        //
        //     function onDeviceAvailable() {
        //         rootLayout.startPreviewing();
        //     }
        //
        //     function onDeviceListChanged() {
        //         var deviceModel = deviceComboBoxSetting.comboModel;
        //         var resModel = resolutionComboBoxSetting.comboModel;
        //         var fpsModel = fpsComboBoxSetting.comboModel;
        //         var resultList = deviceModel.match(deviceModel.index(0, 0), VideoInputDeviceModel.DeviceId, VideoDevices.defaultId);
        //         deviceComboBoxSetting.modelIndex = resultList.length > 0 ? resultList[0].row : deviceModel.rowCount() ? 0 : -1;
        //         resultList = resModel.match(resModel.index(0, 0), VideoFormatResolutionModel.Resolution, VideoDevices.defaultRes);
        //         resolutionComboBoxSetting.modelIndex = resultList.length > 0 ? resultList[0].row : deviceModel.rowCount() ? 0 : -1;
        //         resultList = fpsModel.match(fpsModel.index(0, 0), VideoFormatFpsModel.FPS, VideoDevices.defaultFps);
        //         fpsComboBoxSetting.modelIndex = resultList.length > 0 ? resultList[0].row : deviceModel.rowCount() ? 0 : -1;
        //     }
        // }
        //
        // Component.onCompleted: {
        //     flipControl.checked = UtilsAdapter.getAppValue(Settings.FlipSelf);
        //     hardwareAccelControl.checked = AvAdapter.getHardwareAcceleration();
        //     startPreviewing(true);
        // }
        //
        // Component.onDestruction: previewWidget.stop()



    signal focusOnPreviousItem
    signal focusOnNextItem
    signal imageValidated
    signal imageRemoved

    // signal addDevice

    function tryStartCamera() {
        if (true) {
            root.startCamera()
        }
    }

    function startCamera() {
        recordBox.openRecorder(true)
    }

    function stopCamera(){
        recordBox.closeRecorder()
    }

    function startAlternativeEntry() {
        // load the text bar instead of the camera stuff
        altEntry.open()
    }

    function mirrorVideo() {
       // AvAdapter.getHardwareAcceleration();


        // flipControl.checked = UtilsAdapter.getAppValue(Settings.FlipSelf);
    }

    // function focusOnNextPhotoBoothItem () {
    //     takePhotoButton.forceActiveFocus()
    // }
    //
    // function focusOnPreviousPhotoBoothItem () {
    //     importButton.forceActiveFocus()
    // }

    Item {
        id: altEntry
        visible: false

        // KESS could use an underlay instead TBD
                // flip: flipControl.checked
                //
                // underlayItems: Text {
                //     anchors.centerIn: parent
                //     font.pointSize: 18
                //     font.capitalization: Font.AllUppercase
                //     color: "white"
                //     text: JamiStrings.noVideo
                // }
    }


    RecordBox {
        // title: JamiStrings.selectImage
        id: recordBox

        x: 100
        y: 100

        isPhoto: true
        visible: false

        onValidatePhoto: function(photo) {
            if (!root.newItem) {
                // AccountAdapter.setCurrentAccountAvatarBase64(photo)
            }
            else {
                // eval for qr image
                // UtilsAdapter.setTempCreationImageFromString(photo, imageId);
                // imageValidated();
            }
            // root.close()
            recordBox.close()
        }
    }

    Component.onCompleted: {
        root.tryStartCamera()
    }

    RowLayout {
        id: buttonsRowLayout

        spacing: 18

        JamiPushButton {
            id: takePhotoButton

            objectName: "takePhotoButton"

            Layout.alignment: Qt.AlignHCenter

            height: buttonSize
            width: buttonSize

            enabled: VideoDevices.listSize !== 0
            hoverEnabled: enabled

            normalColor: "transparent"
            imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
            toolTipText: JamiStrings.takePhoto
            source: JamiResources.add_a_photo_black_24dp_svg

            // Keys.onPressed: function (keyEvent) {
            //     if (keyEvent.key === Qt.Key_Enter ||
            //         keyEvent.key === Qt.Key_Return) {
            //         clicked()
            //         keyEvent.accepted = true
            //         } else if (keyEvent.key === Qt.Key_Up) {
            //             root.focusOnPreviousItem()
            //             keyEvent.accepted = true
            //         }
            // }
            //
            // KeyNavigation.tab: {
            //     if (clearButton.visible)
            //         return clearButton
            //         return importButton
            // }
            // KeyNavigation.down: KeyNavigation.tab

            // onClicked: {
            //     recordBox.parent = buttonsRowLayout
            //     startCamera()
            // }
        }

        JamiPushButton {
            id: flipControl

            objectName: "flipControl"

            Layout.alignment: Qt.AlignHCenter

            height: buttonSize
            width: buttonSize

            enabled: VideoDevices.listSize !== 0
            hoverEnabled: enabled

            normalColor: "transparent"
            imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
            toolTipText: JamiStrings.takePhoto
            source: JamiResources.flip_24dp_svg

            onClicked: {
                UtilsAdapter.setAppValue(Settings.FlipSelf, checked);
                CurrentCall.flipSelf = UtilsAdapter.getAppValue(Settings.FlipSelf);
            }
        }

        // ToggleSwitch {
        //     id: flipControl
        //
        //     height: buttonSize
        //     width: buttonSize
        //     // Layout.fillWidth: true
        //     // labelText: JamiStrings.mirrorLocalVideo
        //
        //     onSwitchToggled: {
        //         UtilsAdapter.setAppValue(Settings.FlipSelf, checked);
        //         CurrentCall.flipSelf = UtilsAdapter.getAppValue(Settings.FlipSelf);
        //     }
        // }



        // JamiPushButton {
        //     id: importButton
        //
        //     objectName: "photoboothViewImportButton"
        //
        //     Layout.alignment: Qt.AlignHCenter
        //     visible: parent.visible
        //
        //     height: buttonSize
        //     width: buttonSize
        //
        //     normalColor: "transparent"
        //     source: JamiResources.add_photo_alternate_black_24dp_svg
        //     imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
        //     toolTipText: JamiStrings.importFromFile
        //
        //     Keys.onPressed: function (keyEvent) {
        //         if (keyEvent.key === Qt.Key_Enter ||
        //             keyEvent.key === Qt.Key_Return) {
        //             clicked()
        //             keyEvent.accepted = true
        //             } else if (keyEvent.key === Qt.Key_Down ||
        //                 keyEvent.key === Qt.Key_Tab) {
        //                 clearButton.forceActiveFocus()
        //                 keyEvent.accepted = true
        //                 }
        //     }
        //
        //     KeyNavigation.up: takePhotoButton
        //
        //     onClicked: {
        //         stopCamera()
        //         var dlg = viewCoordinator.presentDialog(
        //             appWindow,
        //             "commoncomponents/JamiFileDialog.qml",
        //             {
        //                 title: JamiStrings.selectAvatarImage,
        //                 fileMode: JamiFileDialog.OpenFile,
        //                 folder: StandardPaths.writableLocation(
        //                     StandardPaths.PicturesLocation),
        //                     nameFilters: [JamiStrings.imageFiles,
        //                     JamiStrings.allFiles]
        //             })
        //         dlg.fileAccepted.connect(function(file) {
        //             var filePath = UtilsAdapter.getAbsPath(file)
        //             if (!root.newItem) {
        //                 AccountAdapter.setCurrentAccountAvatarFile(filePath)
        //             } else {
        //                 UtilsAdapter.setTempCreationImageFromFile(filePath, root.imageId);
        //                 imageValidated();
        //             }
        //             root.close()
        //         })
        //     }
        // }

        // JamiPushButton {
        //     id: clearButton
        //
        //     objectName: "photoboothViewClearButton"
        //
        //     Layout.alignment: Qt.AlignHCenter
        //
        //     height: buttonSize
        //     width: buttonSize
        //
        //     normalColor: "transparent"
        //     source: JamiResources.remove_circle_outline_black_24dp_svg
        //     toolTipText: JamiStrings.removeImage
        //     imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
        //
        //     visible: {
        //         if (!newItem && LRCInstance.currentAccountAvatarSet)
        //             return true
        //             if (newItem && UtilsAdapter.tempCreationImage(imageId).length !== 0)
        //                 return true
        //                 return false
        //     }
        //
        //     // KeyNavigation.up: importButton
        //     //
        //     // Keys.onPressed: function (keyEvent) {
        //     //     if (keyEvent.key === Qt.Key_Enter ||
        //     //         keyEvent.key === Qt.Key_Return) {
        //     //         clicked()
        //     //         importButton.forceActiveFocus()
        //     //         keyEvent.accepted = true
        //     //         } else if (keyEvent.key === Qt.Key_Down ||
        //     //             keyEvent.key === Qt.Key_Tab) {
        //     //             btnCancel.forceActiveFocus()
        //     //             keyEvent.accepted = true
        //     //             }
        //     // }
        //
        //     onClicked: {
        //         if (!root.newItem) {}
        //             // AccountAdapter.setCurrentAccountAvatarBase64()
        //             else {
        //                 UtilsAdapter.setTempCreationImageFromString("", imageId);
        //                 imageRemoved();
        //             }
        //             visible = false
        //             stopCamera()
        //             root.close()
        //     }
        // }


        // JamiPushButton {
        //     id: mirrorButton
        //
        //     objectName: "pbMirrorBtn"
        //
        //     property bool btnChecked: false
        //
        //     Layout.alignment: Qt.AlignHCenter
        //
        //     height: buttonSize
        //     width: buttonSize
        //
        //     normalColor: "transparent"
        //     source: JamiResources.flip_24dp_svg
        //     toolTipText: JamiStrings.removeImage
        //     imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
        //
        //     visible: {
        //         // if (!newItem && LRCInstance.currentAccountAvatarSet)
        //             // return true
        //             if (newItem && UtilsAdapter.tempCreationImage(imageId).length !== 0)
        //                 return true
        //                 return false
        //     }
        //
        //     // KeyNavigation.up: importButton
        //     //
        //     // Keys.onPressed: function (keyEvent) {
        //     //     if (keyEvent.key === Qt.Key_Enter ||
        //     //         keyEvent.key === Qt.Key_Return) {
        //     //         clicked()
        //     //         importButton.forceActiveFocus()
        //     //         keyEvent.accepted = true
        //     //         } else if (keyEvent.key === Qt.Key_Down ||
        //     //             keyEvent.key === Qt.Key_Tab) {
        //     //             btnCancel.forceActiveFocus()
        //     //             keyEvent.accepted = true
        //     //             }
        //     // }
        //
        //     onClicked: {
        //         root.mirrorVideo()
        //     }
        // }
    }
}


