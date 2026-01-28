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
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"
import "../../mainview/components"
import "../../mainview/js/contactpickercreation.js" as ContactPickerCreation

SettingsPageBase {
    id: root

    property int itemWidth: 188

    title: JamiStrings.appearance

    flickableContent: ColumnLayout {
        id: appearanceSettingsColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {
            id: themeSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            property var nativeDarkThemeShift: UtilsAdapter.hasNativeDarkTheme() ? 1 : 0

            function isComplete() {
                var theme = UtilsAdapter.getAppValue(Settings.Key.AppTheme);
                if (themeSettings.nativeDarkThemeShift && theme === "System")
                    sysThemeButton.checked = true;
                if (theme === "Light") {
                    lightThemeButton.checked = true;
                } else if (theme === "Dark") {
                    darkThemeButton.checked = true;
                }
            }

            Component.onCompleted: themeSettings.isComplete()

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.theme
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Flow {

                Layout.preferredWidth: parent.width
                Layout.preferredHeight: childrenRect.height
                spacing: 10

                ButtonGroup {
                    id: optionsB
                }

                MaterialRadioButton {
                    id: lightThemeButton

                    width: 165
                    height: 60
                    backgroundColor: JamiTheme.lightThemeBackgroundColor
                    textColor: JamiTheme.blackColor
                    checkedColor: JamiTheme.lightThemeCheckedColor
                    borderColor: JamiTheme.lightThemeBorderColor
                    borderOuterRectangle: JamiTheme.radioBackgroundColor

                    text: JamiStrings.light
                    ButtonGroup.group: optionsB

                    onCheckedChanged: {
                        if (checked)
                            UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Light");
                    }
                }

                MaterialRadioButton {
                    id: darkThemeButton

                    width: 165
                    height: 60
                    backgroundColor: JamiTheme.darkThemeBackgroundColor
                    textColor: JamiTheme.whiteColor
                    checkedColor: JamiTheme.darkThemeCheckedColor
                    borderColor: JamiTheme.darkThemeBorderColor

                    text: JamiStrings.dark
                    ButtonGroup.group: optionsB

                    onCheckedChanged: {
                        if (checked)
                            UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Dark");
                    }
                }

                MaterialRadioButton {
                    id: sysThemeButton

                    width: 165
                    height: 60
                    text: JamiStrings.system
                    ButtonGroup.group: optionsB

                    onCheckedChanged: {
                        if (checked)
                            UtilsAdapter.setAppValue(Settings.Key.AppTheme, "System");
                    }
                }
            }

            RowLayout {
                SettingMaterialButton {
                    id: btnBackgroundImageDirSelect

                    Layout.fillWidth: true

                    enabled: true
                    textField: AccountSettingsManager.accountSettingsPropertyMap.backgroundUri === "" ? JamiStrings.defaultImage : UtilsAdapter.getAbsPath(AccountSettingsManager.accountSettingsPropertyMap.backgroundUri)

                    titleField: JamiStrings.backgroundImage
                    itemWidth: root.itemWidth

                    onSettingMaterialButtonClicked: {
                        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                            title: JamiStrings.selectBackgroundImage,
                            fileMode: JamiFileDialog.OpenFile,
                            folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation),
                            nameFilters: [JamiStrings.imageFiles, JamiStrings.allFiles]
                        });
                        dlg.fileAccepted.connect(function (file) {
                            if (file.toString().length !== 0) {
                                AccountSettingsManager.accountSettingsPropertyMap.backgroundUri = file;
                            }
                        });
                    }
                }

                JamiPushButton {
                    id: shareButton

                    width: visible ? preferredSize : 0
                    height: visible ? preferredSize : 0
                    Layout.alignment: Qt.AlignVCenter

                    visible: AccountSettingsManager.accountSettingsPropertyMap.backgroundUri !== ""
                    toolTipText: JamiStrings.reset

                    source: JamiResources.round_close_24dp_svg

                    normalColor: JamiTheme.transparentColor
                    imageColor: hovered ? JamiTheme.buttonTintedBlueHovered : JamiTheme.textColor

                    onClicked: AccountSettingsManager.accountSettingsPropertyMap.backgroundUri = ""
                }
            }
            ToggleSwitch {
                id: toggleBackgroundBlur
                Layout.fillWidth: true

                checked: AccountSettingsManager.accountSettingsPropertyMap.backgroundBlurEnabled
                labelText: JamiStrings.blurBackgroundImage
                onSwitchToggled: {
                    AccountSettingsManager.accountSettingsPropertyMap.backgroundBlurEnabled = checked;
                }
            }

            ToggleSwitch {
                id: toggleBackgroundOverlay
                Layout.fillWidth: true

                checked: AccountSettingsManager.accountSettingsPropertyMap.backgroundScrimEnabled
                labelText: JamiStrings.applyOverlayBackgroundImage
                onSwitchToggled: {
                    AccountSettingsManager.accountSettingsPropertyMap.backgroundScrimEnabled = checked;
                }
            }
        }

        ColumnLayout {
            id: zoomSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.zoomLevel
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Slider {
                id: zoomSpinBox

                Layout.maximumWidth: parent.width
                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 10

                value: Math.round(UtilsAdapter.getAppValue(Settings.BaseZoom) * 100.0)

                from: 50
                to: 200
                stepSize: 10
                snapMode: Slider.SnapAlways
                useSystemFocusVisuals: false

                onMoved: {
                    UtilsAdapter.setAppValue(Settings.BaseZoom, value / 100.0);
                }

                background: Rectangle {
                    implicitWidth: 200
                    implicitHeight: 2
                    width: zoomSpinBox.availableWidth
                    height: 2
                    radius: 2
                    color: JamiTheme.tintedBlue
                }

                handle: ColumnLayout {
                    x: zoomSpinBox.visualPosition * zoomSpinBox.availableWidth - textSize.width / 2

                    Rectangle {
                        Layout.topMargin: -12
                        implicitWidth: 6
                        implicitHeight: 25
                        radius: implicitWidth
                        color: JamiTheme.tintedBlue
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        id: zoomSpinBoxValueLabel

                        TextMetrics {
                            id: textSize
                            font.pointSize: JamiTheme.settingsFontSize
                            font.kerning: true
                            font.bold: true
                            text: zoomSpinBoxValueLabel.text
                        }

                        color: JamiTheme.tintedBlue
                        text: zoomSpinBox.value
                        Layout.alignment: Qt.AlignHCenter

                        font.pointSize: JamiTheme.settingsFontSize
                        font.kerning: true
                        font.bold: true
                    }
                }
            }

            Connections {
                target: UtilsAdapter

                function onChangeFontSize() {
                    zoomSpinBox.value = Math.round(UtilsAdapter.getAppValue(Settings.BaseZoom) * 100.0);
                }
            }
        }

        ToggleSwitch {
            id: useNativeWindowFrameCheckBox
            Layout.fillWidth: true

            checked: !UtilsAdapter.getAppValue(Settings.Key.UseFramelessWindow)
            labelText: JamiStrings.useNativeWindowFrame
            onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.UseFramelessWindow, !checked)
        }

        NewMaterialButton {
            id: defaultSettings

            outlinedButton: true
            iconSource: JamiResources.settings_backup_restore_24dp_svg
            text: JamiStrings.defaultSettings

            onClicked: {
                zoomSpinBox.value = Math.round(UtilsAdapter.getDefault(Settings.BaseZoom) * 100.0);
                UtilsAdapter.setToDefault(Settings.Key.AppTheme);
                UtilsAdapter.setToDefault(Settings.Key.BaseZoom);
                AccountSettingsManager.resetToDefaults();
                themeSettings.isComplete();
            }
        }
    }
}
