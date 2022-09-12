/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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

import "../mainview/components/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

ColumnLayout{
    id: root

    property bool showTime
    property bool showDay
    property string formattedTime
    property string formattedDay
    property real detailsOpacity: 0.6

    Item{
        visible: showDay
        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: JamiTheme.dayTimestampTopMargin

        Rectangle {
            id: line

            height: 1
            opacity: detailsOpacity
            color:JamiTheme.timestampColor
            width: chatView.width - JamiTheme.timestampLinePadding
            anchors.centerIn: parent
        }

        Rectangle {
            id: dayRectangle

            width: borderRectangle.width
            height: borderRectangle.height
            radius: 5
            color: JamiTheme.chatviewBgColor
            Layout.fillHeight: true
            anchors.centerIn: parent

            Rectangle {
                id: borderRectangle

                border { color:  JamiTheme.timestampColor; width: 1}
                opacity: detailsOpacity
                width: formattedDayLabel.width + JamiTheme.dayTimestampVPadding
                height: formattedDayLabel.height + JamiTheme.dayTimestampHPadding
                radius: dayRectangle.radius
                color: JamiTheme.transparentColor
            }

            Text {
                id: formattedDayLabel

                color: JamiTheme.chatviewTextColor
                anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter}
                text: formattedDay
                font.pointSize: JamiTheme.timestampFont
            }
        }
    }

    Label {
        id: formattedTimeLabel

        text: formattedTime
        Layout.bottomMargin: JamiTheme.timestampBottomMargin
        Layout.topMargin: JamiTheme.timestampTopMargin
        Layout.alignment: Qt.AlignHCenter
        color: JamiTheme.timestampColor
        visible: showTime
        height: visible * implicitHeight
        font.pointSize: JamiTheme.timestampFont
    }
}
