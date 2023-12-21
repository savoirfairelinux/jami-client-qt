/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

Page {
    id: root

    header: Item {
        height: 45
        Searchbar {
            onVisibleChanged: {
                if (visible) {
                    clearText();
                    forceActiveFocus();
                }
            }
            anchors.fill: parent
            anchors.margins: 5
            onSearchBarTextChanged: function (text) {
                MessagesAdapter.searchbarPrompt = text;
            }
        }
    }

    background: Rectangle {
        color: JamiTheme.backgroundColor
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10

        TabBar {
            id: researchTabBar

            currentIndex: 0
            Layout.preferredHeight: contentHeight + 10
            Layout.preferredWidth: root.width
            background.visible: false
            signal filterTabChange
            onCurrentIndexChanged: {
                filterTabChange();
            }

            onVisibleChanged: {
                researchTabBar.currentIndex = 0;
            }

            FilterTabButton {
                id: messagesResearchTabButton

                backgroundColor: "transparent"
                hoverColor: "transparent"
                borderWidth: 4
                bottomMargin: JamiTheme.settingsMarginSize
                fontSize: JamiTheme.menuFontSize
                underlineContentOnly: true
                underlineColor: CurrentConversation.color
                underlineColorHovered: CurrentConversation.color

                down: researchTabBar.currentIndex === 0
                labelText: JamiStrings.messages
                Layout.fillWidth: true
            }

            FilterTabButton {
                id: fileResearchTabButton
                backgroundColor: "transparent"
                hoverColor: "transparent"
                borderWidth: 4
                bottomMargin: JamiTheme.settingsMarginSize
                fontSize: JamiTheme.menuFontSize
                underlineContentOnly: true
                underlineColor: CurrentConversation.color
                underlineColorHovered: CurrentConversation.color


                down: researchTabBar.currentIndex === 1
                labelText: JamiStrings.files
                Layout.fillWidth: true
            }
        }

        Rectangle {
            id: view

            color: JamiTheme.backgroundColor
            Layout.fillWidth: true
            Layout.fillHeight: true

            MessagesResearchView {
                anchors.fill: parent
                visible: researchTabBar.currentIndex === 0
                clip: true
            }

            DocumentsScrollview {
                anchors.fill: parent
                visible: researchTabBar.currentIndex === 1
                clip: true
                themeColor: JamiTheme.chatviewTextColor
                textFilter: MessagesAdapter.searchbarPrompt
            }
        }
    }
}
