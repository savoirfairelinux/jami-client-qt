/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

        width: contentFlickableWidth
        spacing: JamiTheme.settingsCategorySpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        RowLayout {
            id: timeSharingLocation

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            function standartCountdown(minutes) {
                var hour = Math.floor(minutes / 60);
                var min = minutes % 60;
                if (hour) {
                    if (min)
                        return JamiStrings.xhourxmin.arg(hour).arg(min);
                    else
                        return JamiStrings.xhour.arg(hour);
                }
                return JamiStrings.xmin.arg(min);
            }

            Text {
                Layout.fillWidth: true
                Layout.rightMargin: JamiTheme.preferredMarginSize / 2

                color: JamiTheme.textColor
                text: JamiStrings.positionShareDuration
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
        }

        RowLayout {

            visible: WITH_WEBENGINE
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: childrenRect.height

            Text {
                id: minValue

                Layout.alignment: Qt.AlignLeft
                Layout.fillHeight: true

                color: JamiTheme.tintedBlue
                text: JamiStrings.minLocationDuration

                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true

                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: maxValue

                Layout.alignment: Qt.AlignRight
                Layout.fillHeight: true

                color: JamiTheme.tintedBlue
                text: JamiStrings.maxLocationDuration

                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                verticalAlignment: Text.AlignVCenter
            }
        }

        Slider {
            id: timeSharingSlider

            visible: WITH_WEBENGINE

            Layout.maximumWidth: itemWidth
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            Layout.fillHeight: true

            property bool isMax: UtilsAdapter.getAppValue(Settings.PositionShareDuration) < 0.05
            value: isMax ? Math.log(600) : Math.log(UtilsAdapter.getAppValue(Settings.PositionShareDuration))
            useSystemFocusVisuals: false

            function valueLabel() {
                if (value != Math.log(600)) {
                    UtilsAdapter.setAppValue(Settings.PositionShareDuration, Math.floor(Math.exp(value)));
                    timeSharingLocationValueLabel.text = timeSharingLocation.standartCountdown(Math.floor(Math.exp(value)));
                } else {
                    UtilsAdapter.setAppValue(Settings.PositionShareDuration, 0);
                    timeSharingLocationValueLabel.text = JamiStrings.maxLocationDuration;
                }
            }

            from: 0.5
            to: Math.log(600)
            stepSize: 0.05

            onMoved: valueLabel()

            Component.onCompleted: valueLabel()

            background: Rectangle {
                implicitWidth: 200
                implicitHeight: 2
                width: timeSharingSlider.availableWidth
                height: implicitHeight
                radius: 2
                color: JamiTheme.tintedBlue
            }

            handle: ColumnLayout {
                x: timeSharingSlider.visualPosition * timeSharingSlider.availableWidth - textSize.width / 2

                Rectangle {
                    Layout.topMargin: -12
                    implicitWidth: 6
                    implicitHeight: 25
                    radius: implicitWidth
                    color: JamiTheme.tintedBlue
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    id: timeSharingLocationValueLabel

                    TextMetrics {
                        id: textSize
                        font.pointSize: JamiTheme.settingsFontSize
                        font.kerning: true
                        font.bold: true
                        text: timeSharingLocationValueLabel.text
                    }

                    color: JamiTheme.tintedBlue
                    text: timeSharingLocation.standartCountdown(UtilsAdapter.getAppValue(Settings.PositionShareDuration))
                    Layout.alignment: Qt.AlignHCenter

                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true
                    font.bold: true
                }
            }
        }

        MaterialButton {
            id: defaultSettings

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
                timeSharingSlider.value = Math.log(UtilsAdapter.getDefault(Settings.Key.PositionShareDuration));
                timeSharingSlider.valueLabel();
                UtilsAdapter.setToDefault(Settings.Key.PositionShareDuration);
            }
        }
    }
}
