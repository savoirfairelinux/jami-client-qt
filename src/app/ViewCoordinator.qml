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

import net.jami.Constants 1.1
import net.jami.Models 1.1

// This object should be implemented as a QML singleton, or be instantiated
// once in the main application window component. The top-level application window
// contains a loader[mainview, wizardview] and "rootView" MUST parent a horizontal
// SplitView with a StackView in each pane.
QtObject {
    id: root

    required property QtObject viewManager

    signal initialized
    signal requestAppWindowWizardView

    // A map of view names to file paths for QML files that define each view.
    property variant resources: {
        "WelcomePage": "mainview/components/WelcomePage.qml",
        "SidePanel": "mainview/components/SidePanel.qml",
        "ConversationView": "mainview/ConversationView.qml",
        "NewSwarmPage": "mainview/components/NewSwarmPage.qml",
        "WizardView": "wizardview/WizardView.qml",
        "SettingsView": "settingsview/SettingsView.qml",
    }

    // Maybe this state needs to be toggled because the SidePanel content is replaced.
    // This makes it so the state can't be inferred from loaded views in single pane mode.
    property bool inSettings: viewManager.hasView("SettingsView")
    property bool inWizard: viewManager.hasView("WizardView")
    property bool inNewSwarm: viewManager.hasView("NewSwarmPage")
    property bool inhibitConversationView: inSettings || inWizard || inNewSwarm

    // The `main` view of the application window.
    property StackView rootView

    function init(appWindow) {
        rootView = Qt.createQmlObject(`
                                      import QtQuick; import QtQuick.Controls
                                      StackView { anchors.fill: parent }
                                      `,
                                      appWindow
                                      )
        initialized()
    }

    function deinit() {
        rootView.destroy()
        viewManager.destroyAllViews()
    }

    // Present a view by name.
    function present(viewName, props) {
        const path = resources[viewName]
        if (!viewManager.createView(path, rootView, function(view) {
            // push the view onto the stack if it's not already there
            if (rootView.currentItem !== view) {
                rootView.push(view, StackView.Immediate)
            }
            view.presented()
        }, props)) {
            print("could not create view:", viewName)
        }
    }

    // Dismiss the top view.
    function dismiss() {
        if (rootView.depth === 0) {
            return
        }
        var view
        if (rootView.depth === 1) {
            view = rootView.currentItem
            rootView.clear()
        } else {
            view = rootView.pop(StackView.Immediate)
        }
        view.dismissed()
        viewManager.destroyView(viewManager.viewPaths[view.objectName])
        if (rootView.depth > 0) {
            rootView.currentItem.presented()
        }
    }

    function getView(viewName) {
        return viewManager.getView(viewName)
    }

   // Load a view without presenting it.
   function preload(viewName) {
       if (!viewManager.createView(resources[viewName], null)) {
           console.log("Failed to load view: " + viewName)
       }
   }
}
