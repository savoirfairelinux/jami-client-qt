/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
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

    title: JamiStrings.appearence

    flickableContent: ColumnLayout {
        id: appearenceSettingsColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        ColumnLayout {
            id: generalSettings
            spacing: JamiTheme.settingsCategorySpacing
            width: parent.width

            Text {
                id: enableAccountTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.generalSettingsTitle
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            ToggleSwitch {
                id: enableTypingIndicatorCheckbox
                Layout.fillWidth: true
                checked: UtilsAdapter.getAppValue(Settings.EnableTypingIndicator)
                descText: JamiStrings.enableTypingIndicatorDescription
                labelText: JamiStrings.enableTypingIndicator
                tooltipText: JamiStrings.enableTypingIndicator

                onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.EnableTypingIndicator, checked)
            }
            ToggleSwitch {
                id: displayImagesCheckbox
                Layout.fillWidth: true
                checked: UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews)
                descText: JamiStrings.displayHyperlinkPreviewsDescription
                labelText: JamiStrings.displayHyperlinkPreviews
                tooltipText: JamiStrings.displayHyperlinkPreviews
                visible: WITH_WEBENGINE

                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.DisplayHyperlinkPreviews, checked);
                }
            }
            SettingsComboBox {
                id: outputComboBoxSetting
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                labelText: JamiStrings.layout
                modelIndex: UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally) ? 1 : 0
                role: "textDisplay"
                tipText: JamiStrings.layout
                widthOfComboBox: itemWidth

                onActivated: {
                    UtilsAdapter.setAppValue(Settings.Key.ShowChatviewHorizontally, comboModel.get(modelIndex).textDisplay === JamiStrings.verticalViewOpt);
                }

                Connections {
                    target: UtilsAdapter

                    function onChangeLanguage() {
                        var idx = outputComboBoxSetting.modelIndex;
                        layoutModel.clear();
                        layoutModel.append({
                                "textDisplay": JamiStrings.horizontalViewOpt
                            });
                        layoutModel.append({
                                "textDisplay": JamiStrings.verticalViewOpt
                            });
                        outputComboBoxSetting.modelIndex = idx;
                    }
                }

                comboModel: ListModel {
                    id: layoutModel
                    Component.onCompleted: {
                        append({
                                "textDisplay": JamiStrings.horizontalViewOpt
                            });
                        append({
                                "textDisplay": JamiStrings.verticalViewOpt
                            });
                    }
                }
            }
        }
        ColumnLayout {
            id: themeSettings
            property var nativeDarkThemeShift: UtilsAdapter.hasNativeDarkTheme() ? 1 : 0

            Layout.preferredWidth: parent.width
            spacing: JamiTheme.settingsCategorySpacing

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
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.theme
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            ButtonGroup {
                id: optionsB
            }
            Flow {
                Layout.preferredHeight: childrenRect.height
                Layout.preferredWidth: parent.width
                spacing: 5

                Rectangle {
                    id: lightThemeButtonBg
                    border.color: JamiTheme.darkTheme ? "transparent" : JamiTheme.tintedBlue
                    color: JamiTheme.whiteColor
                    height: 60
                    radius: JamiTheme.settingsBoxRadius
                    width: 165

                    MaterialRadioButton {
                        id: lightThemeButton
                        ButtonGroup.group: optionsB
                        KeyNavigation.down: darkThemeButton
                        KeyNavigation.tab: KeyNavigation.down
                        anchors.fill: parent
                        anchors.leftMargin: 19
                        bgColor: lightThemeButtonBg.color
                        color: JamiTheme.blackColor
                        text: JamiStrings.light

                        onCheckedChanged: {
                            if (checked)
                                UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Light");
                        }
                    }
                }
                Rectangle {
                    id: darkThemeButtonBg
                    border.color: JamiTheme.darkTheme ? JamiTheme.tintedBlue : "transparent"
                    color: JamiTheme.darkTheme ? JamiTheme.blackColor : JamiTheme.bgDarkMode_
                    height: 60
                    radius: JamiTheme.settingsBoxRadius
                    width: 165

                    MaterialRadioButton {
                        id: darkThemeButton
                        ButtonGroup.group: optionsB
                        KeyNavigation.down: sysThemeButton
                        KeyNavigation.tab: KeyNavigation.down
                        KeyNavigation.up: lightThemeButton
                        anchors.fill: parent
                        anchors.leftMargin: 19
                        bgColor: darkThemeButtonBg.color
                        color: JamiTheme.whiteColor
                        text: JamiStrings.dark

                        onCheckedChanged: {
                            if (checked)
                                UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Dark");
                        }
                    }
                }
                Rectangle {
                    id: sysThemeButtonBg
                    color: JamiTheme.darkTheme ? "#515151" : JamiTheme.sysColor
                    height: 60
                    radius: JamiTheme.settingsBoxRadius
                    width: 165

                    MaterialRadioButton {
                        id: sysThemeButton
                        ButtonGroup.group: optionsB
                        KeyNavigation.up: darkThemeButton
                        anchors.fill: parent
                        anchors.leftMargin: 19
                        bgColor: sysThemeButtonBg.color
                        color: JamiTheme.darkTheme ? JamiTheme.whiteColor : JamiTheme.blackColor
                        text: JamiStrings.system

                        onCheckedChanged: {
                            if (checked)
                                UtilsAdapter.setAppValue(Settings.Key.AppTheme, "System");
                        }
                    }
                }
            }
        }
        ColumnLayout {
            id: zoomSettings
            spacing: JamiTheme.settingsCategorySpacing
            width: parent.width

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.zoomLevel
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            Slider {
                id: zoomSpinBox
                Layout.alignment: Qt.AlignLeft
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.maximumWidth: parent.width
                from: 50
                snapMode: Slider.SnapAlways
                stepSize: 10
                to: 200
                value: Math.round(UtilsAdapter.getAppValue(Settings.BaseZoom) * 100.0)

                onMoved: {
                    UtilsAdapter.setAppValue(Settings.BaseZoom, value / 100.0);
                }

                background: Rectangle {
                    color: JamiTheme.tintedBlue
                    height: 2
                    implicitHeight: 2
                    implicitWidth: 200
                    radius: 2
                    width: zoomSpinBox.availableWidth
                }
                handle: ColumnLayout {
                    x: zoomSpinBox.visualPosition * zoomSpinBox.availableWidth - textSize.width / 2

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -12
                        color: JamiTheme.tintedBlue
                        implicitHeight: 25
                        implicitWidth: 6
                        radius: implicitWidth
                    }
                    Text {
                        id: zoomSpinBoxValueLabel
                        Layout.alignment: Qt.AlignHCenter
                        color: JamiTheme.tintedBlue
                        font.bold: true
                        font.kerning: true
                        font.pointSize: JamiTheme.settingsFontSize
                        text: zoomSpinBox.value

                        TextMetrics {
                            id: textSize
                            font.bold: true
                            font.kerning: true
                            font.pointSize: JamiTheme.settingsFontSize
                            text: zoomSpinBoxValueLabel.text
                        }
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
        MaterialButton {
            id: defaultSettings
            preferredWidth: defaultSettingsTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
            secondary: true
            text: JamiStrings.defaultSettings

            onClicked: {
                enableTypingIndicatorCheckbox.checked = UtilsAdapter.getDefault(Settings.Key.EnableTypingIndicator);
                displayImagesCheckbox.checked = UtilsAdapter.getDefault(Settings.Key.DisplayHyperlinkPreviews);
                zoomSpinBox.value = Math.round(UtilsAdapter.getDefault(Settings.BaseZoom) * 100.0);
                UtilsAdapter.setToDefault(Settings.Key.EnableTypingIndicator);
                UtilsAdapter.setToDefault(Settings.Key.DisplayHyperlinkPreviews);
                UtilsAdapter.setToDefault(Settings.Key.AppTheme);
                UtilsAdapter.setToDefault(Settings.Key.BaseZoom);
                themeSettings.isComplete();
            }

            TextMetrics {
                id: defaultSettingsTextSize
                font.capitalization: Font.AllUppercase
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.weight: Font.Bold
                text: defaultSettings.text
            }
        }
    }
}
