/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

    property string recordPathBestName: UtilsAdapter.dirName(AVModel.getRecordPath())
    property string screenshotPathBestName: UtilsAdapter.dirName(UtilsAdapter.getDirScreenshot())

    property int itemWidth: 188
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

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {
            id: generalSettings

            width: parent.width

            FolderDialog {
                id: recordPathDialog

                title: JamiStrings.selectFolder
                currentFolder: UtilsAdapter.getDirScreenshot()
                options: FolderDialog.ShowDirsOnly

                onAccepted: {
                    var dir = UtilsAdapter.getAbsPath(folder.toString());
                    var dirName = UtilsAdapter.dirName(folder.toString());
                    recordPath = dir;
                    recordPathBestName = dirName;
                }
            }

            FolderDialog {
                id: screenshotPathDialog

                title: JamiStrings.selectFolder
                currentFolder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                options: FolderDialog.ShowDirsOnly

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
                    useSystemFocusVisuals: false

                    from: 0
                    to: 500
                    stepSize: 1

                    onMoved: {
                        recordQualityValueLabel.text = UtilsAdapter.getRecordQualityString(value);
                        updateRecordQualityTimer.restart();
                    }

                    background: Rectangle {
                        y: recordQualitySlider.height / 2
                        implicitWidth: 200
                        implicitHeight: 2
                        width: recordQualitySlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: JamiTheme.tintedBlue
                    }

                    handle: ColumnLayout {
                        x: recordQualitySlider.visualPosition * recordQualitySlider.availableWidth
                        y: recordQualitySlider.height / 2

                        Rectangle {
                            Layout.topMargin: -12
                            implicitWidth: 6
                            implicitHeight: 25
                            radius: implicitWidth
                            color: JamiTheme.tintedBlue
                            Layout.alignment: Qt.AlignHCenter
                        }
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
                Layout.minimumHeight: JamiTheme.preferredFieldHeight

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
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding

                    toolTipText: recordPath
                    text: recordPathBestName
                    secondary: true

                    onClicked: recordPathDialog.open()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: JamiTheme.preferredFieldHeight

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
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    textLeftPadding: JamiTheme.buttontextWizzardPadding
                    textRightPadding: JamiTheme.buttontextWizzardPadding

                    toolTipText: screenshotPath
                    text: screenshotPathBestName
                    secondary: true
                    onClicked: screenshotPathDialog.open()
                }
            }
        }
    }
}
