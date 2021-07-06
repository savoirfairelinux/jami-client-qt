import QtQuick 2.14
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtWebEngine 1.8

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

ColumnLayout {
    id: root

    readonly property bool sentByMe: model.Author === ""
    readonly property bool isTextMessage: model.Type === 1
    readonly property var formattedTimeStamp: formatDate(Timestamp)

    property bool previewLoaded: false
    property var previewUrl: ""
    property var previewTitle: ""
    property var previewImage: ""
    property var previewDescription: ""
    property var previewDomain: ""

    function isUrl(str) {
        var pattern = new RegExp('^(https?:\\/\\/)?'
                                 + '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'
                                 + '((\\d{1,3}\\.){3}\\d{1,3}))' + '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'
                                 + '(\\?[;&a-z\\d%_.~+=-]*)?' + '(\\#[-a-z\\d_]*)?$',
                                 'i')
        return !!pattern.test(str)
    }

    function hasUrl(message) {
        var messArr = message.split(" ")
        for (var i = 0; i < messArr.length; i++) {
            if (isUrl(messArr[i])) {
                return messArr[i]
            }
        }
        return ""
    }

    function formatDate(date) {
        var dateString = "20" + date.charAt(6) + date.charAt(7) + "-" + date.charAt(
                    3) + date.charAt(4) + "-" + date.charAt(0) + date.charAt(1)
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

    spacing: 2

    Connections {
        target: MessagesAdapter.messageListModel

        function onPreviewDataAdded(topLeft, bottomRight) {
            if (HyperlinkInformation.url === undefined)
                return

            previewUrl = HyperlinkInformation.url
            previewTitle = HyperlinkInformation.title
            previewImage = HyperlinkInformation.image
            previewDescription = HyperlinkInformation.description
            previewLoader.height = 320
            previewLoader.width = 200
            previewLoaded = true

            //            squareRect.visible = true
            //            squareRect.width = squareRect.width * 2
            //            squareRect.anchors.left = textBackground.left
            //            squareRect.anchors.right = textBackground.right
            //            textBackground.width = previewLoader.width - 15

            //            root.bottomPadding = 0
        }
    }

    RowLayout {
        id: messageRowLayout

        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight

        spacing: 5

        Avatar {
            id: messageAvatar

            width: 30
            height: 30

            imageId: sentByMe ? LRCInstance.currentAccountId : Author
            showPresenceIndicator: false
            mode: sentByMe ? Avatar.Mode.Account : Avatar.Mode.Contact
        }

        TextArea {
            id: messageText

            text: MessageBody
            width: 300

            wrapMode: TextEdit.Wrap
            color: sentByMe ? "black" : "black"
            readOnly: true
            selectByMouse: true

            background: Rectangle {
                color: sentByMe ? "cyan" : "red"
            }
        }
    }

    Loader {
        id: previewLoader

        Layout.alignment: Qt.AlignBottom
        Layout.preferredHeight: previewLoaded ? 320 : 0
        Layout.preferredWidth: previewLoaded ? 199 : 0
        Layout.leftMargin: messageAvatar.width + messageRowLayout.spacing

        active: previewLoaded

        sourceComponent: Component {
            id: previewComponent

            WebEngineView {
                backgroundColor: "blue"

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
                    //console.log(previewUrl)

                    previewWev.loadHtml("
                                        <head> <link rel=\"stylesheet\" href=\"qrc:/src/mainview/components/previewInfo.css\"> </head>
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
                                        <p class=\"preview_card_link\">" + previewDomain + "</p>
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
    }

    Component.onCompleted: {
        var url = hasUrl(MessageBody)
//        if (MessageBody === "youtube.com") {
//            console.log("hello " + HyperlinkInformation.url)
//            console.log("hello " + HyperlinkInformation.title)
//            console.log("hello " + HyperlinkInformation.description)
//            console.log("hello " + HyperlinkInformation.image)
//        }

        if (url !== "" && HyperlinkInformation.url === undefined) {
            MessagesAdapter.beginBuildPreview(MessageId, url)
        } else if (HyperlinkInformation.url) {
            previewUrl = HyperlinkInformation.url
            previewTitle = HyperlinkInformation.title
            previewImage = HyperlinkInformation.image
            previewDescription = HyperlinkInformation.description
            previewDomain = HyperlinkInformation.domain
            previewLoader.height = 320
            previewLoader.width = 200
            previewLoaded = true
        }
    }
}
