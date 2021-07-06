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

    enum Mode {
        Chat = 0,
        Invitation
    }

    property string headerUserAliasLabelText: ""
    property string headerUserUserNameLabelText: ""
    property bool jsLoaded: false
    property var mode: MessageWebView.Mode.Chat



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
    function isUrl(str) {
        var pattern = new RegExp('^(https?:\\/\\/)?'+
                                 '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'+
                                 '((\\d{1,3}\\.){3}\\d{1,3}))'+
                                 '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'+
                                 '(\\?[;&a-z\\d%_.~+=-]*)?'+
                                 '(\\#[-a-z\\d_]*)?$','i');
        return !!pattern.test(str);
    }

    function hasUrl(message){
        var messArr = message.split(" ")
        for (var i = 0; i < messArr.length; i++){
            if (isUrl(messArr[i])){
                return messArr[i]
            }
        }
        return ""
    }

    /**
     * Transform a date to a string group like "1 hour ago".
     *
     * @param date
     */
    function formatDate(date) {

        var dateString = "20" + date.charAt(6) + date.charAt(7) + "-" + date.charAt(3) +  date.charAt(4) + "-" + date.charAt(0) + date.charAt(1)
        const seconds = Math.floor((new Date() - Date.parse(dateString)) / 1000)
        var interval = Math.floor(seconds / (3600 * 24))
        if (interval > 5)
            return date
        if (interval > 1)
            return interval + " days ago"
        if (interval === 1)
            return "one day ago"
        interval = Math.floor(seconds / 3600)
        if (interval > 1)
            return interval + " hours ago"
        if (interval === 1)
            return "one hour ago"
        interval = Math.floor(seconds / 60)
        if (interval > 1)
            return interval + " minutes ago"
        return "just now"
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
            // was not going all the way down so i added listview.flick
            listView.ScrollBar.vertical.position = 1.0 - listView.ScrollBar.vertical.size

            listView.flick(0, -1000)

            MessagesAdapter.beginBuildPreview(1, "https://youtube.com");
        }

        function onPreviewInformationToQML(messageId, previewInformation){
            console.log(messageId + "   " +  previewInformation)

            var item = listView.itemAtIndex(messageId)

        }
    }

    Connections {
        target: MessagesAdapter

        function onSetChatViewMode(showInvitationPage,
                                   isSwarm, needsSyncing,
                                   title, convId) {
            if (showInvitationPage)
                root.mode = MessageWebView.Mode.Invitation
            else {
                root.mode = MessageWebView.Mode.Chat
                return
            }

            invitationView.imageId = convId
            invitationView.title = title
            invitationView.needSyncing = needsSyncing
        }
    }

    Connections {
        target: ConversationsAdapter

        function onCurrentConvIsReadOnlyChanged() {
            var isVisible = !ConversationsAdapter.currentConvIsReadOnly
            setMessagingHeaderButtonsVisible(isVisible)
            messageWebViewFooter.visible = isVisible
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

            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollBar.vertical: ScrollBar {
                id: scrollBar
            }
            delegate:




                Column{

                readonly property bool sentByMe: model.Author === ""
                readonly property bool isTextMessage: model.Type === 1

                property var previewTitle: ""
                property var previewImage: ""
                property var previewDescription: ""
                property var previewUrl: ""


                Connections {
                    target: MessagesAdapter.messageListModel

                    function onPreviewDataAdded(topLeft, bottomRight) {

                        if (HyperlinkInformation.url !== undefined){

                            previewTitle = HyperlinkInformation.title
                            previewImage = HyperlinkInformation.image
                            previewDescription = HyperlinkInformation.description

                            previewUrl = HyperlinkInformation.url

                            previewLoader.sourceComponent = previewComponent
                            previewLoader.width = 200
                            previewLoader.height = 320

                            squareRect.visible = true
                            squareRect.width = squareRect.width * 2
                            squareRect.anchors.left = textBackground.left
                            squareRect.anchors.right = textBackground.right
                            textBackground.width = previewLoader.width - 15

                            row.spacing = 0
                            column.bottomPadding = 0

                        }
                    }


                }




                readonly property var formattedTimeStamp: formatDate(Timestamp)

                id: column

                bottomPadding: 10
                Layout.fillWidth: true
                anchors.right: sentByMe ? listView.contentItem.right : undefined

                Component.onCompleted: {
                    var url = hasUrl(MessageBody)

                    if (url !== ""){
                        MessagesAdapter.beginBuildPreview(MessageId, url)
                    }


                }



                Row{
                    id: row
                    spacing: 5
                    Layout.fillWidth: true
                    anchors.right: sentByMe ? parent.right : undefined

                    Avatar{
                        id: avatar
                        width: 30
                        height: 30
                        imageId: sentByMe ? "" : Author
                        showPresenceIndicator: false
                        mode: Avatar.Mode.Contact
                        visible: true
                    }

                    Rectangle {
                        id: textBackground
                        height: messageText.implicitHeight + 24
                        radius: 20

                        width:  Math.min(messageText.implicitWidth + 24,
                                         300)
                        color: sentByMe ? "#cfd8dc" : "#cfebf5"


                        Rectangle {
                            id: squareRect

                            visible: true
                            color: textBackground.color
                            height: textBackground.radius
                            width: textBackground.width / 2
                            anchors.bottom: textBackground.bottom
                            anchors.left: sentByMe ? undefined : textBackground.left
                            anchors.right: sentByMe ? textBackground.right : undefined

                        }
                        TextArea{
                            id: messageText
                            text: MessageBody
                            //width: Math.min(300, implicitWidth)
                            anchors.fill: parent
                            //anchors.margin: 12
                            wrapMode: TextArea.WrapAnywhere
                            color: sentByMe ? "black" : "black"
                            readOnly: true
                            selectByMouse: true

                        }

                        //                        Label {
                        //                            id: messageText
                        //                            text: MessageBody

                        //                            anchors.fill: parent
                        //                            anchors.margins: 12
                        //                            wrapMode: Label.WrapAnywhere
                        //                            color: sentByMe ? "" : "black"
                        //                        }

                    }

                    Rectangle{
                        id: dummyMessageSpace
                        visible: false
                        color: "transparent"
                        width: 10
                        height: 10
                    }
                    Component.onCompleted: {

                        if (isTextMessage){
                            if(sentByMe){
                                dummyMessageSpace.visible = true
                            }
                            return
                        }
                        textBackground.color = "transparent"
                        column.anchors.right = undefined
                        column.anchors.horizontalCenter = listView.contentItem.horizontalCenter
                        row.anchors.right = undefined
                        row.anchors.horizontalCenter= column.horizontalCenter
                    }
                }

                //                Item{
                //                    id: previewItem
                //                    width: 200
                //                    height: 320
                //                    visible: false

                Loader{
                    anchors.right: sentByMe ? parent.right : undefined

                    id: previewLoader
                    //     anchors.centerIn: parent

                    Component.onCompleted:{
                        //                        if (urlFromMessage !== ""){
                        //                        if (HyperlinkInformation.title !== undefined){



                        //                            previewLoader.sourceComponent = previewComponent
                        //                            previewLoader.width = 200
                        //                            previewLoader.height = 250

                        //                            squareRect.visible = true
                        //                            squareRect.width = squareRect.width * 2
                        //                            squareRect.anchors.left = textBackground.left
                        //                            squareRect.anchors.right = textBackground.right
                        //                            textBackground.width = previewLoader.width - 15

                        //                            row.spacing = 0
                        //                            column.bottomPadding = 0
                        //                        }
                    }
                    Component{
                        id: previewComponent

                        /*                       Column{

                                                    Rectangle{
                                                        color: "red"
                                                        width: 50
                                                        height: 50
                                                        Rectangle {
                                                            id: previewTextBackground
                                                            height: messageText.implicitHeight + 24
                                                            radius: 20
                                                            anchors.right: parent.right
                                                            width:  Math.min(messageText.implicitWidth + 24,
                                                                             300)
                                                            color: sentByMe ? "#cfd8dc" : "#cfebf5"


                                                            Rectangle {
                                                                id: previewSquareRect

                                                                visible: true
                                                                color: previewTextBackground.color
                                                                height: previewTextBackground.radius
                                                                width: previewTextBackground.width
                                                                anchors.bottom: previewTextBackground.bottom
                                                                anchors.left: sentByMe ? undefined : previewTextBackground.left
                                                                anchors.right: sentByMe ? previewTextBackground.right : undefined

                                                            }

                                                            Label {
                                                                id: messageText
                                                                text: MessageBody

                                                                anchors.fill: parent
                                                                anchors.right: previewTextBackground.right
                                                                anchors.margins: 12
                                                                wrapMode: Label.WrapAnywhere
                                                                color: sentByMe ? "black" : "black"
                                                            }
                                                        }
                                                    }*/

                        WebEngineView{
                            backgroundColor: "blue"

                            //                            height: 320
                            //                            width: 200

                            id: previewWev

                            anchors.fill: parent


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

                                console.log(previewUrl)

                                previewWev.runJavaScript(UtilsAdapter.qStringFromFile(
                                                             ":/previewInfo.js"))

                                previewWev.loadHtml("
                                                                    <head> <link rel=\"stylesheet\" href=\"qrc:/src/mainview/components/previewCSS.css\"> </head>
                                                                    <body>
                                                                    <div class=\"msg_cell_with_preview\">
                                                                       <div class=\"preview_wrapper_in\">
                                                                          <div class=\"preview_card_container\">
                                                                             <div class=\"card_container_in\">
                                                                                <a class=\"preview_container_link\" href=\"" + previewUrl + "\" target=\"_blank\">
                                                                                   <img class=\"preview_image\" src=\"" + previewImage + "\">
                                                                                   <div class=\"preview_text_container\">
                                                                                      <pre class=\"preview_card_title\">" + previewTitle + "</pre>
                                                                                      <p class=\"preview_card_subtitle\">" + previewDescription + "</p>
                                                                                      <p class=\"preview_card_link\">" + previewUrl + "</p>
                                                                                   </div>
                                                                                </a>
                                                                             </div>
                                                                          </div>
                                                                       </div>
                                                                    </div>
                                                                    </body>", "")


                            }
                        }
                        //  }
                    }
                    //                    Row{

                    //                        //anchors.right: row.right
                    //                        Loader{

                    //                            //                    anchors.right: sentByMe ? parent.right : undefined
                    //                            anchors.right: undefined
                    //                            id: timestampLoader
                    //                            // sourceComponent: timestampComponent
                    //                            Component.onCompleted: {
                    //                                if (sentByMe && isTextMessage){
                    //                                    sourceComponent = timestampComponent
                    //                                    dummyTimeSpace.visible = true
                    //                                }
                    //                            }

                    //                            Component{

                    //                                id: timestampComponent
                    //                                Label {
                    //                                    id: timestampText
                    //                                    text: formatDate(Timestamp)
                    //                                    color: "lightgrey"
                    //                                }
                    //                            }
                    //                        }

                    //                        Rectangle{
                    //                            id: dummyTimeSpace
                    //                            visible: false
                    //                            color: "black"
                    //                            height: 10
                    //                            width: 15
                    //                        }
                    //                    }
                }
                // }

            }
        }

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

