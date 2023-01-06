/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

// This object should be implemented as a QML singleton, and be instantiated
// once in the main application window component. The view coordinator has an
// understanding of the view hierarchy and overall state of the application views,
// and is specifically designed the structure of the jami-qt desktop client.
// The top-level application window contains a loader[mainview, wizardview]
// The "rootView" MUST parent a single SplitView.
QtObject {
    id: root

    // A map of view names to file paths for QML files that define each view.
    required property variant resources

    // An array of views.
    property variant views: []

    // The number of views.
    property int nViews: 0

    // This should point to the main application view that
    // contains a split view.
    property Item rootView: null

    // Must be the child of `rootView`.
    property Item splitView: null

    // StackView objects, which are children of `splitView`.
    property StackView sv1: null
    property StackView sv2: null

    // The StackView object that is currently active, determined by the value
    // of singlePane.
    readonly property StackView activeStackView: singlePane ? sv1 : sv2

    readonly property string currentViewName: {
        if (activeStackView == null || activeStackView.empty) {
            return "none"
        }
        return activeStackView.get(0, StackView.DontLoad).objectName
    }

    // Represents a width threshold for determining whether the application
    // is "singlePane" or not.
    readonly property real threshold: 480

    readonly property bool singlePane: {
        return (rootView && rootView.width > 0 && rootView.width < threshold)
    }

    signal initialized()

    // Present a dialog.
    function presentDialog(parent, path) {
        // Open the dialog once the object is created
        viewManager.createView(path, parent, function(obj) {
            obj.closed.connect(function() {
                viewManager.destroyView(path)
            })
            obj.open()
        })
    }

    // A private object used to manage the lifecycle of views.
    property QtObject viewManager: QtObject {
        id: viewManager

        property variant views: ({})
        property int nViews: 0

        function createView(path, parent=null, cb=null) {
            if (views[path] !== undefined) {
                // an instance of <path> already exists
                return views[path]
            }

            const component = Qt.createComponent(Qt.resolvedUrl(path))
            if (component.status === Component.Ready) {
                const obj = component.createObject(parent, {})
                if (obj === null) {
                    print("error creating object")
                    return null
                }
                views[path] = obj
                nViews = Object.keys(views).length
                if (cb !== null) {
                    cb(obj)
                }
                return views[path]
            }
            print("error creating component", path)
            return null
        }

        function destroyView(path) {
            if (views[path] === undefined) {
                print(path, "instance does not exist", Object.keys(views))
                return false
            }
            views[path].destroy()
            views[path] = undefined
            // QObject::destroy is queued, and we can't connect to its
            // completion, so we queue the resulting mutation on our view
            // storage.
            Qt.callLater(function() {
                delete views[path]
                nViews = Object.keys(views).length
            })
            return true
        }
    }

    // This function sets the rootView, splitView, sv1, and sv2 properties
    // of the root object based on the given obj parameter.
    // Finally, the function emits the initialized signal, which is a
    // good time to start loading views with the `present` function.
    function setRootView(obj) {
        rootView = obj
        splitView = rootView.splitView

        sv1 = rootView.sv1
        sv1.parent = Qt.binding(function() {
            return singlePane ? rootView : splitView
        })
        sv1.anchors.fill = Qt.binding(function() {
            return singlePane ? rootView : undefined
        })

        sv2 = rootView.sv2

        initialized()
    }

    // This function presents the view with the given viewName in the sv1
    // StackView. This is called to set the control panel item, that has
    // special behaviour.
    function setControlPanelView(viewName) {
        return present(viewName, sv1, true)
    }

    // Prints some info about the current state of the loaded views.
    function printStackInfo() {
        for (const [key, value] of Object.entries(viewManager.views)) {
            if (value !== undefined) {
                print(key, value, value.StackView.view, value.StackView.index)
            }
        }
    }

    // Finds a view and gets its index within the StackView it's in.
    function getStackIndex(viewName) {
        for (const [key, value] of Object.entries(viewManager.views)) {
            if (value.objectName === viewName) {
                return value.StackView.index
            }
        }
        return -1
    }

    // This function presents the view with the given viewName in the
    // specified sv StackView. If force is true, the view will be created
    // even if it already exists. If the view already exists in the StackView
    // and force is false, the function will return true without creating a
    // new instance of the view. If the rootView has not been initialized,
    // the function will print an error message and return false.
    function present(viewName, sv=activeStackView, force=false) {
        if (!rootView) {
            print("Root view not initialized")
            return false
        }

        // If the view already exist in the StackView, the function will
        // attempt to navigate to its StackView position by dismissing elevated
        // views.
        if (sv.find(function(item) {
            return item.objectName === viewName;
        })) {
            const viewIndex = getStackIndex(viewName)
            if (viewIndex >= 0) {
                for (var i = (sv.depth - 1); i > viewIndex; i--) {
                    dismiss(sv.get(i, StackView.DontLoad))
                }
                return true
            }
            return false
        }


        const obj = viewManager.createView(resources[viewName])
        if (obj) {
            if (obj.rootViewName === "" &&
                    sv === sv1 &&
                    !force) {
                return true
            }

            // If the view has a rootViewName property set, the function will present
            // the view specified by the rootViewName property before presenting
            // the requested view.
            if (obj.rootViewName !== undefined &&
                    obj.rootViewName !== "") {
                present(obj.rootViewName, sv)
            }

            const view = sv.push(obj, StackView.Immediate)
            view.objectName = viewName
            return true
        } else {
            print("could not create view:", viewName)
        }

        return false
    }

    function dismiss(obj) {
        if (!rootView) {
            print("root view not initialized")
            return
        }

        const depth = activeStackView.depth
        if (obj === activeStackView.get(depth - 1, StackView.DontLoad)) {
            var view = activeStackView.pop(StackView.Immediate)
            if (!viewManager.destroyView(resources[view.objectName])) {
                print("could not destroy view:", view.objectName)
            }
        }
    }

    function move(from, to, depth=1) {
        var tempStack = []

        while (from.depth > depth) {
            var item = from.pop(StackView.Immediate)
            tempStack.push(item)
        }

        while (tempStack.length) {
            to.push(tempStack.pop(), StackView.Immediate)
        }
    }

    onSinglePaneChanged: {
        // Optimization: don't use a Qt.binding to singlePane
        // for sv2 `visible` here.
        // Hiding sv2 before moving items from, and after moving
        // items to, reduces stack item visibility change events.
        if (singlePane) {
            sv2.visible = false
            move(sv2, sv1)
        } else {
            move(sv1, sv2)
            sv2.visible = true
        }
    }
}
