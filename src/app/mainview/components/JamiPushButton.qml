/*
 * Copyright (C) 2022-2025 Savoir-faire Linux Inc.
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
import "../../commoncomponents"

PushButton {
    pressedColor: JamiTheme.pressedButtonColor
    hoveredColor: JamiTheme.hoveredButtonColor
    radius: JamiTheme.chatViewHeaderButtonRadius

    normalColor: JamiTheme.chatviewBgColor
    imageColor: hovered ? JamiTheme.chatviewButtonColor : JamiTheme.chatViewFooterImgColor
    Accessible.role: Accessible.Button
    Accessible.description: toolTipText
}
