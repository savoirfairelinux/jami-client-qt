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
    property color listViewButtonNormalColor: showDefault ? JamiTheme.chatViewFooterButtonColor : JamiTheme.chatViewFooterShowMoreButtonColor
    property color listViewButtonImgColor: JamiTheme.chatViewFooterButtonImageColor

    property color showMoreNormalColor: showDefault ? JamiTheme.messageInBgColor : JamiTheme.showMoreOpenButtonColor
    property color showMoreImgColor: showDefault ? JamiTheme.blackColor : JamiTheme.showMoreOpenImgColor

    property color showTypoNormalColor: !showTypo ? JamiTheme.messageInBgColor : JamiTheme.showMoreOpenButtonColor
    property color showTypoImgColor: !showTypo ? JamiTheme.blackColor : JamiTheme.showMoreOpenImgColor

    signal sendMessageButtonClicked
    signal sendFileButtonClicked
    signal audioRecordMessageButtonClicked
    signal videoRecordMessageButtonClicked
    signal showMapClicked
    signal emojiButtonClicked

    implicitHeight: test.height//messageBarRowLayout_.height

    spacing: 0

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
                textAreaObj.forceActiveFocus()
        }

        placeholderText: JamiStrings.writeTo.arg(CurrentConversation.title)

        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        Layout.margins: marginSize / 2
        Layout.preferredHeight: {
            return JamiTheme.chatViewFooterPreferredHeight
                    > contentHeight ? JamiTheme.chatViewFooterPreferredHeight : contentHeight
        }
        Layout.maximumHeight: JamiTheme.chatViewFooterTextAreaMaximumHeight
                              - marginSize / 2

        onSendMessagesRequired: root.sendMessageButtonClicked()
        onTextChanged: MessagesAdapter.userIsComposing(text ? true : false)
    }

    Item {
        id: test
        Layout.fillWidth: true
        Layout.maximumWidth: JamiTheme.chatViewMaximumWidth
        Layout.bottomMargin: JamiTheme.preferredMarginSize
        Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize



        RowLayout {

            id: messageBarRowLayout_

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

                    onClicked: showTypo = !showTypo
                }

                ListView {
                    id: listViewTypo

                    visible: showTypo

                    width: count * 36 + 10
                    height: JamiTheme.chatViewFooterButtonSize
                    orientation: ListView.Horizontal
                    interactive: false
                    leftMargin : 10
                    spacing: 10

                    Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.chatViewFooterShowMoreButtonColor
                        z: -1
                    }

                    property list<Action> menuTypoActions: [
                        Action {
                            id: boldAction
                            property var iconSrc: JamiResources.bold_svg
                            property var toolTip: JamiStrings.bold
                            onTriggered: function clickAction() {
                                print("hello")
                            }
                        },
                        Action {
                            id: italicAction
                            property var iconSrc: JamiResources.italic_svg
                            property var toolTip: JamiStrings.italic
                            onTriggered: function clickAction() {
                                print("hello")
                            }
                        },
                        Action {
                            id: barreAction
                            property var iconSrc: JamiResources.barre_svg
                            property var toolTip: JamiStrings.barre
                            onTriggered: function clickAction() {
                                print("hello")
                            }
                        },
                        Action {
                            id: titleAction
                            property var iconSrc: JamiResources.title_svg
                            property var toolTip: JamiStrings.title
                            onTriggered: function clickAction() {
                                print("hello")
                            }
                        },
                        Action {
                            id: linkAction
                            property var iconSrc: JamiResources.link_svg
                            property var toolTip: JamiStrings.link
                            onTriggered: function clickAction() {
                                print("hello")
                            }
                        },
                        Action {
                            id: codeAction
                            property var iconSrc: JamiResources.code_svg
                            property var toolTip: JamiStrings.code
                            onTriggered: function clickAction() {
                                print("hello")
                            }
                        },
                        Action {
                            id: quoteAction
                            property var iconSrc: JamiResources.quote_svg
                            property var toolTip: JamiStrings.quote
                            onTriggered: function clickAction() {
                                print("hello")
                            }
                        },
                        Action {
                            id: bulletPointAction
                            property var iconSrc: JamiResources.bullet_point_svg
                            property var toolTip: JamiStrings.bulletPoint
                            onTriggered: function clickAction() {
                                print("hello")
                            }
                        },
                        Action {
                            id: bulletNumberAction
                            property var iconSrc: JamiResources.bullet_number_svg
                            property var toolTip: JamiStrings.bulletNumber
                            onTriggered: function clickAction() {
                                print("hello")
                            }
                        }
                    ]

                    model: menuTypoActions

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

            Row {

                ListView {
                    id: listViewAction

                    width: count * 36
                    height: JamiTheme.chatViewFooterButtonSize
                    orientation: ListView.Horizontal
                    interactive: false

                    Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.chatViewFooterShowMoreButtonColor
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
                                sendFileButtonClicked()
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
                                emojiButtonClicked()
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
                                audioRecordMessageButtonClicked()
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
                                videoRecordMessageButtonClicked()
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
                                showMapClicked()
                            }
                        }
                    ]
                    ListModel {
                        id: listActions
                        Component.onCompleted: {
                            print(listViewAction.menuActions.length)
                            for(var i = 0; i<listViewAction.menuActions.length; i++){
                                append({menuAction: listViewAction.menuActions[i]})
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

                        preferredSize: JamiTheme.chatViewFooterButtonSize
                        imageContainerWidth: 20
                        imageContainerHeight: 20
                        radius: 0

                        toolTipText: modelData.toolTip
                        source: modelData.iconSrc

                        normalColor: listViewButtonNormalColor
                        imageColor: listViewButtonImgColor
                        hoveredColor: JamiTheme.showMoreOpenButtonColor
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
                        imageColor: showMoreImgColor

                        onClicked: {

                            showDefault = !showDefault
                        }
                    }
                }



            }
        }


        Row {

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

                Behavior on opacity {
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
