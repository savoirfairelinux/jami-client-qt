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

// Manages independent collaborative-editor windows, one per document. Opening a
// document that already has a window simply raises it instead of creating a
// duplicate. A document's "kind" ("rich" or "text") selects the editor flavour:
// a WYSIWYG rich-text window or a plain-text window.

var components = ({})
// Map of documentId -> window object.
var windows = ({})

function sourceForKind(kind) {
    return kind === "rich" ? "../components/CollabRichEditorWindow.qml"
                           : "../components/CollabEditorWindow.qml"
}

function openEditor(appWindow, conversationId, documentId, documentName, peerName, kind) {
    kind = (kind === "rich") ? "rich" : "text"
    // Reuse an already-open window for this document.
    var existing = windows[documentId]
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

    var source = sourceForKind(kind)
    if (!components[kind])
        components[kind] = Qt.createComponent(source, Component.PreferSynchronous)
    var component = components[kind]
    if (component.status === Component.Error) {
        console.log("CollabEditor load error:", component.errorString())
        return
    }
    if (component.status !== Component.Ready) {
        console.log("CollabEditor not ready, status:", component.status)
        return
    }

    var win = component.createObject(null, {
        "conversationId": conversationId,
        "documentId": documentId,
        "documentName": documentName || "",
        "peerName": peerName || "",
        "transientParent": appWindow
    })
    if (win === null) {
        console.log("Error creating CollabEditor:", component.errorString())
        return
    }
    windows[documentId] = win

    // Center on the main window the first time.
    if (appWindow) {
        win.x = appWindow.x + (appWindow.width - win.width) / 2
        win.y = appWindow.y + (appWindow.height - win.height) / 2
    }
    win.closing.connect(function () {
        delete windows[documentId]
        win.destroy()
    })
    win.show()
    win.raise()
    win.requestActivate()
    if (win.focusEditor)
        win.focusEditor()
}
