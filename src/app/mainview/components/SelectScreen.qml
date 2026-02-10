/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../js/screenrubberbandcreation.js" as ScreenRubberBandCreation
import "../../commoncomponents"
import "../../settingsview/components"

// SelectScreenWindow as a seperate window,
// is to make user aware of which screen they want to share,
// during the video call, if the context menu item is selected.
Window {
    id: root

    minimumHeight: minimumWidth * 3 / 4
    minimumWidth: componentMinWidth + 2 * marginSize
    modality: Qt.ApplicationModal
    title: showWindows ? JamiStrings.selectWindow : JamiStrings.selectScreen

    onClosing: this.destroy()

    required property bool showWindows

    property var selectedScreenNumber: undefined
    property bool selectAllScreens: selectedScreenNumber === -1
    property var listModel: []
    property real componentMinWidth: 350
    property real marginSize: JamiTheme.preferredMarginSize

    // Function to safely populate screen/window list
    function calculateRepeaterModel() {
        var newModel = [];
        var idx;
        if (!showWindows) {
            for (idx in Qt.application.screens) {
                newModel.push({
                    title: JamiStrings.screen.arg(idx),
                    index: parseInt(idx),
                    isAllScreens: false
                });
            }
        } else {
            AvAdapter.getListWindows();
            for (idx in AvAdapter.windowsNames) {
                newModel.push({
                    title: AvAdapter.windowsNames[idx],
                    index: parseInt(idx),
                    isAllScreens: false
                });
            }
        }

        // Add "All Screens" option for non-Windows platforms when showing screens
        if (!showWindows && Qt.application.screens.length > 1 && Qt.platform.os.toString() !== "windows") {
            newModel.unshift({
                title: JamiStrings.allScreens,
                index: -1,
                isAllScreens: true
            });
        }
        listModel = newModel;
    }

    onVisibleChanged: {
        if (!visible)
            return;
        if (!active) {
            selectedScreenNumber = undefined;
        }
        // Reset audio muting option to true (mute) each time window is opened
        AvAdapter.muteScreenshareAudio = true;

        calculateRepeaterModel();
    }

    Rectangle {
        id: selectScreenWindowRect
        anchors.fill: parent
        color: JamiTheme.backgroundColor

        ColumnLayout {
            id: selectScreenWindowLayout
            anchors.fill: parent
            spacing: marginSize

            Text {
                id: titleText
                font.pointSize: JamiTheme.menuFontSize
                font.bold: true
                text: showWindows ? JamiStrings.windows : JamiStrings.screens
                verticalAlignment: Text.AlignBottom
                color: JamiTheme.textColor
                Layout.margins: marginSize
            }

            ScrollView {
                id: screenSelectionScrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                GridView {
                    id: screenGrid
                    anchors.fill: parent
                    anchors.margins: marginSize

                    cellWidth: {
                        var cellsPerRow = Math.floor(width / (componentMinWidth + marginSize));
                        cellsPerRow = Math.max(1, cellsPerRow);
                        var calculatedWidth = Math.floor(width / cellsPerRow);
                        return Math.max(componentMinWidth, calculatedWidth);
                    }
                    cellHeight: cellWidth * 3 / 4 + marginSize * 2

                    model: listModel

                    delegate: Item {
                        width: screenGrid.cellWidth - marginSize
                        height: screenGrid.cellHeight - marginSize

                        visible: JamiStrings.selectScreen !== modelData.title && JamiStrings.selectWindow !== modelData.title

                        ScreenSharePreview {
                            id: screenItem
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height - marginSize

                            elementIndex: modelData.index
                            rectTitle: modelData.title
                            rId: {
                                if (modelData.isAllScreens)
                                    return AvAdapter.getSharingResource(-1);
                                else if (showWindows)
                                    return AvAdapter.getSharingResource(-2, AvAdapter.windowsIds[modelData.index], AvAdapter.windowsNames[modelData.index], 1);
                                return AvAdapter.getSharingResource(modelData.index);
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.margins: marginSize
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height
                spacing: marginSize

                ToggleSwitch {
                    id: shareAudioToggle

                    visible: Qt.platform.os.toString() === "linux"

                    Layout.maximumWidth: 200
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: marginSize

                    labelText: JamiStrings.shareAudio
                    checked: !AvAdapter.muteScreenshareAudio

                    onSwitchToggled: {
                        AvAdapter.muteScreenshareAudio = !checked;
                    }
                }

                // Push buttons to the right
                Item {
                    Layout.fillWidth: true
                }

                MaterialButton {
                    id: cancelButton

                    Layout.maximumWidth: 200
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight

                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    secondary: true
                    autoAccelerator: true

                    text: JamiStrings.optionCancel

                    onClicked: root.close()
                }

                MaterialButton {
                    id: selectButton

                    Layout.maximumWidth: 200
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: marginSize

                    enabled: selectedScreenNumber !== undefined
                    opacity: enabled ? 1.0 : 0.5

                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    secondary: true
                    autoAccelerator: true

                    text: showWindows ? JamiStrings.shareWindow : JamiStrings.shareScreen

                    onClicked: {
                        if (selectAllScreens)
                            AvAdapter.shareAllScreens(AvAdapter.muteScreenshareAudio);
                        else {
                            if (!showWindows)
                                AvAdapter.shareEntireScreen(selectedScreenNumber, AvAdapter.muteScreenshareAudio);
                            else {
                                AvAdapter.shareWindow(AvAdapter.windowsIds[selectedScreenNumber], AvAdapter.windowsNames[selectedScreenNumber], -1, AvAdapter.muteScreenshareAudio);
                            }
                        }
                        root.close();
                    }
                }
            }
        }
    }
}
