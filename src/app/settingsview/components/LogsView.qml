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
    property bool logging: false
    property bool isStopped: false
    property bool hasOpened: false

    property int itemWidth: Math.min(root.width / 2 - 50, 350) * 1.5
    property int widthDivisor: 4
    property int selectBeginning
    property int selectEnd

    property var lineSize: []
    property var lineCounter: 0

    function monitor(continuous) {
        UtilsAdapter.monitor(continuous);
    }

    title: JamiStrings.logsViewTitle
    width: 600
    height: 500

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
    color: JamiTheme.backgroundColor

    ColumnLayout {
        anchors.fill: parent

        spacing: 0

        RowLayout {
            id: buttons

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
                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                preferredWidth: itemWidth / widthDivisor
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                secondary: true
                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                pressedColor: JamiTheme.buttonTintedBlackPressed
                text: JamiStrings.logsViewClear
                autoAccelerator: true

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

                preferredWidth: itemWidth / widthDivisor
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                pressedColor: JamiTheme.buttonTintedBlackPressed

                secondary: true
                text: JamiStrings.logsViewCopy
                autoAccelerator: true

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
                        text: JamiStrings.logsViewCopied
                        color: JamiTheme.textColor
                    }
                    background: Rectangle {
                        color: JamiTheme.primaryBackgroundColor
                    }
                }
            }

            MaterialButton {
                id: reportButton

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.bottomMargin: JamiTheme.preferredMarginSize
                Layout.rightMargin: JamiTheme.preferredMarginSize

                preferredWidth: itemWidth / widthDivisor
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                pressedColor: JamiTheme.buttonTintedBlackPressed
                text: JamiStrings.logsViewReport
                secondary: true
                autoAccelerator: true

                onClicked: Qt.openUrlExternally("https://jami.net/bugs-and-improvements/")
            }
        }

        JamiFlickable {
            id: scrollView

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true

            interactive: true
            attachedFlickableMoving: contentHeight > height || scrollView.moving

            TextArea.flickable: TextArea {
                id: logsText

                font.pointSize: JamiTheme.textFontSize
                font.hintingPreference: Font.PreferNoHinting

                readOnly: true
                color: JamiTheme.textColor
                wrapMode: TextArea.Wrap
                selectByMouse: true

                background: Rectangle {
                    border.width: 0
                    color: JamiTheme.transparentColor
                }

                MouseArea {
                    anchors.fill: logsText
                    acceptedButtons: Qt.RightButton
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
            }
        }
    }
}
