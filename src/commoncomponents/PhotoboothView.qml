/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import QtQuick
import QtQuick.Layouts
import Qt.labs.platform
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Item {
    id: root

    property bool isPreviewing: false
    property alias imageId: avatar.imageId
    property bool newConversation: false
    property real avatarSize
    property real buttonSize: avatarSize

    signal focusOnPreviousItem
    signal focusOnNextItem

    height: Math.max(avatarSize, buttonSize)

    function startBooth() {
        preview.startWithId(VideoDevices.getDefaultDevice())
        isPreviewing = true
    }

    function stopBooth(){
        if (!AccountAdapter.hasVideoCall()) {
            VideoDevices.stopDevice(preview.deviceId)
        }
        isPreviewing = false
    }

    function focusOnNextPhotoBoothItem () {
        takePhotoButton.forceActiveFocus()
    }

    function focusOnPreviousPhotoBoothItem () {
        if (isPreviewing)
            clearButton.forceActiveFocus()
        else
            importButton.forceActiveFocus()
    }

    onVisibleChanged: {
        if (!visible) {
            stopBooth()
        }
    }

    JamiFileDialog {
        id: importFromFileDialog

        objectName: "photoboothImportFromFileDialog"

        mode: JamiFileDialog.OpenFile
        title: JamiStrings.chooseAvatarImage
        folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)

        nameFilters: [
            qsTr("Image Files") + " (*.png *.jpg *.jpeg)",
            qsTr("All files") + " (*)"
        ]

        onVisibleChanged: {
            if (!visible) {
                rejected()
            }
        }

        onAccepted: {
            if (importButton.focusAfterFileDialogClosed) {
                importButton.focusAfterFileDialogClosed = false
                importButton.forceActiveFocus()
            }

            var filePath = UtilsAdapter.getAbsPath(file)
            if (!root.newConversation)
                AccountAdapter.setCurrentAccountAvatarFile(filePath)
            else
                UtilsAdapter.setSwarmCreationImageFromFile(filePath, root.imageId)
        }

        onRejected: {
            if (importButton.focusAfterFileDialogClosed) {
                importButton.focusAfterFileDialogClosed = false
                importButton.forceActiveFocus()
            }
        }
    }

    Item {
        id: imageLayer

        anchors.centerIn: parent
        width: avatarSize
        height: avatarSize

        Avatar {
            id: avatar

            anchors.fill: parent
            anchors.margins: 1

            mode: newConversation? Avatar.Mode.Conversation : Avatar.Mode.Account

            fillMode: Image.PreserveAspectCrop
            showPresenceIndicator: false

            HoverHandler {
                target: parent
                enabled: parent.visible
                onHoveredChanged: {
                    overlayHighlighted.visible = hovered
                }
            }

            TapHandler {
                target: parent
                enabled: parent.visible
                onTapped: {
                    imageLayer.visible = false
                    buttonsRowLayout.visible = true
                }
            }

            Rectangle {
                id: overlayHighlighted
                visible: false

                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                radius: parent.height / 2

                opacity: visible

                Behavior on opacity {
                    NumberAnimation {
                        from: 0
                        duration: JamiTheme.shortFadeDuration
                    }
                }

                Image {
                    id: overlayImage

                    width: JamiTheme.smartListAvatarSize / 2
                    height: JamiTheme.smartListAvatarSize / 2
                    anchors.centerIn: parent

                    layer {
                        enabled: true
                        effect: ColorOverlay {
                            color: "white"
                        }
                    }
                    source: JamiResources.round_edit_24dp_svg
                }
            }
        }
    }

    RowLayout {
        id: buttonsRowLayout
        visible: false

        anchors.centerIn: parent
        Layout.preferredHeight: childrenRect.height
        spacing: 12

        function backToAvatar() {
            imageLayer.visible = true
            buttonsRowLayout.visible = false
        }

        PushButton {
            id: takePhotoButton

            objectName: "takePhotoButton"

            Layout.alignment: Qt.AlignHCenter

            height: buttonSize
            width: buttonSize
            radius: height / 2
            border.width: 2
            border.color: JamiTheme.textColor
            normalColor: "transparent"
            imageColor: JamiTheme.textColor
            toolTipText: JamiStrings.takePhoto
            source: isPreviewing ?
                        JamiResources.round_add_a_photo_24dp_svg :
                        JamiResources.baseline_camera_alt_24dp_svg

            Keys.onPressed: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Enter ||
                        keyEvent.key === Qt.Key_Return) {
                    clicked()
                    keyEvent.accepted = true
                } else if (keyEvent.key === Qt.Key_Up) {
                    root.focusOnPreviousItem()
                    keyEvent.accepted = true
                }
            }

            KeyNavigation.tab: {
                if (clearButton.visible)
                    return clearButton
                return importButton
            }
            KeyNavigation.down: KeyNavigation.tab

            onClicked: {
                if (isPreviewing) {
                    flashAnimation.start()
                    var photo = preview.takePhoto(buttonSize)
                    if (!root.newConversation)
                        AccountAdapter.setCurrentAccountAvatarBase64(photo)
                    else
                        UtilsAdapter.setSwarmCreationImageFromString(photo, imageId)
                    stopBooth()
                    buttonsRowLayout.backToAvatar()
                    return
                }

                startBooth()
            }
        }

        Item {
            id: previewLayer

            visible: isPreviewing
            width: buttonSize
            height: buttonSize

            LocalVideo {
                id: preview

                anchors.fill: parent
                anchors.margins: 1


                rendererId: VideoDevices.getDefaultDevice()

                function takePhoto() {
                    return videoProvider.captureVideoFrame(videoSink)
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: buttonSize
                        height: buttonSize
                        radius: buttonSize / 2
                    }
                }
            }

            Rectangle {
                id: flashRect

                anchors.fill: parent
                anchors.margins: 0
                radius: buttonSize / 2
                color: "white"
                opacity: 0

                SequentialAnimation {
                    id: flashAnimation

                    NumberAnimation {
                        target: flashRect; property: "opacity"
                        to: 1; duration: 0
                    }
                    NumberAnimation {
                        target: flashRect; property: "opacity"
                        to: 0; duration: 500
                    }
                }
            }
        }

        PushButton {
            id: clearButton

            objectName: "photoboothViewClearButton"

            Layout.alignment: Qt.AlignHCenter

            height: buttonSize
            width: buttonSize
            radius: height / 2
            border.width: 2
            border.color: JamiTheme.textColor
            normalColor: "transparent"
            source: JamiResources.delete_24dp_svg
            toolTipText: isPreviewing ? JamiStrings.stopTakingPhoto :
                                        JamiStrings.clearAvatar
            imageColor: JamiTheme.textColor

            visible: {
                if (parent.visible && isPreviewing)
                    return false
                if (!newConversation && LRCInstance.currentAccountAvatarSet)
                    return true
                if (newConversation && UtilsAdapter.swarmCreationImage(imageId).length !== 0)
                    return true
                return false
            }

            KeyNavigation.up: takePhotoButton

            Keys.onPressed: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Enter ||
                        keyEvent.key === Qt.Key_Return) {
                    clicked()
                    takePhotoButton.forceActiveFocus()
                    keyEvent.accepted = true
                } else if (keyEvent.key === Qt.Key_Down ||
                            keyEvent.key === Qt.Key_Tab) {
                    importButton.forceActiveFocus()
                    keyEvent.accepted = true
                }
            }

            onClicked: {
                if (!root.newConversation)
                    AccountAdapter.setCurrentAccountAvatarBase64()
                else
                    UtilsAdapter.setSwarmCreationImageFromString("", imageId)
                stopBooth()
                buttonsRowLayout.backToAvatar()
            }
        }

        PushButton {
            id: importButton

            objectName: "photoboothViewImportButton"

            property bool focusAfterFileDialogClosed: false

            Layout.alignment: Qt.AlignHCenter
            visible: parent.visible && !isPreviewing

            height: buttonSize
            width: buttonSize
            radius: height / 2
            border.width: 2
            border.color: JamiTheme.textColor
            normalColor: "transparent"
            source: JamiResources.round_folder_24dp_svg
            toolTipText: JamiStrings.importFromFile
            imageColor: JamiTheme.textColor

            Keys.onPressed: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Enter ||
                        keyEvent.key === Qt.Key_Return) {
                    focusAfterFileDialogClosed = true
                    clicked()
                    keyEvent.accepted = true
                } else if (keyEvent.key === Qt.Key_Down ||
                            keyEvent.key === Qt.Key_Tab) {
                    cancelButton.forceActiveFocus()
                    keyEvent.accepted = true
                }
            }

            KeyNavigation.up: {
                if (clearButton.visible)
                    return clearButton
                return takePhotoButton
            }

            onClicked: {
                stopBooth()
                buttonsRowLayout.backToAvatar()
                importFromFileDialog.open()
            }
        }


        PushButton {
            id: cancelButton

            height: 24
            width: 24
            radius: height / 2
            normalColor: "transparent"
            source: JamiResources.round_close_24dp_svg
            toolTipText: JamiStrings.cancel
            imageColor: JamiTheme.textColor

            Keys.onPressed: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Enter ||
                        keyEvent.key === Qt.Key_Return) {
                    clicked()
                    takePhotoButton.forceActiveFocus()
                    keyEvent.accepted = true
                } else if (keyEvent.key === Qt.Key_Down ||
                            keyEvent.key === Qt.Key_Tab) {
                    importButton.forceActiveFocus()
                    keyEvent.accepted = true
                }
            }

            KeyNavigation.up: {
                if (importButton.visible)
                    return importButton
                return takePhotoButton
            }

            onClicked: {
                stopBooth()
                buttonsRowLayout.backToAvatar()
            }
        }
    }
}
