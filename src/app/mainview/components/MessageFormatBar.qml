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
    id: messageBarRowLayout
    Layout.preferredWidth: showTypo ? firstRow.width + secondRow.width : secondRow.width
    LayoutMirroring.enabled: UtilsAdapter.isRTL
    LayoutMirroring.childrenInherit: true

    property alias listViewTypoFirst: listViewTypoFirst
    property bool isEmojiPickerOpen

    Row {
        id: firstRow

        anchors.left: messageBarRowLayout.left
        anchors.bottom: messageBarRowLayout.bottom

        Row {
            id: listViewTypo
            height: JamiTheme.chatViewFooterButtonSize

            spacing: JamiTheme.messageBarSpacing

            ListView {
                id: listViewTypoFirst
                objectName: "listViewTypoFirst"

                visible: showTypo
                width: visible ? contentWidth + 2 * leftMargin : 0

                Behavior on width {
                    NumberAnimation {
                        duration: JamiTheme.longFadeDuration / 2
                    }
                }

                height: JamiTheme.chatViewFooterButtonSize
                orientation: ListView.Horizontal
                interactive: false

                spacing: JamiTheme.messageBarSpacing

                property list<Action> menuTypoActionsFirst: [
                    Action {
                        id: boldAction
                        property string iconSrc: JamiResources.bold_black_24dp_svg
                        property string shortcutText: JamiStrings.bold
                        property string shortcutKey: "Ctrl+B"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "**",
                                                           "**")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "**", "**")
                    },
                    Action {
                        id: italicAction
                        property string iconSrc: JamiResources.italic_black_24dp_svg
                        property string shortcutText: JamiStrings.italic
                        property string shortcutKey: "Ctrl+I"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "*",
                                                           "*")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "*", "*")
                    },
                    Action {
                        id: strikethroughAction
                        property string iconSrc: JamiResources.s_barre_black_24dp_svg
                        property string shortcutText: JamiStrings.strikethrough
                        property string shortcutKey: "Shift+Alt+X"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "~~",
                                                           "~~")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "~~", "~~")
                    },
                    Action {
                        id: titleAction
                        property string iconSrc: JamiResources.title_black_24dp_svg
                        property string shortcutText: JamiStrings.heading
                        property string shortcutKey: "Ctrl+Alt+H"
                        property bool isStyle: MDE.isPrefixSyle(messageBarTextArea, rectangle.text,
                                                                "### ", false)
                        onTriggered: MDE.addPrefixStyle(messageBarTextArea, rectangle.text, "### ",
                                                        false)
                    },
                    Action {
                        id: linkAction
                        property string iconSrc: JamiResources.link_web_black_24dp_svg
                        property string shortcutText: JamiStrings.link
                        property string shortcutKey: "Ctrl+Alt+K"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "[",
                                                           "](url)")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "[", "](url)")
                    },
                    Action {
                        id: codeAction
                        property string iconSrc: JamiResources.code_black_24dp_svg
                        property string shortcutText: JamiStrings.code
                        property string shortcutKey: "Ctrl+Alt+C"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "```",
                                                           "```")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "```", "```")
                    }
                ]

                model: menuTypoActionsFirst

                delegate: NewIconButton {
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                    enabled: !showPreview

                    iconSize: JamiTheme.iconButtonSmall
                    iconSource: modelData.iconSrc
                    toolTipText: modelData.shortcutText
                    toolTipShortcutKey: modelData.shortcutKey

                    action: modelData
                }
            }

            Rectangle {
                width: 5
                height: JamiTheme.chatViewFooterButtonSize

                color: JamiTheme.primaryBackgroundColor

                visible: showTypo && showTypoSecond

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 1
                    height: JamiTheme.chatViewFooterButtonSize * 2 / 3
                    color: showPreview ? JamiTheme.chatViewFooterImgDisableColor :
                                         JamiTheme.chatViewFooterSeparateLineColor
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter

                width: JamiTheme.chatViewFooterButtonSize
                height: JamiTheme.chatViewFooterButtonSize
                radius: 0

                z: -1

                color: JamiTheme.primaryBackgroundColor

                visible: showTypo && !showTypoSecond

                ComboBox {
                    id: showMoreTypoButton

                    anchors.centerIn: parent

                    width: JamiTheme.chatViewFooterButtonSize
                    height: JamiTheme.chatViewFooterButtonSize

                    enabled: !showPreview
                    hoverEnabled: !showPreview

                    background: null

                    indicator: NewIconButton {
                        anchors.centerIn: parent
                        iconSize: JamiTheme.iconButtonSmall
                        iconSource: JamiResources.more_vert_24dp_svg
                        toolTipText: markdownPopup.visible ? JamiStrings.showLess :
                                                             JamiStrings.showMore

                        checked: markdownPopup.visible

                        onClicked: markdownPopup.visible ? markdownPopup.close() :
                                                           markdownPopup.open()
                    }

                    popup: MarkdownPopup {
                        id: markdownPopup

                        x: -parent.width * 2
                        y: 1.5 * parent.height

                        menuTypoActionsSecond: listViewTypoSecond.menuTypoActionsSecond
                    }
                }
            }

            ListView {
                id: listViewTypoSecond
                visible: showTypo && showTypoSecond
                width: contentWidth + 2 * leftMargin

                height: JamiTheme.chatViewFooterButtonSize
                orientation: ListView.Horizontal
                interactive: false

                Rectangle {
                    anchors.fill: parent
                    color: JamiTheme.transparentColor
                    z: -1
                }

                spacing: JamiTheme.messageBarSpacing

                property list<Action> menuTypoActionsSecond: [
                    Action {
                        id: quoteAction
                        property string iconSrc: JamiResources.quote_black_24dp_svg
                        property string shortcutText: JamiStrings.quote
                        property string shortcutKey: "Shift+Alt+9"
                        property bool isStyle: MDE.isPrefixSyle(messageBarTextArea, rectangle.text,
                                                                "> ", false)
                        onTriggered: MDE.addPrefixStyle(messageBarTextArea, rectangle.text, "> ",
                                                        false)
                    },
                    Action {
                        id: unorderedListAction
                        property string iconSrc: JamiResources.bullet_point_black_24dp_svg
                        property string shortcutText: JamiStrings.unorderedList
                        property string shortcutKey: "Shift+Alt+8"
                        property bool isStyle: MDE.isPrefixSyle(messageBarTextArea, rectangle.text,
                                                                "- ", false)
                        onTriggered: MDE.addPrefixStyle(messageBarTextArea, rectangle.text, "- ",
                                                        false)
                    },
                    Action {
                        id: orderedListAction
                        property string iconSrc: JamiResources.bullet_number_black_24dp_svg
                        property string shortcutText: JamiStrings.orderedList
                        property string shortcutKey: "Shift+Alt+7"
                        property bool isStyle: MDE.isPrefixSyle(messageBarTextArea, rectangle.text,
                                                                "", true)
                        onTriggered: MDE.addPrefixStyle(messageBarTextArea, rectangle.text, "",
                                                        true)
                    }
                ]

                model: menuTypoActionsSecond

                delegate: NewIconButton {

                    anchors.verticalCenter: parent.verticalCenter

                    enabled: !showPreview

                    iconSize: JamiTheme.iconButtonSmall
                    iconSource: modelData.iconSrc
                    toolTipText: modelData.shortcutText
                    toolTipShortcutKey: modelData.shortcutKey

                    action: modelData
                }
            }
        }
    }

    Row {
        id: secondRow

        anchors.right: messageBarRowLayout.right
        anchors.bottom: messageBarRowLayout.bottom

        spacing: JamiTheme.messageBarSpacing

        // Overriden NewIconButton due to icon fitting issues
        NewIconButton {
            id: typoButton

            anchors.verticalCenter: parent.verticalCenter

            iconSize: JamiTheme.iconButtonMedium - 4
            iconSource: JamiResources.text_edit_black_24dp_svg
            toolTipText: showTypo ? JamiStrings.hideFormatting : JamiStrings.showFormatting

            checked: showTypo

            background: Rectangle {
                visible: parent.checked || parent.hovered

                implicitWidth: JamiTheme.iconButtonMedium + (JamiTheme.iconButtonMedium / 2)
                implicitHeight: JamiTheme.iconButtonMedium + (JamiTheme.iconButtonMedium / 2)

                radius: width / 2
                anchors.centerIn: parent

                color: visible ? JamiTheme.hoveredButtonColor : JamiTheme.transparentColor

                opacity: visible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }

            onClicked: {
                showTypo = !showTypo;
                messageBarTextArea.isShowTypo = showTypo;
                if (messageBar.width < messageBarLayoutMaximumWidth + sendMessageButton.width + 2
                        * JamiTheme.preferredMarginSize)
                    showTypoSecond = false;
                if (!showDefault)
                    showDefault = true;
                UtilsAdapter.setAppValue(Settings.Key.ShowMardownOption, showTypo);
                UtilsAdapter.setAppValue(Settings.Key.ShowSendOption, !showDefault);
            }
        }

        ListView {
            id: listViewMoreButton

            width: 0
            Behavior on width {
                NumberAnimation {
                    duration: JamiTheme.longFadeDuration / 2
                }
            }

            height: JamiTheme.chatViewFooterButtonSize
            orientation: ListView.Horizontal
            interactive: false

            leftMargin: 10
            rightMargin: 10
            property list<Action> menuMoreButton: [
                Action {
                    id: leaveAudioMessage
                    property string iconSrc: JamiResources.message_audio_black_24dp_svg
                    property string toolTip: JamiStrings.leaveAudioMessage
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
                    property string iconSrc: JamiResources.message_video_black_24dp_svg
                    property string toolTip: JamiStrings.leaveVideoMessage
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
                    property string iconSrc: JamiResources.localisation_sharing_send_pin_svg
                    property string toolTip: JamiStrings.shareLocation
                    property bool show: false
                    property bool needWebEngine: true
                    property bool needVideoDevice: false
                    property bool noSip: false
                    onTriggered: function clickAction() {
                        showMapClicked();
                    }
                }
            ]

            ListModel {
                id: listMoreButton
                Component.onCompleted: {
                    for (var i = 0; i < listViewMoreButton.menuMoreButton.length; i++) {
                        append({
                                   "menuAction": listViewMoreButton.menuMoreButton[i]
                               });
                    }
                }
            }

            model: SortFilterProxyModel {
                sourceModel: listMoreButton
                filters: [
                    ExpressionFilter {
                        expression: menuAction.show === true
                        enabled: showDefault
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

            delegate: NewIconButton {
                id: buttonDelegateMoreButton

                anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                enabled: !showPreview

                iconSize: JamiTheme.iconButtonMedium
                iconSource: modelData.iconSrc
                toolTipText: modelData.toolTip

                action: modelData
            }
        }

        ComboBox {
            id: showMoreButton

            anchors.bottom: parent.bottom

            width: JamiTheme.chatViewFooterButtonSize
            height: JamiTheme.chatViewFooterButtonSize

            enabled: !showPreview
            hoverEnabled: !showPreview

            focus: true
            visible: !CurrentConversation.isSip

            Accessible.name: JamiStrings.showMoreMessagingOptions
            Accessible.role: Accessible.ComboBox
            Accessible.description: JamiStrings.showMoreMessagingOptionsDescription

            // Used to choose the correct color for the button.
            readonly property bool highlight: down || hovered

            background: Item {}

            indicator: NewIconButton {
                anchors.verticalCenter: parent.verticalCenter

                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.more_menu_black_24dp_svg
                toolTipText: showMoreButton.popup.visible ? JamiStrings.showLess :
                                                            JamiStrings.showMore

                checked: showMoreButton.popup.opened;

                onClicked: sharePopup.visible ? sharePopup.close() : sharePopup.open()
            }

            Component {
                id: sharePopupComp
                ShareMenu {
                    id: sharePopup
                    onAudioRecordMessageButtonClicked: rectangle.audioRecordMessageButtonClicked(
                                                           )
                    onVideoRecordMessageButtonClicked: rectangle.videoRecordMessageButtonClicked(
                                                           )
                    onShowMapClicked: rectangle.showMapClicked()
                    modelList: listViewMoreButton.menuMoreButton
                    y: showMoreButton.y + 31
                    x: showMoreButton.x - 3
                }
            }

            popup: ShareMenu {
                id: sharePopup
                onAudioRecordMessageButtonClicked: rectangle.audioRecordMessageButtonClicked()
                onVideoRecordMessageButtonClicked: rectangle.videoRecordMessageButtonClicked()
                onShowMapClicked: rectangle.showMapClicked()
                modelList: listViewMoreButton.menuMoreButton
                y: showMoreButton.y + 31
                x: showMoreButton.x - 3
            }
        }

        ListView {
            id: listViewAction

            width: contentWidth + 2 * leftMargin

            Behavior on width {
                NumberAnimation {
                    duration: JamiTheme.longFadeDuration / 2
                }
            }

            height: JamiTheme.chatViewFooterButtonSize
            orientation: ListView.Horizontal
            interactive: false

            spacing: JamiTheme.messageBarSpacing

            property list<Action> menuActions: [
                Action {
                    id: sendFile
                    property string iconSrc: JamiResources.link_black_24dp_svg
                    property string toolTip: JamiStrings.sendFile
                    property bool show: true
                    property bool needWebEngine: false
                    property bool needVideoDevice: false
                    property bool noSip: false
                    onTriggered: function clickAction() {
                        sendFileButtonClicked();
                        textAreaObj.forceActiveFocus();
                    }
                },
                Action {
                    id: addEmoji
                    property string iconSrc: JamiResources.emoji_black_24dp_svg
                    property string toolTip: JamiStrings.addEmoji
                    property bool show: true
                    property bool needWebEngine: true
                    property bool needVideoDevice: false
                    property bool noSip: true
                    checked: messageBarRowLayout.isEmojiPickerOpen
                    onTriggered: function clickAction() {
                        emojiButtonClicked();
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
                        enabled: rectangle.showDefault
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

            delegate: NewIconButton {
                id: buttonDelegate

                anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                enabled: !showPreview

                checkable: true
                checked: modelData.checked

                iconSize: JamiTheme.iconButtonMedium
                iconSource: modelData.iconSrc
                toolTipText: modelData.toolTip

                action: modelData
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignRight
            height: JamiTheme.chatViewFooterButtonSize
            width: JamiTheme.chatViewFooterButtonSize
            visible: true
            color: JamiTheme.transparentColor

            PushButton {
                id: sendMessageButton

                objectName: "sendMessageButton"
                anchors.bottom: parent.bottom

                enabled: sendButtonVisibility
                hoverEnabled: enabled

                width: scale * JamiTheme.chatViewFooterButtonSize
                height: JamiTheme.chatViewFooterButtonSize

                radius: JamiTheme.chatViewFooterButtonRadius
                preferredSize: JamiTheme.chatViewFooterButtonIconSize - 6
                imageContainerWidth: 25
                imageContainerHeight: 25


                toolTipText: {
                    if (MessagesAdapter.editId !== "") {
                        return JamiStrings.edit;
                    } else if (MessagesAdapter.replyToId !== "") {
                        return JamiStrings.reply;
                    } else {
                        return JamiStrings.send;
                    }
                }

                mirror: UtilsAdapter.isRTL

                source: {
                    if (MessagesAdapter.editId !== "") {
                        return JamiResources.edit_svg;
                    } else if (MessagesAdapter.replyToId !== "") {
                        return JamiResources.reply_black_24dp_svg;
                    } else {
                        return JamiResources.send_black_24dp_svg;
                    }
                }

                normalColor: enabled ? JamiTheme.chatViewFooterSendButtonColor :
                                       JamiTheme.chatViewFooterSendButtonDisableColor
                imageColor: enabled ? JamiTheme.chatViewFooterSendButtonImgColor :
                                      JamiTheme.chatViewFooterSendButtonImgColorDisable
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: hoveredColor

                opacity: 1
                scale: opacity

                Behavior on opacity {
                    enabled: animate
                    NumberAnimation {
                        duration: JamiTheme.shortFadeDuration
                        easing.type: Easing.InOutQuad
                    }
                }

                onClicked: {
                    rectangle.showPreview = false;
                    sendMessageButtonClicked();
                }
            }
        }
    }
}
