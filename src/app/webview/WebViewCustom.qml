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

WebEngineView {
    id: webEngineView
    anchors.fill: parent
    // url: "https://www.savoirfairelinux.com"

    webChannel: channel

    property string pluginId
    property string accountId
    property string webViewId
    property string attachReason // TODO: rename? also, create enum?

    // sets the url to a given absolute path,
    // filepath should be an html file on the local filesystem
    function openHtml(filepath) {
        let path = "file:///" + filepath;
        console.log("web view trying to open html at: " + path)
        webEngineView.url = path;
    }

    // this is shared with the webview javascript engine
    QtObject {
        id: sharedObj
        WebChannel.id: "sharedObj"

        // signal to tell the webview javascript engine to process new messages
        signal jsMessage(string message, string messageId)

        // called by the webview javascript to send a message down to the plugin
        function sendMessage(payload, messageId) {
            console.log("qml sending webview message");
            WebViewAdapter.sendWebViewMessage(pluginId, webViewId, messageId, payload);
        }
    }

    WebChannel {
        id: channel
        registeredObjects: [sharedObj]
    }

    Component.onCompleted: function() {
        console.log("webviewcustom created for plugin: " + pluginId);
        webEngineView.runJavaScript("console.log('web engine js ready');");

        // load the client-side script that exposes interface to plugin JS
        var helperScript = {
            injectionPoint: WebEngineScript.DocumentCreation,
            sourceUrl: "qrc:///src/app/webview/jamiclientinternal_qt.js",
            worldId: WebEngineScript.MainWorld,
        };

        // allows webview to access webchannel api
        var webChannelScript = {
            injectionPoint: WebEngineScript.DocumentCreation,
            sourceUrl: 'qrc:///qtwebchannel/qwebchannel.js', // automatically bundled in as a qrc resource
            worldId: WebEngineScript.MainWorld,
        };

        webEngineView.userScripts.collection = [ webChannelScript, helperScript ];

        // send an attach event, it returns the html file that we should open (absolute path)
        var path = WebViewAdapter.sendWebViewAttach(pluginId, accountId, webViewId, attachReason);

        openHtml(path); // load our webpage
    }

    Component.onDestruction: function() {
        WebViewAdapter.sendWebViewDetach(pluginId, accountId, webViewId);
        console.log("web view being destroyed!");
    }

    Connections {
        target: WebViewAdapter

        // this handles whenever the plugin sends a message, we have to deliver it to the webview JS
        function onWebViewMessageReceived(pluginId, webViewId, messageId, payload) {

            // make sure we are only handling messages sent to us
            if (webViewId != webEngineView.webViewId) {
                return;
            }

            console.log(
                `WebView #${webEngineView.webViewId} received message from plugin:` +
                `plug: '${pluginId}', webViewId: '${webViewId}', messageId: '${messageId}', payload: '${payload.replace("\n", "\\n")}'`
            );

            // emit signal, make sure both are strings
            sharedObj.jsMessage(payload, messageId);
        }
    }
}