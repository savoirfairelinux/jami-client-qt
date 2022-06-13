/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Tobias Hildebrandt <tobias.hildebrandt@savoirfairelinux.com>
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

import QtWebEngine 1.10
import QtWebChannel 1.3

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

// TODO: add styling
WebEngineView {
    id: root
    anchors.fill: parent

    webChannel: channel

    property string pluginId // actually a datapath
    property string accountId
    property string webViewId
    property string attachReason // TODO: rename? also, create enum?

    // sets the url to a given html file within the datapath
    // filepath should be a relative path to an html file in the datapath
    function openHtml(filepath) {
        const path = "file:///" + pluginId + "/" + filepath;
        console.debug("web view trying to open html at: " + path)
        root.url = path;
    }

    // this is shared with the webview javascript engine
    QtObject {
        id: sharedObj
        WebChannel.id: "sharedObj"

        // signal to tell the webview javascript engine to process new messages
        signal jsMessage(string message, string messageId)

        // called by the webview javascript to send a message down to the plugin
        function sendMessage(payload, messageId) {
            console.error("qml sending webview message");
            WebViewAdapter.sendWebViewMessage(pluginId, webViewId, messageId, payload);
        }
    }

    WebChannel {
        id: channel
        registeredObjects: [sharedObj]
    }

    Component.onCompleted: function() {
        console.debug("webviewcustom created for plugin: " + pluginId);
        root.runJavaScript("console.debug('web engine js ready');");

        // load the client-side script that exposes interface to plugin JS
        const helperScript = {
            injectionPoint: WebEngineScript.DocumentCreation,
            sourceUrl: "qrc:///webview/jamiclientinternal.js",
            worldId: WebEngineScript.MainWorld,
        };

        // allows webview to access webchannel api
        const webChannelScript = {
            injectionPoint: WebEngineScript.DocumentCreation,
            sourceUrl: 'qrc:///qtwebchannel/qwebchannel.js', // automatically bundled in as a qrc resource
            worldId: WebEngineScript.MainWorld,
        };

        root.userScripts.collection = [ webChannelScript, helperScript ];

        // send an attach event, it returns the html file that we should open (relative path inside of datapath)
        const path = WebViewAdapter.sendWebViewAttach(pluginId, accountId, webViewId, attachReason);

        openHtml(path); // load our webpage
    }

    Component.onDestruction: function() {
        WebViewAdapter.sendWebViewDetach(pluginId, webViewId);
        console.debug("web view being destroyed!");
    }

    Connections {
        target: WebViewAdapter

        // this handles whenever the plugin sends a message, we have to deliver it to the webview JS
        function onWebViewMessageReceived(pluginId, webViewId, messageId, payload) {
            console.error(
                `WebView #${root.webViewId} sees message from plugin:` +
                `pluginId: '${pluginId}', webViewId: '${webViewId}', messageId: '${messageId}', payload: '${payload.replace("\n", "\\n")}'`
            );

            // make sure we are only handling messages sent to us
            if (pluginId != root.pluginId || webViewId != root.webViewId) {
                return
            }

            // emit signal on shared object
            sharedObj.jsMessage(payload, messageId);
        }
    }
}
