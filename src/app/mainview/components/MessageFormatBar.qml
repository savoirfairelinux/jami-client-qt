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

    Row {
        id: firstRow
        anchors.left: messageBarRowLayout.left
        anchors.bottom: messageBarRowLayout.bottom

        Row {
            id: listViewTypo
            height: JamiTheme.chatViewFooterButtonSize

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

                property list<Action> menuTypoActionsFirst: [
                    Action {
                        id: boldAction
                        property string iconSrc: JamiResources.bold_black_24dp_svg
                        property string shortcutText: JamiStrings.bold
                        property string shortcutKey: "Ctrl+B"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "**", "**")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "**", "**")
                    },
                    Action {
                        id: italicAction
                        property string iconSrc: JamiResources.italic_black_24dp_svg
                        property string shortcutText: JamiStrings.italic
                        property string shortcutKey: "Ctrl+I"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "*", "*")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "*", "*")
                    },
                    Action {
                        id: strikethroughAction
                        property string iconSrc: JamiResources.s_barre_black_24dp_svg
                        property string shortcutText: JamiStrings.strikethrough
                        property string shortcutKey: "Shift+Alt+X"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "~~", "~~")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "~~", "~~")
                    },
                    Action {
                        id: titleAction
                        property string iconSrc: JamiResources.title_black_24dp_svg
                        property string shortcutText: JamiStrings.heading
                        property string shortcutKey: "Ctrl+Alt+H"
                        property bool isStyle: MDE.isPrefixSyle(messageBarTextArea, rectangle.text, "### ", false)
                        onTriggered: MDE.addPrefixStyle(messageBarTextArea, rectangle.text, "### ", false)
                    },
                    Action {
                        id: linkAction
                        property string iconSrc: JamiResources.link_web_black_24dp_svg
                        property string shortcutText: JamiStrings.link
                        property string shortcutKey: "Ctrl+Alt+K"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "[", "](url)")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "[", "](url)")
                    },
                    Action {
                        id: codeAction
                        property string iconSrc: JamiResources.code_black_24dp_svg
                        property string shortcutText: JamiStrings.code
                        property string shortcutKey: "Ctrl+Alt+C"
                        property bool isStyle: MDE.isStyle(messageBarTextArea, rectangle.text, "```", "```")
                        onTriggered: MDE.addStyle(messageBarTextArea, rectangle.text, "```", "```")
                    }
                ]

                model: menuTypoActionsFirst

                delegate: PushButton {
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    preferredSize: JamiTheme.chatViewFooterButtonSize
                    imageContainerWidth: 15
                    imageContainerHeight: 15
                    radius: 5

                    hoverEnabled: !showPreview
                    enabled: !showPreview

                    toolTipText: modelData.shortcutText
                    shortcutKey: modelData.shortcutKey
                    hasShortcut: true

                    source: modelData.iconSrc
                    focusPolicy: Qt.TabFocus

                    normalColor: {
                        if (showPreview) {
                            return JamiTheme.primaryBackgroundColor;
                        } else if (modelData.isStyle) {
                            return JamiTheme.hoveredButtonColor;
                        } else {
                            return JamiTheme.primaryBackgroundColor;
                        }
                    }
                    imageColor: {
                        if (showPreview) {
                            return JamiTheme.chatViewFooterImgDisableColor;
                        } else if (hovered) {
                            return JamiTheme.chatViewFooterImgHoverColor;
                        } else if (modelData.isStyle) {
                            return JamiTheme.chatViewFooterImgHoverColor;
                        } else {
                            return JamiTheme.chatViewFooterImgColor;
                        }
                    }
                    hoveredColor: JamiTheme.hoveredButtonColor
                    pressedColor: hoveredColor

                    action: modelData
                }
            }

            Rectangle {
                height: JamiTheme.chatViewFooterButtonSize
                color: JamiTheme.primaryBackgroundColor
                visible: showTypo && showTypoSecond
                width: 5

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 1
                    height: JamiTheme.chatViewFooterButtonSize * 2 / 3
                    color: showPreview ? JamiTheme.chatViewFooterImgDisableColor : JamiTheme.chatViewFooterSeparateLineColor
                }
            }

            Rectangle {
                z: -1
                radius: 0
                color: JamiTheme.primaryBackgroundColor
                width: JamiTheme.chatViewFooterButtonSize
                height: JamiTheme.chatViewFooterButtonSize

                visible: showTypo && !showTypoSecond

                ComboBox {
                    id: showMoreTypoButton
                    width: JamiTheme.chatViewFooterButtonSize
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    enabled: !showPreview
                    hoverEnabled: !showPreview

                    MaterialToolTip {
                        id: toolTip
                        parent: showMoreTypoButton
                        visible: showMoreTypoButton.hovered && (text.length > 0)
                        delay: Qt.styleHints.mousePressAndHoldInterval
                        text: markdownPopup.visible ? JamiStrings.showLess : JamiStrings.showMore
                    }

                    background: Rectangle {
                        implicitWidth: showMoreTypoButton.width
                        implicitHeight: showMoreTypoButton.height
                        radius: 5
                        color: showPreview ? JamiTheme.transparentColor : (parent && parent.hovered ? JamiTheme.hoveredButtonColor : JamiTheme.transparentColor)
                    }

                    indicator: ResponsiveImage {
                        containerHeight: 20
                        containerWidth: 20
                        width: 18
                        height: 18

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter

                        source: JamiResources.more_vert_24dp_svg

                        color: showPreview ? JamiTheme.chatViewFooterImgDisableColor : (parent && parent.hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor)
                    }

                    popup: MarkdownPopup {
                        id: markdownPopup
                        y: 1.5 * parent.height
                        x: -parent.width * 2
                        width: listViewTypoSecond.width + 10
                        height: JamiTheme.chatViewFooterButtonSize

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

                property list<Action> menuTypoActionsSecond: [
                    Action {
                        id: quoteAction
                        property string iconSrc: JamiResources.quote_black_24dp_svg
                        property string shortcutText: JamiStrings.quote
                        property string shortcutKey: "Shift+Alt+9"
                        property bool isStyle: MDE.isPrefixSyle(messageBarTextArea, rectangle.text, "> ", false)
                        onTriggered: MDE.addPrefixStyle(messageBarTextArea, rectangle.text, "> ", false)
                    },
                    Action {
                        id: unorderedListAction
                        property string iconSrc: JamiResources.bullet_point_black_24dp_svg
                        property string shortcutText: JamiStrings.unorderedList
                        property string shortcutKey: "Shift+Alt+8"
                        property bool isStyle: MDE.isPrefixSyle(messageBarTextArea, rectangle.text, "- ", false)
                        onTriggered: MDE.addPrefixStyle(messageBarTextArea, rectangle.text, "- ", false)
                    },
                    Action {
                        id: orderedListAction
                        property string iconSrc: JamiResources.bullet_number_black_24dp_svg
                        property string shortcutText: JamiStrings.orderedList
                        property string shortcutKey: "Shift+Alt+7"
                        property bool isStyle: MDE.isPrefixSyle(messageBarTextArea, rectangle.text, "", true)
                        onTriggered: MDE.addPrefixStyle(messageBarTextArea, rectangle.text, "", true)
                    }
                ]

                model: menuTypoActionsSecond

                delegate: PushButton {
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    preferredSize: JamiTheme.chatViewFooterButtonSize
                    imageContainerWidth: 20
                    imageContainerHeight: 20
                    radius: 5

                    hoverEnabled: !showPreview
                    enabled: !showPreview

                    toolTipText: modelData.shortcutText
                    shortcutKey: modelData.shortcutKey
                    hasShortcut: modelData.hasShortcut ? true : false
                    source: modelData.iconSrc
                    focusPolicy: Qt.TabFocus

                    normalColor: {
                        if (showPreview) {
                            return JamiTheme.primaryBackgroundColor;
                        } else if (modelData.normalColor) {
                            return modelData.normalColor;
                        } else if (modelData.isStyle) {
                            return JamiTheme.hoveredButtonColor;
                        } else {
                            return JamiTheme.primaryBackgroundColor;
                        }
                    }
                    imageColor: {
                        if (showPreview) {
                            return JamiTheme.chatViewFooterImgDisableColor;
                        } else if (hovered) {
                            return JamiTheme.chatViewFooterImgHoverColor;
                        } else if (modelData.isStyle) {
                            return JamiTheme.chatViewFooterImgHoverColor;
                        } else {
                            return JamiTheme.chatViewFooterImgColor;
                        }
                    }
                    hoveredColor: JamiTheme.hoveredButtonColor
                    pressedColor: hoveredColor

                    action: modelData
                }
            }
        }
    }

    Row {
        id: secondRow
        anchors.right: messageBarRowLayout.right
        anchors.bottom: messageBarRowLayout.bottom

        PushButton {
            id: typoButton

            preferredSize: JamiTheme.chatViewFooterButtonSize
            imageContainerWidth: 24
            imageContainerHeight: 24

            radius: JamiTheme.chatViewFooterButtonRadius

            hoverEnabled: !showPreview
            enabled: !showPreview

            toolTipText: showTypo ? JamiStrings.hideFormatting : JamiStrings.showFormatting
            source: JamiResources.text_edit_black_24dp_svg

            normalColor: showPreview ? JamiTheme.primaryBackgroundColor : (showTypo ? JamiTheme.hoveredButtonColor : JamiTheme.primaryBackgroundColor)
            imageColor: showPreview ? JamiTheme.chatViewFooterImgDisableColor : (hovered || showTypo ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor)
            hoveredColor: JamiTheme.hoveredButtonColor
            pressedColor: hoveredColor

            onClicked: {
                showTypo = !showTypo;
                messageBarTextArea.isShowTypo = showTypo;
                if (messageBar.width < messageBarLayoutMaximumWidth + sendMessageButton.width + 2 * JamiTheme.preferredMarginSize)
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

            delegate: PushButton {
                id: buttonDelegateMoreButton
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                preferredSize: JamiTheme.chatViewFooterButtonSize
                imageContainerWidth: 20
                imageContainerHeight: 20
                radius: 5
                enabled: !showPreview
                hoverEnabled: !showPreview
                toolTipText: modelData.toolTip
                source: modelData.iconSrc

                normalColor: showPreview ? JamiTheme.primaryBackgroundColor : (showTypo ? JamiTheme.hoveredButtonColor : JamiTheme.primaryBackgroundColor)
                imageColor: showPreview ? JamiTheme.chatViewFooterImgDisableColor : (hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor)
                hoveredColor: JamiTheme.hoveredButtonColor
                pressedColor: hoveredColor
                action: modelData
            }
        }

        Rectangle {
            height: JamiTheme.chatViewFooterButtonSize
            width: JamiTheme.chatViewFooterButtonSize
            Layout.alignment: Qt.AlignRight
            visible: !CurrentConversation.isSip
            color: JamiTheme.transparentColor
            ComboBox {
                id: showMoreButton
                focus: true
                width: JamiTheme.chatViewFooterButtonSize
                height: JamiTheme.chatViewFooterButtonSize
                anchors.bottom: parent.bottom
                enabled: !showPreview
                hoverEnabled: !showPreview
                Accessible.name: JamiStrings.showMoreMessagingOptions
                Accessible.role: Accessible.ComboBox
                Accessible.description: JamiStrings.showMoreMessagingOptionsDescription

                // Used to choose the correct color for the button.
                readonly property bool highlight: down || hovered

                background: Rectangle {
                    implicitWidth: showMoreButton.width
                    implicitHeight: showMoreButton.height
                    radius: 5
                    color: showMoreButton.highlight ? JamiTheme.hoveredButtonColor : JamiTheme.transparentColor
                }

                MaterialToolTip {
                    id: toolTipMoreButton

                    parent: showMoreButton
                    visible: showMoreButton.hovered && (text.length > 0)
                    delay: Qt.styleHints.mousePressAndHoldInterval
                    text: showMoreButton.popup.visible ? JamiStrings.showLess : JamiStrings.showMore
                }


                indicator: ResponsiveImage {

                    width: 20
                    height: 20

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    source: JamiResources.more_menu_black_24dp_svg

                    color: showPreview ? JamiTheme.chatViewFooterImgDisableColor : (hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor)
                }

                Component {
                    id: sharePopupComp
                    ShareMenu {
                        id: sharePopup
                        onAudioRecordMessageButtonClicked: rectangle.audioRecordMessageButtonClicked()
                        onVideoRecordMessageButtonClicked: rectangle.videoRecordMessageButtonClicked()
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

            delegate: PushButton {
                id: buttonDelegate
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                preferredSize: JamiTheme.chatViewFooterButtonSize
                imageContainerWidth: 25
                imageContainerHeight: 25
                radius: 5

                hoverEnabled: !showPreview
                enabled: !showPreview

                toolTipText: modelData.toolTip
                source: modelData.iconSrc

                normalColor: JamiTheme.primaryBackgroundColor
                imageColor: showPreview ? JamiTheme.chatViewFooterImgDisableColor : (hovered ? JamiTheme.chatViewFooterImgHoverColor : JamiTheme.chatViewFooterImgColor)
                hoveredColor: JamiTheme.hoveredButtonColor
                pressedColor: hoveredColor

                action: modelData
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignRight
            height: JamiTheme.chatViewFooterButtonSize
            width: JamiTheme.chatViewFooterButtonSize
            Layout.rightMargin: marginSize / 2
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

                toolTipText: JamiStrings.send

                mirror: UtilsAdapter.isRTL

                source: JamiResources.send_black_24dp_svg

                normalColor: enabled ? JamiTheme.chatViewFooterSendButtonColor : JamiTheme.chatViewFooterSendButtonDisableColor
                imageColor: enabled ? JamiTheme.chatViewFooterSendButtonImgColor : JamiTheme.chatViewFooterSendButtonImgColorDisable
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
