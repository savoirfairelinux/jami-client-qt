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
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    property alias text: textArea.text
    property var textAreaObj: textArea
    property real marginSize: JamiTheme.messageBarMarginSize
    property bool sendButtonVisibility: false
    property bool animate: false
    property bool showDefault: true
    property bool showTypo: false
    property bool showTypoSecond: false
    property color listViewButtonNormalColor: showDefault ? JamiTheme.messageInBgColor : JamiTheme.chatViewFooterShowMoreButtonColor
    property color listViewButtonImgColor: JamiTheme.chatViewFooterButtonImageColor

    property color showMoreNormalColor: showDefault ? JamiTheme.messageInBgColor : JamiTheme.showMoreOpenButtonColor
    property color showMoreImgColor: showDefault ? JamiTheme.blackColor : JamiTheme.showMoreOpenImgColor

    property color showTypoNormalColor: !showTypo ? JamiTheme.messageInBgColor : JamiTheme.showMoreOpenButtonColor
    property color showTypoImgColor: !showTypo ? JamiTheme.blackColor : JamiTheme.showMoreOpenImgColor

    property int messageBarLayoutMaximumWidth: 486

    signal sendMessageButtonClicked
    signal sendFileButtonClicked
    signal audioRecordMessageButtonClicked
    signal videoRecordMessageButtonClicked
    signal showMapClicked
    signal emojiButtonClicked

    //implicitHeight: messageBarHairLine.height + textArea.height + test.height//messageBarRowLayout_.height
    spacing: 0

    function instanceTypoObject() {
        var component = Qt.createComponent("qrc:/commoncomponents/MarkdownPopup.qml");
        var obj = component.createObject(parent, {
                "parent": showMoreTypoButton,
                "start": textArea.selectionStart,
                "end": textArea.selectionEnd,
                "text": root.text
            });
        obj.addStyle.connect(function (char1, char2) {
                listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, char1, char2);
            });
        obj.addSpecificStyle.connect(function (headerPrefix) {
                listViewTypo.addSpecificStyle(root.text, textArea.selectionStart, headerPrefix);
            });
        if (obj === null) {
            // Error Handling
            console.log("Error creating object");
        } else {
            obj.open();
        }
        instanceTypoObject.obj = obj;
    }

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
        Layout.margins: marginSize / 2
        Layout.preferredHeight: {
            return JamiTheme.chatViewFooterPreferredHeight > contentHeight ? JamiTheme.chatViewFooterPreferredHeight : contentHeight;
        }
        Layout.maximumHeight: JamiTheme.chatViewFooterTextAreaMaximumHeight - marginSize / 2

        onSendMessagesRequired: root.sendMessageButtonClicked()
        onTextChanged: MessagesAdapter.userIsComposing(text ? true : false)
    }

    onShowTypoSecondChanged: {
        if (showTypoSecond) {
            if (instanceTypoObject.obj !== undefined) {
                instanceTypoObject.obj.close();
            }
        }
    }

    Item {
        id: test
        Layout.fillWidth: true
        Layout.maximumWidth: JamiTheme.chatViewMaximumWidth
        Layout.bottomMargin: JamiTheme.preferredMarginSize
        Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize

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
                    imageContainerWidth: 20
                    imageContainerHeight: 20

                    radius: JamiTheme.chatViewFooterButtonRadius

                    toolTipText: "new text format"

                    source: JamiResources.text_edit_svg

                    normalColor: showTypoNormalColor
                    imageColor: showTypoImgColor
                    pressedColor: JamiTheme.showMoreOpenButtonColor
                    hoveredColor: JamiTheme.showMoreOpenButtonColor

                    onClicked: {
                        showTypo = !showTypo;
                        if (test.width < messageBarLayoutMaximumWidth + sendButtonRow.width + 2 * JamiTheme.preferredMarginSize)
                            showTypoSecond = false;
                        if (!showDefault)
                            showDefault = true;
                    }
                }

                Row {
                    id: listViewTypo
                    height: JamiTheme.chatViewFooterButtonSize

                    //width: ( listViewTypoFirst.count + listViewTypoSecond.count ) * 36 + 10
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

                    function addSpecificStyle(text, start, headerPrefix) {
                        var lineStart = start;
                        while (lineStart > 0 && text.charAt(lineStart - 1) !== '\n') {
                            lineStart--;
                        }
                        var lineHasHeader = text.startsWith(headerPrefix, lineStart);
                        if (lineHasHeader) {
                            // If the line already has a header, remove it
                            root.text = text.substring(0, lineStart) + text.substring(lineStart + headerPrefix.length);
                            textArea.selectText(start - headerPrefix.length, start - headerPrefix.length);
                        } else {
                            // Otherwise, add the header prefix to the line
                            root.text = text.substring(0, lineStart) + headerPrefix + text.substring(lineStart);
                            textArea.selectText(start + headerPrefix.length, start + headerPrefix.length);
                        }
                    }

                    ListView {
                        id: listViewTypoFirst

                        visible: showTypo

                        width: count * 36 + 10
                        height: JamiTheme.chatViewFooterButtonSize
                        orientation: ListView.Horizontal
                        interactive: false
                        leftMargin: 10
                        spacing: 10

                        Rectangle {
                            anchors.fill: parent
                            color: JamiTheme.chatViewFooterShowMoreButtonColor
                            z: -1
                        }

                        property list<Action> menuTypoActionsFirst: [
                            Action {
                                id: boldAction
                                property var iconSrc: JamiResources.bold_svg
                                property var toolTip: JamiStrings.bold
                                property int start: textArea.selectionStart
                                property int end: textArea.selectionEnd
                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "**", "**");
                                }
                            },
                            Action {
                                id: italicAction
                                property var iconSrc: JamiResources.italic_svg
                                property var toolTip: JamiStrings.italic
                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "*", "*");
                                }
                            },
                            Action {
                                id: barreAction
                                property var iconSrc: JamiResources.barre_svg
                                property var toolTip: JamiStrings.barre
                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "~~", "~~");
                                }
                            },
                            Action {
                                id: titleAction
                                property var iconSrc: JamiResources.title_svg
                                property var toolTip: JamiStrings.title
                                onTriggered: function clickAction() {
                                    listViewTypo.addSpecificStyle(root.text, textArea.selectionStart, "### ");
                                }
                            }
                        ]

                        model: menuTypoActionsFirst

                        delegate: PushButton {
                            anchors.verticalCenter: parent.verticalCenter

                            preferredSize: JamiTheme.chatViewFooterRealButtonSize
                            imageContainerWidth: 10
                            imageContainerHeight: 10
                            radius: 5

                            toolTipText: modelData.toolTip
                            source: modelData.iconSrc

                            normalColor: JamiTheme.chatViewFooterShowMoreButtonColor
                            imageColor: hovered ? JamiTheme.tintedBlue : listViewButtonImgColor
                            hoveredColor: JamiTheme.showMoreOpenButtonColor
                            pressedColor: JamiTheme.showMoreOpenButtonColor

                            action: modelData
                        }
                    }

                    Rectangle {
                        width: 2
                        height: JamiTheme.chatViewFooterButtonSize
                        color: JamiTheme.chatViewFooterShowMoreButtonColor
                        visible: showTypo && showTypoSecond

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: JamiTheme.chatViewFooterButtonSize / 2
                            color: "#b2cce0"
                        }
                    }

                    Rectangle {
                        z: -1
                        radius: 0
                        color: JamiTheme.chatViewFooterShowMoreButtonColor
                        width: JamiTheme.chatViewFooterButtonSize
                        height: JamiTheme.chatViewFooterButtonSize
                        visible: showTypo && !showTypoSecond

                        PushButton {
                            id: showMoreTypoButton

                            anchors.verticalCenter: parent.verticalCenter
                            preferredSize: JamiTheme.chatViewFooterRealButtonSize
                            imageContainerWidth: 12
                            imageContainerHeight: 12

                            radius: JamiTheme.chatViewFooterButtonRadius

                            toolTipText: JamiStrings.showMore

                            source: JamiResources.more_vert_24dp_svg

                            normalColor: JamiTheme.chatViewFooterShowMoreButtonColor
                            imageColor: hovered ? JamiTheme.tintedBlue : listViewButtonImgColor
                            hoveredColor: JamiTheme.showMoreOpenButtonColor
                            pressedColor: JamiTheme.showMoreOpenButtonColor

                            onClicked: instanceTypoObject()
                        }
                    }

                    ListView {
                        id: listViewTypoSecond

                        visible: showTypo && showTypoSecond

                        width: count * 36 + 10
                        height: JamiTheme.chatViewFooterButtonSize
                        orientation: ListView.Horizontal
                        interactive: false
                        leftMargin: 10
                        spacing: 10

                        Rectangle {
                            anchors.fill: parent
                            color: JamiTheme.chatViewFooterShowMoreButtonColor
                            z: -1
                        }

                        property list<Action> menuTypoActionsSecond: [
                            Action {
                                id: linkAction
                                property var iconSrc: JamiResources.link_svg
                                property var toolTip: JamiStrings.link
                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "[", "](url)");
                                }
                            },
                            Action {
                                id: codeAction
                                property var iconSrc: JamiResources.code_svg
                                property var toolTip: JamiStrings.code
                                onTriggered: function clickAction() {
                                    listViewTypo.addStyle(root.text, textArea.selectionStart, textArea.selectionEnd, "```", "```");
                                }
                            },
                            Action {
                                id: quoteAction
                                property var iconSrc: JamiResources.quote_svg
                                property var toolTip: JamiStrings.quote
                                onTriggered: function clickAction() {
                                    listViewTypo.addSpecificStyle(root.text, textArea.selectionStart, "> ");
                                }
                            },
                            Action {
                                id: bulletPointAction
                                property var iconSrc: JamiResources.bullet_point_svg
                                property var toolTip: JamiStrings.bulletPoint
                                onTriggered: function clickAction() {
                                    listViewTypo.addSpecificStyle(root.text, textArea.selectionStart, "- ");
                                }
                            },
                            Action {
                                id: bulletNumberAction
                                property var iconSrc: JamiResources.bullet_number_svg
                                property var toolTip: JamiStrings.bulletNumber
                                onTriggered: function clickAction() {
                                    listViewTypo.addSpecificStyle(root.text, textArea.selectionStart, "1. ");
                                }
                            }
                        ]

                        model: menuTypoActionsSecond

                        delegate: PushButton {
                            anchors.verticalCenter: parent.verticalCenter

                            preferredSize: JamiTheme.chatViewFooterRealButtonSize
                            imageContainerWidth: 10
                            imageContainerHeight: 10
                            radius: 5

                            toolTipText: modelData.toolTip
                            source: modelData.iconSrc

                            normalColor: JamiTheme.chatViewFooterShowMoreButtonColor
                            imageColor: hovered ? JamiTheme.tintedBlue : listViewButtonImgColor
                            hoveredColor: JamiTheme.showMoreOpenButtonColor
                            pressedColor: JamiTheme.showMoreOpenButtonColor

                            action: modelData
                        }
                    }
                }
            }

            Row {

                ListView {
                    id: listViewAction

                    width: count * 36 + 10
                    height: JamiTheme.chatViewFooterButtonSize
                    orientation: ListView.Horizontal
                    interactive: false

                    leftMargin: 10
                    spacing: 10

                    Rectangle {
                        anchors.fill: parent
                        color: listViewButtonNormalColor
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
                            print(listViewAction.menuActions.length);
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

                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        preferredSize: JamiTheme.chatViewFooterRealButtonSize
                        imageContainerWidth: 20
                        imageContainerHeight: 20
                        radius: 5

                        toolTipText: modelData.toolTip
                        source: modelData.iconSrc

                        normalColor: listViewButtonNormalColor
                        imageColor: showDefault ? JamiTheme.blackColor : listViewButtonImgColor
                        hoveredColor: showDefault ? "#cccccc" : JamiTheme.showMoreOpenButtonColor
                        pressedColor: JamiTheme.showMoreOpenButtonColor

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

                        toolTipText: JamiStrings.showMore

                        source: JamiResources.more_vert_24dp_svg

                        normalColor: showMoreNormalColor
                        hoveredColor: JamiTheme.showMoreOpenButtonColor
                        pressedColor: JamiTheme.showMoreOpenButtonColor
                        imageColor: showMoreImgColor

                        onClicked: {
                            showDefault = !showDefault;
                            if (showTypo)
                                showTypo = false;
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

                normalColor: JamiTheme.tintedBlue
                imageColor: JamiTheme.whiteColor

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
