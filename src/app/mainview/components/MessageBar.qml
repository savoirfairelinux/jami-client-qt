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
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root
    property bool animate: false
    property real marginSize: JamiTheme.messageBarMarginSize
    property bool sendButtonVisibility: false
    property alias text: textArea.text
    property var textAreaObj: textArea

    implicitHeight: messageBarRowLayout.height
    spacing: 0

    signal audioRecordMessageButtonClicked
    signal emojiButtonClicked
    signal sendFileButtonClicked
    signal sendMessageButtonClicked
    signal showMapClicked
    signal videoRecordMessageButtonClicked

    Rectangle {
        id: messageBarHairLine
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        Layout.fillWidth: true
        Layout.preferredHeight: JamiTheme.chatViewHairLineSize
        color: JamiTheme.tabbarBorderColor
    }
    RowLayout {
        id: messageBarRowLayout
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.maximumWidth: JamiTheme.chatViewMaximumWidth
        spacing: JamiTheme.chatViewFooterRowSpacing

        Component.onCompleted: JamiQmlUtils.messageBarButtonsRowObj = messageBarRowLayout

        PushButton {
            id: showMapButton
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: marginSize
            Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize
            Layout.preferredWidth: JamiTheme.chatViewFooterButtonSize
            imageColor: JamiTheme.messageWebViewFooterButtonImageColor
            normalColor: JamiTheme.primaryBackgroundColor
            preferredSize: JamiTheme.chatViewFooterButtonIconSize
            radius: JamiTheme.chatViewFooterButtonRadius
            source: JamiResources.share_location_svg
            toolTipText: JamiStrings.shareLocation
            visible: WITH_WEBENGINE && !CurrentConversation.isSip

            onClicked: root.showMapClicked()
        }
        PushButton {
            id: sendFileButton
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize
            Layout.preferredWidth: JamiTheme.chatViewFooterButtonSize
            imageColor: JamiTheme.messageWebViewFooterButtonImageColor
            normalColor: JamiTheme.primaryBackgroundColor
            preferredSize: JamiTheme.chatViewFooterButtonIconSize - 6
            radius: JamiTheme.chatViewFooterButtonRadius
            source: JamiResources.link_black_24dp_svg
            toolTipText: JamiStrings.sendFile
            visible: !CurrentConversation.isSip

            onClicked: root.sendFileButtonClicked()
        }
        PushButton {
            id: audioRecordMessageButton
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize
            Layout.preferredWidth: JamiTheme.chatViewFooterButtonSize
            imageColor: JamiTheme.messageWebViewFooterButtonImageColor
            normalColor: JamiTheme.primaryBackgroundColor
            preferredSize: JamiTheme.chatViewFooterButtonIconSize
            radius: JamiTheme.chatViewFooterButtonRadius
            source: JamiResources.message_audio_black_24dp_svg
            toolTipText: JamiStrings.leaveAudioMessage
            visible: !CurrentConversation.isSip

            Component.onCompleted: JamiQmlUtils.audioRecordMessageButtonObj = audioRecordMessageButton
            onClicked: root.audioRecordMessageButtonClicked()
        }
        PushButton {
            id: videoRecordMessageButton
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize
            Layout.preferredWidth: JamiTheme.chatViewFooterButtonSize
            imageColor: JamiTheme.messageWebViewFooterButtonImageColor
            normalColor: JamiTheme.primaryBackgroundColor
            preferredSize: JamiTheme.chatViewFooterButtonIconSize
            radius: JamiTheme.chatViewFooterButtonRadius
            source: JamiResources.message_video_black_24dp_svg
            toolTipText: JamiStrings.leaveVideoMessage
            visible: VideoDevices.listSize !== 0 && !CurrentConversation.isSip

            Component.onCompleted: JamiQmlUtils.videoRecordMessageButtonObj = videoRecordMessageButton
            onClicked: root.videoRecordMessageButtonClicked()
        }
        MessageBarTextArea {
            id: textArea
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.margins: marginSize / 2
            Layout.maximumHeight: JamiTheme.chatViewFooterTextAreaMaximumHeight - marginSize / 2
            Layout.preferredHeight: {
                return JamiTheme.chatViewFooterPreferredHeight > contentHeight ? JamiTheme.chatViewFooterPreferredHeight : contentHeight;
            }
            objectName: "messageBarTextArea"
            placeholderText: JamiStrings.writeTo.arg(CurrentConversation.title)

            // forward activeFocus to the actual text area object
            onActiveFocusChanged: {
                if (activeFocus)
                    textAreaObj.forceActiveFocus();
            }
            onSendMessagesRequired: root.sendMessageButtonClicked()
            onTextChanged: MessagesAdapter.userIsComposing(text ? true : false)
        }
        PushButton {
            id: emojiButton
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize
            Layout.preferredWidth: JamiTheme.chatViewFooterButtonSize
            Layout.rightMargin: sendMessageButton.visible ? 0 : marginSize
            imageColor: JamiTheme.messageWebViewFooterButtonImageColor
            normalColor: JamiTheme.primaryBackgroundColor
            preferredSize: JamiTheme.chatViewFooterButtonIconSize
            radius: JamiTheme.chatViewFooterButtonRadius
            source: JamiResources.emoji_black_24dp_svg
            toolTipText: JamiStrings.addEmoji
            visible: WITH_WEBENGINE

            Component.onCompleted: JamiQmlUtils.emojiPickerButtonObj = emojiButton
            onClicked: root.emojiButtonClicked()
        }
        PushButton {
            id: sendMessageButton
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: JamiTheme.chatViewFooterButtonSize
            Layout.preferredWidth: scale * JamiTheme.chatViewFooterButtonSize
            Layout.rightMargin: visible ? marginSize : 0
            imageColor: JamiTheme.messageWebViewFooterButtonImageColor
            normalColor: JamiTheme.primaryBackgroundColor
            objectName: "sendMessageButton"
            opacity: sendButtonVisibility ? 1 : 0
            preferredSize: JamiTheme.chatViewFooterButtonIconSize - 6
            radius: JamiTheme.chatViewFooterButtonRadius
            scale: opacity
            source: JamiResources.send_black_24dp_svg
            toolTipText: JamiStrings.send
            visible: opacity

            onClicked: root.sendMessageButtonClicked()

            Behavior on opacity  {
                enabled: animate

                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
