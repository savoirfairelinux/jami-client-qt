/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
 * Author: Nicolas Vengeon <Nicolas.vengeon@savoirfairelinux.com>

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
    property real elementWidth: {
        var layoutWidth = selectScreenWindowLayout.width;
        var minSize = componentMinWidth + 2 * marginSize;
        var numberElementPerRow = Math.floor(layoutWidth / minSize);
        if (numberElementPerRow == 1 && layoutWidth > componentMinWidth * 1.5) {
            numberElementPerRow = 2;
        }
        if (showWindows)
            numberElementPerRow = Math.min(listModel.length, numberElementPerRow);
        else
            numberElementPerRow = Math.min(listModel.length + 1, numberElementPerRow);
        var spacingLength = marginSize * (numberElementPerRow + 2);
        return (layoutWidth - spacingLength) / numberElementPerRow;
    }

    function calculateRepeaterModel() {
        listModel = [];
        var idx;
        if (!showWindows) {
            for (idx in Qt.application.screens) {
                listModel.push(JamiStrings.screen.arg(idx));
            }
        } else {
            AvAdapter.getListWindows();
            for (idx in AvAdapter.windowsNames) {
                listModel.push(AvAdapter.windowsNames[idx]);
            }
        }
    }

    onVisibleChanged: {
        if (!visible)
            return;
        if (!active) {
            selectedScreenNumber = undefined;
        }
        screenSharePreviewRepeater.model = {};
        calculateRepeaterModel();
        screenSharePreviewRepeater.model = root.listModel;
    }

    Rectangle {
        id: selectScreenWindowRect

        anchors.fill: parent
        color: JamiTheme.backgroundColor

        ColumnLayout {
            id: selectScreenWindowLayout

            anchors.fill: parent

            Text {
                font.pointSize: JamiTheme.menuFontSize
                font.bold: true
                text: showWindows ? JamiStrings.windows : JamiStrings.screens
                verticalAlignment: Text.AlignBottom
                color: JamiTheme.textColor
                Layout.margins: marginSize
            }

            ScrollView {
                id: screenSelectionScrollView

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: selectScreenWindowLayout.width
                Layout.fillHeight: true

                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Flow {
                    id: screenSelectionScrollViewFlow

                    // https://bugreports.qt.io/browse/QTBUG-110323
                    width: screenSelectionScrollView.width
                    height: screenSelectionScrollView.height

                    topPadding: marginSize
                    rightPadding: marginSize
                    leftPadding: marginSize
                    spacing: marginSize

                    Loader {
                        // Show all screens
                        active: !showWindows && Qt.application.screens.length > 1 && Qt.platform.os.toString() !== "windows"
                        sourceComponent: ScreenSharePreview {
                            id: screenSelectionRectAll

                            elementIndex: -1
                            rectTitle: JamiStrings.allScreens
                            rId: AvAdapter.getSharingResource(-1)
                        }
                    }

                    Repeater {
                        id: screenSharePreviewRepeater

                        model: listModel.length

                        delegate: ScreenSharePreview {
                            id: screenItem

                            visible: JamiStrings.selectScreen !== listModel[index] && JamiStrings.selectWindow !== listModel[index]
                            elementIndex: index
                            rectTitle: listModel[index] ? listModel[index] : ""
                            rId: {
                                if (showWindows)
                                    return rId = AvAdapter.getSharingResource(-2, AvAdapter.windowsIds[index], AvAdapter.windowsNames[index]);
                                return rId = AvAdapter.getSharingResource(index);
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.margins: marginSize
                Layout.preferredWidth: selectScreenWindowLayout.width
                Layout.preferredHeight: childrenRect.height
                spacing: marginSize

                MaterialButton {
                    id: selectButton

                    Layout.maximumWidth: 200
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.leftMargin: marginSize

                    enabled: selectedScreenNumber != undefined
                    opacity: enabled ? 1.0 : 0.5

                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    secondary: true
                    autoAccelerator: true

                    text: showWindows ? JamiStrings.shareWindow : JamiStrings.shareScreen

                    onClicked: {
                        if (selectAllScreens)
                            AvAdapter.shareAllScreens();
                        else {
                            if (!showWindows)
                                AvAdapter.shareEntireScreen(selectedScreenNumber);
                            else {
                                AvAdapter.shareWindow(AvAdapter.windowsIds[selectedScreenNumber], AvAdapter.windowsNames[selectedScreenNumber - Qt.application.screens.length]);
                            }
                        }
                        root.close();
                    }
                }

                MaterialButton {
                    id: cancelButton

                    Layout.maximumWidth: 200
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.rightMargin: marginSize

                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    secondary: true
                    autoAccelerator: true

                    text: JamiStrings.optionCancel

                    onClicked: root.close()
                }
            }
        }
    }
}
