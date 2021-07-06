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

    property string previousConvId: ""
    property real hairLineSize: 1

    function setFilePathsToSend(filePaths) {
        for (var index = 0; index < filePaths.length; ++index) {
            var path = UtilsAdapter.getAbsPath(filePaths[index])
            dataTransferSendContainer.pendingFilesToSendListModel.addToPending(path)
        }
    }

    implicitHeight: footerColumnLayout.implicitHeight

    color: JamiTheme.primaryBackgroundColor

    Connections {
        target: LRCInstance

        function onSelectedConvUidChanged() {
            // Handle Draft
            if (previousConvId !== "") {
                LRCInstance.setContentDraft(previousConvId, LRCInstance.currentAccountId,
                                            messageBar.textAreaObj.text);
            }

            messageBar.textAreaObj.clearText()
            previousConvId = LRCInstance.selectedConvUid

            var restoredContent = LRCInstance.getContentDraft(LRCInstance.selectedConvUid,
                                                              LRCInstance.currentAccountId);
            if (restoredContent)
                messageBar.textAreaObj.insertText(restoredContent)
        }
    }

    Connections {
        target: MessagesAdapter

        function onNewMessageBarPlaceholderText(placeholderText) {
            messageBar.textAreaObj.placeholderText = JamiStrings.writeTo + " " + placeholderText
        }
    }

    EmojiPicker {
        id: emojiPicker

        onEmojiIsPicked: messageBar.textAreaObj.insertText(content)
    }

    JamiFileDialog {
        id: jamiFileDialog

        mode: JamiFileDialog.Mode.OpenFiles

        onAccepted: setFilePathsToSend(jamiFileDialog.files)
    }

    ColumnLayout {
        id: footerColumnLayout

        anchors.centerIn: root

        width: root.width

        spacing: 0

        MessageBar {
            id: messageBar

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight

            onEmojiButtonClicked: emojiPicker.openEmojiPicker()
            onSendFileButtonClicked: jamiFileDialog.open()
            onVideoRecordMessageButtonClicked: {
                JamiQmlUtils.updateMessageBarButtonsPoints()

                recordBox.x = Qt.binding(function() {
                    var buttonCenterX = JamiQmlUtils.videoRecordMessageButtonInMainViewPoint.x +
                            JamiQmlUtils.videoRecordMessageButtonObj.width / 2
                    return buttonCenterX - recordBox.width / 2
                })
                recordBox.y = Qt.binding(function() {
                    var buttonY = JamiQmlUtils.videoRecordMessageButtonInMainViewPoint.y
                    return buttonY - recordBox.height - recordBox.spikeHeight
                })

                recordBox.openRecorder(true)
            }
            onAudioRecordMessageButtonClicked: {
                JamiQmlUtils.updateMessageBarButtonsPoints()

                recordBox.x = Qt.binding(function() {
                    var buttonCenterX = JamiQmlUtils.audioRecordMessageButtonInMainViewPoint.x +
                            JamiQmlUtils.audioRecordMessageButtonObj.width / 2
                    return buttonCenterX - recordBox.width / 2
                })
                recordBox.y = Qt.binding(function() {
                    var buttonY = JamiQmlUtils.audioRecordMessageButtonInMainViewPoint.y
                    return buttonY - recordBox.height - recordBox.spikeHeight
                })

                recordBox.openRecorder(false)
            }
        }

        PendingFilesTransferContainer {
            id: dataTransferSendContainer

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: pendingFilesCount ?
                                        JamiTheme.messageWebViewFooterFileContainerPreferredHeight : 0
        }
    }

    CustomBorder {
        commonBorder: false
        lBorderwidth: 0
        rBorderwidth: 0
        tBorderwidth: hairLineSize
        bBorderwidth: 0
        borderColor: JamiTheme.tabbarBorderColor
    }
}
