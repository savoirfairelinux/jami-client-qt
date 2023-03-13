/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

SettingsPageBase {
    id: root

    property string recordPath: AVModel.getRecordPath()
    property string screenshotPath: UtilsAdapter.getDirScreenshot()

    property int itemWidth: 188

    signal navigateToMainView
    signal navigateToNewWizardView
    title: JamiStrings.callRecording

    onRecordPathChanged: {
        if(recordPath === "")
            return

        if(AVModel) {
            AVModel.setRecordPath(recordPath)
        }
    }

    onScreenshotPathChanged: {
        if (screenshotPath === "")
            return
        UtilsAdapter.setScreenshotPath(screenshotPath)
    }

    flickableContent: ColumnLayout {
        id: callSettingsColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {
            id: generalSettings

            width: parent.width
            spacing: 15
            Layout.topMargin: JamiTheme.preferredSettingsContentMarginSize

            FolderDialog {
                id: recordPathDialog

                title: JamiStrings.selectFolder
                currentFolder: UtilsAdapter.getDirScreenshot()
                options: FolderDialog.ShowDirsOnly

                onAccepted: {
                    var dir = UtilsAdapter.getAbsPath(folder.toString())
                    recordPath = dir
                }
            }

            FolderDialog {
                id: screenshotPathDialog

                title: JamiStrings.selectFolder
                currentFolder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                options: FolderDialog.ShowDirsOnly

                onAccepted: {
                    var dir = UtilsAdapter.getAbsPath(folder.toString())
                    screenshotPath = dir
                }
            }

            Timer{
                id: updateRecordQualityTimer

                interval: 500

                onTriggered: AVModel.setRecordQuality(recordQualitySlider.value * 100)
            }


            ToggleSwitch {
                id: alwaysRecordingCheckBox

                Layout.fillWidth: true
                checked: AVModel.getAlwaysRecord()

                labelText: JamiStrings.alwaysRecordCalls
                tooltipText: JamiStrings.alwaysRecordCalls
                fontPointSize: JamiTheme.settingsFontSize

                onSwitchToggled: AVModel.setAlwaysRecord(checked)
            }

            ToggleSwitch {
                id: recordPreviewCheckBox

                Layout.fillWidth: true
                checked: AVModel.getRecordPreview()

                labelText: JamiStrings.includeLocalVideo
                fontPointSize: JamiTheme.settingsFontSize

                onSwitchToggled: AVModel.setRecordPreview(checked)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillWidth: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize / 2

                    color: JamiTheme.textColor
                    text: JamiStrings.quality
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: recordQualityValueLabel

                    Layout.alignment: Qt.AlignRight
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize / 2

                    color: JamiTheme.tintedBlue
                    text: UtilsAdapter.getRecordQualityString(AVModel.getRecordQuality() / 100)
                    wrapMode: Text.WordWrap

                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }

                Slider {
                    id: recordQualitySlider

                    Layout.maximumWidth: itemWidth
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    value: AVModel.getRecordQuality() / 100

                    from: 0
                    to: 500
                    stepSize: 1

                    onMoved: {
                        recordQualityValueLabel.text = UtilsAdapter.getRecordQualityString(value)
                        updateRecordQualityTimer.restart()
                    }

                    MaterialToolTip {
                        id: toolTip
                        text: JamiStrings.quality
                        visible: parent.hovered
                        delay: Qt.styleHints.mousePressAndHoldInterval
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    text: JamiStrings.saveRecordingsTo
                    wrapMode: Text.WordWrap
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialButton {
                    id: recordPathButton

                    Layout.alignment: Qt.AlignRight

                    preferredWidth: itemWidth
                    preferredHeight: JamiTheme.preferredFieldHeight
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding

                    toolTipText: JamiStrings.tipRecordFolder
                    text: recordPath
                    secondary: true

                    onClicked: recordPathDialog.open()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    text: JamiStrings.saveScreenshotsTo
                    wrapMode: Text.WordWrap
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialButton {
                    id: screenshotPathButton

                    Layout.alignment: Qt.AlignRight

                    preferredWidth: itemWidth
                    preferredHeight: JamiTheme.preferredFieldHeight
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding

                    toolTipText: UtilsAdapter.getDirScreenshot()
                    text: screenshotPath
                    secondary: true
                    onClicked: screenshotPathDialog.open()
                }
            }
       

        /* TO DO
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
            preferredHeight: JamiTheme.preferredButtonSettingsHeight
            Layout.bottomMargin: 30

        }*/
    }
} }