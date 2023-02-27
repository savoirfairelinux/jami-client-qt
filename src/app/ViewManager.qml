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

QtObject {
    id: viewManager

    // A map of path strings to view objects.
    property variant views: ({})
    // A map of view names to path strings.
    property variant viewPaths: ({})
    // The number of views.
    property int nViews: 0

    // Destroy all views.
    function destroyAllViews() {
        for (var path in views) {
            destroyView(path)
        }
    }

    function createView(path, parent=null, cb=null, props={}) {
        if (views[path] !== undefined) {
            // an instance of <path> already exists
            if (cb !== null) {
                cb(views[path])
            }
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
            const viewName = obj.objectName.toString() !== '' ?
                        obj.objectName :
                        path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, "")
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
        // QObject::destroy is queued, and we can't connect to its completion,
        // so we queue the resulting mutation to our view storage.
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

    function getView(viewName) {
        if (hasView(viewName)) {
            return views[viewPaths[viewName]]
        }
        return null
    }
}
