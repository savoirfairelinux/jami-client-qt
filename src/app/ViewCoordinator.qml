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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "commoncomponents"

QtObject {
    id: root

    required property QtObject viewManager

    signal initialized

    function requestAppWindowWizardView() {
        viewCoordinator.present("WizardView");
    }

    // A map of view names to file paths for QML files that define each view.
    property variant resources: {
        "SidePanel": "mainview/components/SidePanel.qml",
        "WelcomePage": "mainview/components/WelcomePage.qml",
        "ConversationView": "mainview/ConversationView.qml",
        "NewSwarmPage": "mainview/components/NewSwarmPage.qml",
        "WizardView": "wizardview/WizardView.qml",
        "AccountMigrationView": "AccountMigrationView.qml",
        "SettingsView": "settingsview/SettingsView.qml",
        "SettingsSidePanel": "settingsview/SettingsSidePanel.qml"
    }

    // The `main` view of the application window.
    property StackView rootView

    property var currentViewName: rootView && rootView.currentItem && rootView.currentItem.objectName || null

    function init(mainStackView) {
        rootView = Qt.createQmlObject(`import QtQuick; import QtQuick.Controls
                                      StackView { anchors.fill: parent }`, mainStackView);
        initialized();
    }

    function deinit() {
        viewManager.destroyAllViews();
        if (rootView)
            rootView.destroy();
    }

    // Finds a view and gets its index within the StackView it's in.
    function getStackIndex(viewName) {
        for (const [key, value] of Object.entries(viewManager.views)) {
            if (value.objectName === viewName) {
                return value.StackView.index;
            }
        }
        return -1;
    }

    // Create, present, and return a dialog object.
    function presentDialog(parent, path, props = {}) {
        // Open the dialog once the object is created
        return viewManager.createUniqueView(path, parent, function (obj) {
                const doneCb = function () {
                    viewManager.destroyView(path);
                };
                if (obj.closed !== undefined) {
                    obj.closed.connect(doneCb);
                } else {
                    if (obj.accepted !== undefined) {
                        obj.accepted.connect(doneCb);
                    }
                    if (obj.rejected !== undefined) {
                        obj.rejected.connect(doneCb);
                    }
                }
                obj.open();
            }, props);
    }

    // Present a view by name.
    function present(viewName, props) {
        const path = resources[viewName];

        // Check if the current view should inhibit the presentation of this view.
        if (rootView.currentItem && rootView.currentItem.inhibits.includes(viewName)) {
            print("inhibiting view:", viewName);
            return;
        }

        // If the view already exists in the StackView, the function will attempt
        // to navigate to its StackView position by dismissing elevated views.
        if (rootView.find(function (item) {
                return item.objectName === viewName;
            }, StackView.DontLoad)) {
            const viewIndex = getStackIndex(viewName);
            for (var i = (rootView.depth - 1); i > viewIndex; i--) {
                dismissObj(rootView.get(i, StackView.DontLoad));
            }
            return;
        }
        if (!viewManager.createView(path, rootView, function (view) {
                // push the view onto the stack if it's not already there
                if (rootView.currentItem !== view) {
                    rootView.push(view, StackView.Immediate);
                }
                if (!view.managed)
                    view.presented();
            }, props)) {
            print("could not create view:", viewName);
        }
    }

    // Dismiss by object.
    function dismissObj(obj) {
        // Check if it makes sense to remove this view at all.
        if (obj.StackView.view !== rootView || !viewManager.viewCount()) {
            return;
        }

        // If we are dismissing a view that is not at the top of the stack,
        // we need to store each of the views on top into a temporary stack
        // and then restore them after the view is dismissed.
        const viewIndex = obj.StackView.index;
        var tempStack = [];
        for (var i = (rootView.depth - 1); i > viewIndex; i--) {
            var item = rootView.pop(StackView.Immediate);
            tempStack.push(item);
        }
        // And we define a function to restore and resolve the views.
        var resolveStack = () => {
            for (var i = 0; i < tempStack.length; i++) {
                rootView.push(tempStack[i], StackView.Immediate);
            }
            if (rootView.depth > 0)
                rootView.currentItem.presented();
        };

        // Now we can dismiss the view at the top of the stack.
        const depth = rootView.depth;
        if (obj === rootView.get(depth - 1, StackView.DontLoad)) {
            var view;
            if (rootView.depth === 1) {
                view = rootView.currentItem;
                rootView.clear();
            } else
                view = rootView.pop(StackView.Immediate);
            if (!view) {
                print("could not pop view:", obj.objectName);
                resolveStack();
                return;
            }

            // If the view is managed, we can destroy it, otherwise, it can
            // be reused and destroyed by it's parent.
            if (view.managed) {
                var objectName = view ? view.objectName : obj.objectName;
                if (!viewManager.destroyView(resources[objectName])) {
                    print("could not destroy view:", objectName);
                }
            } else
                view.dismissed();
        }
        resolveStack();
    }

    // Dismiss a view by name or the top view if unspecified.
    function dismiss(viewName = undefined) {
        if (!rootView || rootView.depth === 0)
            return;
        if (viewName !== undefined) {
            const depth = rootView.depth;
            for (var i = (depth - 1); i >= 0; i--) {
                const view = rootView.get(i, StackView.DontLoad);
                if (view.objectName === viewName) {
                    dismissObj(view);
                    return;
                }
            }
            return;
        } else {
            dismissObj(rootView.currentItem);
        }
    }

    function getView(viewName) {
        return viewManager.getView(viewName);
    }

    // Load a view without presenting it.
    function preload(viewName) {
        if (!viewManager.createView(resources[viewName], null)) {
            console.log("Failed to load view: " + viewName);
        }
    }
}
