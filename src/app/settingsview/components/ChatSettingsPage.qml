/*
 * Copyright (C) 2024-2025 Savoir-faire Linux Inc.
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
    title: JamiStrings.chatSettingsTitle

    flickableContent: ColumnLayout {
        id: callSettingsColumnLayout

        anchors.topMargin: 10
        width: contentFlickableWidth
        spacing: 2 * JamiTheme.settingsCategorySpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {
            id: generalSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: enableAccountTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.view
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: displayImagesCheckbox
                visible: WITH_WEBENGINE

                Layout.fillWidth: true

                checked: AppSettingsManager.settingsMap.DisplayHyperlinkPreviews

                labelText: JamiStrings.displayHyperlinkPreviews
                descText: JamiStrings.displayHyperlinkPreviewsDescription

                tooltipText: JamiStrings.displayHyperlinkPreviews

                onSwitchToggled: {
                    AppSettingsManager.settingsMap.DisplayHyperlinkPreviews = checked;
                }
            }
        }

        ColumnLayout {
            id: textFormattingSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: textFormattingTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.textFormatting
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Text {
                id: textFormattingDescription

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.textFormattingDescription
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }

            Flow {

                Layout.preferredWidth: parent.width
                Layout.preferredHeight: childrenRect.height
                spacing: 10

                ButtonGroup {
                    id: optionsB
                }

                MaterialRadioButton {
                    id: enterButton

                    width: 130
                    height: 40
                    backgroundColor: JamiTheme.chatSettingButtonBackgroundColor
                    textColor: JamiTheme.chatSettingButtonTextColor
                    checkedColor: JamiTheme.chatSettingButtonBorderColor
                    borderColor: JamiTheme.chatSettingButtonBorderColor

                    text: JamiStrings.enter
                    ButtonGroup.group: optionsB

                    onCheckedChanged: {
                        if (checked)
                            AppSettingsManager.settingsMap.ChatViewEnterIsNewLine = true;
                    }
                }

                MaterialRadioButton {
                    id: shiftEnterButton

                    width: 210
                    height: 40
                    backgroundColor: JamiTheme.chatSettingButtonBackgroundColor
                    textColor: JamiTheme.chatSettingButtonTextColor
                    checkedColor: JamiTheme.chatSettingButtonBorderColor
                    borderColor: JamiTheme.chatSettingButtonBorderColor

                    text: JamiStrings.shiftEnter
                    ButtonGroup.group: optionsB

                    onCheckedChanged: {
                        if (checked)
                            AppSettingsManager.settingsMap.ChatViewEnterIsNewLine = false;
                    }
                }

                Component.onCompleted: {
                    if (AppSettingsManager.settingsMap.ChatViewEnterIsNewLine)
                        enterButton.checked = true;
                    else
                        shiftEnterButton.checked = true;
                }
            }
        }

        ColumnLayout {
            id: fileTransferSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: fileTransferTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.fileTransfer
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: autoAcceptFilesCheckbox
                Layout.fillWidth: true

                checked: CurrentAccount.autoTransferFromTrusted
                labelText: JamiStrings.autoAcceptFiles
                tooltipText: JamiStrings.autoAcceptFiles
                onSwitchToggled: CurrentAccount.autoTransferFromTrusted = checked
            }

            SettingSpinBox {
                id: acceptTransferBelowSpinBox
                Layout.fillWidth: true

                title: JamiStrings.acceptTransferBelow
                tooltipText: JamiStrings.acceptTransferTooltip
                itemWidth: root.itemWidth
                bottomValue: 0

                valueField: CurrentAccount.autoTransferSizeThreshold
                onNewValue: CurrentAccount.autoTransferSizeThreshold = valueField
            }
        }

        MaterialButton {
            id: defaultSettings

            Layout.topMargin: 20

            TextMetrics {
                id: defaultSettingsTextSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.capitalization: Font.AllUppercase
                text: defaultSettings.text
            }

            secondary: true

            text: JamiStrings.defaultSettings
            preferredWidth: defaultSettingsTextSize.width + 2 * JamiTheme.buttontextWizzardPadding

            onClicked: {
                autoAcceptFilesCheckbox.checked = AppSettingsManager.getDefault(Settings.Key.AutoAcceptFiles);
                acceptTransferBelowSpinBox.valueField = AppSettingsManager.getDefault(Settings.Key.AcceptTransferBelow);
                AppSettingsManager.setToDefault(Settings.Key.AutoAcceptFiles);
                AppSettingsManager.setToDefault(Settings.Key.AcceptTransferBelow);
                AppSettingsManager.setToDefault(Settings.Key.ChatViewEnterIsNewLine);
                AppSettingsManager.setToDefault(Settings.Key.DisplayHyperlinkPreviews);
                displayImagesCheckbox.checked = AppSettingsManager.settingsMap.DisplayHyperlinkPreviews;
                if (AppSettingsManager.settingsMap.ChatViewEnterIsNewLine)
                    enterButton.checked = true;
                else
                    shiftEnterButton.checked = true;
            }
        }
    }
}
