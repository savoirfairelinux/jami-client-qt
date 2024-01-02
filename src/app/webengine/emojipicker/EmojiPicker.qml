/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects
import QtWebEngine
import QtWebChannel
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import "../"

Popup {
    id: root

    required property ListView listView
    signal emojiIsPicked(string content)

    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    onClosed: if (messageBar) messageBar.textAreaObj.forceActiveFocus()

    // Close the picker when attached to a listView that receives height/scroll
    // property changes.
    property real listViewHeight: listView ? listView.height : 0
    onListViewHeightChanged: close()
    property bool isScrolling: listView ? listView.verticalScrollBar.active : false
    onIsScrollingChanged: close()

    function openEmojiPicker() {
        root.open();
        emojiPickerWebView.runJavaScript("prepare_to_show(" + JamiTheme.darkTheme + ");");
        emojiPickerWebView.forceActiveFocus();
    }

    function closeEmojiPicker() {
        emojiPickerWebView.runJavaScript("prepare_to_hide();");
        close();
    }
    padding: 0
    visible: false
    background.visible: false

    QtObject {
        id: jsBridgeObject

        // ID, under which this object will be known at chatview.js side.
        WebChannel.id: "jsbridge"

        // Functions that are exposed, return code can be derived from js side
        // by setting callback function.
        function emojiIsPicked(arg) {
            root.emojiIsPicked(arg);
            closeEmojiPicker();
        }

        // For emojiPicker to properly close
        function emojiPickerHideFinished() {
            root.visible = false;
        }
    }

    GeneralWebEngineView {
        id: emojiPickerWebView

        width: JamiTheme.emojiPickerWidth
        height: JamiTheme.emojiPickerHeight

        webChannel.registeredObjects: [jsBridgeObject]

        onCompletedLoadHtml: ":/webengine/emojipicker/emojiPickerLoader.html"

        onLoadingChanged: function (loadingInfo) {
            if (loadingInfo.status === WebEngineView.LoadSucceededStatus) {
                emojiPickerWebView.runJavaScript(UtilsAdapter.qStringFromFile(":/webengine/qwebchannel.js"));
                emojiPickerWebView.runJavaScript(UtilsAdapter.qStringFromFile(":/webengine/emojipicker/emoji.js"));
                emojiPickerWebView.runJavaScript(UtilsAdapter.qStringFromFile(":/webengine/emojipicker/emojiPickerLoader.js"));
                emojiPickerWebView.runJavaScript("init_emoji_picker(" + JamiTheme.darkTheme + ");");
                root.openEmojiPicker();
            }
        }
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
        // Color animation for overlay when pop up is shown.
        ColorAnimation on color  {
            to: JamiTheme.popupOverlayColor
            duration: 500
        }
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 0.0
            to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }

    exit: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 1.0
            to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
