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
import QtWebEngine
import QtWebChannel
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

WebEngineView {
    id: root
    property string onCompletedLoadHtml: ""
    property string onCompletedUrl: "qrc" + onCompletedLoadHtml

    backgroundColor: "transparent"
    settings.allowRunningInsecureContent: true
    settings.errorPageEnabled: false
    settings.fullScreenSupportEnabled: true
    settings.javascriptCanAccessClipboard: true
    settings.javascriptCanOpenWindows: false
    settings.javascriptCanPaste: true
    settings.javascriptEnabled: true
    settings.linksIncludedInFocusChain: false
    settings.localContentCanAccessFileUrls: true
    settings.localContentCanAccessRemoteUrls: true
    settings.localStorageEnabled: true
    settings.pluginsEnabled: false
    settings.screenCaptureEnabled: false

    Component.onCompleted: {
        profile.cachePath = UtilsAdapter.getCachePath();
        profile.persistentStoragePath = UtilsAdapter.getCachePath();
        profile.persistentCookiesPolicy = WebEngineProfile.NoPersistentCookies;
        profile.httpCacheType = WebEngineProfile.NoCache;
        profile.httpUserAgent = JamiStrings.httpUserAgentName;
        root.loadHtml(UtilsAdapter.qStringFromFile(onCompletedLoadHtml), onCompletedLoadHtml);
        root.url = onCompletedUrl;
    }
    onContextMenuRequested: function (request) {
        var needContextMenu = request.selectedText.length || request.isContentEditable;
        if (!needContextMenu)
            request.accepted = true;
    }
    onNavigationRequested: function (request) {
        if (request.navigationType === WebEngineView.LinkClickedNavigation) {
            MessagesAdapter.openUrl(request.url);
            request.action = WebEngineView.IgnoreRequest;
        }
    }

    // Provide WebChannel by registering jsBridgeObject.
    webChannel: WebChannel {
        id: webViewChannel
    }
}
