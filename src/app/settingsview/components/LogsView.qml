/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Window {
    id: root
    property bool cancelPressed: false
    property bool hasOpened: false
    property bool isStopped: false
    property int itemWidth: Math.min(root.width / 2 - 50, 350) * 1.5
    property var lineCounter: 0
    property var lineSize: []
    property bool logging: false
    property int selectBeginning
    property int selectEnd
    property int widthDivisor: 4

    height: 500
    title: JamiStrings.logsViewTitle
    width: 600

    function monitor(continuous) {
        UtilsAdapter.monitor(continuous);
    }

    onVisibleChanged: {
        if (visible && startStopToggle.checked) {
            if (hasOpened && lineCounter == 0) {
                var logList = UtilsAdapter.logList;
                logsText.append(logList.join('\n'));
                lineCounter = logList.length;
                lineSize.push(lineCounter ? logList[0].length : 0);
            }
        } else {
            logsText.clear();
            copiedToolTip.close();
            lineCounter = 0;
            lineSize = [];
        }
        hasOpened = true;
    }

    Connections {
        target: UtilsAdapter

        function onDebugMessageReceived(message) {
            if (!root.visible) {
                return;
            }
            var initialPosition = scrollView.ScrollBar.vertical.position;
            lineCounter += 1;
            lineSize.push(message.length);
            if (!root.cancelPressed) {
                logsText.append(message);
            }
            if (lineCounter >= 10000) {
                lineCounter -= 1;
                logsText.remove(0, lineSize[0]);
                lineSize.shift();
            }
            scrollView.ScrollBar.vertical.position = initialPosition > (.8 * (1.0 - scrollView.ScrollBar.vertical.size)) ? 1.0 - scrollView.ScrollBar.vertical.size : initialPosition;
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: buttonRectangleBackground
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight * 2
            border.width: 0
            color: JamiTheme.backgroundColor
            radius: JamiTheme.modalPopupRadius

            RowLayout {
                id: buttons
                anchors.centerIn: parent

                ToggleSwitch {
                    id: startStopToggle
                    Layout.fillWidth: true
                    Layout.leftMargin: JamiTheme.preferredMarginSize
                    Layout.rightMargin: JamiTheme.preferredMarginSize
                    checked: false
                    labelText: JamiStrings.logsViewDisplay

                    onSwitchToggled: {
                        logging = !logging;
                        if (logging) {
                            isStopped = false;
                            root.cancelPressed = false;
                            monitor(true);
                        } else {
                            isStopped = true;
                            root.cancelPressed = true;
                            monitor(false);
                        }
                    }
                }
                MaterialButton {
                    id: clearButton
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    autoAccelerator: true
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    preferredWidth: itemWidth / widthDivisor
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    secondary: true
                    text: JamiStrings.logsViewClear

                    onClicked: {
                        logsText.clear();
                        logging = false;
                        startStopToggle.checked = false;
                        root.cancelPressed = true;
                        UtilsAdapter.logList = [];
                        monitor(false);
                    }
                }
                MaterialButton {
                    id: copyButton
                    Layout.alignment: Qt.AlignHCenter
                    autoAccelerator: true
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    preferredWidth: itemWidth / widthDivisor
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    secondary: true
                    text: JamiStrings.logsViewCopy

                    onClicked: {
                        logsText.selectAll();
                        logsText.copy();
                        logsText.deselect();
                        copiedToolTip.open();
                    }

                    ToolTip {
                        id: copiedToolTip
                        height: JamiTheme.preferredFieldHeight

                        TextArea {
                            color: JamiTheme.textColor
                            text: JamiStrings.logsViewCopied
                        }

                        background: Rectangle {
                            color: JamiTheme.primaryBackgroundColor
                        }
                    }
                }
                MaterialButton {
                    id: reportButton
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: JamiTheme.preferredMarginSize
                    Layout.rightMargin: JamiTheme.preferredMarginSize
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    autoAccelerator: true
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    preferredWidth: itemWidth / widthDivisor
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    secondary: true
                    text: JamiStrings.logsViewReport

                    onClicked: Qt.openUrlExternally("https://jami.net/bugs-and-improvements/")
                }
            }
        }
        JamiFlickable {
            id: scrollView
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.fillWidth: true
            attachedFlickableMoving: contentHeight > height || scrollView.moving
            interactive: true

            TextArea.flickable: TextArea {
                id: logsText
                color: JamiTheme.blackColor
                font.hintingPreference: Font.PreferNoHinting
                font.pointSize: JamiTheme.textFontSize
                readOnly: true
                selectByMouse: true
                wrapMode: TextArea.Wrap

                MouseArea {
                    acceptedButtons: Qt.RightButton
                    anchors.fill: logsText
                    hoverEnabled: true

                    onClicked: {
                        selectBeginning = logsText.selectionStart;
                        selectEnd = logsText.selectionEnd;
                        rightClickMenu.open();
                        logsText.select(selectBeginning, selectEnd);
                    }

                    Menu {
                        id: rightClickMenu
                        MenuItem {
                            text: JamiStrings.logsViewCopy

                            onTriggered: {
                                logsText.copy();
                            }
                        }
                    }
                }

                background: Rectangle {
                    border.width: 0
                    color: JamiTheme.transparentColor
                }
            }
        }
    }
}
