/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
    width: 550
    minimumWidth: 550
    height: 520
    minimumHeight: 520

    readonly property list<ListModel> keyboardShortcutsModelList: [
        ListModel {
            id: keyboardGeneralShortcutsModel

            ListElement {
                shortcut: "Ctrl+J"
                description: qsTr("Open account list")
            }
            ListElement {
                shortcut: "Ctrl+L"
                description: qsTr("Focus conversation list")
            }
            ListElement {
                shortcut: "Ctrl+R"
                description: qsTr("Requests list")
            }
            ListElement {
                shortcut: "Ctrl+↑"
                description: qsTr("Previous conversation")
            }
            ListElement {
                shortcut: "Ctrl+↓"
                description: qsTr("Next conversation")
            }
            ListElement {
                shortcut: "Ctrl+F"
                description: qsTr("Search bar")
            }
            ListElement {
                shortcut: "Ctrl++"
                description: qsTr("Increase font size")
            }
            ListElement {
                shortcut: "Ctrl+-"
                description: qsTr("Decrease font size")
            }
            ListElement {
                shortcut: "Ctrl+0"
                description: qsTr("Reset font size")
            }
        },
        ListModel {
            id: keyboardConversationShortcutsModel

            ListElement {
                shortcut: "Ctrl+Shift+A"
                description: qsTr("Accept contact request")
            }
            ListElement {
                shortcut: "Ctrl+Shift+F"
                description: qsTr("Search messages/files")
            }
            ListElement {
                shortcut: "↑"
                description: qsTr("Edit last message")
            }
            ListElement {
                shortcut: "Esc"
                description: qsTr("Cancel message edition")
            }
            ListElement {
                shortcut: "Ctrl+Shift+L"
                description: qsTr("Clear history")
            }
            ListElement {
                shortcut: "Ctrl+Shift+B"
                description: qsTr("Block contact")
            }
            ListElement {
                shortcut: "Ctrl+Shift+Delete"
                description: qsTr("Leave conversation")
            }
        },
        ListModel {
            id: keyboardCallsShortcutsModel

            ListElement {
                shortcut: "Ctrl+Shift+C"
                description: qsTr("Start audio call")
            }
            ListElement {
                shortcut: "Ctrl+Shift+X"
                description: qsTr("Start video call")
            }
            ListElement {
                shortcut: "Ctrl+Y"
                description: qsTr("Accept call")
            }
            ListElement {
                shortcut: "Ctrl+D"
                description: qsTr("End call")
            }
            ListElement {
                shortcut: "Ctrl+Shift+D"
                description: qsTr("Decline call")
            }
            ListElement {
                shortcut: "F11"
                description: qsTr("Full screen")
            }
            ListElement {
                shortcut: "M"
                description: qsTr("Mute microphone")
            }
            ListElement {
                shortcut: "V"
                description: qsTr("Stop camera")
            }
            ListElement {
                shortcut: "Ctrl+Mouse middle click"
                description: qsTr("Take tile screenshot")
            }
        },
        ListModel {
            id: keyboardMarkdownShortcutsModel

            ListElement {
                shortcut: "Ctrl+B"
                description: qsTr("Bold")
            }
            ListElement {
                shortcut: "Ctrl+I"
                description: qsTr("Italic")
            }
            ListElement {
                shortcut: "Shift+Alt+X"
                description: qsTr("Strikethrough")
            }
            ListElement {
                shortcut: "Ctrl+Alt+H"
                description: qsTr("Heading")
            }
            ListElement {
                shortcut: "Ctrl+Alt+K"
                description: qsTr("Link")
            }
            ListElement {
                shortcut: "Ctrl+Alt+C"
                description: qsTr("Code")
            }
            ListElement {
                shortcut: "Shift+Alt+9"
                description: qsTr("Quote")
            }
            ListElement {
                shortcut: "Shift+Alt+8"
                description: qsTr("Unordered list")
            }
            ListElement {
                shortcut: "Shift+Alt+7"
                description: qsTr("Ordered list")
            }
            ListElement {
                shortcut: "Shift+Alt+T"
                description: qsTr("Show/hide formatting")
            }
            ListElement {
                shortcut: "Shift+Alt+P"
                description: qsTr("Show preview/Continue editing")
            }
        },
        ListModel {
            id: keyboardSettingsShortcutsModel

            ListElement {
                shortcut: "Ctrl+Alt+I"
                description: qsTr("Open account settings")
            }
            ListElement {
                shortcut: "Ctrl+G"
                description: qsTr("Open general settings")
            }
            ListElement {
                shortcut: "Ctrl+M"
                description: qsTr("Open media settings")
            }
            ListElement {
                shortcut: "Ctrl+E"
                description: qsTr("Open extensions settings")
            }
            ListElement {
                shortcut: "Ctrl+Shift+N"
                description: qsTr("Open account creation wizard")
            }
            ListElement {
                shortcut: "F10"
                shortcut2: ""
                description: qsTr("View keyboard shortcuts")
            }
        }
    ]

    Page {
        id: page

        anchors.fill: parent

        background: Rectangle {
            anchors.fill: parent
            color: JamiTheme.globalBackgroundColor
        }

        // make a list view of keyboardShortcutsModelList[selectionBar.currentIndex]
        JamiListView {
            id: keyboardShortcutsListView

            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Keys.onUpPressed: keyboardShortcutsListView.decrementCurrentIndex()
            Keys.onDownPressed: keyboardShortcutsListView.incrementCurrentIndex()

            // on key tab forceActiveFocus
            Keys.onTabPressed: if (activeFocus)
                selectionBar.forceActiveFocus()

            model: keyboardShortcutsModelList[selectionBar.currentIndex]
            spacing: 24
            delegate: FocusScope {
                id: fs
                height: childrenRect.height
                focus: true

                // Accessible.role: Accessible.Button
                Accessible.name: descriptionLabel.text
                Accessible.description: shortcutLabel.text

                RowLayout {
                    width: keyboardShortcutsListView.width
                    Label {
                        id: descriptionLabel
                        Layout.alignment: Qt.AlignLeft
                        Layout.topMargin: 8
                        Layout.leftMargin: 20
                        text: description
                        color: JamiTheme.textColor
                        background: null
                    }
                    Label {
                        id: shortcutLabel
                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 8
                        Layout.rightMargin: 20
                        text: shortcut
                        color: JamiTheme.textColor
                        background: null
                    }
                }
            }
        }

        header: TabBar {
            id: selectionBar

            readonly property real lambda: 12

            spacing: lambda
            padding: lambda

            focus: true

            background: null

            Repeater {
                model: [JamiStrings.generalSettingsTitle, JamiStrings.conversationKeyboardShortcuts, JamiStrings.callKeyboardShortcuts, JamiStrings.markdownKeyboardShortcuts, JamiStrings.settings]

                FilterTabButton {
                    id: tabButton

                    Accessible.name: modelData + "shortcuts category"

                    down: selectionBar.currentIndex === index
                    labelText: modelData
                }
            }
        }

        footer: Item {
            height: JamiTheme.keyboardShortcutTabBarSize
            PageIndicator {
                id: pageIndicator
                anchors.centerIn: parent
                count: selectionBar.count
                currentIndex: selectionBar.currentIndex
                delegate: Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: index === pageIndicator.currentIndex ? JamiTheme.textColor : JamiTheme.textColorHoveredHighContrast
                }
            }
        }
    }
}
