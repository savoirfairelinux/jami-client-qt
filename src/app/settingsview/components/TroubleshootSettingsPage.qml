/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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

    property int itemWidth

    title: JamiStrings.troubleshootTitle

    flickableContent: Column {
        id: troubleshootSettingsColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {
            width: parent.width

            spacing: 10

            ToggleSwitch {
                id: enableCrashReports
                visible: ENABLE_CRASHREPORTS
                Layout.fillWidth: true
                labelText: qsTr("Enable crash reports")
                checked: UtilsAdapter.getAppValue(Settings.EnableCrashReporting)

                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.EnableCrashReporting, checked);
                    crashReporter.syncHandlerWithSettings();
                }
            }

            ToggleSwitch {
                id: enableAutomaticCrashReporting
                visible: ENABLE_CRASHREPORTS
                enabled: enableCrashReports.checked
                Layout.fillWidth: true
                labelText: qsTr("Automatically send crash reports")
                checked: UtilsAdapter.getAppValue(Settings.EnableAutomaticCrashReporting)

                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.EnableAutomaticCrashReporting, checked);
                    crashReporter.syncHandlerWithSettings();
                }
            }

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

                NewMaterialButton {
                    id: enableTroubleshootingButton

                    Layout.alignment: Qt.AlignRight

                    filledButton: true
                    text: JamiStrings.troubleshootButton
                    toolTipText: JamiStrings.troubleshootButton

                    onClicked: {
                        LogViewWindowCreation.createlogViewWindowObject();
                        LogViewWindowCreation.showLogViewWindow();
                    }
                }
            }
        }

        Rectangle {
            id: connectionMonitoringTable
            height: listview.height + 60
            width: Math.min(JamiTheme.maximumWidthSettingsView * 2, pageContainer.width - 2 * JamiTheme.preferredSettingsMarginSize)
            color: JamiTheme.transparentColor

            ConnectionMonitoringTable {
                id: listview
            }
        }
    }
}
