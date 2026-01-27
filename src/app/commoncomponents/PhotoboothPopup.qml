/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

        NewIconButton {
            id: takePhotoButton

            Layout.alignment: Qt.AlignHCenter

            objectName: "takePhotoButton"

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.add_a_photo_24dp_svg
            toolTipText: JamiStrings.takePhoto

            enabled: VideoDevices.listSize !== 0

            onClicked: {
                recordBox.parent = buttonsRowLayout;
                startBooth();
            }

            Accessible.name: objectName
        }

        NewIconButton {
            id: importButton

            Layout.alignment: Qt.AlignHCenter

            objectName: "photoboothViewImportButton"

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.add_photo_alternate_black_24dp_svg
            toolTipText: JamiStrings.importFromFile

            visible: parent.visible

            Accessible.name: objectName

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

        NewIconButton {
            id: clearButton

            Layout.alignment: Qt.AlignHCenter

            objectName: "photoboothViewClearButton"

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.remove_circle_outline_black_24dp_svg
            toolTipText: JamiStrings.removeImage

            visible: {
                if (!newItem && LRCInstance.currentAccountAvatarSet)
                    return true;
                if (newItem && UtilsAdapter.tempCreationImage(imageId).length !== 0)
                    return true;
                return false;
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
