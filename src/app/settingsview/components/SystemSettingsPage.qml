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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
import SortFilterProxyModel 0.2

SettingsPageBase {
    id: root

    property int itemWidth: 188
    readonly property int appAccessSettingsIndex: 5

    property bool isSIP

    function openAppAccessPage() {
        var sidePanel = viewCoordinator.getView("SettingsSidePanel")
        if (sidePanel)
            sidePanel.select(appAccessSettingsIndex)

        var settingsView = viewCoordinator.getView("SettingsView")
        if (settingsView)
            settingsView.selectIndex(appAccessSettingsIndex)
    }

    title: JamiStrings.system

    flickableContent: ColumnLayout {
        id: manageAccountEnableColumnLayout
        width: contentFlickableWidth
        spacing: 2 * JamiTheme.settingsCategorySpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {
            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.systemNotificationsTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: notificationCheckBox
                Layout.fillWidth: true

                checked: UtilsAdapter.getAppValue(Settings.EnableNotifications)
                labelText: JamiStrings.showNotifications
                tooltipText: JamiStrings.enableNotifications
                onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.EnableNotifications, checked)
            }

            ToggleSwitch {
                id: enableDonation
                Layout.fillWidth: true
                visible: (new Date() >= new Date(Date.parse("2023-11-01")) && !APPSTORE)

                checked: UtilsAdapter.getAppValue(Settings.Key.IsDonationVisible)
                labelText: JamiStrings.enableDonation
                tooltipText: JamiStrings.enableDonation
                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.IsDonationVisible, checked);
                    if (checked) {
                        UtilsAdapter.setToDefault(Settings.Key.Donation2025StartDate);
                    }
                }
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.systemApplicationTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: closeOrMinCheckBox
                Layout.fillWidth: true

                checked: UtilsAdapter.getAppValue(Settings.MinimizeOnClose)
                labelText: JamiStrings.keepMinimized
                onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.MinimizeOnClose, checked)
            }

            ToggleSwitch {
                id: runOnStartUpCheckBox
                Layout.fillWidth: true

                checked: UtilsAdapter.checkStartupLink()
                labelText: JamiStrings.runStartup
                tooltipText: JamiStrings.tipRunStartup
                onSwitchToggled: UtilsAdapter.setRunOnStartUp(checked)
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.systemLanguageTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            SettingsComboBox {
                id: langComboBoxSetting

                Layout.fillWidth: true
                height: JamiTheme.preferredFieldHeight

                labelText: JamiStrings.userInterfaceLanguage
                tipText: JamiStrings.userInterfaceLanguage
                comboModel: ListModel {
                    id: langModel
                    Component.onCompleted: {
                        var supported = UtilsAdapter.supportedLang();
                        var keys = Object.keys(supported);
                        var currentKey = UtilsAdapter.getAppValue(Settings.Key.LANG);
                        for (var i = 0; i < keys.length; ++i) {
                            append({
                                    "textDisplay": supported[keys[i]],
                                    "id": keys[i]
                                });
                            if (keys[i] === currentKey)
                                langComboBoxSetting.modelIndex = i;
                        }
                    }
                }

                widthOfComboBox: itemWidth
                role: "textDisplay"

                onActivated: {
                    UtilsAdapter.setAppValue(Settings.Key.LANG, comboModel.get(modelIndex).id);
                }
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.apiServerSectionTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: serverInfoCardContent.implicitHeight + 32
                radius: 12
                color: JamiTheme.secAndTertiHoveredBackgroundColor
                border.width: 1
                border.color: JamiTheme.tintedBlue

                ColumnLayout {
                    id: serverInfoCardContent

                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: JamiStrings.apiServerInfoTitle
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: JamiStrings.apiServerInfoMessage
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                        wrapMode: Text.WordWrap
                    }

                    NewMaterialButton {
                        Layout.alignment: Qt.AlignLeft
                        implicitHeight: JamiTheme.newMaterialButtonHeight
                        filledButton: true
                        color: JamiTheme.buttonTintedBlue
                        text: JamiStrings.apiOpenAppAccess
                        onClicked: root.openAppAccessPage()
                    }
                }
            }

            ToggleSwitch {
                id: enableApiServerCheckBox
                Layout.fillWidth: true

                checked: UtilsAdapter.getAppValue(Settings.Key.EnableApi)
                labelText: JamiStrings.apiEnableServer
                tooltipText: JamiStrings.apiEnableServerTooltip

                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.EnableApi, checked)
                    if (checked) {
                        ApiServer.start(UtilsAdapter.getAppValue(Settings.Key.ApiPort))
                    } else {
                        ApiServer.stop()
                    }
                }
            }

            SettingSpinBox {
                id: apiPortSpinBox

                title: JamiStrings.apiServerPort
                itemWidth: root.itemWidth
                bottomValue: 1024
                topValue: 65535
                visible: enableApiServerCheckBox.checked

                valueField: UtilsAdapter.getAppValue(Settings.Key.ApiPort)

                onNewValue: {
                    UtilsAdapter.setAppValue(Settings.Key.ApiPort, valueField)
                    if (ApiServer.running) {
                        ApiServer.stop()
                        ApiServer.start(valueField)
                    }
                }
            }

            Text {
                visible: enableApiServerCheckBox.checked
                Layout.fillWidth: true
                color: ApiServer.running ? JamiTheme.successLabelColor
                                         : JamiTheme.faddedLastInteractionFontColor
                text: ApiServer.running
                      ? JamiStrings.apiServerRunning.arg(ApiServer.port)
                      : JamiStrings.apiServerStopped
                wrapMode: Text.WordWrap
                font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 1
                font.italic: true
            }
        }

        NewMaterialButton {
            id: defaultSettings

            outlinedButton: true
            iconSource: JamiResources.bidirectional_settings_backup_restore_24dp_svg
            text: JamiStrings.defaultSettings

            onClicked: {
                notificationCheckBox.checked = UtilsAdapter.getDefault(Settings.Key.EnableNotifications);
                closeOrMinCheckBox.checked = UtilsAdapter.getDefault(Settings.Key.MinimizeOnClose);
                enableApiServerCheckBox.checked = UtilsAdapter.getDefault(Settings.Key.EnableApi);
                langComboBoxSetting.modelIndex = 0;
                spellCheckLangComboBoxSetting.modelIndex = 0;
                apiPortSpinBox.valueField = UtilsAdapter.getDefault(Settings.Key.ApiPort);
                UtilsAdapter.setToDefault(Settings.Key.EnableNotifications);
                UtilsAdapter.setToDefault(Settings.Key.MinimizeOnClose);
                UtilsAdapter.setToDefault(Settings.Key.EnableApi);
                UtilsAdapter.setToDefault(Settings.Key.ApiPort);
                UtilsAdapter.setToDefault(Settings.Key.LANG);
                UtilsAdapter.setToDefault(Settings.Key.IsDonationVisible);
                UtilsAdapter.setToDefault(Settings.Key.Donation2025StartDate);
                ApiServer.stop();
                enableDonation.checked = Qt.binding(() => UtilsAdapter.getAppValue(Settings.Key.IsDonationVisible));
            }
        }
    }
}
