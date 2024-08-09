/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/logviewwindowcreation.js" as LogViewWindowCreation

SettingsPageBase {
    id: root

    Layout.fillWidth: true
    Layout.minimumWidth: 700

    readonly property string baseProviderPrefix: 'image://avatarImage'

    property string typePrefix: 'contact'
    property string divider: '_'

    property bool isSIP: CurrentAccount.type === Profile.Type.SIP

    property int itemWidth

    title: JamiStrings.troubleshootTitle

    flickableContent: Column {
        id: troubleshootSettingsColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        RowLayout {
            id: rawLayout
            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Layout.rightMargin: JamiTheme.preferredMarginSize

                text: JamiStrings.troubleshootText
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                color: JamiTheme.textColor
            }

            MaterialButton {
                id: enableTroubleshootingButton

                TextMetrics {
                    id: enableTroubleshootingButtonTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: enableTroubleshootingButton.text
                }

                Layout.alignment: Qt.AlignRight

                preferredWidth: enableTroubleshootingButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                primary: true

                text: JamiStrings.troubleshootButton
                toolTipText: JamiStrings.troubleshootButton

                onClicked: {
                    LogViewWindowCreation.createlogViewWindowObject();
                    LogViewWindowCreation.showLogViewWindow();
                }
            }
        }

        Rectangle {
            id: connectionMonitoringTable
            height: listview.childrenRect.height + 60
            width: Math.min(JamiTheme.maximumWidthSettingsView * 2, pageContainer.width - 2 * JamiTheme.preferredSettingsMarginSize)
            color: JamiTheme.transparentColor

            ConnectionMonitoringTable {
                id: listview
            }
        }

        ColumnLayout {
            id: exportArchive
            width: parent.width
            visible: !isSIP && CurrentAccount.managerUri === ""
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: exportTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.exportArchiveTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Text {
                id: exportDescription

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.exportArchiveDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                font.kerning: true
                lineHeight: JamiTheme.wizardViewTextLineHeight
            }

            MaterialButton {
                id: btnExportArchive

                TextMetrics {
                    id: btnExportArchiveTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    text: btnExportArchive.text
                }

                preferredWidth: btnExportArchiveTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
                primary: true
                Layout.alignment: Qt.AlignLeft

                toolTipText: JamiStrings.tipExportArchive
                text: JamiStrings.exportArchiveTitle

                onClicked: {
                    var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                            "title": JamiStrings.exportArchiveTo,
                            "fileMode": FileDialog.SaveFile,
                            "folder": StandardPaths.writableLocation(StandardPaths.DesktopLocation),
                            "nameFilters": [JamiStrings.allFiles]
                        });
                    dlg.fileAccepted.connect(function (file) {
                            var exportPath = UtilsAdapter.getAbsPath(file.toString());
                            if (CurrentAccount.hasArchivePassword) {
                                viewCoordinator.presentDialog(appWindow, "commoncomponents/PasswordDialog.qml", {
                                        "purpose": PasswordDialog.ExportArchiveAsPlainText,
                                        "path": exportPath
                                    });
                                return;
                            } else if (exportPath.length > 0) {
                                var success = AccountAdapter.model.exportArchiveAsPlainText(LRCInstance.currentAccountId, exportPath);
                                viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                                        "title": success ? JamiStrings.success : JamiStrings.error,
                                        "infoText": success ? JamiStrings.exportArchiveSuccessful : JamiStrings.exportArchiveFailed,
                                        "buttonTitles": [JamiStrings.optionOk],
                                        "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue],
                                        "buttonRoles": [DialogButtonBox.AcceptRole]
                                    });
                            }
                        });
                }
            }
        }
    }
}
