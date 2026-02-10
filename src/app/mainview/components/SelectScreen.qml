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
import QtQuick.Controls.impl

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

    required property bool showWindows

    property var selectedScreenNumber: undefined
    property bool selectAllScreens: selectedScreenNumber === -1
    property var listModel: []
    property real componentMinWidth: 350
    property real marginSize: JamiTheme.preferredMarginSize
    property bool shareScreenAudio: !AvAdapter.muteScreenshareAudio

    minimumHeight: minimumWidth * 3 / 4
    minimumWidth: componentMinWidth + 2 * marginSize
    modality: Qt.ApplicationModal
    title: showWindows ? JamiStrings.selectWindow : JamiStrings.selectScreen
    color: JamiTheme.globalBackgroundColor

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

    ColumnLayout {
        id: selectScreenWindowLayout

        anchors.fill: parent
        anchors.margins: marginSize

        spacing: marginSize

        Text {
            id: titleText

            Layout.alignment: Qt.AlignHCenter

            text: showWindows ? JamiStrings.windows : JamiStrings.screens
            color: JamiTheme.textColor
            verticalAlignment: Text.AlignBottom

            font.pointSize: JamiTheme.menuFontSize
            font.bold: true
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

                delegate:
                    ScreenSharePreview {
                    id: screenItem

                    width: screenGrid.cellWidth - marginSize
                    height: screenGrid.cellHeight - marginSize

                    visible: JamiStrings.selectScreen !== modelData.title && JamiStrings.selectWindow !== modelData.title
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

        RowLayout {
            id: enableAudioSharingRow

            Layout.alignment: Qt.AlignCenter

            // We don't want swarms to support audio sharing for now, so we disable the ability to share audio
            visible: CurrentConversation.isCoreDialog

            CheckBox {
                id: audioCheckbox

                Layout.alignment: Qt.AlignVCenter

                text: JamiStrings.shareScreenWaylandDialogEnableDesktopAudio
                checked: root.shareScreenAudio

                indicator: IconImage {
                    anchors.verticalCenter: audioCheckbox.verticalCenter
                    width: JamiTheme.iconButtonMedium
                    height: JamiTheme.iconButtonMedium

                    source: audioCheckbox.checked ? JamiResources.check_box_24dp_svg : JamiResources.check_box_outline_blank_24dp_svg
                    sourceSize.width: JamiTheme.iconButtonMedium
                    sourceSize.height: JamiTheme.iconButtonMedium

                    color: audioCheckbox.activeFocus ? JamiTheme.tintedBlue : JamiTheme.textColor

                    Behavior on color {
                        ColorAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }

                contentItem: Text {
                    text: audioCheckbox.text
                    color: JamiTheme.textColor
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: audioCheckbox.indicator.implicitWidth + 8
                }

                onClicked: AvAdapter.muteScreenshareAudio = !AvAdapter.muteScreenshareAudio;
            }

            NewIconButton {
                Layout.alignment: Qt.AlignVCenter

                iconSize: JamiTheme.iconButtonSmall
                iconSource: JamiResources.bidirectional_help_outline_24dp_svg
                toolTipText: showMoreText.visible ? JamiStrings.showLess : JamiStrings.showMore

                checked: showMoreText.visible

                onClicked: showMoreText.visible = !showMoreText.visible
            }
        }

        Text {
            id: showMoreText

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            text: JamiStrings.shareScreenWindowDesktopAudioInfo
            horizontalAlignment: Text.AlignHCenter
            color: JamiTheme.textColor
            wrapMode: Text.WordWrap

            visible: false

            opacity: visible ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            Layout.margins: marginSize

            spacing: marginSize

            Item {
                Layout.fillWidth: true
            }

            NewMaterialButton {
                id: cancelButton

                Layout.fillWidth: true
                Layout.maximumWidth: 200
                Layout.alignment: Qt.AlignRight

                textButton: true
                text: JamiStrings.optionCancel

                onClicked: root.close()
            }

            NewMaterialButton {
                id: selectButton

                Layout.fillWidth: true
                Layout.maximumWidth: 200
                Layout.rightMargin: marginSize
                Layout.alignment: Qt.AlignRight

                textButton: true
                iconSource: JamiResources.share_screen_black_24dp_svg
                text: showWindows ? JamiStrings.shareWindow : JamiStrings.shareScreen

                enabled: selectedScreenNumber !== undefined

                onClicked: {
                    if (selectAllScreens)
                        AvAdapter.shareAllScreens(!root.shareScreenAudio);
                    else {
                        if (!showWindows)
                            AvAdapter.shareEntireScreen(selectedScreenNumber, !root.shareScreenAudio);
                        else
                            AvAdapter.shareWindow(AvAdapter.windowsIds[selectedScreenNumber], AvAdapter.windowsNames[selectedScreenNumber], -1, !root.shareScreenAudio);
                    }
                    root.close();
                }
            }
        }
    }
}
