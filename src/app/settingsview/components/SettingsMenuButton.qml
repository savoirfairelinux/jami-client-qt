/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

PushButton {
    id: root

    property int menuType: 0

    preferredHeight: 64
    preferredLeftMargin: 24
    preferredRightMargin: 24

    buttonTextFont.pointSize: JamiTheme.textFontSize + 2
    textHAlign: Text.AlignLeft

    imageColor: JamiTheme.textColor
    imageContainerHeight: 40
    imageContainerWidth: 40

    pressedColor: Qt.lighter(JamiTheme.pressedButtonColor, 1.25)
    checkedColor: JamiTheme.smartListSelectedColor
    hoveredColor: JamiTheme.smartListHoveredColor

    duration: 0
    checkable: true
    radius: 0
}
