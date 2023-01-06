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

// This object should be implemented as a QML singleton, or be instantiated
// once in the main application window component. The top-level application window
// contains a loader[mainview, wizardview] and "rootView" MUST parent a single SplitView
// with 2 StackViews.
QtObject {
    id: root

    // A map of view names to file paths for QML files that define each view.
    required property variant resources

    // Maybe this state needs to be toggled because the SidePanel content is replaced.
    // This makes it so the state can't be inferred from loaded views in single pane mode.
    property bool inSettings: viewManager.hasView("SettingsView")

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
        if (activeStackView == null || activeStackView.depth === 0) {
            return "none"
        }
        return activeStackView.currentItem.objectName
    }

    readonly property var currentView: {
        return activeStackView ? activeStackView.currentItem : undefined
    }

    // Represents a width threshold for determining whether the application
    // is "singlePane" or not.
    readonly property real threshold: 480

    readonly property bool singlePane: {
        return (rootView && rootView.width > 0 && rootView.width < threshold)
    }

    signal initialized()

    // Create and present a dialog object.
    // Returns the object.
    function presentDialog(parent, path, props={}) {
        // Open the dialog once the object is created
        return viewManager.createView(path, parent, function(obj) {
            const doneCb = function() { viewManager.destroyView(path) }
            if (obj.closed !== undefined) {
                obj.closed.connect(doneCb)
            } else {
                if (obj.accepted !== undefined) { obj.accepted.connect(doneCb) }
                if (obj.rejected !== undefined) { obj.rejected.connect(doneCb) }
            }
            obj.open()
        }, props)
    }

    // Dismiss all views.
    function dismissAll() {
        for (var path in viewManager.views) {
            viewManager.destroyView(path)
        }
    }

    // A private object used to manage the lifecycle of views.
    property QtObject viewManager: QtObject {
        id: viewManager

        // A map of path strings to view objects.
        property variant views: ({})
        // A map of view names to path strings.
        property variant viewPaths: ({})
        // The number of views.
        property int nViews: 0

        function createView(path, parent=null, cb=null, props={}) {
            if (views[path] !== undefined) {
                // an instance of <path> already exists
                return views[path]
            }

            const component = Qt.createComponent(Qt.resolvedUrl(path))
            if (component.status === Component.Ready) {
                const obj = component.createObject(parent, props)
                if (obj === null) {
                    print("error creating object")
                    return null
                }
                views[path] = obj
                // Set the view name to the object name if it has one.
                const viewName = obj.objectName !== undefined ? obj.objectName : path
                viewPaths[viewName] = path
                nViews = Object.keys(views).length
                if (cb !== null) {
                    cb(obj)
                }
                return views[path]
            }
            print("error creating component", path)
            console.error(component.errorString())
            Qt.exit(1)
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
            // completion, so we queue the resulting mutation to our view
            // storage.
            Qt.callLater(function() {
                delete views[path]
                // Remove the view name from the viewPaths map.
                for (var viewName in viewPaths) {
                    if (viewPaths[viewName] === path) {
                        delete viewPaths[viewName]
                        break
                    }
                }
                nViews = Object.keys(views).length
            })
            return true
        }

        function hasView(viewName) {
            return nViews && viewPaths[viewName] !== undefined
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
    // specified StackView.
    function present(viewName, sv=activeStackView) {
        // If the view already exists in the StackView, the function will
        // attempt to navigate to its StackView position by dismissing elevated
        // views.
        if (sv.find(function(item) {
            return item.objectName === viewName;
        })) {
            const viewIndex = getStackIndex(viewName)
            if (viewIndex >= 0) {
                for (var i = (sv.depth - 1); i > viewIndex; i--) {
                    dismissObj(sv.get(i, StackView.DontLoad))
                }
                return true
            }
            return false
        }

        // If we are in single-pane mode and the view was previously forced into
        // sv2, we can move it back to the top of sv1.
        if (singlePane && sv === sv1) {
            // See if the item is at the top of sv2
            if (sv2.currentItem && sv2.currentItem.objectName === viewName) {
                // Move it to the top of sv1
                const view = sv2.pop(StackView.Immediate)
                sv1.push(view, StackView.Immediate)
                view.presented()
                return true
            }
        }

        const obj = viewManager.createView(resources[viewName], appWindow)
        if (!obj) {
            print("could not create view:", viewName)
            return false
        }
        if (obj === currentView) {
            print("view is current:", viewName)
            return false
        }

        // If we are in single-pane mode and the view should start hidden
        // (requiresIndex), we can push it into sv2.
        if (singlePane && sv === sv1 && obj.requiresIndex) {
            sv = sv2
        }

        const view = sv.push(obj, StackView.Immediate)
        if (!view) {
            return false
        }
        if (view.objectName === '') {
            view.objectName = viewName
        }
        view.presented()
        return true
    }

    // Dismiss by object.
    function dismissObj(obj, sv=activeStackView) {
        // First check if the view is in the StackView.
        if (obj.StackView.view !== sv) {
            print("view not in the stack:", obj)
            return
        }

        // It's possible that the view is not at the top of the stack, so we
        // need to check the depth of the view in the stack, and then pop and
        // destroy views until we get to the one we want to dismiss.
        const objDepth = obj.StackView.index
        if (objDepth < (sv.depth - 1)) {
            for (var i = (sv.depth - 1); i > objDepth; i--) {
                dismissObj(sv.get(i, StackView.DontLoad))
            }
        }

        // Now we can dismiss the view at the top of the stack.
        const depth = sv.depth
        if (obj === sv.get(depth - 1, StackView.DontLoad)) {
            var view = sv.pop(StackView.Immediate)
            if (!view) {
                print("could not pop view:", obj.objectName)
                return
            }
            // If the view is managed, we can destroy it, otherwise, we leave
            //  it in the view manager, and it will be destroyed when the view
            // manager is destroyed, or ready to be reused.
            if (view.managed) {
                var objectName = view ? view.objectName : obj.objectName
                if (!viewManager.destroyView(resources[objectName])) {
                    print("could not destroy view:", objectName)
                }
            } else {
                view.dismissed()
            }
        }
    }

    // Dismiss by view name.
    function dismiss(viewName) {
        const depth = activeStackView.depth
        for (var i = (depth - 1); i >= 0; i--) {
            const view = activeStackView.get(i, StackView.DontLoad)
            if (view.objectName === viewName) {
                dismissObj(view)
                return
            }
        }

        // Check if the view is on the top of sv2 (if in single-pane mode),
        // and dismiss it in that case.
        if (singlePane && sv2.currentItem && sv2.currentItem.objectName === viewName) {
            dismissObj(sv2.currentItem, sv2)
        }
    }

    // Move items from one stack to another. We avoid the recursive technique to
    // avoid  visibility change events.
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

    // Effectively hide the current view by moving it to the other StackView.
    // This function only works when in single-pane mode.
    function hideCurrentView() {
        if (singlePane) {
            move(sv1, sv2)
        }
    }

    onSinglePaneChanged: {
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
