/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../mainview/components"

Popup {
    id: root

    property list<Action> menuTypoActionsSecond

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    leftPadding: JamiTheme.markdownPopupPadding
    rightPadding: JamiTheme.markdownPopupPadding
    topPadding: JamiTheme.markdownPopupPadding
    bottomPadding: JamiTheme.markdownPopupPadding

    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    contentItem: RowLayout {
        spacing: JamiTheme.markdownPopupContentItemSpacing

        Repeater {
            model: menuTypoActionsSecond

            delegate: NewIconButton {
                Layout.alignment: Qt.AlignVCenter

                iconSize: JamiTheme.iconButtonSmall
                toolTipText: modelData.shortcutText
                toolTipShortcutKey: modelData.shortcutKey
                iconSource: modelData.iconSrc

                action: modelData
            }
        }
    }

    background: Rectangle {
        radius: height / 2

        color: JamiTheme.backgroundColor
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 0.0
            to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }
    exit: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 1.0
            to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
