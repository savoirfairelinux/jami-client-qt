/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Franck Laurent <franck.laurent@savoirfairelinux.com>
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
import net.jami.Constants 1.1

ToolTip {
    id: root

    property alias backGroundColor: background.color
    property alias textColor: label.color
    property bool hasShortcut: false
    property string shortcutKey

    onVisibleChanged: {
        if (visible)
            animation.start();
    }

    contentItem: ColumnLayout {

        Text {
            id: label
            text: root.text
            font.pixelSize: 13
            color: "white"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: label.contentHeight
            Layout.preferredWidth: label.contentWidth
        }

        Rectangle {
            id: shortcutTextRect
            Layout.preferredWidth: shortcutText.contentWidth + 10
            Layout.preferredHeight: shortcutText.contentHeight + 10
            visible: hasShortcut

            color: JamiTheme.tooltipShortCutBackgroundColor
            radius: JamiTheme.primaryRadius

            Text {
                id: shortcutText
                anchors.centerIn: parent
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: JamiTheme.tooltipShortCutTextColor
                text: root.shortcutKey
            }
        }
    }

    background: Rectangle {
        id: background
        color: JamiTheme.tooltipBackgroundColor
        radius: 5
    }

    ParallelAnimation {
        id: animation
        NumberAnimation {
            target: background
            properties: "opacity"
            from: 0
            to: 1.0
            duration: JamiTheme.shortFadeDuration
        }

        NumberAnimation {
            target: shortcutTextRect
            properties: "opacity"
            from: 0
            to: 1.0
            duration: JamiTheme.shortFadeDuration
        }

        NumberAnimation {
            target: background
            properties: "scale"
            from: 0.5
            to: 1.0
            duration: JamiTheme.shortFadeDuration * 0.5
        }

        NumberAnimation {
            target: shortcutTextRect
            properties: "scale"
            from: 0.5
            to: 1.0
            duration: JamiTheme.shortFadeDuration * 0.5
        }
    }
}
