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
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../settingsview/components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
        id: innerRect

        anchors.fill: parent
        anchors.margins: viewCoordinator.isInSinglePaneMode ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding
        anchors.topMargin: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding * 2

        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15

            Searchbar {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
                Layout.alignment: Qt.AlignTop

                onVisibleChanged: {
                    if (visible) {
                        clearText();
                        forceActiveFocus();
                    }
                }
                onSearchBarTextChanged: function (text) {
                    MessagesAdapter.searchbarPrompt = text;
                }
            }

            TabBar {
                id: researchTabBar

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.tabBarHeight
                // Break implicitWidth binding loop (Universal TabBar).
                implicitWidth: 0

                spacing: JamiTheme.tabBarSpacing

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

                    down: researchTabBar.currentIndex === 0
                    labelText: JamiStrings.messages
                }

                FilterTabButton {
                    id: fileResearchTabButton

                    down: researchTabBar.currentIndex === 1
                    labelText: JamiStrings.files
                }
            }

            MessagesResearchView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: researchTabBar.currentIndex === 0
                clip: true
            }

            DocumentsScrollview {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: researchTabBar.currentIndex === 1
                clip: true
                themeColor: JamiTheme.chatviewTextColor
                textFilter: MessagesAdapter.searchbarPrompt
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            anchors.fill: innerRect
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }
    }
}
