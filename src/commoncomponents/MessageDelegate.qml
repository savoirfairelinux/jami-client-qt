import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebEngine 1.10

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Column {
    id: item

    readonly property bool sentByMe: Author === ""
    readonly property bool isTextMessage: Type === 1
    readonly property var formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    readonly property bool isImage: MessagesAdapter.isImage(Body)
    readonly property bool isAnimatedImage: MessagesAdapter.isAnimatedImage(Body)
    readonly property bool hasUrl: LinkifyStatus === 2

    property bool showOptions: false
    property int seq: seqTimeVisPair.seq
    property variant seqTimeVisPair: ListView.view.computeSequencing(index)

    width: parent !== null ? parent.width : 0
    bottomPadding: timestampLabel.visible ? 2 : 0
    spacing: 2
    Row {
        id: msgRow
        width: Math.min(parent.width - (sentByMe ?
                                            80 :
                                            80 + avatar.width + spacing),
                        512)
        anchors.right: sentByMe ? parent.right : undefined
        anchors.left: sentByMe ? undefined : parent.left
        anchors.leftMargin: 9
        anchors.rightMargin: 18
        spacing: 12
        Item {
            height: msgBlock.height
            width: avatar.width

            Avatar {
                id: avatar

                width: sentByMe ? 0 : 32
                height: 32
                anchors.bottom: parent.bottom
                visible: sentByMe ?
                             false :
                             (seq !== MsgSeq.first && seq !== MsgSeq.middle)
                imageId: Author
                showPresenceIndicator: false
                mode: Avatar.Mode.Contact
            }
        }
        Control {
            id: msgBlock
            width: parent.width
            contentItem: TextArea {
                id: ta

                onFocusChanged: !focus ? item.showOptions = false : true
                onPressed: item.showOptions = !item.showOptions

                text: Body
                padding: 10
                font.pointSize: 11
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                textFormat: TextEdit.RichText
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                onLinkActivated: Qt.openUrlExternally(link)
                selectByMouse: true
                readOnly: true
                horizontalAlignment: sentByMe ? Qt.AlignRight : Qt.AlignLeft
                rightPadding: sentByMe ? padding * 1.5 : 0
                selectedTextColor: "grey"
                selectionColor: "lightgreen"
                color: sentByMe ? "#353637" : "white"
            }
            background: MessageBubble {
                id: bg

                out: sentByMe
                type: item.seq
                anchors.right: sentByMe ? ta.right : undefined
                anchors.left: sentByMe ? undefined : ta.left
                width: ta.contentWidth + 3 * ta.padding
                radius: 18
                color1: sentByMe ?
                            Qt.lighter("darkslateblue", 1.8) :
                            Qt.lighter("cornflowerblue", 1.0)
            }
            MouseArea {
                anchors.fill: bg
                acceptedButtons: Qt.NoButton
                cursorShape: ta.hoveredLink ?
                                 Qt.PointingHandCursor :
                                 Qt.IBeamCursor
            }
        }
    }
    Loader {
        id: previewLoader

        height: active * 320
        width: Math.min(parent.width - (sentByMe ?
                                            80 :
                                            80 + avatar.width + spacing),
                        199)
        anchors.right: sentByMe ? parent.right : undefined
        anchors.left: sentByMe ? undefined : parent.left
        anchors.leftMargin: 9
        anchors.rightMargin: 18

        active: LinkPreviewInfo.url !== undefined &&
                !isAnimatedImage && !isImage

        sourceComponent: HyperlinkPreview {
            anchors.fill: parent
            onContentsSizeChanged: height = contentsSize.height;
            information: LinkPreviewInfo

            onNavigationRequested: function(request) {
                if (request.navigationType ===
                        WebEngineNavigationRequest.LinkClickedNavigation) {
                    Qt.openUrlExternally(request.url)
                    request.action = WebEngineNavigationRequest.IgnoreRequest
                }
            }
        }
    }
    Label {
        id: timestampLabel

        visible: height !== 0
        opacity: height / implicitHeight
        height: (seqTimeVisPair.timeVis || item.showOptions) ?
                    implicitHeight :
                    0

        text: formattedTime
        color: "grey"
        anchors.right: sentByMe ? parent.right : parent.left
        anchors.left: sentByMe ? undefined : parent.left
        anchors.leftMargin: avatar.width + msgRow.spacing + 4 + 9
        anchors.rightMargin: 4 + 18

        Behavior on height { NumberAnimation { duration: 50 }}
        Behavior on opacity { NumberAnimation { duration: 50 }}
    }

    Component.onCompleted: {
        if (LinkifyStatus === 1 && !isImage && !isAnimatedImage) {
            MessagesAdapter.parseMessageUrls(Id, Body)
        }
    }
}
