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
 * @file This file implements `jamiclientinternal.d.ts`.
 */

// expose a global variable equivalent to a typescript namespace
var _JamiClientInternal;

// anonymous function that initializes the global variable
(function (_JamiClientInternal) {
    class _JamiClient extends EventTarget {
        #sharedObj; // private member
        eventName = "jami_client_message"; // internal client event name
        constructor() {
            super();

            console.log("JamiClient constructor Qt client");

            // create webchannel, link up shared object
            new QWebChannel(qt.webChannelTransport, (channel) => {
                console.log("QWebChannel initializing!");
                this.#sharedObj = channel.objects.sharedObj;

                // link up qt signal
                this.#sharedObj.jsMessage.connect((message, messageId) => {
                    console.log(`_JamiClientInternal.JamiClient sees a jsMessage event: ` +
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
                console.log("QWebChannel done initializing");
            });

            console.log("JamiClient constructor Qt client -- done");
        }

        sendMessage(message, messageId) {
            // call the function inside the qml object (which then calls the adapter function)
            this.#sharedObj.sendMessage(message, messageId);
        }
    }

    // expose single instance only
    _JamiClientInternal.JamiClient = new _JamiClient();

    console.log("done initializing _JamiClientInternal Qt client");
})(_JamiClientInternal || (_JamiClientInternal = {}));
