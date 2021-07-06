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

    function isUrl(str) {
        var pattern = new RegExp('^(https?:\\/\\/)?'
                                 + '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'
                                 + '((\\d{1,3}\\.){3}\\d{1,3}))' + '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'
                                 + '(\\?[;&a-z\\d%_.~+=-]*)?' + '(\\#[-a-z\\d_]*)?$',
                                 'i')
        return pattern.test(str)
    }

    function getUrl(message) {
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

    property var hyperlinkInfo: HyperlinkInformation

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

        Layout.preferredHeight: active * 320
        Layout.preferredWidth: active * 199
        Layout.alignment: Qt.AlignBottom
        Layout.leftMargin: messageAvatar.width + messageRowLayout.spacing

        active: HyperlinkInformation.url !== undefined

        sourceComponent: Component {
            id: previewComponent

            WebEngineView {
                id: previewWev

                backgroundColor: "blue"
                anchors.fill: parent

                settings.localContentCanAccessRemoteUrls: true
                settings.localContentCanAccessFileUrls: true

                Component.onCompleted: {
                    loadHtml("<head> <link rel=\"stylesheet\" href=\"qrc:/misc/previewInfo.css\"></head>
                              <body>
                              <div class=\"msg_cell_with_preview\">
                              <div class=\"preview_wrapper_in\">
                              <div class=\"preview_card_container\">
                              <div class=\"card_container_in\">
                              <a class=\"preview_container_link\" href=\"" + HyperlinkInformation.url + "\" target=\"_blank\">
                              <img class=\"preview_image\" src=\"" + HyperlinkInformation.image + "\">
                              <div class=\"preview_text_container\">
                              <pre class=\"preview_card_title\">" + HyperlinkInformation.title + "</pre>
                              <p class=\"preview_card_subtitle\">" + HyperlinkInformation.description + "</p>
                              <p class=\"preview_card_link\">" + HyperlinkInformation.domain + "</p>
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
        var url = getUrl(MessageBody)
        if (url !== "" && HyperlinkInformation.url === undefined) {
            MessagesAdapter.beginBuildPreview(MessageId, url)
        }
    }
}
