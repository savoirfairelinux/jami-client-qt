/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

import SortFilterProxyModel 0.2

import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Popup {
    id: root

    required property int type

    contentWidth: 250
    contentHeight: contactPickerPopupRectColumnLayout.height + 50

    padding: 0

    modal: true

    contentItem: Item {
        id: contactPickerPopupRect
        width: 250

        PushButton {
            id: closeButton

            anchors.top: contactPickerPopupRect.top
            anchors.topMargin: 5
            anchors.right: contactPickerPopupRect.right
            anchors.rightMargin: 5
            imageColor: JamiTheme.textColor

            source: JamiResources.round_close_24dp_svg

            onClicked: {
                root.close()
            }
        }

        ColumnLayout {
            id: contactPickerPopupRectColumnLayout

            anchors.top: contactPickerPopupRect.top
            anchors.topMargin: 15

            Text {
                id: contactPickerTitle

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: contactPickerPopupRect.width
                Layout.preferredHeight: 30

                font.pointSize: JamiTheme.textFontSize
                font.bold: true
                color: JamiTheme.textColor

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                text: {
                    switch(type) {
                    case ContactList.CONFERENCE:
                        return JamiStrings.addToConference
                    case ContactList.ADDCONVMEMBER:
                        return JamiStrings.addToConversation
                    case ContactList.TRANSFER:
                        return JamiStrings.transferThisCall
                    default:
                        return JamiStrings.addDefaultModerator
                    }
                }
            }

            ContactSearchBar {
                id: searchBar

                Layout.alignment: Qt.AlignCenter
                Layout.margins: 5
                Layout.fillWidth: true
                Layout.preferredHeight: 35

                placeHolderText: type === ContactList.TRANSFER
                                 ? JamiStrings.transferTo
                                 : JamiStrings.addParticipant
            }

            JamiListView {
                id: contactPickerListView

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: contactPickerPopupRect.width
                Layout.preferredHeight: 200

                model: SmartListProxyModel {
                    id: proxyModel
                    filterPattern: searchBar.textContent
                    Component.onCompleted: print(type)
                    type: root.type
                    filters: [
                        ExpressionFilter {
                            enabled: type === ContactList.CONVERSATION
                            property var defaultModerators: CurrentAccount.defaultModerators
                            onDefaultModeratorsChanged: Qt.callLater(invalidated)
                            expression: !defaultModerators.includes(model.URI)
                        },
                        AllOf {
                            enabled: type === ContactList.CONFERENCE
                            ValueFilter { roleName: "Presence"; value: true }
                            ValueFilter { roleName: "InCall"; value: false }
                        },
                        ExpressionFilter {
                            enabled: type === ContactList.TRANSFER
                            property var currentMembers: CurrentConversation.members
                            onCurrentMembersChanged: Qt.callLater(invalidated)
                            expression: !currentMembers.includes(model.URI)
                        }
                    ]
                }

                delegate: ContactPickerItemDelegate {
                    id: contactPickerItemDelegate

                    showPresenceIndicator: type !== ContactList.TRANSFER
                    onItemSelected: index => {
                                        proxyModel.selectItem(index)
                                        root.close()
                                    }
                }
            }
        }


    }

    background: Rectangle {
        radius: 10
        color: JamiTheme.backgroundColor
    }
}
