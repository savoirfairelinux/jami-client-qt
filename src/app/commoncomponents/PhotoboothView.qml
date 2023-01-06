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

import "../mainview/components"

Item {
    id: root

    property alias imageId: avatar.imageId
    property alias cancelButton: cancelButton.visible

    property bool newItem: false
    property bool readOnly: false
    property real avatarSize
    property real buttonSize: avatarSize
    property bool darkTheme: false
    property bool doubleEditAvatar: false

    signal focusOnPreviousItem
    signal focusOnNextItem

    height: Math.max(avatarSize, buttonSize)

    function startBooth() {
        recordBox.openRecorder(true)
    }

    function stopBooth(){
        recordBox.closeRecorder()
    }

    function focusOnNextPhotoBoothItem () {
        takePhotoButton.forceActiveFocus()
    }

    function focusOnPreviousPhotoBoothItem () {
        importButton.forceActiveFocus()
    }

    onVisibleChanged: {
        if (!visible) {
            imageLayer.visible = true
            buttonsRowLayout.visible = false
            stopBooth()
        }
    }

    RecordBox {
        id: recordBox

        isPhoto: true
        visible: false

        onValidatePhoto: function(photo) {
            if (!root.newItem)
                AccountAdapter.setCurrentAccountAvatarBase64(photo)
            else
                UtilsAdapter.setTempCreationImageFromString(photo, imageId)
            buttonsRowLayout.backToAvatar()
        }
    }

    Rectangle {
        id: imageLayer

        anchors.centerIn: parent
        anchors.fill: parent
        color: "transparent"

        Avatar {
            id: avatar

            width: avatarSize
            height: avatarSize
            anchors.centerIn: parent
            anchors.margins: 1

            mode: newItem? Avatar.Mode.Conversation : Avatar.Mode.Account

            fillMode: Image.PreserveAspectCrop
            showPresenceIndicator: false
        }

        PushButton {
            id: editImage

            width: doubleEditAvatar ? avatar.width / 2 : avatar.width / 4
            height: doubleEditAvatar ? avatar.height / 2 : avatar.height / 4
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: doubleEditAvatar ? height / 4 : avatar.width / 22

            source: JamiResources.round_edit_24dp_svg

            preferredSize: doubleEditAvatar ? avatar.width / 3 : avatar.width / 6

            border.color: JamiTheme.buttonTintedBlue
            normalColor: "white"
            imageColor:  JamiTheme.buttonTintedBlue
            hoveredColor: "#e5eef5"
            pressedColor: "#e5eef5"
            enabled: avatar.visible && !root.readOnly

            onClicked :{

                imageLayer.visible = false
                buttonsRowLayout.visible = true
            }
        }
    }

    RowLayout {
        id: buttonsRowLayout
        visible: false

        anchors.centerIn: parent
        Layout.preferredHeight: childrenRect.height
        spacing: 10

        function backToAvatar() {
            imageLayer.visible = true
            buttonsRowLayout.visible = false
        }

        PushButton {
            id: takePhotoButton

            objectName: "takePhotoButton"

            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: cancelButton.width

            height: buttonSize
            width: buttonSize
            imageContainerWidth: buttonSize
            imageContainerHeight: buttonSize
            radius: height / 2
            border.width: 2
            border.color: darkTheme ? "white" : JamiTheme.buttonTintedBlue
            normalColor: "transparent"
            imageColor: darkTheme ? "white" : JamiTheme.buttonTintedBlue
            toolTipText: JamiStrings.takePhoto
            source: JamiResources.baseline_camera_alt_24dp_svg
            hoveredColor: darkTheme ? Qt.rgba(255, 255, 255, 0.2) : JamiTheme.buttonTintedBlueInternalHover

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
                recordBox.parent = buttonsRowLayout

                recordBox.x = Qt.binding(function() {
                    var buttonCenterX = buttonsRowLayout.width / 2
                    return buttonCenterX - recordBox.width / 2
                })
                recordBox.y = Qt.binding(function() {
                    return - recordBox.height / 2
                })
                startBooth()
            }
        }

        PushButton {
            id: importButton

            objectName: "photoboothViewImportButton"

            Layout.alignment: Qt.AlignHCenter
            visible: parent.visible

            height: buttonSize
            width: buttonSize
            imageContainerWidth: buttonSize
            imageContainerHeight: buttonSize
            radius: height / 2
            border.width: 2
            border.color: darkTheme ? "white" : JamiTheme.buttonTintedBlue
            normalColor: "transparent"
            source: JamiResources.round_folder_24dp_svg
            toolTipText: JamiStrings.importFromFile
            imageColor: darkTheme ? "white" : JamiTheme.buttonTintedBlue
            hoveredColor: darkTheme ? Qt.rgba(255, 255, 255, 0.2) : JamiTheme.buttonTintedBlueInternalHover

            Keys.onPressed: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Enter ||
                        keyEvent.key === Qt.Key_Return) {
                    clicked()
                    keyEvent.accepted = true
                } else if (keyEvent.key === Qt.Key_Down ||
                           keyEvent.key === Qt.Key_Tab) {
                    clearButton.forceActiveFocus()
                    keyEvent.accepted = true
                }
            }

            KeyNavigation.up: takePhotoButton

            onClicked: {
                stopBooth()
                buttonsRowLayout.backToAvatar()
                var dlg = viewCoordinator.presentDialog(
                            appWindow,
                            "commoncomponents/JamiFileDialog.qml",
                            {
                                title: JamiStrings.chooseAvatarImage,
                                fileMode: JamiFileDialog.OpenFile,
                                folder: StandardPaths.writableLocation(
                                            StandardPaths.PicturesLocation),
                                nameFilters: [JamiStrings.imageFiles,
                                    JamiStrings.allFiles]
                            })
                dlg.fileAccepted.connect(function(file) {
                    var filePath = UtilsAdapter.getAbsPath(file)
                    if (!root.newItem) {
                        AccountAdapter.setCurrentAccountAvatarFile(filePath)
                    } else {
                        UtilsAdapter.setTempCreationImageFromFile(filePath, root.imageId)
                    }
                })
            }
        }

        PushButton {
            id: clearButton

            objectName: "photoboothViewClearButton"

            Layout.alignment: Qt.AlignHCenter

            height: buttonSize
            width: buttonSize
            imageContainerWidth: buttonSize
            imageContainerHeight: buttonSize
            radius: height / 2
            border.width: 2
            border.color: darkTheme ? "white" : JamiTheme.buttonTintedBlue
            normalColor: "transparent"
            source: JamiResources.ic_hangup_participant_24dp_svg
            toolTipText: JamiStrings.clearAvatar
            imageColor: darkTheme ? "white" : JamiTheme.buttonTintedBlue
            hoveredColor: darkTheme ? Qt.rgba(255, 255, 255, 0.2) : JamiTheme.buttonTintedBlueInternalHover

            visible: {
                if (!newItem && LRCInstance.currentAccountAvatarSet)
                    return true
                if (newItem && UtilsAdapter.tempCreationImage(imageId).length !== 0)
                    return true
                return false
            }

            KeyNavigation.up: importButton

            Keys.onPressed: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Enter ||
                        keyEvent.key === Qt.Key_Return) {
                    clicked()
                    importButton.forceActiveFocus()
                    keyEvent.accepted = true
                } else if (keyEvent.key === Qt.Key_Down ||
                           keyEvent.key === Qt.Key_Tab) {
                    cancelButton.forceActiveFocus()
                    keyEvent.accepted = true
                }
            }

            onClicked: {
                if (!root.newItem)
                    AccountAdapter.setCurrentAccountAvatarBase64()
                else
                    UtilsAdapter.setTempCreationImageFromString("", imageId)
                stopBooth()
                buttonsRowLayout.backToAvatar()
            }
        }

        PushButton {
            id: cancelButton

            visible: true
            preferredSize: 18
            width: 18
            height: 18
            radius: height / 2
            normalColor: "transparent"
            source: JamiResources.round_close_24dp_svg
            toolTipText: JamiStrings.cancel
            imageColor: darkTheme ? "white" : JamiTheme.buttonTintedBlue
            hoveredColor: darkTheme ? Qt.rgba(255, 255, 255, 0.2) : JamiTheme.buttonTintedBlueInternalHover

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
                if (clearButton.visible)
                    return clearButton
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
