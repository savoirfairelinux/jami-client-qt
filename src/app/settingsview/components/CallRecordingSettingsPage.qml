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

Rectangle {
    id: root

    property int contentWidth: callSettingsColumnLayout.width
    property int preferredHeight: callSettingsColumnLayout.implicitHeight
    property int preferredColumnWidth: 400
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)
    property string recordPath: AVModel.getRecordPath()
    property string screenshotPath: UtilsAdapter.getDirScreenshot()

    property int itemWidth

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

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

    ColumnLayout {
        id: callSettingsColumnLayout

        anchors.left: root.left
        anchors.top: root.top
        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        spacing: JamiTheme.wizardViewPageBackButtonMargins *2
        anchors.topMargin: JamiTheme.wizardViewPageBackButtonSize

        ColumnLayout {
            id: generalSettings

            width: preferredWidth
            spacing: 15

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
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: recordQualityValueLabel

                    Layout.alignment: Qt.AlignRight
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize / 2

                    color: JamiTheme.textColor
                    text: UtilsAdapter.getRecordQualityString(AVModel.getRecordQuality() / 100)

                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true

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

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    text: JamiStrings.saveRecordingsTo
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

                    toolTipText: JamiStrings.tipRecordFolder
                    text: recordPath
                    iconSource: JamiResources.round_folder_24dp_svg
                    color: JamiTheme.buttonTintedGrey
                    hoveredColor: JamiTheme.buttonTintedGreyHovered
                    pressedColor: JamiTheme.buttonTintedGreyPressed

                    onClicked: recordPathDialog.open()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    text: JamiStrings.saveScreenshotsTo
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

                    toolTipText: UtilsAdapter.getDirScreenshot()
                    text: screenshotPath
                    iconSource: JamiResources.round_folder_24dp_svg
                    color: JamiTheme.buttonTintedGrey
                    hoveredColor: JamiTheme.buttonTintedGreyHovered
                    pressedColor: JamiTheme.buttonTintedGreyPressed

                    onClicked: screenshotPathDialog.open()
                }
            }
        }
    }
}
