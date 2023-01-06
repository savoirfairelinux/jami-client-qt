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
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

// Import qml component files.
import "components"
import "../"
import "../wizardview"
import "../settingsview"
import "../settingsview/components"

import "js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

Rectangle {
    id: mainView

    objectName: "mainView"

    property int sidePanelViewStackCurrentWidth: 300

    // To calculate tab bar bottom border hidden rect left margin.
    property int tabBarLeftMargin: 8
    property int tabButtonShrinkSize: 8
    property bool inSettingsView: viewCoordinator.inSettings

    signal loaderSourceChangeRequested(int sourceToLoad)

    property string currentConvId: CurrentConversation.id
    onCurrentConvIdChanged: {
        if (currentConvId !== '' && !inSettingsView) {
            viewCoordinator.present("ConversationView")
        }
    }

    color: JamiTheme.backgroundColor

    // Needed by ViewCoordinator.
    property alias splitView: splitView
    property alias sv1: sv1
    property alias sv2: sv2

    StackView {
        id: mainStackView
        anchors.fill: parent

        initialItem: SplitView {
            id: splitView

            handle: Rectangle {
                implicitWidth: JamiTheme.splitViewHandlePreferredWidth
                implicitHeight: splitView.height
                color: JamiTheme.primaryBackgroundColor
                Rectangle {
                    implicitWidth: 1
                    implicitHeight: splitView.height
                    color: JamiTheme.tabbarBorderColor
                }
            }

            StackView {
                id: sv1
                objectName: "sv1"
                SplitView.maximumWidth: splitView.width
                SplitView.minimumWidth: sidePanelViewStackCurrentWidth
                SplitView.preferredWidth: sidePanelViewStackCurrentWidth
                SplitView.fillHeight: true
                clip: true
                initialItem: SidePanel {}
            }

            StackView {
                id: sv2
                objectName: "sv2"
                SplitView.fillHeight: true
                clip: true
            }
        }
    }

    onHeightChanged: JamiQmlUtils.updateMessageBarButtonsPoints()

    Component.onCompleted: {
        JamiQmlUtils.mainViewRectObj = mainView
    }

    Shortcut {
        sequence: "Ctrl+M"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.settingsPageRequested(SettingsView.Media)
    }

    WheelHandler {
        onWheel: (wheel)=> {
            if (wheel.modifiers & Qt.ControlModifier) {
                var delta = wheel.angleDelta.y / 120
                UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) + delta * 0.1)
            }
        }
    }

    Shortcut {
        sequence: "Ctrl++"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) + 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+="
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) + 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+-"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) - 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+_"
        context: Qt.ApplicationShortcut
        onActivated: {
            UtilsAdapter.setAppValue(Settings.BaseZoom, parseFloat(UtilsAdapter.getAppValue(Settings.BaseZoom)) - 0.1)
        }
    }

    Shortcut {
        sequence: "Ctrl+0"
        context: Qt.ApplicationShortcut
        onActivated: UtilsAdapter.setAppValue(Settings.BaseZoom, 1.0)
    }

    Shortcut {
        sequence: "Ctrl+G"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.settingsPageRequested(SettingsView.General)
    }

    Shortcut {
        sequence: "Ctrl+I"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.settingsPageRequested(SettingsView.Account)
    }

    Shortcut {
        sequence: "Ctrl+P"
        context: Qt.ApplicationShortcut
        onActivated: JamiQmlUtils.settingsPageRequested(SettingsView.Plugin)
    }

    Shortcut {
        sequence: "F10"
        context: Qt.ApplicationShortcut
        onActivated: {
            KeyboardShortcutTableCreation.createKeyboardShortcutTableWindowObject(appWindow)
            KeyboardShortcutTableCreation.showKeyboardShortcutTableWindow()
        }
    }

    Shortcut {
        sequence: "F11"
        context: Qt.ApplicationShortcut
        onActivated: layoutManager.toggleWindowFullScreen()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: {
            MessagesAdapter.replyToId = ""
            MessagesAdapter.editId = ""
            layoutManager.popFullScreenItem()
        }
    }

    Shortcut {
        sequence: "Ctrl+D"
        context: Qt.ApplicationShortcut
        onActivated: CallAdapter.hangUpThisCall()
        onActivatedAmbiguously: CallAdapter.hangUpThisCall()
    }

    Shortcut {
        sequence: "Ctrl+Shift+A"
        context: Qt.ApplicationShortcut
        onActivated: LRCInstance.makeConversationPermanent()
    }

    Shortcut {
        sequence: "Ctrl+Shift+N"
        context: Qt.ApplicationShortcut
        onActivated: viewCoordinator.present("WizardView")
    }

    Shortcut {
        sequence: StandardKey.Quit
        context: Qt.ApplicationShortcut
        onActivated: Qt.quit()
    }
}
