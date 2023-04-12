/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Item {
    id: root
    property var iconSize: 26
    property var margin: 5
    property var prefWidth: 170

    height: backupLayout.height
    width: parent.width

    signal ignore

    ColumnLayout {
        id: backupLayout
        anchors.top: parent.top
        width: parent.width

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 15

            ResponsiveImage {
                id: icon
                Layout.alignment: Qt.AlignLeft
                Layout.preferredHeight: root.iconSize
                Layout.preferredWidth: root.iconSize
                Layout.topMargin: root.margin
                color: JamiTheme.buttonTintedBlue
                containerHeight: Layout.preferredHeight
                containerWidth: Layout.preferredWidth
                source: JamiResources.noun_paint_svg
                visible: !opened
            }
            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: root.margin
                Layout.preferredWidth: root.prefWidth - 2 * root.margin - root.iconSize
                Layout.topMargin: root.margin
                color: JamiTheme.textColor
                elide: Qt.ElideRight
                font.pixelSize: JamiTheme.tipBoxTitleFontSize
                font.weight: Font.Medium
                text: JamiStrings.backupAccountBtn
                visible: !opened
            }
        }
        Text {
            Layout.bottomMargin: 15
            Layout.leftMargin: 20
            Layout.preferredWidth: root.prefWidth
            Layout.topMargin: 8
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.tipBoxContentFontSize
            font.weight: Font.Normal
            text: JamiStrings.whyBackupAccount
            visible: !opened
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.leftMargin: 20
            Layout.preferredWidth: root.width - 32
            Layout.topMargin: 20
            color: JamiTheme.textColor
            font.pixelSize: JamiTheme.tipBoxContentFontSize
            text: JamiStrings.backupAccountInfos
            visible: opened
            wrapMode: Text.WordWrap
        }
        MaterialButton {
            id: backupBtn
            Layout.alignment: Qt.AlignCenter
            autoAccelerator: true
            color: JamiTheme.buttonTintedGrey
            hoveredColor: JamiTheme.buttonTintedGreyHovered
            preferredWidth: parent.width
            pressedColor: JamiTheme.buttonTintedGreyPressed
            text: JamiStrings.backupAccountBtn
            visible: opened

            onClicked: {
                var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                        "title": JamiStrings.backupAccountHere,
                        "fileMode": JamiFileDialog.SaveFile,
                        "folder": StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Desktop",
                        "nameFilters": [JamiStrings.jamiArchiveFiles, JamiStrings.allFiles]
                    });
                dlg.fileAccepted.connect(function (file) {
                        // Is there password? If so, go to password dialog, else, go to following directly
                        if (CurrentAccount.hasArchivePassword) {
                            var pwdDlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/PasswordDialog.qml", {
                                    "path": UtilsAdapter.getAbsPath(file),
                                    "purpose": PasswordDialog.ExportAccount
                                });
                            pwdDlg.done.connect(function () {
                                    root.ignore();
                                });
                        } else {
                            if (file.toString().length > 0) {
                                root.ignore();
                            }
                        }
                    });
                dlg.rejected.connect(function () {
                        backupBtn.forceActiveFocus();
                    });
            }
        }
    }
}
