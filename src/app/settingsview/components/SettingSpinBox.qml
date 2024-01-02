/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

    property alias title: title.text
    property alias enabled: spinbox.enabled
    property alias bottomValue: spinbox.from
    property alias topValue: spinbox.to
    property alias valueField: spinbox.value
    property alias tooltipText: toolTip.text
    property alias step: spinbox.stepSize

    property string borderColor: JamiTheme.greyBorderColor
    property int itemWidth

    signal newValue

    Text {
        id: title

        Layout.fillWidth: true
        Layout.rightMargin: JamiTheme.preferredMarginSize

        color: JamiTheme.textColor
        wrapMode: Text.WordWrap
        font.pointSize: JamiTheme.settingsFontSize
        font.kerning: true
        verticalAlignment: Text.AlignVCenter
    }

    SpinBox {
        id: spinbox

        wheelEnabled: true
        hoverEnabled: true

        Layout.preferredWidth: root.itemWidth
        Layout.alignment: Qt.AlignCenter
        font.pointSize: JamiTheme.settingsFontSize
        font.kerning: true
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true

        onValueChanged: newValue()

        Keys.onPressed: function (keyEvent) {
            if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
                textInput.focus = false;
                spinbox.value = textInput.text;
                keyEvent.accepted = true;
            }
        }

        contentItem: TextInput {
            id: textInput

            text: spinbox.textFromValue(spinbox.value, spinbox.locale)
            color: JamiTheme.textColor
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            inputMethodHints: Qt.ImhDigitsOnly
            validator: spinbox.validator
            font.pointSize: JamiTheme.settingsFontSize
        }

        background: Rectangle {
            border.color: JamiTheme.spinboxBorderColor
            implicitHeight: textInput.implicitHeight + JamiTheme.buttontextHeightMargin
            color: JamiTheme.transparentColor
            radius: JamiTheme.primaryRadius
        }

        MaterialToolTip {
            id: toolTip
            parent: spinbox
            visible: spinbox.hovered && (root.tooltipText.length > 0)
            delay: Qt.styleHints.mousePressAndHoldInterval
        }

        height: down.implicitIndicatorHeight

        up.indicator: Rectangle {

            width: parent.width / 8
            radius: 4
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                margins: 1
            }

            color: JamiTheme.transparentColor

            ResponsiveImage {

                containerHeight: 6
                containerWidth: 10
                width: 20
                height: 20
                color: JamiTheme.tintedBlue
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                source: JamiResources.chevron_right_black_24dp_svg
            }
        }

        down.indicator: Rectangle {

            width: parent.width / 8
            radius: 4
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                margins: 1
            }

            color: JamiTheme.transparentColor

            ResponsiveImage {

                containerHeight: 6
                containerWidth: 10
                width: 20
                height: 20
                color: JamiTheme.tintedBlue
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                source: JamiResources.chevron_left_black_24dp_svg
            }
        }
    }
}
