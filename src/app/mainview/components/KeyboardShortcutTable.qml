/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

    readonly property list<ListModel> keyboardShortcutsModelList: [
        ListModel {
            id: keyboardGeneralShortcutsModel

            ListElement {
                shortcut: "Ctrl + J"
                description: qsTr("Open account list")
            }
            ListElement {
                shortcut: "Ctrl + L"
                description: qsTr("Focus conversations list")
            }
            ListElement {
                shortcut: "Ctrl + R"
                description: qsTr("Requests list")
            }
            ListElement {
                shortcut: "Ctrl + ↑"
                description: qsTr("Previous conversation")
            }
            ListElement {
                shortcut: "Ctrl + ↓"
                description: qsTr("Next conversation")
            }
            ListElement {
                shortcut: "Ctrl + F"
                description: qsTr("Search bar")
            }
            ListElement {
                shortcut: "F11"
                description: qsTr("Full screen")
            }
            ListElement {
                shortcut: "Ctrl + +"
                description: qsTr("Increase font size")
            }
            ListElement {
                shortcut: "Ctrl + -"
                description: qsTr("Decrease font size")
            }
            ListElement {
                shortcut: "Ctrl + 0"
                description: qsTr("Reset font size")
            }
        },
        ListModel {
            id: keyboardConversationShortcutsModel

            ListElement {
                shortcut: "Ctrl + Shift + C"
                description: qsTr("Start an audio call")
            }
            ListElement {
                shortcut: "Ctrl + Shift + X"
                description: qsTr("Start a video call")
            }
            ListElement {
                shortcut: "Ctrl + Shift + L"
                description: qsTr("Clear history")
            }
            ListElement {
                shortcut: "Ctrl + Shift + F"
                description: qsTr("Search messages/files")
            }
            ListElement {
                shortcut: "Ctrl + Shift + B"
                description: qsTr("Block contact")
            }
            ListElement {
                shortcut: "Ctrl + Shift + Delete"
                description: qsTr("Remove conversation")
            }
            ListElement {
                shortcut: "Ctrl + Shift + A"
                description: qsTr("Accept contact request")
            }
            ListElement {
                shortcut: "↑"
                description: qsTr("Edit last message")
            }
            ListElement {
                shortcut: "Esc"
                description: qsTr("Cancel message edition")
            }
        },
        ListModel {
            id: keyboardSettingsShortcutsModel

            ListElement {
                shortcut: "Ctrl + M"
                description: qsTr("Media settings")
            }
            ListElement {
                shortcut: "Ctrl + G"
                description: qsTr("General settings")
            }
            ListElement {
                shortcut: "Ctrl + Alt + I"
                description: qsTr("Account settings")
            }
            ListElement {
                shortcut: "Ctrl + P"
                description: qsTr("Plugin settings")
            }
            ListElement {
                shortcut: "Ctrl + Shift + N"
                description: qsTr("Open account creation wizard")
            }
            ListElement {
                shortcut: "F10"
                shortcut2: ""
                description: qsTr("Open keyboard shortcut table")
            }
        },
        ListModel {
            id: keyboardCallsShortcutsModel

            ListElement {
                shortcut: "Ctrl + Y"
                description: qsTr("Answer an incoming call")
            }
            ListElement {
                shortcut: "Ctrl + D"
                description: qsTr("End call")
            }
            ListElement {
                shortcut: "Ctrl + Shift + D"
                description: qsTr("Decline the call request")
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
                shortcut: "Ctrl + Mouse middle click"
                description: qsTr("Take tile screenshot")
            }
        },
        ListModel {
            id: keyboardMarkdownShortcutsModel

            ListElement {
                shortcut: "Ctrl + B"
                description: qsTr("Bold")
            }
            ListElement {
                shortcut: "Ctrl + I"
                description: qsTr("Italic")
            }
            ListElement {
                shortcut: "Shift + Alt + X"
                description: qsTr("Strikethrough")
            }
            ListElement {
                shortcut: "Ctrl + Alt + H"
                description: qsTr("Heading")
            }
            ListElement {
                shortcut: "Ctrl + Alt + K"
                description: qsTr("Link")
            }
            ListElement {
                shortcut: "Ctrl + Alt + C"
                description: qsTr("Code")
            }
            ListElement {
                shortcut: "Shift + Alt + 9"
                description: qsTr("Quote")
            }
            ListElement {
                shortcut: "Shift + Alt + 8"
                description: qsTr("Unordered list")
            }
            ListElement {
                shortcut: "Shift + Alt + 7"
                description: qsTr("Ordered list")
            }
            ListElement {
                shortcut: "Shift + Alt + T"
                description: qsTr("Show formatting")
            }
            ListElement {
                shortcut: "Shift + Alt + P"
                description: qsTr("Show preview")
            }
        }
    ]

    Page {
        id: page

        anchors.fill: parent

        // make a list view of keyboardShortcutsModelList[selectionBar.currentIndex]
        JamiListView {
            id: keyboardShortcutsListView

            anchors.fill: parent
            anchors.leftMargin: 48
            anchors.rightMargin: 48

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
                        background: Rectangle {
                            width: parent.width + 16
                            height: parent.height + 16
                            border.color: fs.activeFocus ? "darkblue" : "transparent"
                            border.width: 2
                            radius: 5
                            anchors.centerIn: parent
                        }
                    }
                    Label {
                        id: shortcutLabel
                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 8
                        Layout.rightMargin: 20
                        text: shortcut
                        background: Rectangle {
                            width: parent.width + 16
                            height: parent.height + 16
                            border.color: fs.activeFocus ? "darkblue" : "transparent"
                            border.width: 2
                            radius: 5
                            anchors.centerIn: parent
                        }
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

            Repeater {
                model: [JamiStrings.generalSettingsTitle, JamiStrings.conversationKeyboardShortcuts, JamiStrings.callKeyboardShortcuts, JamiStrings.settings, JamiStrings.markdownKeyboardShortcuts]

                TabButton {
                    id: tabButton

                    Accessible.name: modelData + "shortcuts category"

                    Keys.onTabPressed: if (activeFocus)
                        keyboardShortcutsListView.forceActiveFocus()

                    contentItem: Text {
                        text: modelData
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.titleFontSize
                        horizontalAlignment: Text.AlignHCenter
                    }

                    background: Rectangle {
                        border.color: tabButton.activeFocus ? "darkblue" : "transparent"
                        border.width: 2

                        color: {
                            if (tabButton.checked || tabButton.pressed)
                                return JamiTheme.pressedButtonColor;
                            if (tabButton.hovered)
                                return JamiTheme.hoveredButtonColor;
                            else
                                return JamiTheme.normalButtonColor;
                        }
                        radius: JamiTheme.primaryRadius
                    }
                }
            }
        }

        footer: Item {
            height: JamiTheme.keyboardShortcutTabBarSize
            PageIndicator {
                anchors.centerIn: parent
                count: selectionBar.count
                currentIndex: selectionBar.currentIndex
            }
        }
    }
}
