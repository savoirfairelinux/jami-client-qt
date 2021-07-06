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
    readonly property bool isImage: MessagesAdapter.isImage(MessageBody)
    readonly property bool isAnimatedImage: MessagesAdapter.isAnimatedImage(MessageBody)

    function formatDate(date) {
        const seconds = (Date.now() / 1000) - date
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

    spacing: 0

    property var hyperlinkInfo: HyperlinkInformation


    RowLayout{


        id: messageRowLayout

        Layout.alignment: Qt.AlignTop | Qt.AlignRight
        Layout.preferredHeight: implicitHeight
        Layout.fillWidth: true

        spacing: 5

        Avatar {
            id: messageAvatar
            Layout.rightMargin: 0

            width: 30
            height: 30

            imageId: sentByMe ? LRCInstance.currentAccountId : Author
            showPresenceIndicator: false
            mode: Avatar.Mode.Contact
            visible: !sentByMe
        }

        TextArea {
            id: messageText

            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link);
            text: MessageBody
            width: 300

            visible: !isImage

            wrapMode: TextEdit.Wrap
            color: sentByMe ? "black" : "black"
            readOnly: true
            selectByMouse: true

            Component.onCompleted: {

                if (!isTextMessage) {
                    textBackground.visible = false
                    squareRect.visible = false
                    messageAvatar.visible = false
                    Layout.leftMargin = parent.width/2
                }
            }

            background: Rectangle {
                id: textBackground
                radius: 20
                color: sentByMe ? JamiTheme.messageOutBgColor: JamiTheme.messageInBgColor

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
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ?
                                 Qt.PointingHandCursor :
                                 Qt.IBeamCursor
            }
        }
    }

    Loader {
        id: previewLoader



        Layout.preferredHeight: active * 320
        Layout.preferredWidth: active * 199
        Layout.alignment: Qt.AlignBottom | Qt.AlignRight
        Layout.leftMargin: messageAvatar.width + messageRowLayout.spacing

        active: HyperlinkInformation.url !== undefined

        MouseArea{
            anchors.fill: parent
            onClicked: Qt.openUrlExternally(HyperlinkInformation.url)
        }

        sourceComponent: Component {
            id: previewComponent

            HyperlinkPreview {
                information: HyperlinkInformation
            }

            //            WebEngineView {
            //                id: previewWev

            ////                property var locale: Qt.LocaleDate

            //                backgroundColor: "transparent"
            //                anchors.fill: parent

            //                settings.localContentCanAccessRemoteUrls: true
            //                settings.localContentCanAccessFileUrls: true

            //                Component.onCompleted: {
            //                    textBackground.width = previewLoader.width
            //                    squareRect.width = textBackground.width

            //                    loadHtml("<head> <link rel=\"stylesheet\" href=\"qrc:/misc/previewInfo.css\"></head>
            //                              <body>
            //                              <div class=\"msg_cell_with_preview\">
            //                              <div class=\"preview_wrapper_in\">
            //                              <div class=\"preview_card_container\">
            //                              <div class=\"card_container_in\">
            //                              <a class=\"preview_container_link\" href=\"" + HyperlinkInformation.url + "\" target=\"_blank\">
            //                              <img class=\"preview_image\" src=\"" + HyperlinkInformation.image + "\">
            //                              <div class=\"preview_text_container\">
            //                              <pre class=\"preview_card_title\">" + HyperlinkInformation.title + "</pre>
            //                              <p class=\"preview_card_subtitle\">" + HyperlinkInformation.description + "</p>
            //                              <p class=\"preview_card_link\">" + HyperlinkInformation.domain + "</p>
            //                              </div>
            //                              </a>
            //                              </div>
            //                              </div>
            //                              </div>
            //                              </div>
            //                              </body>", "")
            //                }
            //            }
        }
    }

    Image {
        id: imageMedia
        asynchronous: true
        source: isImage ? "file:" + MessageBody : ""
        sourceSize.width: 200
        sourceSize.height: 200
        visible: isImage
    }

    AnimatedImage {
        id: animatedImageMedia
        asynchronous: true
        source: MessageBody
        sourceSize.width: 200
        sourceSize.height: 200
    }

    Loader{
        active: isTextMessage
        height: 5 * active
        width: 30 * active
        sourceComponent: Component {
            TextArea {
                readOnly: true
                text: formattedTimeStamp
                font.pixelSize: 10
            }
        }
    }

    Component.onCompleted: {
        //        var url = MessagesAdapter.messageHasUrl(MessageBody)
        // MessagesAdapter.linkifyUrlInMessage(MessageId, MessageBody)
        if (/*url !== "" &&*/ HyperlinkInformation.url === undefined) {
            if (isImage){
                imageMedia.source = MessageBody
                return
            }

            MessagesAdapter.linkifyUrlInMessage(MessageId, MessageBody)
        }
    }
}
