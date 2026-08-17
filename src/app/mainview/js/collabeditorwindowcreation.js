/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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

// Manages independent collaborative-editor windows, one per conversation
// document. Opening a document that already has a window simply raises it
// instead of creating a duplicate.

var component = null
// Map of conversation/document keys -> window object.
var windows = ({})

// The account is part of the key: two local accounts can be members of the same
// swarm, and would otherwise share a single window bound to whichever account
// opened it first.
function windowKey(accountId, conversationId, documentId) {
    return accountId + "::" + conversationId + "::" + documentId
}

function openEditor(appWindow, accountId, conversationId, documentId, documentName, peerName, documentAuthor, accountUri) {
    if (!accountId || !conversationId || !documentId) {
        console.log("Cannot open collaborative editor: missing account, conversation or document id")
        return
    }
    // Reuse an already-open window for this document.
    var key = windowKey(accountId, conversationId, documentId)
    var existing = windows[key]
    if (existing) {
        if (documentName && documentName.length > 0)
            existing.documentName = documentName
        if (peerName && peerName.length > 0)
            existing.peerName = peerName
        existing.show()
        existing.raise()
        existing.requestActivate()
        if (existing.focusEditor)
            existing.focusEditor()
        return
    }

    if (!component)
        component = Qt.createComponent("../components/CollabRichEditorWindow.qml",
            Component.PreferSynchronous)
    if (component.status === Component.Error) {
        console.log("CollabEditor load error:", component.errorString())
        return
    }
    if (component.status !== Component.Ready) {
        console.log("CollabEditor not ready, status:", component.status)
        return
    }

    var win = component.createObject(null, {
        "accountId": accountId,
        "conversationId": conversationId,
        "documentId": documentId,
        "documentName": documentName || "",
        "peerName": peerName || "",
        "documentAuthor": documentAuthor || "",
        "accountUri": accountUri || "",
        "transientParent": appWindow
    })
    if (win === null) {
        console.log("Error creating CollabEditor:", component.errorString())
        return
    }
    windows[key] = win

    // Center on the main window the first time.
    if (appWindow) {
        win.x = appWindow.x + (appWindow.width - win.width) / 2
        win.y = appWindow.y + (appWindow.height - win.height) / 2
    }
    win.closing.connect(function () {
        delete windows[key]
        win.destroy()
    })
    win.show()
    win.raise()
    win.requestActivate()
    if (win.focusEditor)
        win.focusEditor()
}
