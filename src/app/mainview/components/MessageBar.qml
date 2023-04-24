/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

ColumnLayout {
    id: root

    property alias text: textArea.text
    property var textAreaObj: textArea
    property real marginSize: JamiTheme.messageBarMarginSize
    property bool sendButtonVisibility: false
    property bool animate: false
    property bool showDefault: !UtilsAdapter.getAppValue(Settings.Key.ShowSendOption)
    property bool showTypo: UtilsAdapter.getAppValue(Settings.Key.ShowMardownOption)
    property bool showTypoSecond: false

    property int messageBarLayoutMaximumWidth: 486

    signal sendMessageButtonClicked
    signal sendFileButtonClicked
    signal audioRecordMessageButtonClicked
    signal videoRecordMessageButtonClicked
    signal showMapClicked
    signal emojiButtonClicked

    spacing: 5

    Rectangle {
        id: messageBarHairLine

        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        Layout.preferredHeight: JamiTheme.chatViewHairLineSize
        Layout.fillWidth: true

        color: JamiTheme.tabbarBorderColor
    }

    MessageBarTextArea {
        id: textArea

        objectName: "messageBarTextArea"

        // forward activeFocus to the actual text area object
        onActiveFocusChanged: {
            if (activeFocus)
                textAreaObj.forceActiveFocus();
        }

        placeholderText: JamiStrings.writeTo.arg(CurrentConversation.title)

        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        Layout.leftMargin: marginSize / 2
        Layout.rightMargin: marginSize / 2
        Layout.preferredHeight: {
            return JamiTheme.chatViewFooterPreferredHeight > contentHeight ? JamiTheme.chatViewFooterPreferredHeight : contentHeight;
        }
        Layout.maximumHeight: JamiTheme.chatViewFooterTextAreaMaximumHeight - marginSize / 2

        onSendMessagesRequired: root.sendMessageButtonClicked()
        onTextChanged: MessagesAdapter.userIsComposing(text ? true : false)

        property var markdownShortCut: {
            "Bold": function () {
                listViewTypoFirst.itemAtIndex(0).action.triggered();
            },
            "Italic": function () {
                listViewTypoFirst.itemAtIndex(1).action.triggered();
            },
            "Barre": function () {
                listViewTypoFirst.itemAtIndex(2).action.triggered();
            },
            "Heading": function () {
                listViewTypoFirst.itemAtIndex(3).action.triggered();
            },
            "Link": function () {
                listViewTypoSecond.itemAtIndex(0).action.triggered();
            },
            "Code": function () {
                listViewTypoSecond.itemAtIndex(1).action.triggered();
            },
            "Quote": function () {
                listViewTypoSecond.itemAtIndex(2).action.triggered();
            },
            "Bulleted List": function () {
                listViewTypoSecond.itemAtIndex(3).action.triggered();
            },
            "Numbered List": function () {
                listViewTypoSecond.itemAtIndex(4).action.triggered();
            }
        }

        Shortcut {
            sequence: "Ctrl+B"
            context: Qt.ApplicationShortcut
            onActivated: textArea.markdownShortCut["Bold"]()
        }

        Shortcut {
            sequence: "Ctrl+I"
            context: Qt.ApplicationShortcut
            onActivated: textArea.markdownShortCut["Italic"]()
        }

        Shortcut {
            sequence: "Shift+Alt+X"
            context: Qt.ApplicationShortcut
            onActivated: textArea.markdownShortCut["Barre"]()
        }

        Shortcut {
            sequence: "Ctrl+Alt+H"
            context: Qt.ApplicationShortcut
            onActivated: textArea.markdownShortCut["Heading"]()
        }

        Shortcut {
            sequence: "Ctrl+Alt+K"
            context: Qt.ApplicationShortcut
            onActivated: textArea.markdownShortCut["Link"]()
        }

        Shortcut {
            sequence: "Ctrl+Alt+C"
            context: Qt.ApplicationShortcut
            onActivated: textArea.markdownShortCut["Code"]()
        }

        Shortcut {
            sequence: "Shift+Alt+9"
            context: Qt.ApplicationShortcut
            onActivated: textArea.markdownShortCut["Quote"]()
        }

        Shortcut {
            sequence: "Shift+Alt+8"
            context: Qt.ApplicationShortcut
            onActivated: textArea.markdownShortCut["Bulleted List"]()
        }

        Shortcut {
            sequence: "Shift+Alt+7"
            context: Qt.ApplicationShortcut
            onActivated: textArea.markdownShortCut["Numbered List"]()
        }
    }

    Item {
        id: messageBar
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize
        Layout.leftMargin: marginSize
        Layout.bottomMargin: marginSize

        onWidthChanged: {
            if (width < messageBarRowLayout.width + sendButtonRow.width + 2 * JamiTheme.preferredMarginSize) {
                showTypoSecond = false;
            } else {
                if (width > 2 * messageBarRowLayout.width) {
                    showTypoSecond = true;
                }
            }
        }

        RowLayout {
            id: messageBarRowLayout

            spacing: JamiTheme.chatViewFooterRowSpacing

            Row {

                PushButton {
                    id: typoButton

                    preferredSize: JamiTheme.chatViewFooterButtonSize
                    imageContainerWidth: 24
                    imageContainerHeight: 24

                    radius: JamiTheme.chatViewFooterButtonRadius

                    toolTipText: showTypo ? JamiStrings.hideFormating : JamiStrings.showFormating
                    source: JamiResources.text_edit_black_24dp_svg

                    normalColor: !showTypo ? JamiTheme.chatViewFooterListColor : JamiTheme.showMoreButtonOpenColor
                    imageColor: JamiTheme.chatViewFooterImgColor
                    pressedColor: JamiTheme.showMoreButtonOpenColor
                    hoveredColor: JamiTheme.showMoreButtonOpenColor

                    onClicked: {
                        showTypo = !showTypo;
                        if (messageBar.width < messageBarLayoutMaximumWidth + sendButtonRow.width + 2 * JamiTheme.preferredMarginSize)
                            showTypoSecond = false;
                        if (!showDefault)
                            showDefault = true;
                        UtilsAdapter.setAppValue(Settings.Key.ShowMardownOption, showTypo);
                        UtilsAdapter.setAppValue(Settings.Key.ShowSendOption, !showDefault);
                    }

                    Rectangle {
                        visible: showTypo

                        anchors.fill: parent
                        anchors.leftMargin: 3
                        anchors.rightMargin: -5
                        color: JamiTheme.showMoreButtonOpenColor
                        z: -2
                    }
                }

                Row {
                    id: listViewTypo
                    height: JamiTheme.chatViewFooterButtonSize

                    function addStyle(text, start, end, char1, char2) {
                        // get the selected text with markdown effect
                        var selectedText = text.substring(start - char1.length, end + char2.length);
                        if (selectedText.startsWith(char1) && selectedText.endsWith(char2)) {
                            // If the selected text is already formatted with the given characters, remove them
                            selectedText = text.substring(start, end);
                            root.text = text.substring(0, start - char1.length) + selectedText + text.substring(end + char2.length);
                            textArea.selectText(start - char1.length, end - char1.length);
                        } else {
                            // Otherwise, add the formatting characters to the selected text
                            root.text = text.substring(0, start) + char1 + text.substring(start, end) + char2 + text.substring(end);
                            textArea.selectText(start + char1.length, end + char1.length);
                        }
                    }

                    function addPrefixStyle(message, selectionStart, selectionEnd, delimiter, isBulletNumber) {

                        //represents all the selected lines
                        var multilineSelection;
                        var newPrefix;
                        var newSuffix;
                        var newStartPos;
                        var newEndPos;
                        function nextIndexOf(text, char1, startPos) {
                            return text.indexOf(char1, startPos + 1);
                        }

                        //get the previous index of the multilineSelection text
                        if (message[selectionStart] === "\n")
                            newStartPos = message.lastIndexOf('\n', selectionStart - 1);
                        else
                            newStartPos = message.lastIndexOf('\n', selectionStart);

                        //get the next index of the multilineSelection text
                        if (message[selectionEnd] === "\n" || message[selectionEnd] === undefined)
                            newEndPos = selectionEnd;
                        else
                            newEndPos = nextIndexOf(message, "\n", selectionEnd);

                        //if the text is empty
                        if (newStartPos === -1)
                            newStartPos = 0;
                        newPrefix = message.slice(0, newStartPos);
                        multilineSelection = message.slice(newStartPos, newEndPos);
                        newSuffix = message.slice(newEndPos);
                        var isFirstLineSelected = !multilineSelection.startsWith('\n') || newPrefix === "";
                        var getDelimiter_counter = 1;
                        function getDelimiter() {
                            return `${getDelimiter_counter++}. `;
                        }
                        function getHasCurrentMarkdown() {
                            const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
                            const newLinesWithDelimitersQuantity = (multilineSelection.match(new RegExp(`\n${delimiter}`, 'g')) || []).length;
                            if (newLinesWithDelimitersQuantity === linesQuantity && !isFirstLineSelected)
                                return true;
                            return linesQuantity === newLinesWithDelimitersQuantity && multilineSelection.startsWith(delimiter);
                        }
                        function getHasCurrentMarkdownBullet() {
                            const linesQuantity = (multilineSelection.match(/\n/g) || []).length;
                            const newLinesWithDelimitersQuantity = (multilineSelection.match(/\n\d+\. /g) || []).length;
                            if (newLinesWithDelimitersQuantity === linesQuantity && !isFirstLineSelected)
                                return true;
                            return linesQuantity === newLinesWithDelimitersQuantity && (/^\d\. /).test(multilineSelection);
                        }
                        var newValue;
                        var newStart;
                        var newEnd;
                        var count;
                        var startPos;
                        var multilineSelectionLength;
                        if (!isBulletNumber) {
                            if (getHasCurrentMarkdown()) {

                                // clear first line from delimiter
                                if (isFirstLineSelected)
                                    multilineSelection = multilineSelection.slice(delimiter.length);
                                newValue = newPrefix + multilineSelection.replace(new RegExp(`\n${delimiter}`, 'g'), '\n') + newSuffix;
                                count = 0;
                                if (isFirstLineSelected)
                                    count++;
                                count += (multilineSelection.match(/\n/g) || []).length;
                                newStart = Math.max(selectionStart - delimiter.length, 0);
                                newEnd = Math.max(selectionEnd - (delimiter.length * count), 0);
                            } else {
                                newValue = newPrefix + multilineSelection.replace(/\n/g, `\n${delimiter}`) + newSuffix;
                                count = 0;
                                if (isFirstLineSelected) {
                                    newValue = delimiter + newValue;
                                    count++;
                                }
                                count += (multilineSelection.match(new RegExp('\\n', 'g')) || []).length;
                                newStart = selectionStart + delimiter.length;
                                newEnd = selectionEnd + (delimiter.length * count);
                            }
                        } else if (getHasCurrentMarkdownBullet()) {
                            if (message[selectionStart] === "\n")
                                startPos = message.lastIndexOf('\n', selectionStart - 1) + 1;
                            else
                                startPos = message.lastIndexOf('\n', selectionStart) + 1;
                            newStart = startPos;
                            multilineSelection = multilineSelection.replace(/^\d+\.\s/gm, '');
                            newValue = newPrefix + multilineSelection + newSuffix;
                            multilineSelectionLength = multilineSelection.length;

                            //if the first line is not selected, we need to remove the first "\n" of multilineSelection
                            if (newStart)
                                multilineSelectionLength = multilineSelection.length - 1;
                            newEnd = Math.max(newStart + multilineSelectionLength, 0);
                        } else {
                            if (message[selectionStart] === "\n")
                                startPos = message.lastIndexOf('\n', selectionStart - 1) + 1;
                            else
                                startPos = message.lastIndexOf('\n', selectionStart) + 1;
                            newStart = startPos;

                            // if no text is selected
                            if (selectionStart === selectionEnd)
                                newStart = newStart + 3;
                            if (isFirstLineSelected)
                                multilineSelection = getDelimiter() + multilineSelection;
                            const selectionArr = Array.from(multilineSelection);
                            for (var i = 0; i < selectionArr.length; i++) {
                                if (selectionArr[i] === '\n')
                                    selectionArr[i] = `\n${getDelimiter()}`;
                            }
                            multilineSelection = selectionArr.join('');
                            newValue = newPrefix + multilineSelection + newSuffix;
                            multilineSelectionLength = multilineSelection.length;

                            //if the first line is not selected, we meed to remove the first "\n" of multilineSelection
                            if (startPos)
                                multilineSelectionLength = multilineSelection.length - 1;
                            newEnd = Math.max(startPos + multilineSelectionLength, 0);
                        }
                        root.text = newValue;
                        textArea.selectText(newStart, newEnd);
                    }

                    ListView {
                        id: listViewTypoFirst

                        objectName: "listViewTypoFirst"

                        visible: width > 0
                        width: showTypo ? contentWidth + 2 * leftMargin : 0

                        Behavior on width  {
                            NumberAnimation {
                                duration: JamiTheme.longFadeDuration
                            }
                        }

                        height: JamiTheme.chatViewFooterButtonSize
                        orientation: ListView.Horizontal
                        interactive: false
                        leftMargin: 10
                        rightMargin: 10
                        spacing: 10

                        Rectangle {
                            anchors.fill: parent
                            color: JamiTheme.chatViewFooterListColor
                            z: -1
                        }

                        property list<Action> menuTypoActionsFirst: [
                            Action {
                                id: boldAction
                                property var iconSrc: JamiResources.bold_black_24dp_svg
                                property var shortcutText: JamiStrings.bold
                                property string shortcutKey: "Ctrl+B"

                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "**", "**");
                                }
                            },
                            Action {
                                id: italicAction
                                property var iconSrc: JamiResources.italic_black_24dp_svg
                                property var shortcutText: JamiStrings.italic
                                property string shortcutKey: "Ctrl+I"
                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "*", "*");
                                }
                            },
                            Action {
                                id: barreAction
                                property var iconSrc: JamiResources.s_barre_black_24dp_svg
                                property var shortcutText: JamiStrings.barre
                                property string shortcutKey: "Shift+Alt+X"
                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "~~", "~~");
                                }
                            },
                            Action {
                                id: titleAction
                                property var iconSrc: JamiResources.title_black_24dp_svg
                                property var shortcutText: JamiStrings.title
                                property string shortcutKey: "Ctrl+Alt+H"
                                onTriggered: function clickAction() {
                                    listViewTypo.addPrefixStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "### ", false);
                                }
                            }
                        ]

                        model: menuTypoActionsFirst

                        delegate: PushButton {
                            anchors.verticalCenter: parent.verticalCenter

                            preferredSize: JamiTheme.chatViewFooterRealButtonSize
                            imageContainerWidth: 15
                            imageContainerHeight: 15
                            radius: 5

                            toolTipText: modelData.shortcutText
                            shortcutKey: modelData.shortcutKey
                            hasShortcut: true

                            source: modelData.iconSrc

                            normalColor: JamiTheme.chatViewFooterListColor
                            imageColor: JamiTheme.chatViewFooterImgColor
                            hoveredColor: JamiTheme.showMoreButtonOpenColor
                            pressedColor: hoveredColor

                            action: modelData
                        }
                    }

                    Rectangle {

                        height: JamiTheme.chatViewFooterButtonSize
                        color: JamiTheme.chatViewFooterListColor
                        visible: width > 0
                        width: showTypo && showTypoSecond ? 2 : 0

                        Behavior on width  {
                            NumberAnimation {
                                duration: JamiTheme.longFadeDuration
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: JamiTheme.chatViewFooterButtonSize / 2
                            color: JamiTheme.chatViewFooterSeparateLineColor
                        }
                    }

                    Rectangle {
                        z: -1
                        radius: 0
                        color: JamiTheme.chatViewFooterListColor
                        width: JamiTheme.chatViewFooterButtonSize
                        height: JamiTheme.chatViewFooterButtonSize

                        visible: showTypo && !showTypoSecond

                        ComboBox {
                            id: showMoreTypoButton
                            width: JamiTheme.chatViewFooterRealButtonSize
                            height: width
                            anchors.verticalCenter: parent.verticalCenter

                            MaterialToolTip {
                                id: toolTip

                                parent: showMoreTypoButton
                                visible: showMoreTypoButton.hovered && (text.length > 0)
                                delay: Qt.styleHints.mousePressAndHoldInterval
                                text: JamiStrings.showMore
                            }

                            background: Rectangle {
                                implicitWidth: showMoreTypoButton.width
                                implicitHeight: showMoreTypoButton.height
                                radius: 5
                                color: showMoreTypoButton.popup.opened || showMoreTypoButton.hovered ? JamiTheme.showMoreButtonOpenColor : JamiTheme.chatViewFooterListColor
                            }

                            indicator: ResponsiveImage {
                                containerHeight: 20
                                containerWidth: 20
                                width: 18
                                height: 18

                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter

                                source: JamiResources.more_vert_24dp_svg

                                color: JamiTheme.chatViewFooterImgColor
                            }

                            popup: MarkdownPopup {
                                y: 1.5 * parent.height
                                x: -parent.width * 3
                                width: 190
                                height: JamiTheme.chatViewFooterButtonSize

                                menuTypoActionsSecond: listViewTypoSecond.menuTypoActionsSecond
                            }
                        }
                    }

                    ListView {
                        id: listViewTypoSecond
                        visible: width > 0
                        width: showTypo && showTypoSecond ? contentWidth + 2 * leftMargin : 0

                        Behavior on width  {
                            NumberAnimation {
                                duration: JamiTheme.longFadeDuration
                            }
                        }

                        height: JamiTheme.chatViewFooterButtonSize
                        orientation: ListView.Horizontal
                        interactive: false
                        leftMargin: 10
                        rightMargin: 10
                        spacing: 10

                        Rectangle {
                            anchors.fill: parent
                            color: JamiTheme.chatViewFooterListColor
                            z: -1
                        }

                        property list<Action> menuTypoActionsSecond: [
                            Action {
                                id: linkAction
                                property var iconSrc: JamiResources.link_web_black_24dp_svg
                                property var shortcutText: JamiStrings.link
                                property string shortcutKey: "Ctrl+Alt+K"
                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "[", "](url)");
                                }
                            },
                            Action {
                                id: codeAction
                                property var iconSrc: JamiResources.code_black_24dp_svg
                                property var shortcutText: JamiStrings.code
                                property string shortcutKey: "Ctrl+Alt+C"
                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "```", "```");
                                }
                            },
                            Action {
                                id: quoteAction
                                property var iconSrc: JamiResources.quote_black_24dp_svg
                                property var shortcutText: JamiStrings.quote
                                property string shortcutKey: "Shift+Alt+9"
                                onTriggered: function clickAction() {
                                    listViewTypo.addPrefixStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "> ", false);
                                }
                            },
                            Action {
                                id: bulletPointAction
                                property var iconSrc: JamiResources.bullet_point_black_24dp_svg
                                property var shortcutText: JamiStrings.bulletPoint
                                property string shortcutKey: "Shift+Alt+8"
                                onTriggered: function clickAction() {
                                    listViewTypo.addPrefixStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "- ", false);
                                }
                            },
                            Action {
                                id: bulletNumberAction
                                property var iconSrc: JamiResources.bullet_number_black_24dp_svg
                                property var shortcutText: JamiStrings.bulletNumber
                                property string shortcutKey: "Shift+Alt+7"
                                onTriggered: function clickAction() {
                                    listViewTypo.addPrefixStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "", true);
                                }
                            }
                        ]

                        model: menuTypoActionsSecond

                        delegate: PushButton {
                            anchors.verticalCenter: parent.verticalCenter

                            preferredSize: JamiTheme.chatViewFooterRealButtonSize
                            imageContainerWidth: 20
                            imageContainerHeight: 20
                            radius: 5

                            toolTipText: modelData.shortcutText
                            shortcutKey: modelData.shortcutKey
                            hasShortcut: true
                            source: modelData.iconSrc

                            normalColor: JamiTheme.chatViewFooterListColor
                            imageColor: JamiTheme.chatViewFooterImgColor
                            hoveredColor: JamiTheme.showMoreButtonOpenColor
                            pressedColor: hoveredColor

                            action: modelData
                        }
                    }
                }
            }

            Row {

                ListView {
                    id: listViewAction

                    width: contentWidth + 2 * leftMargin

                    Behavior on width  {
                        NumberAnimation {
                            duration: JamiTheme.longFadeDuration
                        }
                    }

                    height: JamiTheme.chatViewFooterButtonSize
                    orientation: ListView.Horizontal
                    interactive: false

                    leftMargin: 10
                    rightMargin: 10
                    spacing: 10

                    Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.chatViewFooterListColor
                        z: -1
                    }

                    property list<Action> menuActions: [
                        Action {
                            id: sendFile
                            property var iconSrc: JamiResources.link_black_24dp_svg
                            property var toolTip: JamiStrings.sendFile
                            property bool show: true
                            property bool needWebEngine: false
                            property bool needVideoDevice: false
                            property bool noSip: false
                            onTriggered: function clickAction() {
                                sendFileButtonClicked();
                            }
                        },
                        Action {
                            id: addEmoji
                            property var iconSrc: JamiResources.emoji_black_24dp_svg
                            property var toolTip: JamiStrings.addEmoji
                            property bool show: true
                            property bool needWebEngine: true
                            property bool needVideoDevice: false
                            property bool noSip: true
                            onTriggered: function clickAction() {
                                emojiButtonClicked();
                            }
                        },
                        Action {
                            id: leaveAudioMessage
                            property var iconSrc: JamiResources.message_audio_black_24dp_svg
                            property var toolTip: JamiStrings.leaveAudioMessage
                            property bool show: false
                            property bool needWebEngine: false
                            property bool needVideoDevice: false
                            property bool noSip: false
                            onTriggered: function clickAction() {
                                audioRecordMessageButtonClicked();
                            }
                        },
                        Action {
                            id: leaveVideoMessage
                            property var iconSrc: JamiResources.message_video_black_24dp_svg
                            property var toolTip: JamiStrings.leaveVideoMessage
                            property bool show: false
                            property bool needWebEngine: false
                            property bool needVideoDevice: true
                            property bool noSip: false
                            onTriggered: function clickAction() {
                                videoRecordMessageButtonClicked();
                            }
                        },
                        Action {
                            id: shareLocation
                            property var iconSrc: JamiResources.localisation_sharing_send_pin_svg
                            property var toolTip: JamiStrings.shareLocation
                            property bool show: false
                            property bool needWebEngine: false
                            property bool needVideoDevice: false
                            property bool noSip: false
                            onTriggered: function clickAction() {
                                showMapClicked();
                            }
                        }
                    ]

                    ListModel {
                        id: listActions
                        Component.onCompleted: {
                            for (var i = 0; i < listViewAction.menuActions.length; i++) {
                                append({
                                        "menuAction": listViewAction.menuActions[i]
                                    });
                            }
                        }
                    }

                    model: SortFilterProxyModel {
                        sourceModel: listActions
                        filters: [
                            ExpressionFilter {
                                expression: menuAction.show === true
                                enabled: root.showDefault
                            },
                            ExpressionFilter {
                                expression: menuAction.needWebEngine === false
                                enabled: !WITH_WEBENGINE
                            },
                            ExpressionFilter {
                                expression: menuAction.noSip === true
                                enabled: CurrentConversation.isSip
                            },
                            ExpressionFilter {
                                expression: menuAction.needVideoDevice === false
                                enabled: VideoDevices.listSize === 0
                            }
                        ]
                    }

                    delegate: PushButton {
                        id: buttonDelegate
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        preferredSize: JamiTheme.chatViewFooterRealButtonSize
                        imageContainerWidth: 20
                        imageContainerHeight: 20
                        radius: 5

                        toolTipText: modelData.toolTip
                        source: modelData.iconSrc

                        normalColor: JamiTheme.chatViewFooterListColor
                        imageColor: JamiTheme.chatViewFooterImgColor
                        hoveredColor: JamiTheme.showMoreButtonOpenColor
                        pressedColor: hoveredColor

                        action: modelData
                    }
                }

                Rectangle {
                    z: -1
                    radius: 0
                    color: showMoreButton.normalColor
                    width: JamiTheme.chatViewFooterButtonSize / 2
                    height: JamiTheme.chatViewFooterButtonSize

                    PushButton {
                        id: showMoreButton
                        anchors.left: parent.left

                        preferredSize: JamiTheme.chatViewFooterButtonSize
                        imageContainerWidth: 20
                        imageContainerHeight: 20

                        radius: JamiTheme.chatViewFooterButtonRadius

                        toolTipText: showDefault ? JamiStrings.showMore : JamiStrings.showLess

                        source: JamiResources.more_vert_24dp_svg

                        normalColor: showDefault ? JamiTheme.chatViewFooterListColor : JamiTheme.showMoreButtonOpenColor
                        imageColor: JamiTheme.chatViewFooterImgColor
                        pressedColor: JamiTheme.showMoreButtonOpenColor
                        hoveredColor: JamiTheme.showMoreButtonOpenColor

                        onClicked: {
                            showDefault = !showDefault;
                            if (showTypo)
                                showTypo = false;
                            UtilsAdapter.setAppValue(Settings.Key.ShowMardownOption, showTypo);
                            UtilsAdapter.setAppValue(Settings.Key.ShowSendOption, !showDefault);
                        }
                    }
                }
            }
        }

        Row {
            id: sendButtonRow
            spacing: JamiTheme.chatViewFooterRowSpacing
            anchors.right: parent.right
            anchors.rightMargin: sendMessageButton.visible ? marginSize : 0

            PushButton {
                id: sendMessageButton

                objectName: "sendMessageButton"

                width: scale * JamiTheme.chatViewFooterButtonSize
                height: JamiTheme.chatViewFooterButtonSize

                radius: JamiTheme.chatViewFooterButtonRadius
                preferredSize: JamiTheme.chatViewFooterButtonIconSize - 6
                imageContainerWidth: 25
                imageContainerHeight: 25

                toolTipText: JamiStrings.send

                source: JamiResources.send_black_24dp_svg

                normalColor: JamiTheme.chatViewFooterSendButtonColor
                imageColor: JamiTheme.chatViewFooterSendButtonImgColor
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: hoveredColor

                opacity: sendButtonVisibility ? 1 : 0
                visible: opacity
                scale: opacity

                Behavior on opacity  {
                    enabled: animate
                    NumberAnimation {
                        duration: JamiTheme.shortFadeDuration
                        easing.type: Easing.InOutQuad
                    }
                }

                onClicked: root.sendMessageButtonClicked()
            }
        }
    }
}
