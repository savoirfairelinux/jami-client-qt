/*
 * Copyright (C) 2020 by Savoir-faire Linux
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Styles 1.4

import net.jami.Constants 1.0

TextField{
    enum BorderColorMode{
        NORMAL,
        RIGHT,
        ERROR
    }

    property int fieldLayoutWidth: 256
    property int fieldLayoutHeight: 30
    property bool layoutFillwidth: false

    property int borderColorMode: InfoLineEdit.NORMAL
    property var backgroundColor: JamiTheme.rgb256(240,240,240)
    property var borderColor: {
        switch(borderColorMode){
        case InfoLineEdit.NORMAL:
            return "transparent"
        case InfoLineEdit.RIGHT:
            return "green"
        case InfoLineEdit.ERROR:
            return "red"
        }
    }

    wrapMode: Text.Wrap
    color: JamiTheme.textColor
    readOnly: false
    selectByMouse: true
    font.pointSize: JamiTheme.settingsFontSize
    font.kerning: true
    horizontalAlignment: Text.AlignLeft
    verticalAlignment: Text.AlignVCenter

    background: Rectangle {
        anchors.fill: parent
        radius: readOnly? 0 : height / 2
        border.color: readOnly? "transparent" : borderColor
        border.width:readOnly? 0 : 2
        color: readOnly? "transparent" : backgroundColor
    }
}
