/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
import "../../commoncomponents"

Rectangle {
    id: root

    opacity: visible

    property alias text: errorLabel.text

    color: JamiTheme.filterBadgeColor
    visible: CurrentAccount.id !== ""
             && CurrentAccount.status !== Account.Status.REGISTERED
             && CurrentAccount.status !== Account.Status.READY
             && CurrentAccount.status !== Account.Status.TRYING
             && CurrentAccount.status !== Account.Status.INITIALIZING

    RowLayout {
        anchors.fill: parent
        anchors.margins: JamiTheme.preferredMarginSize

        Text {
            id: errorLabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            color: JamiTheme.filterBadgeTextColor
            font.pixelSize: JamiTheme.headerFontSize
            elide: Text.ElideRight
        }
    }

    Behavior on opacity  {
        NumberAnimation {
            from: 0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
