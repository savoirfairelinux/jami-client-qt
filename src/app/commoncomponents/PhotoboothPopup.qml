/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
import "../mainview/components"

BaseModalDialog {
    id: root

    height: 157
    x: -width / 2
    y: -height / 5

    property string imageId
    property bool newItem
    property real buttonSize: JamiTheme.smartListAvatarSize
    property real imageSize: 25

    signal focusOnPreviousItem
    signal focusOnNextItem

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

    RecordBox {
        id: recordBox

        isPhoto: true
        visible: false

        onValidatePhoto: function (photo) {
            if (!root.newItem)
                AccountAdapter.setCurrentAccountAvatarBase64(photo);
            else
                UtilsAdapter.setTempCreationImageFromString(photo, imageId);
            root.close();
        }
    }

    popupContent: Item {

        Component.onCompleted: {
            root.width = Qt.binding(() => clearButton.visible ? 283 : 210;);
        }

        Rectangle {
            id: container

            anchors.fill: parent
            radius: JamiTheme.photoPopupRadius
            color: JamiTheme.inviteHoverColor

            PushButton {
                id: btnCancel
                imageColor: "grey"
                normalColor: "transparent"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.rightMargin: 10
                source: JamiResources.round_close_24dp_svg
                onClicked: {
                    close();
                }
            }

            ColumnLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: JamiTheme.preferredMarginSize

                Text {
                    id: informativeLabel

                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.topMargin: 26
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: JamiStrings.chooseAvatarPicture
                    color: JamiTheme.primaryForegroundColor
                    font.pixelSize: JamiTheme.popupPhotoTextSize
                    elide: Text.ElideRight
                }

                RowLayout {
                    id: buttonsRowLayout
                    Layout.preferredHeight: childrenRect.height
                    Layout.alignment: Qt.AlignCenter
                    spacing: 10

                    PushButton {
                        id: takePhotoButton

                        objectName: "takePhotoButton"

                        Layout.alignment: Qt.AlignHCenter

                        height: buttonSize
                        width: buttonSize
                        imageContainerWidth: imageSize
                        imageContainerHeight: imageSize
                        radius: height / 2
                        border.color: JamiTheme.buttonTintedBlue
                        normalColor: "transparent"
                        imageColor: JamiTheme.buttonTintedBlue
                        toolTipText: JamiStrings.takePhoto
                        source: JamiResources.baseline_camera_alt_24dp_svg
                        hoveredColor: JamiTheme.smartListHoveredColor

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
                            recordBox.x = Qt.binding(function () {
                                    var buttonCenterX = buttonsRowLayout.width / 2;
                                    return buttonCenterX - recordBox.width / 2;
                                });
                            recordBox.y = Qt.binding(function () {
                                    return -recordBox.height / 2;
                                });
                            startBooth();
                        }
                    }

                    PushButton {
                        id: importButton

                        objectName: "photoboothViewImportButton"

                        Layout.alignment: Qt.AlignHCenter
                        visible: parent.visible

                        height: buttonSize
                        width: buttonSize
                        imageContainerWidth: imageSize
                        imageContainerHeight: imageSize
                        radius: height / 2
                        border.color: JamiTheme.buttonTintedBlue
                        normalColor: "transparent"
                        source: JamiResources.round_folder_24dp_svg
                        toolTipText: JamiStrings.importFromFile
                        imageColor: JamiTheme.buttonTintedBlue
                        hoveredColor: JamiTheme.smartListHoveredColor

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
                                    "title": JamiStrings.chooseAvatarImage,
                                    "fileMode": JamiFileDialog.OpenFile,
                                    "folder": StandardPaths.writableLocation(StandardPaths.PicturesLocation),
                                    "nameFilters": [JamiStrings.imageFiles, JamiStrings.allFiles]
                                });
                            dlg.fileAccepted.connect(function (file) {
                                    var filePath = UtilsAdapter.getAbsPath(file);
                                    if (!root.newItem) {
                                        AccountAdapter.setCurrentAccountAvatarFile(filePath);
                                    } else {
                                        UtilsAdapter.setTempCreationImageFromFile(filePath, root.imageId);
                                    }
                                    root.close();
                                });
                        }
                    }

                    PushButton {
                        id: clearButton

                        objectName: "photoboothViewClearButton"

                        Layout.alignment: Qt.AlignHCenter

                        height: buttonSize
                        width: buttonSize
                        imageContainerWidth: imageSize
                        imageContainerHeight: imageSize
                        radius: height / 2
                        border.color: JamiTheme.buttonTintedBlue
                        normalColor: "transparent"
                        source: JamiResources.ic_hangup_participant_24dp_svg
                        toolTipText: JamiStrings.clearAvatar
                        imageColor: JamiTheme.buttonTintedBlue
                        hoveredColor: JamiTheme.smartListHoveredColor

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
                            if (!root.newItem)
                                AccountAdapter.setCurrentAccountAvatarBase64();
                            else
                                UtilsAdapter.setTempCreationImageFromString("", imageId);
                            visible = false;
                            stopBooth();
                            root.close();
                        }
                    }
                }
            }
        }
    }
}
