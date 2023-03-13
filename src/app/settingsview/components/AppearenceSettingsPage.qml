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
    property int preferredColumnWidth: 400
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)

    property int itemWidth

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

            SettingsComboBox {
                id: themeComboBoxSettings

                Layout.fillWidth: true
                Layout.leftMargin: JamiTheme.preferredMarginSize

                property var nativeDarkThemeShift: UtilsAdapter.hasNativeDarkTheme() ? 1 : 0

                labelText: JamiStrings.applicationTheme
                fontPointSize: JamiTheme.settingsFontSize

                comboModel: ListModel {
                    id: themeModel
                    Component.onCompleted: {
                        if (themeComboBoxSettings.nativeDarkThemeShift)
                            append({ textDisplay: JamiStrings.system })
                        append({ textDisplay: JamiStrings.light })
                        append({ textDisplay: JamiStrings.dark })
                    }
                }
                widthOfComboBox: itemWidth
                tipText: JamiStrings.applicationTheme
                role: "textDisplay"

                modelIndex: {
                    var theme = UtilsAdapter.getAppValue(Settings.Key.AppTheme)
                    if (themeComboBoxSettings.nativeDarkThemeShift && theme === "System")
                        return 0
                    if (theme === "Light") {
                        return 0 + nativeDarkThemeShift
                    } else if (theme === "Dark") {
                        return 1 + nativeDarkThemeShift
                    }
                    return nativeDarkThemeShift
                }

                onActivated: {
                    if (modelIndex === 0 + nativeDarkThemeShift)
                        UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Light")
                    else if (modelIndex === 1 + nativeDarkThemeShift)
                        UtilsAdapter.setAppValue(Settings.Key.AppTheme, "Dark")
                    else if (modelIndex === 0)
                        UtilsAdapter.setAppValue(Settings.Key.AppTheme, "System")
                }
            }

            Connections {
                target: UtilsAdapter

                function onChangeFontSize() {
                    zoomSpinBox.valueField = Math.round(UtilsAdapter.getAppValue(Settings.BaseZoom) * 100.0)
                }

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

        }
    }


}
