/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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
    width: parent.width
    height: backupLayout.height

    signal ignore

    ColumnLayout {
        id: backupLayout

        anchors.top: parent.top
        width: parent.width

        RowLayout {

            Layout.leftMargin: 15
            Layout.alignment: Qt.AlignLeft

            ResponsiveImage {
                id: icon

                visible: !opened

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: 5
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                containerHeight: Layout.preferredHeight
                containerWidth: Layout.preferredWidth

                source: JamiResources.noun_paint_svg
                color: "#005699"
            }

            Label {
                text: JamiStrings.backupAccountBtn
                color: JamiTheme.textColor
                font.weight: Font.Medium
                Layout.topMargin: 5
                visible: !opened
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 5
                font.pixelSize: JamiTheme.tipBoxTitleFontSize
            }
        }

        Text {

            Layout.preferredWidth: 170
            Layout.leftMargin: 20
            Layout.topMargin: 8
            Layout.bottomMargin: 15
            font.pixelSize: JamiTheme.tipBoxContentFontSize
            visible: !opened
            wrapMode: Text.WordWrap
            font.weight: Font.Normal
            text: JamiStrings.whyBackupAccount
            color: JamiTheme.textColor
        }

        Text {
            Layout.preferredWidth: root.width - 32
            Layout.leftMargin: 20
            Layout.topMargin: 20
            font.pixelSize: JamiTheme.tipBoxContentFontSize
            visible: opened
            wrapMode: Text.WordWrap
            text: JamiStrings.backupAccountInfos
            color: JamiTheme.textColor
        }

        MaterialButton {
            id: backupBtn

            Layout.alignment: Qt.AlignCenter

            preferredWidth: parent.width
            visible: opened

            text: JamiStrings.backupAccountBtn
            autoAccelerator: true
            color: JamiTheme.buttonTintedGrey
            hoveredColor: JamiTheme.buttonTintedGreyHovered
            pressedColor: JamiTheme.buttonTintedGreyPressed

            onClicked: {
                var dlg = viewCoordinator.presentDialog(
                            appWindow,
                            "commoncomponents/JamiFileDialog.qml",
                            {
                                //objectName: "exportDialog",
                                title: JamiStrings.backupAccountHere,
                                fileMode: JamiFileDialog.SaveFile,
                                folder: StandardPaths.writableLocation(
                                            StandardPaths.HomeLocation) + "/Desktop",
                                nameFilters: [JamiStrings.jamiArchiveFiles, JamiStrings.allFiles]
                            })
                dlg.fileAccepted.connect(function (file) {
                    // Is there password? If so, go to password dialog, else, go to following directly
                    if (CurrentAccount.hasArchivePassword) {
                        var pwdDlg = viewCoordinator.presentDialog(
                                    appWindow,
                                    "commoncomponents/PasswordDialog.qml",
                                    {
                                        //objectName: "passwordDialog",
                                        path: UtilsAdapter.getAbsPath(file),
                                        purpose: PasswordDialog.ExportAccount
                                    })
                        pwdDlg.done.connect(function () { root.ignore() })
                    } else {
                        if (file.toString().length > 0) {
                            root.ignore()
                        }
                    }
                })
                dlg.rejected.connect(function () {
                    backupBtn.forceActiveFocus()
                })
            }
        }
    }
}
