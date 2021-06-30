/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import net.jami.Models 1.0
import net.jami.Constants 1.0
import net.jami.Adapters 1.0

import "../../commoncomponents"
import "../../commoncomponents/emojipicker"

Rectangle {
    id: root

    color: JamiTheme.primaryBackgroundColor

    EmojiPicker {
        id: test
    }

    RowLayout {
        anchors.fill: root

        spacing: 20

        PushButton {
            id: sendFileButton

            Layout.alignment: Qt.AlignVCenter

            toolTipText: JamiStrings.sendFile

            source: "qrc:/images/icons/link_black-24dp.svg"

            normalColor: JamiTheme.backgroundColor
            imageColor: JamiTheme.textColor

            onClicked: {

            }
        }

        PushButton {
            id: audioRecordMessageButton

            Layout.alignment: Qt.AlignVCenter

            toolTipText: JamiStrings.addEmoji

            source: "qrc:/images/icons/message_audio_black-24dp.svg"

            normalColor: JamiTheme.backgroundColor
            imageColor: JamiTheme.textColor

            onClicked: {

            }
        }

        PushButton {
            id: videoRecordMessageButton

            Layout.alignment: Qt.AlignVCenter

            toolTipText: JamiStrings.addEmoji

            source: "qrc:/images/icons/message_video_black-24dp.svg"

            normalColor: JamiTheme.backgroundColor
            imageColor: JamiTheme.textColor

            onClicked: {

            }
        }

        JamiTextArea {
            id: textAreaFlick

            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            Layout.maximumHeight: 90

            onTextChanged: {
                if (text)
                    sendMessageButton.state = "buttonFadeOut"
                else
                    sendMessageButton.state = "buttonFadeIn"
            }
        }

        PushButton {
            id: emojiButton

            Layout.alignment: Qt.AlignVCenter

            toolTipText: JamiStrings.addEmoji

            source: "qrc:/images/icons/emoji_black-24dp.svg"

            normalColor: JamiTheme.backgroundColor
            imageColor: JamiTheme.textColor

            onClicked: {
                test.openEmojiPicker()
            }
        }

        PushButton {
            id: sendMessageButton

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: opacity ? preferredSize : 0

            toolTipText: JamiStrings.addEmoji

            source: "qrc:/images/icons/send_black-24dp.svg"

            normalColor: JamiTheme.backgroundColor
            imageColor: JamiTheme.textColor

            opacity: 0

            states: [
                State {
                    name: "buttonFadeIn"
                    PropertyChanges {
                        target: sendMessageButton
                        opacity: 0
                    }
                },
                State {
                    name: "buttonFadeOut"
                    PropertyChanges {
                        target: sendMessageButton
                        opacity: 1
                    }
                }
            ]

            transitions: Transition {
                NumberAnimation {
                    properties: "opacity"
                    easing.type: Easing.InOutQuad
                    duration: 200
                }
            }

            onClicked: {

            }
        }
    }

    CustomBorder {
        commonBorder: false
        lBorderwidth: 0
        rBorderwidth: 0
        tBorderwidth: 0
        bBorderwidth: 1
        borderColor: JamiTheme.tabbarBorderColor
    }
}
