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


Rectangle {
    id: root

    property int contentWidth: callSettingsColumnLayout.width
    property int preferredHeight: callSettingsColumnLayout.implicitHeight
    property int preferredColumnWidth: 400
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)

    property int itemWidth

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

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

            ToggleSwitch {
                id: isTimeLimit

                visible: WITH_WEBENGINE

                Layout.fillWidth: true
                Layout.leftMargin: JamiTheme.preferredMarginSize

                checked: UtilsAdapter.getAppValue(Settings.PositionShareLimit)

                labelText: JamiStrings.positionShareLimit
                fontPointSize: JamiTheme.settingsFontSize

                tooltipText: JamiStrings.positionShareLimit

                onSwitchToggled: {
                    positionSharingLimitation = !UtilsAdapter.getAppValue(Settings.PositionShareLimit)
                    UtilsAdapter.setAppValue(Settings.PositionShareLimit,
                                             positionSharingLimitation)

                }
                property bool positionSharingLimitation: UtilsAdapter.getAppValue(Settings.PositionShareLimit)
            }

            RowLayout {
                id: timeSharingLocation

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.leftMargin: JamiTheme.preferredMarginSize
                visible: isTimeLimit.positionSharingLimitation

                function standartCountdown(minutes) {
                    var hour = Math.floor(minutes / 60)
                    var min = minutes % 60
                    if (hour) {
                        if (min)
                            return qsTr("%1h%2min").arg(hour).arg(min)
                        else
                            return qsTr("%1h").arg(hour)
                    }
                    return qsTr("%1min").arg(min)
                }

                Text {
                    Layout.fillWidth: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize / 2

                    color: JamiTheme.textColor
                    text: JamiStrings.positionShareDuration
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: timeSharingLocationValueLabel

                    Layout.alignment: Qt.AlignRight
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize / 2

                    color: JamiTheme.textColor
                    text: timeSharingLocation.standartCountdown(UtilsAdapter.getAppValue(Settings.PositionShareDuration))

                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }

                Slider {
                    id: timeSharingSlider

                    Layout.maximumWidth: itemWidth
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    value: Math.log(UtilsAdapter.getAppValue(Settings.PositionShareDuration))

                    from: 0.5
                    to: Math.log(600)
                    stepSize: 0.05

                    onMoved: {
                        timeSharingLocationValueLabel.text = timeSharingLocation.standartCountdown(Math.floor(Math.exp(value)))
                        UtilsAdapter.setAppValue(Settings.PositionShareDuration, Math.floor(Math.exp(value)))
                    }

                    MaterialToolTip {
                        id: toolTip

                        text: JamiStrings.positionShareDuration
                        visible: parent.hovered
                        delay: Qt.styleHints.mousePressAndHoldInterval
                    }
                }
            }

        }

    }
}
