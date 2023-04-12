/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root
    color: JamiTheme.chatviewBgColor

    ColumnLayout {
        anchors.fill: parent

        TabBar {
            id: researchTabBar
            Layout.preferredHeight: contentHeight + 10
            Layout.preferredWidth: root.width
            background.visible: false
            currentIndex: 0

            signal filterTabChange

            onCurrentIndexChanged: {
                filterTabChange();
            }
            onVisibleChanged: {
                researchTabBar.currentIndex = 0;
            }

            FilterTabButton {
                id: messagesResearchTabButton
                Layout.fillWidth: true
                backgroundColor: "transparent"
                borderWidth: 4
                bottomMargin: JamiTheme.settingsMarginSize
                down: researchTabBar.currentIndex === 0
                fontSize: JamiTheme.menuFontSize
                hoverColor: "transparent"
                labelText: JamiStrings.messages
                underlineContentOnly: true
            }
            FilterTabButton {
                id: fileResearchTabButton
                Layout.fillWidth: true
                backgroundColor: "transparent"
                borderWidth: 4
                bottomMargin: JamiTheme.settingsMarginSize
                down: researchTabBar.currentIndex === 1
                fontSize: JamiTheme.menuFontSize
                hoverColor: "transparent"
                labelText: JamiStrings.files
                underlineContentOnly: true
            }
        }
        Rectangle {
            id: view
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: JamiTheme.chatviewBgColor

            MessagesResearchView {
                anchors.fill: parent
                clip: true
                visible: researchTabBar.currentIndex === 0
            }
            DocumentsScrollview {
                anchors.fill: parent
                clip: true
                textFilter: MessagesAdapter.searchbarPrompt
                themeColor: JamiTheme.chatviewTextColor
                visible: researchTabBar.currentIndex === 1
            }
        }
    }
}
