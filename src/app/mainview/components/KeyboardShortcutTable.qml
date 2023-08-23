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

    title: JamiStrings.keyboardShortcutTableWindowTitle
    width: 500
    minimumWidth: 300
    height: 480
    minimumHeight: 300

    ListModel {
        id: keyboardGeneralShortcutsModel

        ListElement {
            shortcut: "Ctrl + J"
            shortcut2: ""
            description: qsTr("Open account list")
        }
        ListElement {
            shortcut: "Ctrl + L"
            shortcut2: ""
            description: qsTr("Focus conversations list")
        }
        ListElement {
            shortcut: "Ctrl + R"
            shortcut2: ""
            description: qsTr("Requests list")
        }
        ListElement {
            shortcut: "Ctrl + ↑"
            shortcut2: ""
            description: qsTr("Previous conversation")
        }
        ListElement {
            shortcut: "Ctrl + ↓"
            shortcut2: ""
            description: qsTr("Next conversation")
        }
        ListElement {
            shortcut: "Ctrl + F"
            shortcut2: ""
            description: qsTr("Search bar")
        }
        ListElement {
            shortcut: "F11"
            shortcut2: ""
            description: qsTr("Full screen")
        }
        ListElement {
            shortcut: "Ctrl + +"
            shortcut2: ""
            description: qsTr("Increase font size")
        }
        ListElement {
            shortcut: "Ctrl + -"
            shortcut2: ""
            description: qsTr("Decrease font size")
        }
        ListElement {
            shortcut: "Ctrl + 0"
            shortcut2: ""
            description: qsTr("Reset font size")
        }
    }

    ListModel {
        id: keyboardConversationShortcutsModel

        ListElement {
            shortcut: "Ctrl + Shift + C"
            shortcut2: ""
            description: qsTr("Start an audio call")
        }
        ListElement {
            shortcut: "Ctrl + Shift + X"
            shortcut2: ""
            description: qsTr("Start a video call")
        }
        ListElement {
            shortcut: "Ctrl + Shift + L"
            shortcut2: ""
            description: qsTr("Clear history")
        }
        ListElement {
            shortcut: "Ctrl + Shift + F"
            shortcut2: ""
            description: qsTr("Search messages/files")
        }
        ListElement {
            shortcut: "Ctrl + Shift + B"
            shortcut2: ""
            description: qsTr("Block contact")
        }
        ListElement {
            shortcut: "Ctrl + Shift + Delete"
            shortcut2: ""
            description: qsTr("Remove conversation")
        }
        ListElement {
            shortcut: "Ctrl + Shift + A"
            shortcut2: ""
            description: qsTr("Accept contact request")
        }
        ListElement {
            shortcut: "↑"
            shortcut2: ""
            description: qsTr("Edit last message")
        }
        ListElement {
            shortcut: "Esc"
            shortcut2: ""
            description: qsTr("Cancel message edition")
        }
    }

    ListModel {
        id: keyboardSettingsShortcutsModel

        ListElement {
            shortcut: "Ctrl + M"
            shortcut2: ""
            description: qsTr("Media settings")
        }
        ListElement {
            shortcut: "Ctrl + G"
            shortcut2: ""
            description: qsTr("General settings")
        }
        ListElement {
            shortcut: "Ctrl + Alt + I"
            shortcut2: ""
            description: qsTr("Account settings")
        }
        ListElement {
            shortcut: "Ctrl + P"
            shortcut2: ""
            description: qsTr("Plugin settings")
        }
        ListElement {
            shortcut: "Ctrl + Shift + N"
            shortcut2: ""
            description: qsTr("Open account creation wizard")
        }
        ListElement {
            shortcut: "F10"
            shortcut2: ""
            description: qsTr("Open keyboard shortcut table")
        }
    }

    ListModel {
        id: keyboardCallsShortcutsModel

        ListElement {
            shortcut: "Ctrl + Y"
            shortcut2: ""
            description: qsTr("Answer an incoming call")
        }
        ListElement {
            shortcut: "Ctrl + D"
            shortcut2: ""
            description: qsTr("End call")
        }
        ListElement {
            shortcut: "Ctrl + Shift + D"
            shortcut2: ""
            description: qsTr("Decline the call request")
        }
        ListElement {
            shortcut: "M"
            shortcut2: ""
            description: qsTr("Mute microphone")
        }
        ListElement {
            shortcut: "V"
            shortcut2: ""
            description: qsTr("Stop camera")
        }
        ListElement {
            shortcut: "Ctrl"
            shortcut2: qsTr("Mouse middle click")
            description: qsTr("Take tile screenshot")
        }
    }

    ListModel {
        id: keyboardMarkdownShortcutsModel

        ListElement {
            shortcut: "Ctrl + B"
            shortcut2: ""
            description: qsTr("Bold")
        }
        ListElement {
            shortcut: "Ctrl + I"
            shortcut2: ""
            description: qsTr("Italic")
        }
        ListElement {
            shortcut: "Shift + Alt + X"
            shortcut2: ""
            description: qsTr("Strikethrough")
        }
        ListElement {
            shortcut: "Ctrl + Alt + H"
            shortcut2: ""
            description: qsTr("Heading")
        }
        ListElement {
            shortcut: "Ctrl + Alt + K"
            shortcut2: ""
            description: qsTr("Link")
        }
        ListElement {
            shortcut: "Ctrl + Alt + C"
            shortcut2: ""
            description: qsTr("Code")
        }
        ListElement {
            shortcut: "Shift + Alt + 9"
            shortcut2: ""
            description: qsTr("Quote")
        }
        ListElement {
            shortcut: "Shift + Alt + 8"
            shortcut2: ""
            description: qsTr("Unordered list")
        }
        ListElement {
            shortcut: "Shift + Alt + 7"
            shortcut2: ""
            description: qsTr("Ordered list")
        }
        ListElement {
            shortcut: "Shift + Alt + T"
            shortcut2: ""
            description: qsTr("Show formatting")
        }
        ListElement {
            shortcut: "Shift + Alt + P"
            shortcut2: ""
            description: qsTr("Show preview")
        }
        ListElement {
            shortcut: "Shift + Enter"
            shortcut2: ""
            description: qsTr("New line")
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
                    var modelId = UtilsAdapter.isRTL ? 4 - selectionBar.currentIndex : selectionBar.currentIndex;
                    switch (modelId) {
                    case 0:
                        return JamiStrings.generalSettingsTitle;
                    case 1:
                        return JamiStrings.conversationKeyboardShortcuts;
                    case 2:
                        return JamiStrings.callKeyboardShortcuts;
                    case 3:
                        return JamiStrings.settings;
                    case 4:
                        return JamiStrings.markdownKeyboardShortcuts;
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
            height: parent.height - titleRect.height - JamiTheme.titleRectMargin - keyboardShortCutList.anchors.topMargin - selectionBar.height - selectionBar.anchors.bottomMargin

            model: {
                var modelId = UtilsAdapter.isRTL ? 4 - selectionBar.currentIndex : selectionBar.currentIndex;
                switch (modelId) {
                case 0:
                    return keyboardGeneralShortcutsModel;
                case 1:
                    return keyboardConversationShortcutsModel;
                case 2:
                    return keyboardCallsShortcutsModel;
                case 3:
                    return keyboardSettingsShortcutsModel;
                case 4:
                    return keyboardMarkdownShortcutsModel;
                }
            }
            delegate: KeyboardShortcutKeyDelegate {
                width: keyboardShortCutList.width
                height: Math.max(JamiTheme.keyboardShortcutDelegateSize, implicitHeight)
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
            background: Rectangle {
                color: windowRect.color
            }

            Repeater {
                model: UtilsAdapter.isRTL ? ["5", "4", "3", "2", "1"] : ["1", "2", "3", "4", "5"]

                KeyboardShortcutTabButton {
                    currentIndex: selectionBar.currentIndex
                    text: modelData
                }
            }

            Component.onCompleted: {
                setCurrentIndex(UtilsAdapter.isRTL ? 4 : 0);
            }
        }
    }
}
