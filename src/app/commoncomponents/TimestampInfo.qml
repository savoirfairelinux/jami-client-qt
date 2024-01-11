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

    property bool showTime
    property bool showDay
    property string formattedTime
    property string formattedDay
    property real detailsOpacity: 0.6
    property color timeColor: JamiTheme.chatviewSecondaryInformationColor
    property alias timeLabel: formattedTimeLabel
    property alias borderColor: dayRectangle.border.color

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
        visible: showDay
        Layout.alignment: Qt.AlignHCenter

        Layout.preferredHeight: childrenRect.height
        Layout.fillWidth: true
        Layout.topMargin: 30

        Rectangle {
            id: line

            height: 1
            opacity: detailsOpacity
            color: JamiTheme.timestampColor
            width: parent.width - JamiTheme.timestampLinePadding
            anchors.centerIn: parent
        }

        Rectangle {
            id: dayRectangle

            width: formattedDayLabel.width + JamiTheme.dayTimestampVPadding
            height: formattedDayLabel.height + JamiTheme.dayTimestampHPadding
            radius: 5
            color: JamiTheme.chatviewBgColor
            Layout.fillHeight: true
            anchors.centerIn: parent

            border {
                color: JamiTheme.timestampColor
                width: 1
            }

            Text {
                id: formattedDayLabel

                color: JamiTheme.chatviewTextColor
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                text: formattedDay
                font.pointSize: JamiTheme.timestampFont
            }
        }
    }

    Label {
        id: formattedTimeLabel

        text: formattedTime
        Layout.topMargin: 30
        Layout.bottomMargin: 30
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        color: root.timeColor
        visible: showTime
        Layout.preferredHeight: visible * implicitHeight
        font.pointSize: JamiTheme.smallFontSize
    }
}
