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
import QtWebEngine

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
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

    Loader {
        id: mapLoader

        active: MessagesAdapter.isMapActive
        z: 10
        //anchors.centerIn: root
        sourceComponent: mapComp
    }

    Component {
        id: mapComp

        Rectangle
        {
            id: mapPopup

            x: 10
            y: 10
            width: isFullScreen ? root.width : windowSize
            height: isFullScreen ? root.height : windowSize
            color: "black"

            property bool isFullScreen: false
            property real windowSize: windowPreferedSize > JamiTheme.minimumMapWidth
                                      ? windowPreferedSize
                                      : JamiTheme.minimumMapWidth
            property real windowPreferedSize: root.width > root.height
                                              ? root.height / 3
                                              : root.width / 3

            onWindowSizeChanged: {
                console.warn(windowSize)
            }

            Component.onCompleted: {
                console.warn(width, height)
            }

            WebEngineView {
                id: webView

                property string mapHtml: ":/commoncomponents/mapWebengine/map.html"
                property string olCss: ":/commoncomponents/mapWebengine/ol.css"
                // TODO: fix urls
                property string mapJs: "../../commoncomponents/mapWebengine/map.js"
                property string olJs: "../../commoncomponents/mapWebengine/ol.js"
                property bool isLoaded: false

                property int zoom: 2
                property var positionList: MessagesAdapter.positionList;
                property var avatarPositionList: MessagesAdapter.avatarPositionList;
                property bool couldSendAvatar: false
                property bool setZoom: false

                width: parent.width
                height: parent.height

                function dynamicZoom() {
                    //zoom and center the map according to shared positions
                    var avgLat = 0;
                    var avgLong = 0;
                    var gapPosLat = 0;
                    var gapPosLong = 0;

                    //maximum values according to convention
                    var rangeLat = 360
                    var rangeLong = 180

                    var minPosLat = 181;
                    var maxPosLat = -181;
                    var minPosLong = 91;
                    var maxPosLong = -91;

                    var maxZoom = 17
                    var minZoom = 1

                    if(webView.isLoaded) {

                        for(var i = 0; i < positionList.length; i++) {
                            avgLat += positionList[i].lat;
                            avgLong += positionList[i].long;
                            if(positionList[i].lat > maxPosLat )
                                maxPosLat = positionList[i].lat;
                            if(positionList[i].lat < minPosLat )
                                minPosLat = positionList[i].lat
                            if(positionList[i].long > maxPosLong )
                                maxPosLong = positionList[i].long;
                            if(positionList[i].long < minPosLong )
                                minPosLong = positionList[i].long

                        }
                        avgLat = avgLat / positionList.length;
                        avgLong = avgLong / positionList.length;
                        console.warn("minPosLong: ", minPosLong );
                        console.warn("maxPosLong: ", maxPosLong );
                        console.warn("minPosLat: ", minPosLat );
                        console.warn("maxPosLat: ", maxPosLat );
                        gapPosLat = Math.abs(maxPosLat - minPosLat);
                        gapPosLong = Math.abs(maxPosLong - minPosLong);
                        console.warn("gapPosLat: ", gapPosLat )
                        console.warn("gapPosLong: ", gapPosLong )
                        var dynamicZoom_lat =  gapPosLat * (- (maxZoom - minZoom ) / rangeLat) + maxZoom
                        var dynamicZoom_long =  gapPosLong  * (- (maxZoom - minZoom ) / rangeLong) + maxZoom
                        var dynamicZoom = 2
                        if ( dynamicZoom_lat > dynamicZoom_long )
                            dynamicZoom = dynamicZoom_long
                        else
                            dynamicZoom = dynamicZoom_lat
                        console.warn("dynamic zoomLat: ", dynamicZoom_lat )
                        console.warn("dynamic zoomLong: ", dynamicZoom_long )
                        console.warn("dynamic zoom: ", dynamicZoom )
                        runJavaScript("setMapView([" + avgLong + ","+ avgLat  + "], " + dynamicZoom + " );" );
                    }

                }
                function sendAvatarListToJs () {
                    console.warn("setAvatarList -------------------------------------------------------------");
                    //console.warn("setAvatarList ( '" + avatarPositionList[0].author + "','" +avatarPositionList[0].avatar + "' );");
                    for(var i = 0; i < avatarPositionList.length; i++) {
                        runJavaScript("setAvatarList ( '" + avatarPositionList[i].author + "','" +avatarPositionList[i].avatar + "' );");
                    }
                    setZoom = true

                }

                Component.onCompleted: {

                    loadHtml(UtilsAdapter.qStringFromFile(mapHtml), mapHtml);
                    var scriptMapJs = {
                        sourceUrl: Qt.resolvedUrl(mapJs),
                        injectionPoint: WebEngineScript.DocumentReady,
                        worldId: WebEngineScript.MainWorld
                    }
                    var scriptOlJs = { name: "olJs",
                        sourceUrl: Qt.resolvedUrl(olJs),
                        injectionPoint: WebEngineScript.DocumentReady,worldId: WebEngineScript.MainWorld }


                    userScripts.collection = [ scriptOlJs, scriptMapJs ];
                    couldSendAvatar = false;

                }
                onVisibleChanged: {
                    couldSendAvatar = false;
                }

                onLoadingChanged: function (loadingInfo) {

                    if (loadingInfo.status === WebEngineView.LoadSucceededStatus) {
                        webView.isLoaded = true
                        runJavaScript(UtilsAdapter.getStyleSheet("olcss",UtilsAdapter.qStringFromFile(olCss)))
                        runJavaScript("setMapView([" + 0 + ","+ 0  + "], " + zoom + " );" );
                        //runJavaScript("printIcon();" );
                        //runJavaScript("printIcon([" + 0 + ","+0  + "] );" );
                        MessagesAdapter.startPositioning()
                    }
                }
                onAvatarPositionListChanged : {
                    if(webView.isLoaded) {
                        couldSendAvatar = true;
                        sendAvatarListToJs();
                    }
                }

                onPositionListChanged: {

                    if(webView.isLoaded) {
                        if (! couldSendAvatar) {
                            couldSendAvatar = true;
                            //console.warn("send avatar last option");
                            sendAvatarListToJs();

                        }
                        runJavaScript("resetPoints();" );
                        for(var i = 0; i < positionList.length; i++) {
                            //console.warn("layer: " + positionList[i].long + " " + positionList[i].lat );
                            runJavaScript("printIcon([" + positionList[i].long + ","+ positionList[i].lat  + "], '" + positionList[i].author+ "' );" );
                        }
                        if(setZoom) {
                            dynamicZoom()
                            setZoom = false
                        }

                    }
                }
            }

            MaterialButton {
                property bool isSharing: false;
                anchors.horizontalCenter: mapPopup.horizontalCenter;
                anchors.bottom: mapPopup.bottom;
                preferredWidth: text.contentWidth
                textLeftPadding: JamiTheme.buttontextPadding
                textRightPadding: JamiTheme.buttontextPadding
                primary:true
                text: isSharing ? JamiStrings.stopSharingPosition : JamiStrings.sharePosition

                onClicked: {
                    if(isSharing) {
                        MessagesAdapter.stopSharingPosition();
                    } else {
                        MessagesAdapter.sharePosition();
                    }
                    isSharing = !isSharing
                }


            }

            PushButton {
                id: btnClose

                anchors.right: mapPopup.right
                anchors.top: mapPopup.top
                anchors.topMargin: JamiTheme.preferredMarginSize
                anchors.rightMargin: JamiTheme.preferredMarginSize
                imageColor: "grey"
                normalColor: JamiTheme.transparentColor

                source: JamiResources.round_close_24dp_svg

                onClicked: {MessagesAdapter.isMapActive = false}
            }

            PushButton {
                id: btnmaximise

                anchors.right: btnClose.left
                anchors.top: mapPopup.top
                anchors.topMargin: JamiTheme.preferredMarginSize
                anchors.rightMargin: JamiTheme.preferredMarginSize
                imageColor: "grey"
                normalColor: JamiTheme.transparentColor
                source: isFullScreen? JamiResources.close_fullscreen_24dp_svg : JamiResources.open_in_full_24dp_svg

                onClicked: {
                    if (!isFullScreen) {
                        mapPopup.x = 0
                        mapPopup.y = 0
                    }
                    isFullScreen = !isFullScreen
                }
            }

            PushButton {
                id: btnMove

                anchors.right: btnmaximise.left
                anchors.top: mapPopup.top
                anchors.topMargin: JamiTheme.preferredMarginSize
                anchors.rightMargin: JamiTheme.preferredMarginSize
                imageColor: "grey"
                normalColor: JamiTheme.transparentColor

                source: JamiResources.hand_black_24dp_svg

                MouseArea {
                    anchors.fill: parent
                    drag.target: mapPopup
                    drag.minimumX: 0
                    drag.maximumX: root.width - mapPopup.width
                    drag.minimumY: 0
                    drag.maximumY: root.height - mapPopup.height
                }

            }
        }
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
