/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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

    property var iconSize: 26
    property var margin: 5
    property var prefWidth: 170

    property real maxHeight: 250

    property color textColor: JamiTheme.textColor
    property color iconColor: JamiTheme.tintedBlue

    signal ignore

    ColumnLayout {
        id: backupLayout

        anchors.top: parent.top
        width: parent.width

        RowLayout {
            id: rowlayout

            Layout.leftMargin: 15
            Layout.alignment: Qt.AlignLeft

            ResponsiveImage {
                id: icon

                visible: !opened

                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: root.margin
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize

                containerHeight: Layout.preferredHeight
                containerWidth: Layout.preferredWidth

                source: JamiResources.backup_svg
                color: root.iconColor
            }

            Text {
                id: title
                text: JamiStrings.backupAccountBtn
                color: root.textColor
                font.weight: Font.Medium
                Layout.topMargin: root.margin
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: root.margin
                Layout.preferredWidth: root.prefWidth - 2 * root.margin - root.iconSize
                font.pixelSize: JamiTheme.tipBoxTitleFontSize
                horizontalAlignment: Text.AlignLeft
                elide: Qt.ElideRight
            }
        }

        Text {
            Layout.preferredWidth: root.prefWidth
            Layout.leftMargin: 20
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            font.pixelSize: JamiTheme.tipBoxContentFontSize
            visible: !opened
            wrapMode: Text.WordWrap
            font.weight: Font.Normal
            text: JamiStrings.whyBackupAccount
            color: root.textColor
            horizontalAlignment: Text.AlignLeft
        }

        JamiFlickable {
            Layout.preferredWidth: root.width - 32
            Layout.leftMargin: 20
            property real maxDescriptionHeight: maxHeight - rowlayout.Layout.preferredHeight - title.Layout.preferredHeight - 3 * JamiTheme.preferredMarginSize
            Layout.preferredHeight: opened ? Math.min(contentHeight, maxDescriptionHeight) : 0
            contentHeight: description.height
            Text {
                id: description
                width: parent.width
                font.pixelSize: JamiTheme.tipBoxContentFontSize
                visible: opened
                wrapMode: Text.WordWrap
                text: JamiStrings.backupAccountInfos
                color: root.textColor
                horizontalAlignment: Text.AlignLeft
                linkColor: JamiTheme.buttonTintedBlue

                onLinkActivated: {
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
}
