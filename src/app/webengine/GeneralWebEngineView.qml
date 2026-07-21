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
import QtWebEngine
import QtWebChannel
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

WebEngineView {
    id: root
    objectName: JamiQmlUtils.webEngineNames.general

    property string onCompletedLoadHtml: ""
    property string onCompletedUrl: "qrc" + onCompletedLoadHtml

    backgroundColor: "transparent"

    settings.javascriptEnabled: true
    settings.javascriptCanOpenWindows: false
    settings.javascriptCanAccessClipboard: true
    settings.javascriptCanPaste: true
    settings.fullScreenSupportEnabled: true
    settings.allowRunningInsecureContent: true
    settings.localContentCanAccessRemoteUrls: true
    settings.localContentCanAccessFileUrls: true
    settings.errorPageEnabled: false
    settings.pluginsEnabled: false
    settings.screenCaptureEnabled: false
    settings.linksIncludedInFocusChain: false
    settings.localStorageEnabled: true

    // Provide WebChannel by registering jsBridgeObject.
    webChannel: WebChannel {
        id: webViewChannel
    }

    onContextMenuRequested: function (request) {
        var needContextMenu = request.selectedText.length || request.isContentEditable;
        if (!needContextMenu)
            request.accepted = true;
    }

    Component.onCompleted: {
        UtilsAdapter.ensureWebEngineProfileConfigured();
        // Load the local content once using the qrc URL as the base. Setting
        // 'url' separately would trigger a second, redundant navigation to the
        // same page, needlessly re-entering the WebEngine navigation machinery.
        root.loadHtml(UtilsAdapter.qStringFromFile(onCompletedLoadHtml), onCompletedUrl);
    }
}
