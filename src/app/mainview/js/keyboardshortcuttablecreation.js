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

// Global select screen window component, object variable for creation.
var keyboardShortcutTableWindowComponent
var keyboardShortcutTableWindowObject
var mainWindow

function createKeyboardShortcutTableWindowObject(appWindow) {
    if (keyboardShortcutTableWindowObject)
        return
    keyboardShortcutTableWindowComponent = Qt.createComponent(
                "../components/KeyboardShortcutTable.qml")
    mainWindow = appWindow
    if (keyboardShortcutTableWindowComponent.status === Component.Ready)
        finishCreation()
    else if (keyboardShortcutTableWindowComponent.status === Component.Error)
        console.log("Error loading component:",
                    keyboardShortcutTableWindowComponent.errorString())
}

function finishCreation() {
    keyboardShortcutTableWindowObject = keyboardShortcutTableWindowComponent.createObject()
    if (keyboardShortcutTableWindowObject === null) {
        // Error Handling.
        console.log("Error creating select screen object")
    }

    // Signal connection.
    keyboardShortcutTableWindowObject.onClosing.connect(destroyKeyboardShortcutTableWindow)
}

function showKeyboardShortcutTableWindow() {
    keyboardShortcutTableWindowObject.show()
    var centerX = mainWindow.x + mainWindow.width / 2
    var centerY = mainWindow.y + mainWindow.height / 2

    keyboardShortcutTableWindowObject.width = 0.75 * appWindow.width
    keyboardShortcutTableWindowObject.height = 0.75 * appWindow.height
    keyboardShortcutTableWindowObject.x = centerX - keyboardShortcutTableWindowObject.width / 2
    keyboardShortcutTableWindowObject.y = centerY - keyboardShortcutTableWindowObject.height / 2
}

// Destroy and reset selectScreenWindowObject when window is closed.
function destroyKeyboardShortcutTableWindow() {
    if(!keyboardShortcutTableWindowObject)
        return
    keyboardShortcutTableWindowObject.destroy()
    keyboardShortcutTableWindowObject = false
}
