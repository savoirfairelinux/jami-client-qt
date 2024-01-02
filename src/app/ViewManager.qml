/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

    // Create a view from a path only if it doesn't already exist. This is used
    // by the view coordinator to create views that are not self-destructing
    // (main views) and only exist once per instance of the app.
    function createView(path, parent = null, cb = null, props = {}) {
        const component = Qt.createComponent(Qt.resolvedUrl(path));
        return createViewFromComponent(component, path, parent, cb, props);
    }

    // Create a new view. Useful when we want to create multiple views that are
    // self-destructing (dialogs).
    function createUniqueView(path, parent = null, cb = null, props = {}) {
        const component = Qt.createComponent(Qt.resolvedUrl(path));
        return createViewFromComponent(component, getViewName(path), parent, cb,
                                       props);
    }

    // Create a new view from a component. If a view with the same path already
    // exists, it is returned instead.
    function createViewFromComponent(component, viewName, parent = null,
                                     cb = null, props = {}) {
        if (views.hasOwnProperty(viewName)) {
            // an instance of the view already exists
            if (cb !== null) {
                cb(views[viewName])
            }
            return views[viewName]
        }
        if (component.status === Component.Ready) {
            const obj = component.createObject(parent, props)
            if (obj === null) {
                console.error("error creating object")
                return null
            }
            views[viewName] = obj
            // Set the view name to the object name if it has one.
            const friendlyName = obj.objectName.toString() !== '' ?
                obj.objectName :
                viewName.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, "")
            viewPaths[friendlyName] = viewName
            if (cb !== null) {
                cb(obj)
            }
            return views[viewName]
        }
        console.error("error creating component", component.url)
        console.error(component.errorString())
        Qt.exit(1)
        return null
    }

    // Finds a unique view name for a given path by appending a number to the
    // base name. For example, if a view named "MyView" already exists, the next
    // view will be named "MyView_1".
    function getViewName(path) {
        const baseName = path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, "")
        let viewName = baseName
        let suffix = 1
        while (views.hasOwnProperty(viewName)) {
            viewName = `${baseName}_${suffix}`
            suffix++
        }
        return viewName
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
