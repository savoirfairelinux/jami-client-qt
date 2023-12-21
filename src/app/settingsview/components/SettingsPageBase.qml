/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

JamiSplitView {
    id: root

    required property Item flickableContent
    property real contentFlickableWidth: Math.min(JamiTheme.maximumWidthSettingsView, settingsPage.width - 2 * JamiTheme.preferredSettingsMarginSize)
    property alias title: settingsPage.title
    property color backgroundColor: JamiTheme.secondaryBackgroundColor
    property alias pageContainer: settingsPage

    Page {
        id: settingsPage
        SplitView.maximumWidth: root.width
        SplitView.fillWidth: true
        SplitView.minimumWidth: 500
        Rectangle {
            width: parent.width
            height: parent.height
            color: backgroundColor
        }
        header: Rectangle {
            height: JamiTheme.settingsHeaderpreferredHeight
            width: root.preferredWidth
            color: backgroundColor

            SettingsHeader {
                id: settingsHeader
                title: root.title
                anchors.fill: parent
                onBackArrowClicked: viewNode.dismiss()
            }
        }

        JamiFlickable {
            id: flickable
            anchors.fill: parent
            contentHeight: contentItem.childrenRect.height
            contentItem.children: [flickableContent]
            topMargin: JamiTheme.preferredSettingsBottomMarginSize
            bottomMargin: JamiTheme.preferredSettingsBottomMarginSize
            ScrollBar.horizontal.visible: false
        }
    }
}
