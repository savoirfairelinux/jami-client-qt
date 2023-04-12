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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Button {
    id: buttonA
    property string iconSource
    property string textButton

    font.pixelSize: JamiTheme.messageOptionTextFontSize
    height: 20
    icon.color: JamiTheme.emojiReactPushButtonColor

    background: Rectangle {
        color: parent.down ? JamiTheme.pressedButtonColor : JamiTheme.hoveredButtonColor
        radius: 10
        visible: parent.hovered
    }
    contentItem: RowLayout {
        ResponsiveImage {
            id: icon
            Layout.rightMargin: 10
            color: JamiTheme.emojiReactPushButtonColor
            height: 25
            source: iconSource
            width: 25
        }
        Text {
            Layout.fillWidth: true
            color: JamiTheme.chatviewTextColor
            font.pixelSize: JamiTheme.messageOptionTextFontSize
            horizontalAlignment: Text.AlignLeft
            text: textButton
        }
    }
}
