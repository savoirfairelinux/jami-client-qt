/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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
import net.jami.Constants 1.1
import "../../commoncomponents"

RowLayout {
    id: root
    property string borderColor: JamiTheme.greyBorderColor
    property alias bottomValue: spinbox.from
    property alias enabled: spinbox.enabled
    property int itemWidth
    property alias step: spinbox.stepSize
    property alias title: title.text
    property alias tooltipText: toolTip.text
    property alias topValue: spinbox.to
    property alias valueField: spinbox.value

    signal newValue

    Text {
        id: title
        Layout.fillWidth: true
        Layout.rightMargin: JamiTheme.preferredMarginSize
        color: JamiTheme.textColor
        font.kerning: true
        font.pointSize: JamiTheme.settingsFontSize
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    SpinBox {
        id: spinbox
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: root.itemWidth
        font.kerning: true
        font.pointSize: JamiTheme.settingsFontSize
        height: down.implicitIndicatorHeight
        hoverEnabled: true
        wheelEnabled: true

        Keys.onPressed: function (keyEvent) {
            if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
                textInput.focus = false;
                spinbox.value = textInput.text;
                keyEvent.accepted = true;
            }
        }
        onValueChanged: newValue()

        MaterialToolTip {
            id: toolTip
            delay: Qt.styleHints.mousePressAndHoldInterval
            parent: spinbox
            visible: spinbox.hovered && (root.tooltipText.length > 0)
        }

        background: Rectangle {
            border.color: JamiTheme.spinboxBorderColor
            color: JamiTheme.transparentColor
            implicitHeight: textInput.implicitHeight + JamiTheme.buttontextHeightMargin
            radius: JamiTheme.primaryRadius
        }
        contentItem: TextInput {
            id: textInput
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.settingsFontSize
            horizontalAlignment: Qt.AlignHCenter
            inputMethodHints: Qt.ImhDigitsOnly
            text: spinbox.textFromValue(spinbox.value, spinbox.locale)
            validator: spinbox.validator
            verticalAlignment: Qt.AlignVCenter
        }
        down.indicator: Rectangle {
            color: JamiTheme.transparentColor
            radius: 4
            width: parent.width / 8

            anchors {
                bottom: parent.bottom
                left: parent.left
                margins: 1
                top: parent.top
            }
            ResponsiveImage {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                color: JamiTheme.tintedBlue
                containerHeight: 6
                containerWidth: 10
                height: 20
                source: JamiResources.chevron_left_black_24dp_svg
                width: 20
            }
        }
        up.indicator: Rectangle {
            color: JamiTheme.transparentColor
            radius: 4
            width: parent.width / 8

            anchors {
                bottom: parent.bottom
                margins: 1
                right: parent.right
                top: parent.top
            }
            ResponsiveImage {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                color: JamiTheme.tintedBlue
                containerHeight: 6
                containerWidth: 10
                height: 20
                source: JamiResources.chevron_right_black_24dp_svg
                width: 20
            }
        }
    }
}
