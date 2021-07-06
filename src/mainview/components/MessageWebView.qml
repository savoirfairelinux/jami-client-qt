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
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

Rectangle {
    id: root

    property string headerUserAliasLabelText: ""
    property string headerUserUserNameLabelText: ""
    property bool jsLoaded: false

    property bool allMessagesLoaded

    signal needToHideConversationInCall
    signal messagesCleared
    signal messagesLoaded

    // TODO: fix me
    function focusChatView() {
        chatView.forceActiveFocus()
    }

    color: JamiTheme.primaryBackgroundColor

    ColumnLayout {
        anchors.fill: root

        spacing: 0

        MessageWebViewHeader {
            id: messageWebViewHeader

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.messageWebViewHeaderPreferredHeight
            Layout.maximumHeight: JamiTheme.messageWebViewHeaderPreferredHeight

            userAliasLabelText: headerUserAliasLabelText
            userUserNameLabelText: headerUserUserNameLabelText

            DropArea {
                anchors.fill: parent
                onDropped: messageWebViewFooter.setFilePathsToSend(drop.urls)
            }

            onBackClicked: {
                mainView.showWelcomeView()
            }

            onNeedToHideConversationInCall: {
                root.needToHideConversationInCall()
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

        StackLayout {
            id: messageWebViewStack

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: JamiTheme.messageWebViewHairLineSize
            Layout.bottomMargin: JamiTheme.messageWebViewHairLineSize

            currentIndex: CurrentConversation.isRequest || CurrentConversation.needsSyncing

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignRight


                ListView {
                    id: chatView

                    Layout.alignment: Qt.AlignRight


                    onAtYBeginningChanged: {
                        if (chatView.atYBeginning){
                            MessagesAdapter.loadMoreMessages()
                            console.log("MESSAGES LOADED " + !CurrentConversation.allMessagesLoaded)
                        }
                    }

                    header: Loader {

                        active: !CurrentConversation.allMessagesLoaded

                        sourceComponent: loadingComponent
                        height: active * 30
                        width: chatView.width

                        Component {
                            id: loadingComponent
                            Rectangle {
                                height: 30
                                width: chatView.width
                                TextArea{
                                    text: "Loading..."
                                    anchors.centerIn: parent
                                }

                            }
                        }


                        // all messagesloaded is false, then it is visible
                        // current conversation-> add property (qml property) to know if all messages are loaded
                        // if (atYbeginning and header item is visible (or not messages loaded)) then
                        // onatYbeginning changed and ^ then invoke loading of 20 more messages
                    }

                    model: MessagesAdapter.messageListModel

                    displayMarginBeginning: height * 2
                    displayMarginEnd: height * 2

                    // TODO: remove this
                    Component.onCompleted: {
                        jsLoaded = true
                    }

                    width: parent.width
                    implicitHeight: Math.min(contentHeight,
                                             parent.height)
                    anchors.bottom: parent.bottom
                    boundsBehavior: Flickable.StopAtBounds

                    clip: true
                    verticalLayoutDirection: ListView.TopToBottom

                    ScrollBar.vertical: ScrollBar {}

                    delegate: MessageDelegate {}

                    Connections {
                        target: MessagesAdapter

                        function onNewInteraction(interaction_type){
                            // was not going all the way down so i added listview.flick
                            chatView.ScrollBar.vertical.position = 1.0 - chatView.ScrollBar.vertical.size
                            chatView.flick(0, -1000)
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        onDropped: messageWebViewFooter.setFilePathsToSend(drop.urls)
                    }
                }
            }

            InvitationView {
                id: invitationView

                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        ReadOnlyFooter {
            visible: CurrentConversation.readOnly
            Layout.fillWidth: true
        }

        MessageWebViewFooter {
            id: messageWebViewFooter

            visible: {
                if (CurrentConversation.needsSyncing || CurrentConversation.readOnly)
                    return false
                else if (CurrentConversation.isSwarm && CurrentConversation.isRequest)
                    return false
                return true
            }

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            Layout.maximumHeight: JamiTheme.messageWebViewFooterMaximumHeight

            DropArea {
                anchors.fill: parent
                onDropped: messageWebViewFooter.setFilePathsToSend(drop.urls)
            }
        }
    }
}
