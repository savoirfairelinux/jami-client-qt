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

BaseModalDialog {
    id: root

    property var previousBodies: undefined

    popupContent: JamiListView {
        id: editsList

        width: 400 - 2 * root.popupMargins
        height: Math.min(count * 50, 150)

        model: root.previousBodies

        delegate: Rectangle {
            width: editsList.width
            height: Math.max(JamiTheme.menuItemsPreferredHeight, rowBody.implicitHeight)
            color: index % 2 === 0 ? JamiTheme.backgroundColor : JamiTheme.secondaryBackgroundColor

            RowLayout {
                id: rowBody
                spacing: JamiTheme.preferredMarginSize
                anchors.fill: parent

                Text {
                    Layout.maximumWidth: root.width / 2
                    Layout.leftMargin: JamiTheme.settingsMarginSize
                    elide: Text.ElideRight

                    text: MessagesAdapter.getFormattedDay(modelData.timestamp.toString()) + " - " + MessagesAdapter.getFormattedTime(modelData.timestamp.toString())
                    color: JamiTheme.textColor
                    opacity: 0.5
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight

                    text: modelData.body === "" ? JamiStrings.deletedMessage : modelData.body
                    color: JamiTheme.textColor
                }
            }
        }
    }
}
