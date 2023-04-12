/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Constants 1.1

ItemDelegate {
    id: root
    property int checkBoxWidth: 24
    property bool isEnabled: false
    property int mediaCodecId
    property string mediaCodecName: ""
    property int mediaType
    property string samplerRate: ""

    highlighted: ListView.isCurrentItem
    hoverEnabled: true

    signal mediaCodecStateChange(string idToSet, bool isToBeEnabled)

    RowLayout {
        anchors.fill: parent

        CheckBox {
            id: checkBoxIsEnabled
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillHeight: true
            Layout.leftMargin: 20
            Layout.preferredWidth: checkBoxWidth
            checkState: isEnabled ? Qt.Checked : Qt.Unchecked
            nextCheckState: function () {
                var result;
                var result_bool;
                if (checkState === Qt.Checked) {
                    result = Qt.Unchecked;
                    result_bool = false;
                } else {
                    result = Qt.Checked;
                    result_bool = true;
                }
                mediaCodecStateChange(mediaCodecId, result_bool);
                return result;
            }
            text: ""
            tristate: false

            indicator: Image {
                anchors.centerIn: parent
                height: checkBoxWidth
                source: checkBoxIsEnabled.checked ? JamiResources.check_box_24dp_svg : JamiResources.check_box_outline_blank_24dp_svg
                width: checkBoxWidth

                layer {
                    enabled: true
                    mipmap: false
                    smooth: true

                    effect: ColorOverlay {
                        color: JamiTheme.tintedBlue
                    }
                }
            }
        }
        Label {
            id: formatNameLabel
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.rightMargin: JamiTheme.preferredMarginSize / 2
            color: JamiTheme.textColor
            elide: Text.ElideRight
            font.kerning: true
            font.pointSize: JamiTheme.textFontSize
            horizontalAlignment: Text.AlignLeft
            text: {
                if (mediaType == MediaSettings.VIDEO)
                    return mediaCodecName;
                else if (mediaType == MediaSettings.AUDIO)
                    return mediaCodecName + " " + samplerRate + " Hz";
            }
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        color: highlighted || hovered ? JamiTheme.smartListSelectedColor : JamiTheme.editBackgroundColor
    }
}
