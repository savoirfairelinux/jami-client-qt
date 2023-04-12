/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Page {
    id: root
    property color backgroundColor: JamiTheme.secondaryBackgroundColor
    property real contentFlickableWidth: Math.min(JamiTheme.maximumWidthSettingsView, root.width - 2 * JamiTheme.preferredSettingsMarginSize)
    required property Item flickableContent

    Rectangle {
        color: backgroundColor
        height: parent.height
        width: parent.width
    }
    JamiFlickable {
        id: flickable
        ScrollBar.horizontal.visible: false
        anchors.fill: parent
        bottomMargin: JamiTheme.preferredSettingsBottomMarginSize
        contentHeight: contentItem.childrenRect.height
        contentItem.children: [flickableContent]
        topMargin: JamiTheme.preferredSettingsBottomMarginSize
    }

    header: Rectangle {
        color: backgroundColor
        height: JamiTheme.settingsHeaderpreferredHeight
        width: root.preferredWidth

        SettingsHeader {
            id: settingsHeader
            anchors.fill: parent
            title: root.title

            onBackArrowClicked: viewNode.dismiss()
        }
    }
}
