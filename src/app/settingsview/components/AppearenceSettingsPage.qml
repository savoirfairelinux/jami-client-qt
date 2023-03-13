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


Rectangle {
    id: root

    property int contentWidth: appearenceSettingsColumnLayout.width
    property int preferredHeight: appearenceSettingsColumnLayout.implicitHeight
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)

    property int itemWidth: 188

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: appearenceSettingsColumnLayout

        anchors.left: root.left
        anchors.top: root.top
        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        spacing: JamiTheme.wizardViewPageBackButtonMargins *2
        anchors.topMargin: JamiTheme.wizardViewPageBackButtonSize

        ColumnLayout {
            id: generalSettings

            width: preferredWidth
            spacing: 15

            Text {
                id: enableAccountTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.generalSettingsTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: 22
                font.kerning: true

            }

            ToggleSwitch {
                id: enableTypingIndicatorCheckbox

                Layout.fillWidth: true

                checked: UtilsAdapter.getAppValue(Settings.EnableTypingIndicator)

                labelText: JamiStrings.enableTypingIndicator
                fontPointSize: JamiTheme.settingsFontSize

                tooltipText: JamiStrings.enableTypingIndicator

                onSwitchToggled: UtilsAdapter.setAppValue(Settings.Key.EnableTypingIndicator, checked)
            }

            ToggleSwitch {
                id: checkBoxSendDisplayed

                tooltipText: JamiStrings.enableReadReceiptsTooltip
                labelText: JamiStrings.enableReadReceipts
                fontPointSize: JamiTheme.settingsFontSize

                checked: CurrentAccount.sendReadReceipt

                onSwitchToggled: CurrentAccount.sendReadReceipt = checked
            }

            ToggleSwitch {
                id: displayImagesCheckbox
                visible: WITH_WEBENGINE

                Layout.fillWidth: true

                checked: UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews)

                labelText: JamiStrings.displayHyperlinkPreviews
                fontPointSize: JamiTheme.settingsFontSize

                tooltipText: JamiStrings.displayHyperlinkPreviews

                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.DisplayHyperlinkPreviews, checked)
                }
            }

            SettingsComboBox {
                id: outputComboBoxSetting

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                labelText: JamiStrings.layout
                tipText: JamiStrings.layout
                fontPointSize: JamiTheme.settingsFontSize
                comboModel: ListModel {
                    id: layoutModel
                    Component.onCompleted: {
                        append({ textDisplay: JamiStrings.horizontalViewOpt })
                        append({ textDisplay: JamiStrings.verticalViewOpt })
                    }
                }
                widthOfComboBox: itemWidth
                role: "textDisplay"

                modelIndex: UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally) ? 1 : 0

                onActivated: {
                    UtilsAdapter.setAppValue(
                                Settings.Key.ShowChatviewHorizontally,
                                comboModel.get(modelIndex).textDisplay === JamiStrings.verticalViewOpt
                                )
                }

                Connections {
                    target: UtilsAdapter

                    function onChangeLanguage() {
                        var idx = outputComboBoxSetting.modelIndex
                        layoutModel.clear()
                        layoutModel.append({ textDisplay: JamiStrings.horizontalViewOpt })
                        layoutModel.append({ textDisplay: JamiStrings.verticalViewOpt })
                        outputComboBoxSetting.modelIndex = idx
                    }
                }
            }


        }

        ColumnLayout {
            id: themeSettings

            Layout.preferredWidth: preferredWidth
            spacing: 15

            property var nativeDarkThemeShift: UtilsAdapter.hasNativeDarkTheme() ? 1 : 0

            Component.onCompleted: {

                var theme = UtilsAdapter.getAppValue(Settings.Key.AppTheme)
                if (themeSettings.nativeDarkThemeShift && theme === "System")
                    sysThemeButton.checked = true
                if (theme === "Light") {
                    lightThemeButton.checked = true
                } else if (theme === "Dark") {
                    darkThemeButton.checked = true
                }
            }

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.theme
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: 22
                font.kerning: true
            }

            ButtonGroup { id: optionsB }

            RowLayout {

                Layout.preferredWidth: preferredWidth
                Layout.preferredHeight: childrenRect.height

                Rectangle {

                    Layout.preferredWidth: 165
                    Layout.preferredHeight: 60
                    border.color: JamiTheme.tintedBlue
                    color: JamiTheme.whiteColor
                    radius: JamiTheme.settingsBoxRadius

                    MaterialRadioButton {
                        id: lightThemeButton

                        anchors.fill: parent
                        anchors.leftMargin: 19

                        text: JamiStrings.light
                        ButtonGroup.group: optionsB
                        color: JamiTheme.textColor

                        KeyNavigation.down: darkThemeButton
                        KeyNavigation.tab: KeyNavigation.down

                        onCheckedChanged: {
                            if (checked)
                                UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Light")
                        }
                    }
                }

                Rectangle {

                    Layout.preferredWidth: 165
                    Layout.preferredHeight: 60
                    color: JamiTheme.bgDarkMode_
                    radius: JamiTheme.settingsBoxRadius

                    MaterialRadioButton {
                        id: darkThemeButton

                        anchors.fill: parent
                        anchors.leftMargin: 19

                        text: JamiStrings.dark
                        ButtonGroup.group: optionsB
                        color: JamiTheme.whiteColor

                        KeyNavigation.up: lightThemeButton
                        KeyNavigation.down: sysThemeButton
                        KeyNavigation.tab: KeyNavigation.down

                        onCheckedChanged: {
                            if (checked)
                                UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Dark")
                        }
                    }
                }

                Rectangle {

                    Layout.preferredWidth: 165
                    Layout.preferredHeight: 60
                    color: JamiTheme.sysColor
                    radius: JamiTheme.settingsBoxRadius

                    visible: preferredWidth >= JamiTheme.maximumWidthSettingsView - JamiTheme.preferredMarginSize*4

                    MaterialRadioButton {
                        id: sysThemeButton

                        anchors.fill: parent
                        anchors.leftMargin: 19

                        text: JamiStrings.system
                        ButtonGroup.group: optionsB
                        color: JamiTheme.textColor

                        KeyNavigation.up: darkThemeButton

                        onCheckedChanged: {
                            if (checked)
                                UtilsAdapter.setAppValue(Settings.Key.AppTheme, "System")
                        }
                    }
                }
            }


        }

        ColumnLayout {
            id: zoomSettings

            width: preferredWidth
            spacing: 15

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: Math.min(350, root.width - JamiTheme.preferredMarginSize * 2)

                text: JamiStrings.zoomLevel
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: 22
                font.kerning: true

            }

            SettingSpinBox {
                id: zoomSpinBox
                Layout.fillWidth: true
                Layout.leftMargin: JamiTheme.preferredMarginSize

                title: JamiStrings.textZoom
                tooltipText: JamiStrings.changeTextSize
                itemWidth: root.itemWidth

                bottomValue: 50
                topValue: 200
                step: 10

                valueField: UtilsAdapter.getAppValue(Settings.BaseZoom) * 100.0

                onNewValue: UtilsAdapter.setAppValue(Settings.BaseZoom, valueField / 100.0)

            }

            Connections {
                target: UtilsAdapter

                function onChangeFontSize() {
                    zoomSpinBox.valueField = Math.round(UtilsAdapter.getAppValue(Settings.BaseZoom) * 100.0)
                }

            }
        }

        MaterialButton {
            id: defaultSettings

            TextMetrics{
                id: defaultSettingsTextSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.capitalization: Font.AllUppercase
                text: defaultSettings.text
            }

            secondary: true

            text: JamiStrings.defaultSettings
            preferredWidth: defaultSettingsTextSize.width + 2*JamiTheme.buttontextWizzardPadding

        }


    }


}
