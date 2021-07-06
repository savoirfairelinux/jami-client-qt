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
import QtWebEngine 1.10
import QtWebChannel 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"
import "../../../images"
import "../js/pluginhandlerpickercreation.js" as PluginHandlerPickerCreation

Rectangle {
    id: root

    property string headerUserAliasLabelText: ""
    property string headerUserUserNameLabelText: ""
    property bool jsLoaded: false



    signal needToHideConversationInCall
    signal messagesCleared
    signal messagesLoaded

    // function setSendMessageContent(content) {
    //     jsBridgeObject.setSendMessageContentRequest(content)
    // }

    function focusMessageWebView() {
        listView.forceActiveFocus()
    }

    // function webViewRunJavaScript(arg) {
    //     messageWebView.runJavaScript(arg)
    // }

    function setSendContactRequestButtonVisible(visible) {
        messageWebViewHeader.sendContactRequestButtonVisible = visible
    }

    function setMessagingHeaderButtonsVisible(visible) {
        messageWebViewHeader.toggleMessagingHeaderButtonsVisible(visible)
    }

    function resetMessagingHeaderBackButtonSource(reset) {
        messageWebViewHeader.resetBackToWelcomeViewButtonSource(reset)
    }

    // function updateChatviewTheme() {
    //     var theme = 'setTheme("\
    //         --svg-invert-percentage:' + JamiTheme.invertPercentageInDecimal + ';\
    //         --jami-light-blue:' + JamiTheme.jamiLightBlue + ';\
    //         --jami-dark-blue: ' + JamiTheme.jamiDarkBlue + ';\
    //         --text-color: ' + JamiTheme.chatviewTextColor + ';\
    //         --timestamp-color:' + JamiTheme.timestampColor + ';\
    //         --message-out-bg:' + JamiTheme.messageOutBgColor + ';\
    //         --message-out-txt:' + JamiTheme.messageOutTxtColor + ';\
    //         --message-in-bg:' + JamiTheme.messageInBgColor + ';\
    //         --message-in-txt:' + JamiTheme.messageInTxtColor + ';\
    //         --file-in-timestamp-color:' + JamiTheme.fileOutTimestampColor + ';\
    //         --file-out-timestamp-color:' + JamiTheme.fileInTimestampColor + ';\
    //         --bg-color:' + JamiTheme.chatviewBgColor + ';\
    //         --action-icon-color:' + JamiTheme.chatviewButtonColor + ';\
    //         --action-icon-hover-color:' + JamiTheme.hoveredButtonColor + ';\
    //         --action-icon-press-color:' + JamiTheme.pressedButtonColor + ';\
    //         --placeholder-text-color:' + JamiTheme.placeholderTextColor + ';\
    //         --invite-hover-color:' + JamiTheme.inviteHoverColor + ';\
    //         --bg-text-input:' + JamiTheme.bgTextInput + ';\
    //         --bg-invitation-rect:' + JamiTheme.bgInvitationRectColor + ';\
    //         --preview-text-container-color:' + JamiTheme.previewTextContainerColor + ';\
    //         --preview-title-color:' + JamiTheme.previewTitleColor + ';\
    //         --preview-subtitle-color:' + JamiTheme.previewSubtitleColor + ';\
    //         --preview-image-background-color:' + JamiTheme.previewImageBackgroundColor + ';\
    //         --preview-card-container-color:' + JamiTheme.previewCardContainerColor + ';\
    //         --preview-url-color:' + JamiTheme.previewUrlColor + ';")'
    //     messageWebView.runJavaScript("init_picker(" + JamiTheme.darkTheme + ");")
    //     messageWebView.runJavaScript(theme);
    // }

    color: JamiTheme.primaryBackgroundColor

    Connections {
        target: JamiTheme

        function onDarkThemeChanged() {
            updateChatviewTheme()
        }


    }
    Connections{
        target: MessagesAdapter
        function onNewInteraction(interaction_type){
          listView.ScrollBar.vertical.position = 1.0 - listView.ScrollBar.vertical.size

        }
    }


    QtObject {
        id: jsBridgeObject

        // ID, under which this object will be known at chatview.js side.
        WebChannel.id: "jsbridge"

        // signals to trigger functions in chatview.js
        // mainly used to avoid input arg string escape
        signal setSendMessageContentRequest(string content)

        // Functions that are exposed, return code can be derived from js side
        // by setting callback function.
        function deleteInteraction(arg) {
            MessagesAdapter.deleteInteraction(arg)
        }

        function retryInteraction(arg) {
            MessagesAdapter.retryInteraction(arg)
        }

        function openFile(arg) {
            MessagesAdapter.openFile(arg)
        }

        function acceptFile(arg) {
            MessagesAdapter.acceptFile(arg)
        }

        function refuseFile(arg) {
            MessagesAdapter.refuseFile(arg)
        }

        function acceptInvitation() {
            MessagesAdapter.acceptInvitation()
        }

        function refuseInvitation() {
            MessagesAdapter.refuseInvitation()
        }

        function blockConversation() {
            MessagesAdapter.blockConversation()
        }

        function emitMessagesCleared() {
            root.messagesCleared()
        }

        function emitMessagesLoaded() {
            root.messagesLoaded()
        }

        function copyToDownloads(interactionId, displayName) {
            MessagesAdapter.copyToDownloads(interactionId, displayName)
        }

        function parseI18nData() {
            return MessagesAdapter.chatviewTranslatedStrings
        }

        function loadMessages(n) {
            return MessagesAdapter.loadMessages(n)
        }
    }



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

        ListView{
            id: listView
            model: MessagesAdapter.messageListModel
            Component.onCompleted:{
                jsLoaded = true
            }

            height: root.height - messageWebViewHeader.height - messageWebViewFooter.height - 50
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.fillWidth: true

            ScrollBar.vertical: ScrollBar {
                id: scrollBar
            }
            clip: true
            delegate:

                Column{

                readonly property bool sentByMe: model.Author === ""
                readonly property bool isTextMessage: model.Type === 1
                readonly property var urlFromMessage: MessagesAdapter.messageHasUrl(model.MessageBody)

                id: column

                bottomPadding: 10
                Layout.fillWidth: true
                anchors.right: sentByMe ? listView.contentItem.right : undefined
                Row{
                    id: row
                    spacing: 5
                    Layout.fillWidth: true
                    anchors.right: sentByMe ? parent.right : undefined

                    Image{
                        id: avatar
                        source: sentByMe ? "" : "../../../images/jami.png"
                        width: 30
                        height: 30
                    }

                    Rectangle {
                        id: textBackground
                        height: messageText.implicitHeight + 24
                        radius: 20

                        width:  Math.min(messageText.implicitWidth + 24,
                                         300)
                        color: sentByMe ? "cyan" : "lightgrey"


//                        Rectangle {
//                          id: squareRect

//                          color: textBackground.color
//                          height: textBackground.radius
//                          anchors.bottom: textBackground.bottom
//                          anchors.left: textBackground.left
//                          anchors.right: textBackground.right

//                        }
                        Label {
                            id: messageText
                            text: MessageBody
                           // width: 300

                            anchors.fill: parent
                            anchors.margins: 12
                            wrapMode: Label.WrapAnywhere
                            color: sentByMe ? "black" : "black"
                        }

                    }
                    Component.onCompleted: {
                        if (isTextMessage){
                            return
                        }

                        textBackground.color = "transparent"
                      //  squareRect.color = "transparent"
                        column.anchors.right = undefined
                        column.anchors.horizontalCenter = listView.contentItem.horizontalCenter
                        row.anchors.right = undefined
                        row.anchors.horizontalCenter= column.horizontalCenter
                        avatar.source = ""


                    }
                }


                Loader{
                    anchors.right: sentByMe ? parent.right : undefined
                    id: previewLoader

                    Component.onCompleted:{
//                        if (urlFromMessage !== ""){
                        if (MessageBody.includes("JD123")){

                            sourceComponent = previewComponent
                            previewLoader.width = 200
                            previewLoader.height = 250

                            textBackground.width = previewLoader.width - 20

                            row.spacing = 0
                            column.bottomPadding = 0
                        }
                    }
                }
                Component{
                    id: previewComponent
                    WebEngineView{


                        id: previewWev

                        settings.javascriptEnabled: true
                        settings.javascriptCanOpenWindows: true
                        settings.javascriptCanAccessClipboard: true
                        settings.javascriptCanPaste: true
                        settings.fullScreenSupportEnabled: true
                        settings.allowRunningInsecureContent: true
                        settings.localContentCanAccessRemoteUrls: true
                        settings.localContentCanAccessFileUrls: true
                        settings.errorPageEnabled: false
                        settings.pluginsEnabled: false
                        settings.screenCaptureEnabled: false
                        settings.linksIncludedInFocusChain: false
                        settings.localStorageEnabled: true

                        Component.onCompleted: {

                           previewWev.runJavaScript(UtilsAdapter.qStringFromFile(
                                                                         ":/previewInfo.js"))

                            previewWev.loadHtml("
                <head> <link rel=\"stylesheet\" href=\"qrc:/src/mainview/components/previewCSS.css\"> </head>
                <body>
                <div class=\"msg_cell_with_preview\">
                   <div class=\"preview_wrapper_in\">
                      <div class=\"preview_card_container\">
                         <div class=\"card_container_in\">
                            <a class=\"preview_container_link\" href=\"http://lapresse.com\" target=\"_blank\">
                               <img class=\"preview_image\" src=\"https://static.lpcdn.ca/lpweb/lapresse/img/share/lapresse.png\">
                               <div class=\"preview_text_container\">
                                  <pre class=\"preview_card_title\">LaPresse.ca | Actualités et Infos au Québec et dans le monde</pre>
                                  <p class=\"preview_card_subtitle\">Le site d'information francophone le plus complet en Amérique du Nord: Actualités régionales, provinciales, nationales et internationales.</p>
                                  <p class=\"preview_card_link\">lapresse.com</p>
                               </div>
                            </a>
                         </div>
                      </div>
                   </div>
                </div>
                </body>", "")
                        }
                    }
                }
                Loader{
                    anchors.right: sentByMe ? parent.right : undefined
                    id: timestampLoader
                    // sourceComponent: timestampComponent
                    Component.onCompleted: {
                        if (sentByMe && isTextMessage){
                            sourceComponent = timestampComponent
                        }
                    }

                    Component{

                        id: timestampComponent
                        Label {
                            id: timestampText
                            text: Timestamp
                            color: "lightgrey"
                        }
                    }
                }
            }
        }

        // WebEngineView {
        //     id: messageWebView

        //     Layout.alignment: Qt.AlignHCenter
        //     Layout.fillWidth: true
        //     Layout.fillHeight: true
        //     Layout.topMargin: JamiTheme.messageWebViewHairLineSize
        //     Layout.bottomMargin: JamiTheme.messageWebViewHairLineSize

        //     backgroundColor: "transparent"

        //     // settings.javascriptEnabled: true
        //     // settings.javascriptCanOpenWindows: true
        //     // settings.javascriptCanAccessClipboard: true
        //     // settings.javascriptCanPaste: true
        //     // settings.fullScreenSupportEnabled: true
        //     // settings.allowRunningInsecureContent: true
        //     // settings.localContentCanAccessRemoteUrls: true
        //     // settings.localContentCanAccessFileUrls: true
        //     // settings.errorPageEnabled: false
        //     // settings.pluginsEnabled: false
        //     // settings.screenCaptureEnabled: false
        //     // settings.linksIncludedInFocusChain: false
        //     // settings.localStorageEnabled: true

        //     webChannel: messageWebViewChannel

        //     DropArea {
        //         anchors.fill: parent
        //         onDropped: messageWebViewFooter.setFilePathsToSend(drop.urls)
        //     }

        //     onNavigationRequested: {
        //         if (request.navigationType === WebEngineView.LinkClickedNavigation) {
        //             MessagesAdapter.openUrl(request.url)
        //             request.action = WebEngineView.IgnoreRequest
        //         }
        //     }

        //     onLoadingChanged: {
        //         if (loadRequest.status == WebEngineView.LoadSucceededStatus) {
        //             messageWebView.runJavaScript(UtilsAdapter.getStyleSheet(
        //                                              "chatcss",
        //                                              UtilsAdapter.qStringFromFile(
        //                                                  ":/chatview.css")))
        //             messageWebView.runJavaScript(UtilsAdapter.getStyleSheet(
        //                                              "chatwin",
        //                                              UtilsAdapter.qStringFromFile(
        //                                                  ":/chatview-qt.css")))
        //             messageWebView.runJavaScript(UtilsAdapter.qStringFromFile(
        //                                              ":/linkify.js"))
        //             messageWebView.runJavaScript(UtilsAdapter.qStringFromFile(
        //                                              ":/linkify-html.js"))
        //             messageWebView.runJavaScript(UtilsAdapter.qStringFromFile(
        //                                              ":/linkify-string.js"))
        //             messageWebView.runJavaScript(UtilsAdapter.qStringFromFile(
        //                                              ":/qwebchannel.js"))
        //             messageWebView.runJavaScript(UtilsAdapter.qStringFromFile(
        //                                              ":/jed.js"))
        //             messageWebView.runJavaScript(UtilsAdapter.qStringFromFile(
        //                                              ":/emoji.js"))
        //             messageWebView.runJavaScript(UtilsAdapter.qStringFromFile(
        //                                              ":/previewInfo.js"))
        //             messageWebView.runJavaScript(
        //                         UtilsAdapter.qStringFromFile(":/chatview.js"),
        //                         function() {
        //                             messageWebView.runJavaScript("init_i18n();")
        //                             MessagesAdapter.setDisplayLinks()
        //                             updateChatviewTheme()
        //                             messageWebView.runJavaScript("displayNavbar(false);")
        //                             messageWebView.runJavaScript("hideMessageBar(true);")
        //
        //                         })
        //         }
        //     }

        //     onContextMenuRequested: {
        //         var needContextMenu = request.selectedText.length || request.isContentEditable
        //         if (!needContextMenu)
        //             request.accepted = true
        //     }

        //     Component.onCompleted: {
        //         profile.cachePath = UtilsAdapter.getCachePath()
        //         profile.persistentStoragePath = UtilsAdapter.getCachePath()
        //         profile.persistentCookiesPolicy = WebEngineProfile.NoPersistentCookies
        //         profile.httpCacheType = WebEngineProfile.NoCache
        //         profile.httpUserAgent = JamiStrings.httpUserAgentName

        //         messageWebView.loadHtml(UtilsAdapter.qStringFromFile(
        //                                     ":/chatview.html"), ":/chatview.html")
        //         messageWebView.url = "qrc:/chatview.html"
        //     }
        // }

        MessageWebViewFooter {
            id: messageWebViewFooter

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
