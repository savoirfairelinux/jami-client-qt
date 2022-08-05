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
    id: contactPickerPopup

    property int type: ContactList.CONFERENCE

    contentWidth: 250
    contentHeight: contactPickerPopupRectColumnLayout.height + 50

    padding: 0

    modal: true

    contentItem: Rectangle {
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
                contactPickerPopup.close()
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

                placeHolderText: JamiStrings.addParticipant

                onContactSearchBarTextChanged: {
                    if (type === ContactList.CONFERENCE)
                        ContactAdapter.setConferenceableFilter(text)
                }
            }

            JamiListView {
                id: contactPickerListView

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: contactPickerPopupRect.width
                Layout.preferredHeight: 200

                model: SortFilterProxyModel {
                    //sourceModel: ConversationListModel

                    Component.onCompleted: ContactAdapter.setConferenceableFilter("")
//                    proxyRoles: ExpressionRole {
//                         name: "hasDifferentMembers"
//                         property var currentMembers: CurrentConversation.members
//                         property var currenAccountUri: CurrentAccount.uri
//                         expression: {
//                             for (const uri in model.Uris) {
//                                 if (uri !== currenAccountUri && !currentMembers.includes(uri))
//                                     return true
//                             }
//                             return false
//                         }
//                    }
                    filters: [
                        AnyOf {
                            RegExpFilter {
                                roleName: "Title"
                                pattern: searchBar.textContent
                                caseSensitivity: Qt.CaseInsensitive
                            }
                            RegExpFilter {
                                roleName: "RegisteredName"
                                pattern: searchBar.textContent
                                caseSensitivity: Qt.CaseInsensitive
                            }
                            RegExpFilter {
                                roleName: "URI"
                                pattern: searchBar.textContent
                                caseSensitivity: Qt.CaseInsensitive
                            }
                        },
//                        ValueFilter {
//                            enabled: type === ContactList.ADDCONVMEMBER
//                            roleName: "hasDifferentMembers"
//                            value: true
//                        },
                        ExpressionFilter {
                            enabled: type === ContactList.ADDCONVMEMBER
                            property var currentMembers: CurrentConversation.members
                            property var currenAccountUri: CurrentAccount.uri
                            expression: {
                                for (const uri in model.Uris) {
                                    if (uri !== currenAccountUri && !currentMembers.includes(uri))
                                        return true
                                }
                                return false
                            }
                        },
                        ExpressionFilter {
                            enabled: type === ContactList.CONVERSATION
                            expression: !CurrentAccount.defaulModerators.contains(URI)
                        }
                    ]
                    sorters: ExpressionSorter {
                        expression: modelLeft.LastInteractionTimeStamp <
                                    modelRight.LastInteractionTimeStamp
                    }
                }

                delegate: ContactPickerItemDelegate {
                    id: contactPickerItemDelegate

                    showPresenceIndicator: type !== ContactList.TRANSFER
                }
            }
        }

        radius: 10
        color: JamiTheme.backgroundColor
    }

    background: Rectangle {
        color: "transparent"
    }
}
