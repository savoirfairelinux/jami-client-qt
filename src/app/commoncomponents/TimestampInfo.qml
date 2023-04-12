/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import "../mainview/components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

ColumnLayout {
    id: root
    property real detailsOpacity: 0.6
    property string formattedDay
    property string formattedTime
    property bool showDay
    property bool showTime

    spacing: 0

    Connections {
        target: MessagesAdapter

        function onTimestampUpdated() {
            if ((showTime || showDay) && Timestamp !== undefined) {
                formattedTime = MessagesAdapter.getFormattedTime(Timestamp);
            }
        }
    }
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: formattedTimeLabel.visible ? 0 : JamiTheme.dayTimestampBottomMargin
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height
        Layout.topMargin: JamiTheme.dayTimestampTopMargin
        visible: showDay

        Rectangle {
            id: line
            anchors.centerIn: parent
            color: JamiTheme.timestampColor
            height: 1
            opacity: detailsOpacity
            width: parent.width - JamiTheme.timestampLinePadding
        }
        Rectangle {
            id: dayRectangle
            Layout.fillHeight: true
            anchors.centerIn: parent
            color: JamiTheme.chatviewBgColor
            height: formattedDayLabel.height + JamiTheme.dayTimestampHPadding
            radius: 5
            width: formattedDayLabel.width + JamiTheme.dayTimestampVPadding

            border {
                color: JamiTheme.timestampColor
                width: 1
            }
            Text {
                id: formattedDayLabel
                color: JamiTheme.chatviewTextColor
                font.pointSize: JamiTheme.timestampFont
                text: formattedDay

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }
    Label {
        id: formattedTimeLabel
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        Layout.bottomMargin: JamiTheme.timestampBottomMargin
        Layout.preferredHeight: visible * implicitHeight
        Layout.topMargin: JamiTheme.timestampTopMargin
        color: JamiTheme.timestampColor
        font.pointSize: JamiTheme.timestampFont
        text: formattedTime
        visible: showTime || showDay
    }
}
