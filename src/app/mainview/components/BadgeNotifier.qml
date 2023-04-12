/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import QtQuick
import net.jami.Constants 1.1

Rectangle {
    id: root
    property bool animate: true
    property int count: 0
    property int lastCount: count
    property bool populated: false
    property real size

    color: JamiTheme.filterBadgeColor
    height: size
    radius: JamiTheme.primaryRadius
    visible: count > 0
    width: size

    onCountChanged: {
        if (count > lastCount && animate)
            notifyAnim.start();
        lastCount = count;
        if (!populated)
            populated = true;
    }

    Text {
        id: countLabel
        anchors.centerIn: root
        color: JamiTheme.filterBadgeTextColor
        font.pointSize: JamiTheme.filterBadgeFontSize
        font.weight: Font.ExtraBold
        text: count > 9 ? "9+" : count
    }
    ParallelAnimation {
        id: notifyAnim
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
            from: JamiTheme.filterBadgeTextColor
            properties: "color"
            target: root
            to: JamiTheme.filterBadgeColor
        }
        ColorAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
            from: JamiTheme.filterBadgeColor
            properties: "color"
            target: countLabel
            to: JamiTheme.filterBadgeTextColor
        }
        NumberAnimation {
            duration: 150
            easing.type: Easing.InOutQuad
            from: -3
            property: "y"
            target: root
            to: 0
        }
    }
}
