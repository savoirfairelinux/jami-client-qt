/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import QtQuick.Layouts
import QtQuick.Controls
import SortFilterProxyModel 0.2
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

import "qrc:/js/markdownedition.js" as MDE

RowLayout {
    id: root

    property alias text: messageBarTextArea.text
    property alias fileContainer: dataTransferSendContainer
    property var textAreaObj: messageBarTextArea
    property real marginSize: JamiTheme.messageBarMarginSize
    property bool sendButtonVisibility: true
    property bool animate: false
    property bool showDefault: !UtilsAdapter.getAppValue(Settings.Key.ShowSendOption)
    property bool showTypo: UtilsAdapter.getAppValue(Settings.Key.ShowMardownOption)
    property bool chatViewEnterIsNewLine: UtilsAdapter.getAppValue(Settings.Key.ChatViewEnterIsNewLine)
    property bool showTypoSecond: false
    property bool showPreview: false
    property bool multiLine: messageBarTextArea.tooMuch

    property int messageBarLayoutMaximumWidth: 486

    readonly property bool isFullScreen: visibility === Window.FullScreen

    signal sendMessageButtonClicked
    signal sendFileButtonClicked
    signal audioRecordMessageButtonClicked
    signal videoRecordMessageButtonClicked
    signal showMapClicked
    signal emojiButtonClicked


    height: messageRow.height + formatRow.height + fileContainer.height + 2*marginSize 
    Layout.preferredHeight : messageRow.height + formatRow.height + fileContainer.height + 2*marginSize
    onShowTypoChanged: {
        messageBarTextArea.forceActiveFocus();
    }

   

    Rectangle {
        id: rectangle

        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: 5
        color: JamiTheme.transparentColor
        border.color: JamiTheme.chatViewFooterRectangleBorderColor
        border.width: 2

        onWidthChanged: {
            height = Qt.binding(() => root.height);
            if (width < JamiTheme.messageBarMinimumWidth) {
                showTypoSecond = false;
            } else {
                showTypoSecond = true;
        }
        }
        
        


        ColumnLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.margins: marginSize / 2

            Rectangle {
                id: messageRow
                
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                Layout.rightMargin: marginSize / 2
                Layout.leftMargin: marginSize / 2
                Layout.preferredHeight: MessageBarTextArea.height
                Layout.minimumHeight: 35
                Layout.maximumHeight: 35*10
                
                
                color: JamiTheme.transparentColor
                MessageBarTextArea {
                    id: messageBarTextArea
                    objectName: "messageBarTextArea"
                    

                    // forward activeFocus to the actual text area object
                    onActiveFocusChanged: {
                        if (activeFocus)
                            textAreaObj.forceActiveFocus();
                    }

                    placeholderText: JamiStrings.writeTo.arg(CurrentConversation.title)

                    Layout.margins: marginSize / 2
                    Layout.topMargin: 0

                    Layout.maximumHeight: JamiTheme.chatViewFooterTextAreaMaximumHeight - marginSize / 2
                    
                    Layout.preferredWidth: parent.width - previewButton.preferredSize

                    onSendMessagesRequired: {
                        sendMessageButtonClicked();
                    }
                    onTextChanged: {
                        if (!text) {
                            messageBarTextArea.heightBinding();
                        }
                    }
                    property var markdownShortCut: {
                        "Bold": function () {
                            if (!showPreview) {
                                listViewTypoFirst.itemAtIndex(0).action.triggered();
                            }
                        },
                        "Italic": function () {
                            if (!showPreview) {
                                listViewTypoFirst.itemAtIndex(1).action.triggered();
                            }
                        },
                        "Barre": function () {
                            if (!showPreview) {
                                listViewTypoFirst.itemAtIndex(2).action.triggered();
                            }
                        },
                        "Heading": function () {
                            if (!showPreview) {
                                listViewTypoFirst.itemAtIndex(3).action.triggered();
                            }
                        },
                        "Link": function () {
                            if (!showPreview) {
                                listViewTypoFirst.itemAtIndex(4).action.triggered();
                            }
                        },
                        "Code": function () {
                            if (!showPreview) {
                                listViewTypoFirst.itemAtIndex(5).action.triggered();
                            }
                        },
                        "Quote": function () {
                            if (!showPreview) {
                                listViewTypoSecond.itemAtIndex(0).action.triggered();
                            }
                        },
                        "Unordered list": function () {
                            if (!showPreview) {
                                listViewTypoSecond.itemAtIndex(1).action.triggered();
                            }
                        },
                        "Ordered list": function () {
                            if (!showPreview) {
                                listViewTypoSecond.itemAtIndex(2).action.triggered();
                            }
                        },
                        "Enter is new line": function () {
                            if (!showPreview) {
                                listViewTypoSecond.itemAtIndex(3).action.triggered();
                            }
                        }
                    }

                    Shortcut {
                        sequence: "Ctrl+B"
                        context: Qt.ApplicationShortcut
                        onActivated: messageBarTextArea.markdownShortCut["Bold"]()
                    }

                    Shortcut {
                        sequence: "Ctrl+I"
                        context: Qt.ApplicationShortcut
                        onActivated: messageBarTextArea.markdownShortCut["Italic"]()
                    }

                    Shortcut {
                        sequence: "Shift+Alt+X"
                        context: Qt.ApplicationShortcut
                        onActivated: messageBarTextArea.markdownShortCut["Barre"]()
                    }

                    Shortcut {
                        sequence: "Ctrl+Alt+H"
                        context: Qt.ApplicationShortcut
                        onActivated: messageBarTextArea.markdownShortCut["Heading"]()
                    }

                    Shortcut {
                        sequence: "Ctrl+Alt+K"
                        context: Qt.ApplicationShortcut
                        onActivated: messageBarTextArea.markdownShortCut["Link"]()
                    }

                    Shortcut {
                        sequence: "Ctrl+Alt+C"
                        context: Qt.ApplicationShortcut
                        onActivated: messageBarTextArea.markdownShortCut["Code"]()
                    }

                    Shortcut {
                        sequence: "Shift+Alt+9"
                        context: Qt.ApplicationShortcut
                        onActivated: messageBarTextArea.markdownShortCut["Quote"]()
                    }

                    Shortcut {
                        sequence: "Shift+Alt+8"
                        context: Qt.ApplicationShortcut
                        onActivated: messageBarTextArea.markdownShortCut["Unordered list"]()
                    }

                    Shortcut {
                        sequence: "Shift+Alt+7"
                        context: Qt.ApplicationShortcut
                        onActivated: messageBarTextArea.markdownShortCut["Ordered list"]()
                    }

                    Shortcut {
                        sequence: "Shift+Alt+T"
                        context: Qt.ApplicationShortcut
                        onActivated: {
                            showTypo = !showTypo;
                            messageBarTextArea.isShowTypo = showTypo;
                            UtilsAdapter.setAppValue(Settings.Key.ShowMardownOption, showTypo);
                        }
                    }

                    Shortcut {
                        sequence: "Shift+Alt+P"
                        context: Qt.ApplicationShortcut
                        onActivated: {
                            showPreview = !showPreview;
                            messageBarTextArea.showPreview = showPreview;
                        }
                    }
                }
                    PushButton {
                        id: previewButton
                        anchors.top: parent.top
                        anchors.right: parent.right
                        preferredSize: JamiTheme.chatViewFooterButtonSize
                        radius: 5
                        source: JamiResources.preview_black_24dp_svg
                        normalColor: showPreview ? hoveredColor : JamiTheme.primaryBackgroundColor
                        imageColor: (hovered || showPreview) ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor
                        hoveredColor: JamiTheme.hoveredButtonColor
                        pressedColor: hoveredColor
                        toolTipText: showPreview ? JamiStrings.continueEditing : JamiStrings.showPreview


                        onClicked: {
                            showPreview = !showPreview;
                            messageBarTextArea.showPreview = showPreview;
                        }
                    }
            }
           
            FilesToSendContainer {
                        id: dataTransferSendContainer


                        objectName: "dataTransferSendContainer"
                        visible: filesToSendCount > 0
                        height: visible ? JamiTheme.layoutWidthFileTransfer : 0
                        Layout.rightMargin: marginSize / 2
                        Layout.leftMargin: marginSize / 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter 
                        Layout.preferredHeight: filesToSendCount ? JamiTheme.layoutWidthFileTransfer : 0
                    }

           MessageFormatBar {
                id: formatRow
                    color: JamiTheme.transparentColor
                    Layout.alignment: Qt.AlignBottom
                    Layout.fillWidth: true
                    Layout.rightMargin: marginSize / 2
                    Layout.leftMargin: marginSize / 2
                    Layout.preferredHeight:  JamiTheme.chatViewFooterButtonSize
    

                    

           } 
            
                      
        }
    }
}
