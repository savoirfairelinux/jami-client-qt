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
import QtQuick.Layouts
import QtQuick.Controls
import SortFilterProxyModel 0.2
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "qrc:/js/markdownedition.js" as MDE

Rectangle {
    id: rectangle

    property alias text: messageBarTextArea.text
    property alias fileContainer: dataTransferSendContainer
    property var textAreaObj: messageBarTextArea
    property real marginSize: JamiTheme.messageBarMarginSize
    property bool sendButtonVisibility: true
    property bool animate: false
    property bool showDefault: !UtilsAdapter.getAppValue(Settings.Key.ShowSendOption)
    property bool showTypo: UtilsAdapter.getAppValue(Settings.Key.ShowMardownOption)
    property bool showTypoSecond: false
    property bool showPreview: false
    property bool isEmojiPickerOpen: false

    property bool maximized: (showTypo || dataTransferSendContainer.visible)
    property int messageBarLayoutMaximumWidth: 486

    readonly property bool isFullScreen: visibility === Window.FullScreen

    signal sendMessageButtonClicked
    signal sendFileButtonClicked
    signal audioRecordMessageButtonClicked
    signal videoRecordMessageButtonClicked
    signal showMapClicked
    signal emojiButtonClicked

    onSendMessageButtonClicked: {
        messageBarTextArea.restoreVisibilityAfterSend();
        messageBarTextArea.forceActiveFocus();
    }

    onShowTypoChanged: {
        messageBarTextArea.forceActiveFocus();
    }

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignBottom
    height: Math.min(JamiTheme.chatViewFooterTextAreaMaximumHeight + 2 * marginSize, colLayout.height + 2 * marginSize)

    radius: JamiTheme.messageBarRadius
    color: JamiTheme.globalBackgroundColor
    border.color: JamiTheme.chatViewFooterRectangleBorderColor
    border.width: 2

    onWidthChanged: {
        if (width < JamiTheme.showTypoSecondToggleWidth) {
            showTypoSecond = false;
        } else {
            showTypoSecond = true;
        }
    }

    GridLayout {
        id: colLayout
        columns: 2
        rows: 4

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: marginSize
        }

        Rectangle {
            id: replyOrEditContainer

            visible: MessagesAdapter.replyToId !== "" || MessagesAdapter.editId !== ""

            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.row: 0
            Layout.column: 0
            Layout.columnSpan: 2

            Layout.alignment: Qt.AlignTop

            color: JamiTheme.transparentColor

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: -marginSize + rectangle.border.width
                anchors.right: parent.right
                anchors.rightMargin: -marginSize + rectangle.border.width
                anchors.top: parent.top
                anchors.topMargin: -marginSize + rectangle.border.width

                height: 50

                color: JamiTheme.chatViewFooterRectangleBorderColor

                topRightRadius: JamiTheme.messageBarRadius
                topLeftRadius: JamiTheme.messageBarRadius

                RowLayout {

                    anchors.fill: parent

                    Item {
                        id: containerContent

                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                        property bool isSelf: false
                        property var author: {
                            if (MessagesAdapter.replyToId === "")
                                return "";
                            var author = MessagesAdapter.dataForInteraction(MessagesAdapter.replyToId, MessageList.Author);
                            isSelf = author === "" || author === undefined;
                            if (isSelf) {
                                containerLabelAvatar.mode = Avatar.Mode.Account;
                                containerLabelAvatar.imageId = CurrentAccount.id;
                            } else {
                                containerLabelAvatar.mode = Avatar.Mode.Contact;
                                containerLabelAvatar.imageId = author;
                            }
                            return isSelf ? CurrentAccount.uri : author;
                        }

                        Label {
                            id: containerLabel

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter

                            text: {
                                if (MessagesAdapter.replyToId !== "") {
                                    return JamiStrings.replyTo;
                                } else if (MessagesAdapter.editId !== "") {
                                    return JamiStrings.editMessage;
                                }
                                return "";
                            }
                            textFormat: Text.MarkdownText
                            color: JamiTheme.textColor
                            opacity: 0.8

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true
                            font.bold: true
                        }

                        Avatar {
                            id: containerLabelAvatar

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: containerLabel.right
                            anchors.leftMargin: 12

                            visible: MessagesAdapter.replyToId !== ""

                            width: JamiTheme.messageBarReplyToAvatarSize
                            height: JamiTheme.messageBarReplyToAvatarSize

                            showPresenceIndicator: false

                            imageId: ""

                            mode: Avatar.Mode.Account
                        }

                        Label {
                            id: username

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: containerLabelAvatar.right
                            anchors.leftMargin: 8

                            TextMetrics {
                                id: textMetricsUsername
                                text: containerContent.author === CurrentAccount.uri ? CurrentAccount.bestName : UtilsAdapter.getBestNameForUri(CurrentAccount.id, containerContent.author)
                                elideWidth: 200
                                elide: Qt.ElideMiddle
                            }

                            text: textMetricsUsername.elidedText

                            wrapMode: Text.NoWrap

                            color: JamiTheme.textColor

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true
                            font.bold: true
                        }
                    }

                    NewIconButton {
                        id: closeContainerButton

                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        Layout.rightMargin: 12

                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: JamiResources.close_black_24dp_svg
                        toolTipText: JamiStrings.cancel

                        onClicked: {
                            if (MessagesAdapter.replyToId !== "") {
                                MessagesAdapter.replyToId = "";
                            } else if (MessagesAdapter.editId !== "") {
                                MessagesAdapter.editId = "";
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: messageRow

            property bool isExpanding: !(showTypo && dataTransferSendContainer.visible) && (textAreaObj.textWidth >= rectangle.width - formatRow.width - 8 * marginSize)

            Layout.fillWidth: true
            Layout.row: maximized || isExpanding ? 1 : 2
            Layout.column: 0
            Layout.columnSpan: maximized || isExpanding ? 2 : 1

            Layout.alignment: Qt.AlignTop
            Layout.rightMargin: 0
            Layout.leftMargin: marginSize / 2
            Layout.preferredHeight: Math.max(messageBarTextArea.contentHeight + 4, 36)
            Layout.maximumHeight: JamiTheme.messageBarMaximumHeight
            color: JamiTheme.transparentColor

            MessageBarTextArea {
                id: messageBarTextArea
                objectName: "messageBarTextArea"

                placeholderText: CurrentConversation.isTemporary ? JamiStrings.writeToNewContact.arg(CurrentConversation.title) : JamiStrings.writeTo.arg(CurrentConversation.title)

                anchors {
                    right: (showTypo) ? previewButton.left : messageRow.right
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    top: parent.top
                }

                // forward activeFocus to the actual text area object
                onActiveFocusChanged: {
                    if (activeFocus)
                        textAreaObj.forceActiveFocus();
                }

                onSendMessagesRequired: {
                    sendMessageButtonClicked();
                }

                property var markdownShortCut: {
                    "Bold": function () {
                        if (!showPreview) {
                            formatRow.listViewTypoFirst.itemAtIndex(0).action.triggered();
                        }
                    },
                    "Italic": function () {
                        if (!showPreview) {
                            formatRow.listViewTypoFirst.itemAtIndex(1).action.triggered();
                        }
                    },
                    "Strikethrough": function () {
                        if (!showPreview) {
                            formatRow.listViewTypoFirst.itemAtIndex(2).action.triggered();
                        }
                    },
                    "Heading": function () {
                        if (!showPreview) {
                            formatRow.listViewTypoFirst.itemAtIndex(3).action.triggered();
                        }
                    },
                    "Link": function () {
                        if (!showPreview) {
                            formatRow.listViewTypoFirst.itemAtIndex(4).action.triggered();
                        }
                    },
                    "Code": function () {
                        if (!showPreview) {
                            formatRow.listViewTypoFirst.itemAtIndex(5).action.triggered();
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
                    onActivated: messageBarTextArea.markdownShortCut["Strikethrough"]()
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

                visible: showTypo && messageBarTextArea.text
                anchors.top: parent.top
                anchors.right: parent.right
                preferredSize: JamiTheme.chatViewFooterButtonSize
                imageContainerWidth: 25
                imageContainerHeight: 25
                radius: 5
                source: JamiResources.preview_black_24dp_svg
                normalColor: showPreview ? hoveredColor : JamiTheme.primaryBackgroundColor
                imageColor: (hovered || showPreview) ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor
                hoveredColor: JamiTheme.hoveredButtonColor
                pressedColor: hoveredColor
                toolTipText: showPreview ? JamiStrings.continueEditing : JamiStrings.showPreview
                Layout.margins: 0

                onClicked: {
                    showPreview = !showPreview;
                    messageBarTextArea.showPreview = showPreview;
                    messageBarTextArea.forceActiveFocus();
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
            Layout.alignment: Qt.AlignBottom
            Layout.preferredHeight: filesToSendCount ? JamiTheme.layoutWidthFileTransfer : 0
            Layout.row: 1
            Layout.column: 0
            Layout.columnSpan: 2
        }

        MessageFormatBar {
            id: formatRow
            color: JamiTheme.transparentColor

            isEmojiPickerOpen: rectangle.isEmojiPickerOpen

            Layout.alignment: Qt.AlignBottom
            Layout.fillWidth: maximized ? true : false
            Layout.rightMargin: 0
            Layout.leftMargin: marginSize / 2
            Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize
            Layout.row: 2
            Layout.column: maximized ? 0 : 1
            Layout.columnSpan: maximized ? 2 : 1
        }
    }
}
