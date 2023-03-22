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

    // The number of views loaded (`views` is only resized).
    function viewCount() {
        return Object.keys(views).length
    }

    // Destroy all views.
    function destroyAllViews() {
        for (var path in views) {
            destroyView(path)
        }
    }

    function createView(path, parent=null, cb=null, props={}) {
        if (views.hasOwnProperty(path)) {
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
        // The view may already have been destroyed.
        if (!views.hasOwnProperty(path)) {
            return false
        }
        views[path].destroy()
        delete views[path]
        // Remove the view name from the viewPaths map.
        for (var viewName in viewPaths) {
            if (viewPaths[viewName] === path) {
                delete viewPaths[viewName]
                break
            }
        }
        return true
    }

    function getView(viewName) {
        return views[viewPaths[viewName]] || null
    }
}
