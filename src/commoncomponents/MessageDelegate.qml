import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebEngine 1.10

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Control {
    id: root

    function seqStr(s) {
        switch (s) {
        case MsgSeq.single:
            return "SINGLE"
        case MsgSeq.first:
            return "FIRST"
        case MsgSeq.middle:
            return "MIDDLE"
        case MsgSeq.last:
            return "LAST"
        }
    }

    readonly property bool isGenerated: Type === Interaction.Type.CALL ||
                                        Type === Interaction.Type.CONTACT
    readonly property string author: Author
    readonly property var timestamp: Timestamp
    readonly property bool isOutgoing: Author === ""
    readonly property var formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    readonly property bool isImage: MessagesAdapter.isImage(Body)
    readonly property bool isAnimatedImage: MessagesAdapter.isAnimatedImage(Body)
    readonly property var linkPreviewInfo: LinkPreviewInfo

    property bool showOptions: false
    property bool showTime: false
    property int seq: MsgSeq.unknown
    readonly property var body: Body

    readonly property real msgMargin: 64

    width: parent !== null ? parent.width : 0
    height: loader.height
    bottomPadding: timestampLabel.visible ? 2 : 0
    topPadding: (seq === MsgSeq.first || seq === MsgSeq.single) ? 6 : 0

    Loader {
        id: loader

        property alias seq: root.seq
        property alias isOutgoing: root.isOutgoing
        property alias isGenerated: root.isGenerated
        readonly property var author: Author
        readonly property var body: Body

        sourceComponent: userMessageComp
    }

    Component {
        id: userMessageComp

        GridLayout {
            id: gridLayout

            width: root.width

            columns: 2
            rows: 2

            columnSpacing: 2
            rowSpacing: isGenerated ? 0 : 2

            Column {
                id: msgCell

                //color: "transparent"
                Layout.column: isOutgoing ? 0 : 1
                Layout.row: 0
                Layout.fillWidth: true
                Layout.maximumWidth: 640
                Layout.preferredHeight: childrenRect.height
                Layout.alignment: isGenerated ?
                                      Qt.AlignHCenter :
                                      isOutgoing ? Qt.AlignRight : Qt.AlignLeft
                Layout.leftMargin: isGenerated ?
                                       msgMargin :
                                       isOutgoing ? msgMargin : 0
                Layout.rightMargin: isGenerated ?
                                        msgMargin :
                                        isOutgoing ? 0 : msgMargin
                Control {
                    id: msgBlock

                    width: parent.width
                    contentItem: TextArea {
                        id: ta

                        onFocusChanged: !focus ? root.showOptions = false : true
                        onPressAndHold: root.showOptions = !root.showOptions

                        text: body
                        padding: 10
                        font.pointSize: 11
                        font.hintingPreference: Font.PreferNoHinting
                        renderType: Text.NativeRendering
                        textFormat: TextEdit.RichText
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        onLinkActivated: Qt.openUrlExternally(link)
                        readOnly: true
                        horizontalAlignment: isGenerated ?
                                                 Qt.AlignHCenter :
                                                 isOutgoing ? Qt.AlignRight : Qt.AlignLeft
                        rightPadding: isGenerated ?
                                          0 :
                                          isOutgoing ? padding * 1.5 : 0
                        color: isGenerated ?
                                   JamiTheme.primaryForegroundColor :
                                   isOutgoing ? "#353637" : "white"
                    }
                    background: MessageBubble {
                        id: bg

                        visible: !isGenerated
                        out: isOutgoing
                        type: seq
                        anchors.right: isOutgoing ? ta.right : undefined
                        anchors.left: isOutgoing ? undefined : ta.left
                        width: ta.contentWidth + 3 * ta.padding
                        radius: 18
                        color1: isOutgoing ?
                                    Qt.lighter("darkslateblue", 1.8) :
                                    Qt.lighter("cornflowerblue", 1.0)

                        //Text { text: root.seqStr(bg.type) }
                    }
                    MouseArea {
                        enabled: !isGenerated
                        anchors.fill: bg
                        acceptedButtons: Qt.NoButton
                        cursorShape: ta.hoveredLink ?
                                         Qt.PointingHandCursor :
                                         Qt.ArrowCursor
                    }
                }
                Loader {
                    id: previewLoader

//                    anchors.right: isOutgoing ? parent.right : undefined
//                    anchors.left: !isOutgoing ? parent.left : undefined

                    width: sourceComponent.width
                    height: sourceComponent.height
                    active: linkPreviewInfo.url !== undefined &&
                            !isAnimatedImage && !isImage
                    onActiveChanged: {
                        if (active)
                            print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
                                  JSON.stringify(linkPreviewInfo))
                    }
                    sourceComponent: HyperlinkPreview {
                        dir: isOutgoing ? "out" : "in"
                        Component.onCompleted: loadContent(linkPreviewInfo)
                    }
                }
            }
            Item {
                id: infoCell

                Layout.column: isOutgoing ? 0 : 1
                Layout.row: 1
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height

                Component.onCompleted: children = timestampLabel
            }
            Item {
                id: avatarCell

                Layout.column: isOutgoing ? 1 : 0
                Layout.row: 0
                Layout.preferredWidth: isOutgoing ? 16 : childrenRect.width
                Layout.preferredHeight: msgCell.height
                Layout.leftMargin: isOutgoing ? 0 : 6
                Layout.rightMargin: Layout.leftMargin
                Loader {
                    anchors.bottom: parent.bottom
                    active: (!isOutgoing && !isGenerated) &&
                             seq === MsgSeq.single || seq === MsgSeq.last

                    property string imageId_: author

                    sourceComponent: Avatar {
                        width: visible ? 32 : 0
                        height: 32
                        imageId: imageId_
                        showPresenceIndicator: false
                        mode: Avatar.Mode.Contact
                    }
                }
            }
        }
    }

    Label {
        id: timestampLabel

//        visible: showTime || showOptions
//        height: visible * implicitHeight

        text: formattedTime + "("+timestamp+")"
        color: "grey"

        anchors.right: isOutgoing ? parent.right : undefined

        visible: height !== 0
        opacity: height / implicitHeight
        height: (showTime || showOptions) ? implicitHeight : 0
        Behavior on height { NumberAnimation { duration: 50 }}
        Behavior on opacity { NumberAnimation { duration: 50 }}
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 20 } }

    Component.onCompleted: {
        opacity = 1
        if (!Linkified && !isImage && !isAnimatedImage) {
            MessagesAdapter.parseMessageUrls(Id, Body)
        }
    }
}
