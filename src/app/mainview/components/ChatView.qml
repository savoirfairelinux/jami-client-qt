/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../commoncomponents/mapWebengine"
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

Rectangle {
    id: root

    property bool allMessagesLoaded

    signal needToHideConversationInCall
    signal messagesCleared
    signal messagesLoaded

    function focusChatView() {
        chatViewFooter.textInput.forceActiveFocus()
        swarmDetailsPanel.visible = false
        addMemberPanel.visible = false
    }

    color: JamiTheme.chatviewBgColor

    property string currentConvId: CurrentConversation.id
    onCurrentConvIdChanged: MessagesAdapter.setMapActive(false);


    NoLocationServicePopup {
        id: popupLocationError

        Connections {
            target: MessagesAdapter
            function onPositioningError (err) {
                popupLocationError.error = err;
                popupLocationError.open();
            }
        }
    }

    Loader {
        id: mapLoader

        active: MessagesAdapter.isMapActive && WITH_WEBENGINE
        z: 10
        sourceComponent: MapPosition {}
    }

    RecordBox {
        id: recordBox

        visible: false
    }

    Loader {
        id: empjiLoader
        source: WITH_WEBENGINE ? "qrc:/commoncomponents/emojipicker/EmojiPicker.qml" : "qrc:/nowebengine/EmojiPicker.qml"

        function openEmojiPicker() {
            item.openEmojiPicker()
        }
        Connections {
            target: empjiLoader.item
            function onEmojiIsPicked(content) {
                messageBar.textAreaObj.insertText(content)
            }
        }
    }
    ColumnLayout {
        anchors.fill: root

        spacing: 0

        ChatViewHeader {
            id: chatViewHeader

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.chatViewHeaderPreferredHeight
            Layout.maximumHeight: JamiTheme.chatViewHeaderPreferredHeight
            Layout.minimumWidth: JamiTheme.chatViewHeaderMinimumWidth

            DropArea {
                anchors.fill: parent
                onDropped: chatViewFooter.setFilePathsToSend(drop.urls)
            }

            onBackClicked: {
                mainView.showWelcomeView()
            }

            onNeedToHideConversationInCall: {
                root.needToHideConversationInCall()
            }

            onShowDetailsClicked: {
                addMemberPanel.visible = false
                swarmDetailsPanel.visible = !swarmDetailsPanel.visible
            }

            Connections {
                target: CurrentConversation

                function onUrisChanged(uris) {
                    if (CurrentConversation.uris.length >= 8 && addMemberPanel.visible) {
                        swarmDetailsPanel.visible = false
                        addMemberPanel.visible = !addMemberPanel.visible
                    }
                }
            }

            onAddToConversationClicked: {
                swarmDetailsPanel.visible = false
                addMemberPanel.visible = !addMemberPanel.visible
            }

            onPluginSelector: {
                // Create plugin handler picker - PLUGINS
                PluginHandlerPickerCreation.createPluginHandlerPickerObjects(
                            root, false)
                PluginHandlerPickerCreation.calculateCurrentGeo(root.width / 2,
                                                                root.height / 2)
                PluginHandlerPickerCreation.openPluginHandlerPicker()
            }
        }

        ConversationErrorsRow {
            id: errorRect
            color: JamiTheme.filterBadgeColor
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.chatViewHeaderPreferredHeight
            visible: false
        }

        SplitView {
            id: chatViewMainRow
            Layout.fillWidth: true
            Layout.fillHeight: true

            handle: Rectangle {
                implicitWidth: JamiTheme.splitViewHandlePreferredWidth
                implicitHeight: splitView.height
                color: JamiTheme.primaryBackgroundColor
                Rectangle {
                    implicitWidth: 1
                    implicitHeight: splitView.height
                    color: JamiTheme.tabbarBorderColor
                }
            }

            ColumnLayout {
                SplitView.maximumWidth: splitView.width
                // Note, without JamiTheme.detailsPageMinWidth, sometimes the details page is hidden at the right
                SplitView.preferredWidth: Math.max(0, 2 * splitView.width / 3 - JamiTheme.detailsPageMinWidth)
                SplitView.fillHeight: true

                StackLayout {
                    id: chatViewStack

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: JamiTheme.chatViewHairLineSize
                    Layout.bottomMargin: JamiTheme.chatViewHairLineSize
                    Layout.leftMargin: JamiTheme.chatviewMargin
                    Layout.rightMargin: JamiTheme.chatviewMargin

                    currentIndex: CurrentConversation.isRequest ||
                                  CurrentConversation.needsSyncing

                    Loader {
                        active: CurrentConversation.id !== ""
                        sourceComponent: MessageListView {
                            DropArea {
                                anchors.fill: parent
                                onDropped: function(drop) {
                                    chatViewFooter.setFilePathsToSend(drop.urls)
                                }
                            }
                        }
                    }

                    InvitationView {
                        id: invitationView

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }

                UpdateToSwarm {
                    visible: !CurrentConversation.isSwarm && !CurrentConversation.isTemporary && CurrentAccount.type  === Profile.Type.JAMI
                    Layout.fillWidth: true
                }

                ChatViewFooter {
                    id: chatViewFooter

                    visible: {
                        if (CurrentAccount.type  === Profile.Type.SIP)
                            return true
                        if (CurrentConversation.isBlocked)
                            return false
                        else if (CurrentConversation.needsSyncing)
                            return false
                        else if (CurrentConversation.isSwarm && CurrentConversation.isRequest)
                            return false
                        return CurrentConversation.isSwarm || CurrentConversation.isTemporary
                    }

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    Layout.maximumHeight: JamiTheme.chatViewFooterMaximumHeight

                    DropArea {
                        anchors.fill: parent
                        onDropped: chatViewFooter.setFilePathsToSend(drop.urls)
                    }
                }
            }

            SwarmDetailsPanel {
                id: swarmDetailsPanel
                visible: false

                SplitView.maximumWidth: splitView.width
                SplitView.preferredWidth: Math.max(JamiTheme.detailsPageMinWidth, splitView.width / 3)
                SplitView.minimumWidth: JamiTheme.detailsPageMinWidth
                SplitView.fillHeight: true
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            AddMemberPanel {
                id: addMemberPanel
                visible: false

                SplitView.maximumWidth: splitView.width
                SplitView.preferredWidth: Math.max(JamiTheme.detailsPageMinWidth, splitView.width / 3)
                SplitView.minimumWidth: JamiTheme.detailsPageMinWidth
                SplitView.fillHeight: true
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
