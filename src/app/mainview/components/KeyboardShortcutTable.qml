/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
    height: 480
    minimumHeight: 300
    minimumWidth: 300
    title: JamiStrings.keyboardShortcutTableWindowTitle
    width: 500

    ListModel {
        id: keyboardGeneralShortcutsModel
        ListElement {
            description: qsTr("Open account list")
            shortcut: "Ctrl + J"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Focus conversations list")
            shortcut: "Ctrl + L"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Requests list")
            shortcut: "Ctrl + R"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Previous conversation")
            shortcut: "Ctrl + ↑"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Next conversation")
            shortcut: "Ctrl + ↓"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Search bar")
            shortcut: "Ctrl + F"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Full screen")
            shortcut: "F11"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Increase font size")
            shortcut: "Ctrl + +"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Decrease font size")
            shortcut: "Ctrl + -"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Reset font size")
            shortcut: "Ctrl + 0"
            shortcut2: ""
        }
    }
    ListModel {
        id: keyboardConversationShortcutsModel
        ListElement {
            description: qsTr("Start an audio call")
            shortcut: "Ctrl + Shift + C"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Start a video call")
            shortcut: "Ctrl + Shift + X"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Clear history")
            shortcut: "Ctrl + Shift + L"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Search messages/files")
            shortcut: "Ctrl + Shift + F"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Block contact")
            shortcut: "Ctrl + Shift + B"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Remove conversation")
            shortcut: "Ctrl + Shift + Delete"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Accept contact request")
            shortcut: "Ctrl + Shift + A"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Edit last message")
            shortcut: "↑"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Cancel message edition")
            shortcut: "Esc"
            shortcut2: ""
        }
    }
    ListModel {
        id: keyboardSettingsShortcutsModel
        ListElement {
            description: qsTr("Media settings")
            shortcut: "Ctrl + M"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("General settings")
            shortcut: "Ctrl + G"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Account settings")
            shortcut: "Ctrl + I"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Plugin settings")
            shortcut: "Ctrl + P"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Open account creation wizard")
            shortcut: "Ctrl + Shift + N"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Open keyboard shortcut table")
            shortcut: "F10"
            shortcut2: ""
        }
    }
    ListModel {
        id: keyboardCallsShortcutsModel
        ListElement {
            description: qsTr("Answer an incoming call")
            shortcut: "Ctrl + Y"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("End call")
            shortcut: "Ctrl + D"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Decline the call request")
            shortcut: "Ctrl + Shift + D"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Mute microphone")
            shortcut: "M"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Stop camera")
            shortcut: "V"
            shortcut2: ""
        }
        ListElement {
            description: qsTr("Take tile screenshot")
            shortcut: "Ctrl"
            shortcut2: qsTr("Mouse middle click")
        }
    }
    Rectangle {
        id: windowRect
        anchors.fill: parent
        color: JamiTheme.secondaryBackgroundColor

        Rectangle {
            id: titleRect
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: JamiTheme.titleRectMargin
            color: JamiTheme.backgroundColor
            height: titleName.contentHeight + JamiTheme.titleRectMargin
            radius: JamiTheme.primaryRadius
            width: titleName.contentWidth + JamiTheme.titleRectMargin

            Text {
                id: titleName
                anchors.centerIn: parent
                color: JamiTheme.textColor
                font.pointSize: JamiTheme.titleFontSize
                text: {
                    switch (selectionBar.currentIndex) {
                    case 0:
                        return JamiStrings.generalSettingsTitle;
                    case 1:
                        return JamiStrings.conversationKeyboardShortcuts;
                    case 2:
                        return JamiStrings.callKeyboardShortcuts;
                    case 3:
                        return JamiStrings.settings;
                    }
                }
            }
        }
        JamiListView {
            id: keyboardShortCutList
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: titleRect.bottom
            anchors.topMargin: 10
            height: parent.height - titleRect.height - JamiTheme.titleRectMargin - keyboardShortCutList.anchors.topMargin - selectionBar.height - selectionBar.anchors.bottomMargin
            model: {
                switch (selectionBar.currentIndex) {
                case 0:
                    return keyboardGeneralShortcutsModel;
                case 1:
                    return keyboardConversationShortcutsModel;
                case 2:
                    return keyboardCallsShortcutsModel;
                case 3:
                    return keyboardSettingsShortcutsModel;
                }
            }
            width: parent.width

            delegate: KeyboardShortcutKeyDelegate {
                height: Math.max(JamiTheme.keyboardShortcutDelegateSize, implicitHeight)
                width: keyboardShortCutList.width
            }
        }
        TabBar {
            id: selectionBar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            contentHeight: JamiTheme.keyboardShortcutTabBarSize
            height: JamiTheme.keyboardShortcutTabBarSize
            width: 96

            Repeater {
                model: ["1", "2", "3", "4"]

                KeyboardShortcutTabButton {
                    currentIndex: selectionBar.currentIndex
                    text: modelData
                }
            }

            background: Rectangle {
                color: windowRect.color
            }
        }
    }
}
