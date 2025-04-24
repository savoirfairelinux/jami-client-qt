/*
 * Copyright (C) 2024-2025 Savoir-faire Linux Inc.
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
import "../mainview/components"

BaseModalDialog {
    id: root

    property string imageId
    property bool newItem
    property real buttonSize: 36
    property real imageSize: 25

    signal focusOnPreviousItem
    signal focusOnNextItem
    signal imageValidated
    signal imageTemporaryValidated
    signal imageRemoved
    signal imageTemporaryRemoved

    function startBooth() {
        recordBox.openRecorder(true);
    }

    function stopBooth() {
        recordBox.closeRecorder();
    }

    function focusOnNextPhotoBoothItem() {
        takePhotoButton.forceActiveFocus();
    }

    function focusOnPreviousPhotoBoothItem() {
        importButton.forceActiveFocus();
    }

    title: JamiStrings.selectImage

    RecordBox {
        id: recordBox

        x: 100
        y: 100

        isPhoto: true
        visible: false

        onValidatePhoto: function (photo) {
            if (!root.newItem) {
                AccountAdapter.setCurrentAccountAvatarBase64(photo);
                imageTemporaryValidated();
            } else {
                UtilsAdapter.setTempCreationImageFromString(photo, imageId);
                imageValidated();
            }
            root.close();
        }
    }

    popupContent: RowLayout {
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

            Keys.onPressed: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
                    clicked();
                    keyEvent.accepted = true;
                } else if (keyEvent.key === Qt.Key_Up) {
                    root.focusOnPreviousItem();
                    keyEvent.accepted = true;
                }
            }

            KeyNavigation.tab: {
                if (clearButton.visible)
                    return clearButton;
                return importButton;
            }
            KeyNavigation.down: KeyNavigation.tab

            onClicked: {
                recordBox.parent = buttonsRowLayout;
                startBooth();
            }
        }

        JamiPushButton {
            id: importButton

            objectName: "photoboothViewImportButton"

            Layout.alignment: Qt.AlignHCenter
            visible: parent.visible

            height: buttonSize
            width: buttonSize

            normalColor: "transparent"
            source: JamiResources.add_photo_alternate_black_24dp_svg
            imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
            toolTipText: JamiStrings.importFromFile

            Keys.onPressed: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
                    clicked();
                    keyEvent.accepted = true;
                } else if (keyEvent.key === Qt.Key_Down || keyEvent.key === Qt.Key_Tab) {
                    clearButton.forceActiveFocus();
                    keyEvent.accepted = true;
                }
            }

            KeyNavigation.up: takePhotoButton

            onClicked: {
                stopBooth();
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                        title: JamiStrings.selectProfilePicture,
                        fileMode: JamiFileDialog.OpenFile,
                        folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation),
                        nameFilters: [JamiStrings.imageFiles, JamiStrings.allFiles]
                    });
                dlg.fileAccepted.connect(function (file) {
                        var filePath = UtilsAdapter.getAbsPath(file);
                        if (!root.newItem) {
                            AccountAdapter.setCurrentAccountAvatarFile(filePath);
                            imageTemporaryValidated();
                        } else {
                            UtilsAdapter.setTempCreationImageFromFile(filePath, root.imageId);
                            imageValidated();
                        }
                        root.close();
                    });
            }
        }

        JamiPushButton {
            id: clearButton

            objectName: "photoboothViewClearButton"

            Layout.alignment: Qt.AlignHCenter

            height: buttonSize
            width: buttonSize

            normalColor: "transparent"
            source: JamiResources.remove_circle_outline_black_24dp_svg
            toolTipText: JamiStrings.removeImage
            imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered

            visible: {
                if (!newItem && LRCInstance.currentAccountAvatarSet)
                    return true;
                if (newItem && UtilsAdapter.tempCreationImage(imageId).length !== 0)
                    return true;
                return false;
            }

            KeyNavigation.up: importButton

            Keys.onPressed: function (keyEvent) {
                if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
                    clicked();
                    importButton.forceActiveFocus();
                    keyEvent.accepted = true;
                } else if (keyEvent.key === Qt.Key_Down || keyEvent.key === Qt.Key_Tab) {
                    btnCancel.forceActiveFocus();
                    keyEvent.accepted = true;
                }
            }

            onClicked: {
                if (!root.newItem) {
                    AccountAdapter.setCurrentAccountAvatarBase64();
                    imageTemporaryRemoved();
                } else {
                    UtilsAdapter.setTempCreationImageFromString("", imageId);
                    imageRemoved();
                }
                visible = false;
                stopBooth();
                root.close();
            }
        }
    }
}
