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
    property int itemWidth: 188
    property string recordPath: AVModel.getRecordPath()
    property string recordPathBestName: UtilsAdapter.dirName(AVModel.getRecordPath())
    property string screenshotPath: UtilsAdapter.getDirScreenshot()
    property string screenshotPathBestName: UtilsAdapter.dirName(UtilsAdapter.getDirScreenshot())

    title: JamiStrings.callRecording

    onRecordPathChanged: {
        if (recordPath === "")
            return;
        if (AVModel) {
            AVModel.setRecordPath(recordPath);
        }
    }
    onScreenshotPathChanged: {
        if (screenshotPath === "")
            return;
        UtilsAdapter.setScreenshotPath(screenshotPath);
    }

    flickableContent: ColumnLayout {
        id: callSettingsColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        ColumnLayout {
            id: generalSettings
            width: parent.width

            FolderDialog {
                id: recordPathDialog
                currentFolder: UtilsAdapter.getDirScreenshot()
                options: FolderDialog.ShowDirsOnly
                title: JamiStrings.selectFolder

                onAccepted: {
                    var dir = UtilsAdapter.getAbsPath(folder.toString());
                    var dirName = UtilsAdapter.dirName(folder.toString());
                    recordPath = dir;
                    recordPathBestName = dirName;
                }
            }
            FolderDialog {
                id: screenshotPathDialog
                currentFolder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                options: FolderDialog.ShowDirsOnly
                title: JamiStrings.selectFolder

                onAccepted: {
                    var dir = UtilsAdapter.getAbsPath(folder.toString());
                    var dirName = UtilsAdapter.dirName(folder.toString());
                    screenshotPath = dir;
                    screenshotPathBestName = dirName;
                }
            }
            Timer {
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

                onSwitchToggled: AVModel.setAlwaysRecord(checked)
            }
            ToggleSwitch {
                id: recordPreviewCheckBox
                Layout.fillWidth: true
                checked: AVModel.getRecordPreview()
                labelText: JamiStrings.includeLocalVideo

                onSwitchToggled: AVModel.setRecordPreview(checked)
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillWidth: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize / 2
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pointSize: JamiTheme.settingsFontSize
                    horizontalAlignment: Text.AlignLeft
                    text: JamiStrings.quality
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                Text {
                    id: recordQualityValueLabel
                    Layout.alignment: Qt.AlignRight
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize / 2
                    color: JamiTheme.tintedBlue
                    font.kerning: true
                    font.pointSize: JamiTheme.settingsFontSize
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignRight
                    text: UtilsAdapter.getRecordQualityString(AVModel.getRecordQuality() / 100)
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                Slider {
                    id: recordQualitySlider
                    Layout.alignment: Qt.AlignRight
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.maximumWidth: itemWidth
                    from: 0
                    stepSize: 1
                    to: 500
                    value: AVModel.getRecordQuality() / 100

                    onMoved: {
                        recordQualityValueLabel.text = UtilsAdapter.getRecordQualityString(value);
                        updateRecordQualityTimer.restart();
                    }

                    MaterialToolTip {
                        id: toolTip
                        delay: Qt.styleHints.mousePressAndHoldInterval
                        text: JamiStrings.quality
                        visible: parent.hovered
                    }

                    background: Rectangle {
                        color: JamiTheme.tintedBlue
                        height: implicitHeight
                        implicitHeight: 2
                        implicitWidth: 200
                        radius: 2
                        width: recordQualitySlider.availableWidth
                        y: recordQualitySlider.height / 2
                    }
                    handle: ColumnLayout {
                        x: recordQualitySlider.visualPosition * recordQualitySlider.availableWidth
                        y: recordQualitySlider.height / 2

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: -12
                            color: JamiTheme.tintedBlue
                            implicitHeight: 25
                            implicitWidth: 6
                            radius: implicitWidth
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pointSize: JamiTheme.settingsFontSize
                    horizontalAlignment: Text.AlignLeft
                    text: JamiStrings.saveRecordingsTo
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                MaterialButton {
                    id: recordPathButton
                    Layout.alignment: Qt.AlignRight
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    preferredWidth: itemWidth
                    secondary: true
                    text: recordPathBestName
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding
                    toolTipText: recordPath

                    onClicked: recordPathDialog.open()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pointSize: JamiTheme.settingsFontSize
                    horizontalAlignment: Text.AlignLeft
                    text: JamiStrings.saveScreenshotsTo
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                MaterialButton {
                    id: screenshotPathButton
                    Layout.alignment: Qt.AlignRight
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    preferredWidth: itemWidth
                    secondary: true
                    text: screenshotPathBestName
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding
                    toolTipText: screenshotPath

                    onClicked: screenshotPathDialog.open()
                }
            }
        }
    }
}
