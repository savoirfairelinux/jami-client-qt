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
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Window {
    id: root

    title: JamiStrings.keyboardShortcutTableWindowTitle
    width: 500
    height: 480

    ListModel {
        id: keyboardGeneralShortcutsModel

        ListElement {
            shortcut: "Ctrl + J"
            description: JamiStrings.openAccountList
        }
        ListElement {
            shortcut: "Ctrl + L"
            description: JamiStrings.focusConversationsList
        }
        ListElement {
            shortcut: "Ctrl + R"
            description: JamiStrings.requestsList
        }
        ListElement {
            shortcut: "Ctrl + ↑"
            description: JamiStrings.previousConversation
        }
        ListElement {
            shortcut: "Ctrl + ↓"
            description: JamiStrings.nextConversation
        }
        ListElement {
            shortcut: "Ctrl + F"
            description: JamiStrings.searchBar
        }
        ListElement {
            shortcut: "F11"
            description: JamiStrings.fullScreen
        }
    }

    ListModel {
        id: keyboardConversationShortcutsModel

        ListElement {
            shortcut: "Ctrl + Shift + C"
            description: JamiStrings.startAudioCall
        }
        ListElement {
            shortcut: "Ctrl + Shift + X"
            description: JamiStrings.startVideoCall
        }
        ListElement {
            shortcut: "Ctrl + Shift + L"
            description: JamiStrings.clearHistory
        }
        ListElement {
            shortcut: "Ctrl + Shift + B"
            description: JamiStrings.blockContact
        }
        ListElement {
            shortcut: "Ctrl + Shift + Delete"
            description: JamiStrings.removeConversation
        }
        ListElement {
            shortcut: "Shift + Ctrl + A"
            description: JamiStrings.acceptContactRequest
        }
    }

    ListModel {
        id: keyboardSettingsShortcutsModel

        ListElement {
            shortcut: "Ctrl + M"
            description: JamiStrings.mediaSettings
        }
        ListElement {
            shortcut: "Ctrl + G"
            description: JamiStrings.generalSettings
        }
        ListElement {
            shortcut: "Ctrl + I"
            description: JamiStrings.accountSettings
        }
        ListElement {
            shortcut: "Ctrl + P"
            description: JamiStrings.pluginSettings
        }
        ListElement {
            shortcut: "Ctrl + Shift + N"
            description: JamiStrings.openAccountCreationWizard
        }
        ListElement {
            shortcut: "F10"
            description: JamiStrings.openKeyboardShortcutTable
        }
    }

    ListModel {
        id: keyboardCallsShortcutsModel

        ListElement {
            shortcut: "Ctrl + Y"
            description: JamiStrings.answerIncoming
        }
        ListElement {
            shortcut: "Ctrl + D"
            description: JamiStrings.endCall
        }
        ListElement {
            shortcut: "Ctrl + Shift + D"
            description: JamiStrings.declineCallRequest
        }
    }

    Rectangle {
        id: windowRect

        anchors.fill: parent

        color: JamiTheme.secondaryBackgroundColor

        Rectangle {
            id: titleRect

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: JamiTheme.titleRectMargin

            height: titleName.contentHeight + JamiTheme.titleRectMargin
            width: titleName.contentWidth + JamiTheme.titleRectMargin

            color: JamiTheme.backgroundColor
            radius: JamiTheme.primaryRadius

            Text {
                id: titleName

                anchors.centerIn: parent

                font.pointSize: JamiTheme.titleFontSize
                text: {
                    switch (selectionBar.currentIndex) {
                    case 0:
                        return JamiStrings.generalKeyboardShortcuts
                    case 1:
                        return JamiStrings.conversationKeyboardShortcuts
                    case 2:
                        return JamiStrings.callKeyboardShortcuts
                    case 3:
                        return JamiStrings.settingsKeyboardShortcuts

                    }
                }
                color: JamiTheme.textColor
            }
        }

        JamiListView {
            id: keyboardShortCutList

            anchors.top: titleRect.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter

            width: parent.width
            height: parent.height - titleRect.height - JamiTheme.titleRectMargin -
                    keyboardShortCutList.anchors.topMargin - selectionBar.height -
                    selectionBar.anchors.bottomMargin

            model: {
                switch (selectionBar.currentIndex) {
                case 0:
                    return keyboardGeneralShortcutsModel
                case 1:
                    return keyboardConversationShortcutsModel
                case 2:
                    return keyboardCallsShortcutsModel
                case 3:
                    return keyboardSettingsShortcutsModel

                }
            }
            delegate: KeyboardShortcutKeyDelegate {
                width: keyboardShortCutList.width
                height: Math.max(JamiTheme.keyboardShortcutDelegateSize,
                                 implicitHeight)
            }
        }

        TabBar {
            id: selectionBar

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter

            width: 96
            height: JamiTheme.keyboardShortcutTabBarSize
            contentHeight: JamiTheme.keyboardShortcutTabBarSize

            Repeater {
                model: ["1", "2", "3", "4"]

                KeyboardShortcutTabButton {
                    currentIndex: selectionBar.currentIndex
                    text: modelData
                }
            }
        }
    }
}
