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
"use strict";

/**
 * @file This file implements `jamiclientinternal.d.ts` from `jami-webview-plugin-utils`
 */

// expose a global variable equivalent to a typescript namespace
var _JamiClientInternal;

// run an anonymous function that adds members to the global variable
(function (_JamiClientInternal) {
    // class not exposed
    class _JamiClient extends EventTarget {
        #sharedObj; // private member
        eventName = "jami_client_message"; // internal client event name
        constructor() {
            super();

            console.debug("JamiClient constructor Qt client");

            // create webchannel, link up shared object
            new QWebChannel(qt.webChannelTransport, (channel) => {
                console.debug("QWebChannel initializing!");
                this.#sharedObj = channel.objects.sharedObj;

                // link up the qt signal to a JS event
                this.#sharedObj.jsMessage.connect((message, messageId) => {
                    console.debug(`_JamiClientInternal.JamiClient sees a jsMessage event: ` +
                        `message: '${message}':${typeof message}, messageId: '${messageId}':${typeof messageId}`);

                    // create our internal event
                    const event = new CustomEvent(this.eventName, {
                        detail: {
                            message: message,
                            messageId: messageId,
                        },
                    });

                    // send it on self
                    this.dispatchEvent(event);
                });
                console.debug("QWebChannel done initializing");
            });

            console.debug("_JamiClientInternal.JamiClient constructor Qt client -- done");
        }

        sendMessage(message, messageId) {
            // call the function inside the qml object (which then calls the adapter function)
            this.#sharedObj.sendMessage(message, messageId);
        }

        requestAccountName() {
            console.error("_JamiClientInternal.JamiClient received request for account name");
            // call the function inside the qml object (which then calls the adapter function)
            return this.#sharedObj.requestAccountName();
        }
    }

    // expose single instance only
    _JamiClientInternal.JamiClient = new _JamiClient();

    console.debug("done initializing _JamiClientInternal Qt client");
})(_JamiClientInternal ? _JamiClientInternal : _JamiClientInternal = {});
