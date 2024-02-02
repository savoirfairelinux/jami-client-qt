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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Helpers 1.1
import net.jami.Constants 1.1

import "mainview"
import "mainview/components"
import "wizardview"
import "commoncomponents"

// A window into which we can load a QML file for testing.
ApplicationWindow {
    id: appWindow
    visible: true
    width: testWidth || loader.implicitWidth || 800
    height: testHeight || loader.implicitHeight || 600
    title: testComponentURI

    // WARNING: The following currently must be maintained in tandem with MainApplicationWindow.qml
    // Used to manage full screen mode and save/restore window geometry.
    property bool isRTL: UtilsAdapter.isRTL
    LayoutMirroring.enabled: isRTL
    LayoutMirroring.childrenInherit: isRTL
    // This needs to be set from the start.
    readonly property bool useFrameless: false
    LayoutManager {
        id: layoutManager
        appContainer: null
    }
    // Used to manage dynamic view loading and unloading.
    property ViewManager viewManager: ViewManager {}
    // Used to manage the view stack and the current view.
    property ViewCoordinator viewCoordinator: ViewCoordinator {}

    Loader {
        id: loader
        source: Qt.resolvedUrl(testComponentURI)
        onStatusChanged: {
            console.log("Status changed to:", loader.status)
            if (loader.status == Loader.Error || loader.status == Loader.Null) {
                console.error("Couldn't load component:", source)
                Qt.exit(1);
            } else if (loader.status == Loader.Ready) {
                console.info("Loaded component:", source);
                // If any of the dimensions are not set, set them to the appWindow's dimensions
                item.width = item.width || Qt.binding(() => appWindow.width);
                item.height = item.height || Qt.binding(() => appWindow.height);
                viewCoordinator.init(appWindow);
            }
        }
    }

    // Closing this window should always exit the application.
    onClosing: Qt.quit()

    // A window to modify properties for Jamified components.
    // Sometimes we need to modify properties including current conversation ID, account ID, etc.
    // This window should have a simple layout: a list of editable parameters within a scroll view.
    Window {
        id: configTool
        width: 400
        height: 400
        title: "Config tool"

        visible: true
        // Cannot be closed.
        flags: Qt.SplashScreen

        // Anchor the window to the right of the parent window.
        x: appWindow.x + appWindow.width
        y: appWindow.y

        color: "lightgray"

        Page {
            anchors.fill: parent
            header: Control {
                contentItem: Text {
                    horizontalAlignment: Text.AlignHCenter
                    text: "Config tool"
                }
                background: Rectangle { color: configTool.color }
            }
            contentItem: Control {
                background: Rectangle { color: Qt.lighter(configTool.color, 1.1) }
                padding: 10
                contentItem: ListView {
                    // Declare types of controls. TODO: add as needed.
                    Component {
                        id: checkComponent
                        CheckBox {
                            text: label
                            onCheckedChanged: checkChangedCb(checked)
                        }
                    }
                    Component {
                        id: comboComponent
                        Control {
                            contentItem: RowLayout {
                                Text { text: label }
                                ComboBox {
                                    id: comboBox
                                    displayText: CurrentConversation.title || "undefined"
                                    model: getDataModel()
                                    delegate: ItemDelegate {
                                        highlighted: comboBox.highlightedIndex === index
                                        width: parent.width
                                        text: JamiQmlUtils.getModelData(comboBox.model, index, displayRole)
                                    }
                                    onCurrentIndexChanged: onIndexChanged(model, currentIndex)
                                }
                            }
                        }
                    }
                    spacing: 5
                    model: ListModel {
                        ListElement {
                            label: "Conversation ID"
                            type: "combobox"
                            getDataModel: () => ConversationsAdapter.convListProxyModel
                            displayRole: ConversationList.Title
                            onIndexChanged: function(model, index) {
                                const convUid = JamiQmlUtils.getModelData(model, index, ConversationList.UID);
                                LRCInstance.selectConversation(convUid);
                            }
                        }
                        ListElement {
                            label: "Force local preview"
                            type: "checkbox"
                            value: false
                            checkChangedCb: function(checked) {
                                // Find any child component of type `LocalVideo` and start it.
                                const localVideo = findChild(loader.item, LocalVideo, "type");
                                if (localVideo) {
                                    if (checked) {
                                        localVideo.startWithId(VideoDevices.getDefaultDevice());
                                    } else {
                                        localVideo.startWithId("");
                                    }
                                } else {
                                    console.error("LocalVideo not found");
                                }
                            }
                        }
                    }
                    delegate: DelegateChooser {
                        role: "type"
                        DelegateChoice {
                            roleValue: "checkbox"
                            delegate: checkComponent
                        }
                        DelegateChoice {
                            roleValue: "combobox"
                            delegate: comboComponent
                        }
                    }
                }
            }
        }
    }

    // From TestCase.qml, refactored to find a child by type or name.
    function findChild(parent, searchValue, searchBy = "name") {
        if (!parent || parent.children === undefined) {
            console.error("No children found");
            return null;
        }
        // Search directly under the given parent
        for (var i = 0; i < parent.children.length; ++i) {
            var child = parent.children[i];
            var match = false;
            if (searchBy === "name" && child.objectName === searchValue) {
                match = true;
            } else if (searchBy === "type" && child instanceof searchValue) {
                match = true;
            }
            if (match) return child;
        }
        // Recursively search in child objects
        for (i = 0; i < parent.children.length; ++i) {
            var found = findChild(parent.children[i], searchValue, searchBy);
            if (found) return found;
        }
        return null;
    }
}
