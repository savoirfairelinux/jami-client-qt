import QtQuick
import QtQuick.Controls

import net.jami.Adapters 1.1

import "mainview/components"

QtObject {
    id: root

    required property Item appContainer

    readonly property bool isFullScreen: visibility === Window.FullScreen
    readonly property bool isHidden: visibility === Window.Hidden ||
                                     visibility === Window.Minimized
    property bool isWindowFullScreen: false
    property bool isCallFullscreen: false
    property int windowedVisibility
    property variant fullScreenItems: []
    signal fullScreenItemsLengthChanged
    onFullScreenItemsLengthChanged: {
        isCallFullscreen = fullScreenItems
        .filter(o => o.item instanceof OngoingCallPage)
        .length
    }

    property var data: Connections {
        target: CallAdapter

        function onHasCallChanged() {
            if (!CallAdapter.hasCall && isCallFullscreen) {
                popFullScreenItem()
            }
        }
    }

    function restoreApp() {
        if (isHidden) {
            showNormal()
        }
    }

    function pushFullScreenItem(item, originalParent, pushCb, popCb) {
        if (item === null || item === undefined
                || fullScreenItems.length !== 0) {
            return
        }

        // Make sure our window is in fullscreen mode.
        requestWindowModeChange(true)

        // Add the item to our list and reparent it to appContainer.
        fullScreenItems.push({
                                 "item": item,
                                 "originalParent": originalParent,
                                 "popCb": popCb
                             })
        item.parent = appContainer
        if (pushCb) {
            pushCb()
        }

        // Reevaluate isCallFullscreen.
        fullScreenItemsLengthChanged()
    }

    function popFullScreenItem() {
        if (fullScreenItems.length === 0) {
            return
        }

        // Remove the item and reparent it to its original parent.
        var removedItem = fullScreenItems.pop()
        if (removedItem !== undefined) {
            removedItem.item.parent = removedItem.originalParent
            if (removedItem.popCb) {
                removedItem.popCb()
            }

            // Reevaluate isCallFullscreen.
            fullScreenItemsLengthChanged()
        }

        // Only leave fullscreen mode if our window isn't in fullscreen
        // mode already.
        if (fullScreenItems.length === 0 && !isWindowFullScreen) {
            setWindowed()
        }
    }

    function setFullScreen() {
        if (!isFullScreen) {
            // Save the previous visibility state.
            windowedVisibility = visibility
            showFullScreen()
        }
    }

    function setWindowed() {
        // Recall the visibility state.
        visibility = windowedVisibility
        isWindowFullScreen = false
    }

    function requestWindowModeChange(fullScreen) {
        if (fullScreen) {
            setFullScreen()
        } else {
            // Remove any full screen components.
            popFullScreenItem()
            if (!isWindowFullScreen) {
                setWindowed()
            }
        }
    }

    function cancelFullScreenMode() {
        if (isWindowFullScreen) {
            if (fullScreenItems.length === 0) {
                toggleWindowFullScreen()
            } else {
                popFullScreenItem()
            }
            return
        }
        requestWindowModeChange(false)
    }

    function toggleWindowFullScreen() {
        if (fullScreenItems.length !== 0) {
            popFullScreenItem()
            return
        }
        isWindowFullScreen = !isWindowFullScreen
        requestWindowModeChange(isWindowFullScreen)
    }
}
