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
            return "S"
        case MsgSeq.first:
            return "F"
        case MsgSeq.middle:
            return "M"
        case MsgSeq.last:
            return "L"
        }
    }

    readonly property bool isGenerated: Type === Interaction.Type.CALL ||
                                        Type === Interaction.Type.CONTACT
    readonly property string author: Author
    readonly property var timestamp: Timestamp
    readonly property bool isOutgoing: model.Author === ""
    readonly property var formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    readonly property bool isImage: MessagesAdapter.isImage(Body)
    readonly property bool isAnimatedImage: MessagesAdapter.isAnimatedImage(Body)
    readonly property var linkPreviewInfo: LinkPreviewInfo

    property bool showOptions: false
    property bool showTime: false
    property int seq: MsgSeq.single
    readonly property var body: Body

    readonly property real msgMargin: 64

    width: parent ? parent.width : 0
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

        sourceComponent: isGenerated ?
                             generatedMsgComp :
                             userMsgComp
    }

    focus: false
    MouseArea {
        anchors.fill: parent
        onPressAndHold: root.forceActiveFocus()
    }
    onActiveFocusChanged: {
        print(activeFocus, index)
        !activeFocus ? root.showOptions = false : true
    }

    //Text { text: root.seqStr(seq) }

    Component {
        id: generatedMsgComp

        Column {
            width: root.width
            spacing: 2

            TextArea {
                width: parent.width
                text: body
                horizontalAlignment: Qt.AlignHCenter
                readOnly: true
                font.pointSize: 11
            }

            Item {
                id: infoCell

                width: parent.width
                height: childrenRect.height

                Component.onCompleted: children = timestampLabel
            }

            bottomPadding: 12
        }
    }

    Component {
        id: userMsgComp

        GridLayout {
            id: gridLayout

            width: root.width

            columns: 2
            rows: 2

            columnSpacing: 2
            rowSpacing: isGenerated ? 0 : 2

            Column {
                id: msgCell

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
                                                 Qt.AlignLeft
                        transform: Translate { x: bg.x }
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

                    width: msgCell.width
                    height: sourceComponent.height
                    active: linkPreviewInfo.url !== undefined &&
                            !isAnimatedImage && !isImage
                    sourceComponent: Control {
                        width: previewLoader.width
                        contentItem: Label {
                            id: previewContent
                            width: parent.width
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            text: JSON.stringify(linkPreviewInfo)
                        }
//                        background: Rectangle {
//                            anchors.right: isOutgoing ? previewContent.right : undefined
//                            anchors.left: isOutgoing ? undefined : previewContent.left
//                            width: previewContent.contentWidth +
//                                   3 * previewContent.padding
//                            radius: 18
//                            color: isOutgoing ?
//                                        Qt.lighter("darkslateblue", 1.8) :
//                                        Qt.lighter("cornflowerblue", 1.0)
//                        }
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
                Layout.preferredWidth: isOutgoing ? 16 : avatar.width
                Layout.preferredHeight: msgCell.height
                Layout.leftMargin: isOutgoing ? 0 : 6
                Layout.rightMargin: Layout.leftMargin
                Avatar {
                    id: avatar
                    visible: (!isOutgoing && !isGenerated) &&
                             seq === MsgSeq.single || seq === MsgSeq.last
                    anchors.bottom: parent.bottom
                    width: 32
                    height: 32
                    imageId: author
                    showPresenceIndicator: false
                    mode: Avatar.Mode.Contact
                }
            }
        }
    }

    Label {
        id: timestampLabel

        text: formattedTime + "("+timestamp+")"
        color: "grey"

        anchors.right: isGenerated ?
                           undefined :
                           isOutgoing ? parent.right : undefined
        anchors.rightMargin: 6
        anchors.left: isGenerated ?
                          undefined :
                          !isOutgoing ? parent.left : undefined
        anchors.leftMargin: 6
        anchors.horizontalCenter: isGenerated ?
                                      parent.horizontalCenter :
                                      undefined

        visible: height !== 0
        opacity: height / implicitHeight
        height: (showTime || showOptions || seq === MsgSeq.last) ?
                    implicitHeight :
                    0
        Behavior on height { NumberAnimation { duration: 40 }}
        Behavior on opacity { NumberAnimation { duration: 40 }}
    }

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 40 } }

    Component.onCompleted: {
        opacity = 1
        if (!Linkified && !isImage && !isAnimatedImage) {
            MessagesAdapter.parseMessageUrls(Id, Body)
        }
    }
}
