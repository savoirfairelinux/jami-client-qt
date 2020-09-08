/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.14
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.1
import net.jami.Models 1.0
import net.jami.Adapters 1.0

import "../../commoncomponents"
import "../../constant"

ColumnLayout {
    id: root

    property int itemWidth

    function updateSDPAccountInfos(){
        audioRTPMinPortSpinBox.value = SettingsAdapter.getAccountConfig_Audio_AudioPortMin()
        audioRTPMaxPortSpinBox.value = SettingsAdapter.getAccountConfig_Audio_AudioPortMax()
        videoRTPMinPortSpinBox.value = SettingsAdapter.getAccountConfig_Video_VideoPortMin()
        videoRTPMaxPortSpinBox.value = SettingsAdapter.getAccountConfig_Video_VideoPortMax()
    }

    function audioRTPMinPortSpinBoxEditFinished(value) {
        if (SettingsAdapter.getAccountConfig_Audio_AudioPortMax() < value) {
            audioRTPMinPortSpinBox.value = SettingsAdapter.getAccountConfig_Audio_AudioPortMin()
            return
        }
       SettingsAdapter.audioRTPMinPortSpinBoxEditFinished(value)
    }

    function audioRTPMaxPortSpinBoxEditFinished(value) {
        if (value <SettingsAdapter.getAccountConfig_Audio_AudioPortMin()) {
            audioRTPMaxPortSpinBox.value = SettingsAdapter.getAccountConfig_Audio_AudioPortMax()
            return
        }
       SettingsAdapter.audioRTPMaxPortSpinBoxEditFinished(value)
    }

    function videoRTPMinPortSpinBoxEditFinished(value) {
        if (SettingsAdapter.getAccountConfig_Video_VideoPortMax() < value) {
            videoRTPMinPortSpinBox.value = SettingsAdapter.getAccountConfig_Video_VideoPortMin()
            return
        }
       SettingsAdapter.videoRTPMinPortSpinBoxEditFinished(value)
    }

    function videoRTPMaxPortSpinBoxEditFinished(value) {
        if (value <SettingsAdapter.getAccountConfig_Video_VideoPortMin()) {
            videoRTPMinPortSpinBox.value = SettingsAdapter.getAccountConfig_Video_VideoPortMin()
            return
        }
       SettingsAdapter.videoRTPMaxPortSpinBoxEditFinished(value)
    }

    ElidedTextLabel {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        eText: qsTr("SDP Session Negotiation (ICE Fallback)")
        fontSize: JamiTheme.headerFontSize
        maxWidth: width
    }

    ElidedTextLabel {
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.preferredFieldHeight
        Layout.leftMargin: JamiTheme.preferredMarginSize

        eText: qsTr("Only used during negotiation in case ICE is not supported")
        fontSize: JamiTheme.settingsFontSize
        maxWidth: width
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        rows: 4
        columns: 2

        // 1st row
        Text {
            Layout.fillWidth: true
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            text: qsTr("Audio RTP Min Port")
            elide: Text.ElideRight
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true
            verticalAlignment: Text.AlignVCenter
        }

        SpinBox {
            id:audioRTPMinPortSpinBox

            Layout.preferredWidth: itemWidth
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            from: 0
            to: 65535
            stepSize: 1

            up.indicator.width: (width < 200) ? (width / 5) : 40
            down.indicator.width: (width < 200) ? (width / 5) : 40

            onValueModified: {
                audioRTPMinPortSpinBoxEditFinished(value)
            }
        }

        // 2nd row
        Text {
            Layout.fillWidth: true
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            text: qsTr("Audio RTP Max Port")
            elide: Text.ElideRight
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true
            verticalAlignment: Text.AlignVCenter
        }

        SpinBox {
            id:audioRTPMaxPortSpinBox

            Layout.preferredWidth: itemWidth
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            from: 0
            to: 65535
            stepSize: 1

            up.indicator.width: (width < 200) ? (width / 5) : 40
            down.indicator.width: (width < 200) ? (width / 5) : 40

            onValueModified: {
                audioRTPMaxPortSpinBoxEditFinished(value)
            }
        }

        // 3rd row
        Text {
            Layout.fillWidth: true
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            text: qsTr("Video RTP Min Port")
            elide: Text.ElideRight
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true
            verticalAlignment: Text.AlignVCenter
        }

        SpinBox {
            id:videoRTPMinPortSpinBox

            Layout.preferredWidth: itemWidth
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            from: 0
            to: 65535
            stepSize: 1

            up.indicator.width: (width < 200) ? (width / 5) : 40
            down.indicator.width: (width < 200) ? (width / 5) : 40

            onValueModified: {
                videoRTPMinPortSpinBoxEditFinished(value)
            }
        }

        // 4th row
        Text {
            Layout.fillWidth: true
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            text: qsTr("Video RTP Max Port")
            elide: Text.ElideRight
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true
            verticalAlignment: Text.AlignVCenter
        }

        SpinBox {
            id:videoRTPMaxPortSpinBox

            Layout.preferredWidth: itemWidth
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            from: 0
            to: 65535
            stepSize: 1

            up.indicator.width: (width < 200) ? (width / 5) : 40
            down.indicator.width: (width < 200) ? (width / 5) : 40

            onValueModified: {
                videoRTPMaxPortSpinBoxEditFinished(value)
            }
        }
    }
}
