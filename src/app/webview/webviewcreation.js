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

var webViewComponent
var webViewObject

/**
 * @brief the QML component from which webview objects are created
 */

/**
 * @brief Create a new custom WebView
 * @param parent the parent object for this webview
 * @param pluginId the pluginId associated with this webview (should not include '/data' at the end)
 * @param accountId the accountId associated with this webview
 * @param attachReason the reason why this web view was opened (whenever it finally does get opened)
 * @returns the newly-created web view object
 */

// TODO: (maybe) accept a signal to hook up to onLoadingChanged with
//       WebEngineView.LoadSucceededStatus to allow the parent to know when the webview is ready
function createWebView(parent, pluginId, accountId, attachReason) {
    webViewComponent = Qt.createComponent("./WebViewCustom.qml");
    if (webViewComponent.status == Component.Ready) {
        // create the object
        webViewObject = webViewComponent.createObject(
            parent, // parent object
            //  initial properties
            {
                attachReason: attachReason, // TODO: create enum?
                pluginId: pluginId + "/data", // actually a datapath
                accountId: accountId, // not valid for global preferences
                webViewId: WebViewAdapter.getNextWebViewId()
            }
        );

        if (!webViewObject) {
            console.error("Error creating WebView object!");
        } else {
            console.debug("webview object created");
        }
    } else if (webViewComponent.status == Component.Error) {
        console.error("error loading webview component: ", webViewComponent.errorString());
    }

    return webViewObject;
}
