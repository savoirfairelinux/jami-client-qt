/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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
import QtQuick.Effects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Item {
    id: root

    property int type: ContactList.ADDCONVMEMBER

    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
        id: innerRect

        anchors.fill: parent
        anchors.margins: viewCoordinator.isInSinglePaneMode ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding
        anchors.topMargin: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding

        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius

        ColumnLayout {
            id: contactPickerPopupRectColumnLayout

            anchors.fill: parent
            anchors.margins: 15

            Searchbar {
                id: contactPickerContactSearchBar

                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
                Layout.alignment: Qt.AlignTop

                placeHolderText: JamiStrings.inviteMember

                onVisibleChanged: {
                    if (visible)
                        forceActiveFocus();
                }

                onSearchBarTextChanged: function (text) {
                    ContactAdapter.setSearchFilter(text);
                }
            }

            JamiListView {
                id: contactPickerListView

                Layout.fillHeight: true
                Layout.fillWidth: true

                // Reset the model if visible or the current conv member count changes (0 or greater)
                model: visible && CurrentConversation.members.count >= 0 ? ContactAdapter.getContactSelectableModel(type) : null

                delegate: ContactPickerItemDelegate {
                    id: contactPickerItemDelegate

                    showPresenceIndicator: true
                }
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
