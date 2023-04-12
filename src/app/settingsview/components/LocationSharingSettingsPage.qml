/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
    property int itemWidth: 578

    title: JamiStrings.locationSharingLabel

    flickableContent: ColumnLayout {
        id: callSettingsColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsCategorySpacing
        width: contentFlickableWidth

        RowLayout {
            id: timeSharingLocation
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            function standartCountdown(minutes) {
                var hour = Math.floor(minutes / 60);
                var min = minutes % 60;
                if (hour) {
                    if (min)
                        return qsTr("%1h%2min").arg(hour).arg(min);
                    else
                        return qsTr("%1h").arg(hour);
                }
                return qsTr("%1min").arg(min);
            }

            Text {
                Layout.fillWidth: true
                Layout.rightMargin: JamiTheme.preferredMarginSize / 2
                color: JamiTheme.textColor
                font.kerning: true
                font.pointSize: JamiTheme.settingsFontSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.positionShareDuration
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
        }
        RowLayout {
            Layout.preferredHeight: childrenRect.height
            Layout.preferredWidth: parent.width
            visible: WITH_WEBENGINE

            Text {
                id: minValue
                Layout.alignment: Qt.AlignLeft
                Layout.fillHeight: true
                color: JamiTheme.tintedBlue
                font.kerning: true
                font.pointSize: JamiTheme.settingsFontSize
                text: JamiStrings.minLocationDuration
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: maxValue
                Layout.alignment: Qt.AlignRight
                Layout.fillHeight: true
                color: JamiTheme.tintedBlue
                font.kerning: true
                font.pointSize: JamiTheme.settingsFontSize
                text: JamiStrings.maxLocationDuration
                verticalAlignment: Text.AlignVCenter
            }
        }
        Slider {
            id: timeSharingSlider
            property bool isMax: UtilsAdapter.getAppValue(Settings.PositionShareDuration) < 0.05

            Layout.alignment: Qt.AlignLeft
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.maximumWidth: itemWidth
            from: 0.5
            stepSize: 0.05
            to: Math.log(600)
            value: isMax ? Math.log(600) : Math.log(UtilsAdapter.getAppValue(Settings.PositionShareDuration))
            visible: WITH_WEBENGINE

            function valueLabel() {
                if (value != Math.log(600)) {
                    UtilsAdapter.setAppValue(Settings.PositionShareDuration, Math.floor(Math.exp(value)));
                    timeSharingLocationValueLabel.text = timeSharingLocation.standartCountdown(Math.floor(Math.exp(value)));
                } else {
                    UtilsAdapter.setAppValue(Settings.PositionShareDuration, 0);
                    timeSharingLocationValueLabel.text = JamiStrings.maxLocationDuration;
                }
            }

            Component.onCompleted: valueLabel()
            onMoved: valueLabel()

            background: Rectangle {
                color: JamiTheme.tintedBlue
                height: implicitHeight
                implicitHeight: 2
                implicitWidth: 200
                radius: 2
                width: timeSharingSlider.availableWidth
            }
            handle: ColumnLayout {
                x: timeSharingSlider.visualPosition * timeSharingSlider.availableWidth - textSize.width / 2

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -12
                    color: JamiTheme.tintedBlue
                    implicitHeight: 25
                    implicitWidth: 6
                    radius: implicitWidth
                }
                Text {
                    id: timeSharingLocationValueLabel
                    Layout.alignment: Qt.AlignHCenter
                    color: JamiTheme.tintedBlue
                    font.bold: true
                    font.kerning: true
                    font.pointSize: JamiTheme.settingsFontSize
                    text: timeSharingLocation.standartCountdown(UtilsAdapter.getAppValue(Settings.PositionShareDuration))

                    TextMetrics {
                        id: textSize
                        font.bold: true
                        font.kerning: true
                        font.pointSize: JamiTheme.settingsFontSize
                        text: timeSharingLocationValueLabel.text
                    }
                }
            }
        }
        MaterialButton {
            id: defaultSettings
            preferredWidth: defaultSettingsTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
            secondary: true
            text: JamiStrings.defaultSettings

            onClicked: {
                timeSharingSlider.value = Math.log(UtilsAdapter.getDefault(Settings.Key.PositionShareDuration));
                timeSharingSlider.valueLabel();
                UtilsAdapter.setToDefault(Settings.Key.PositionShareDuration);
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
