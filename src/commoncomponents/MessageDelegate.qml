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

    // message interaction
    property bool showOptions: false
    property string hoveredLink
    focus: false
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.hoveredLink)
                Qt.openUrlExternally(root.hoveredLink)
            else if (root.activeFocus) {
                root.showOptions = false
            } else {
                root.forceActiveFocus()
            }
        }
        cursorShape: root.hoveredLink ?
                         Qt.PointingHandCursor :
                         Qt.ArrowCursor
    }
    onActiveFocusChanged: root.showOptions = activeFocus

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
            rowSpacing: 2

            Column {
                id: msgCell

                Layout.column: isOutgoing ? 0 : 1
                Layout.row: 0
                Layout.fillWidth: true
                Layout.maximumWidth: 640
                Layout.preferredHeight: childrenRect.height
                Layout.alignment: isOutgoing ? Qt.AlignRight : Qt.AlignLeft
                Layout.leftMargin: isOutgoing ? msgMargin : 0
                Layout.rightMargin: isOutgoing ? 0 : msgMargin

                Control {
                    id: msgBlock

                    width: parent.width

                    contentItem: Column {
                        id: msgContent

                        property real txtWidth: ta.contentWidth + 3 * ta.padding

                        TextArea {
                            id: ta
                            width: parent.width
                            text: body
                            padding: 10
                            font.pointSize: 11
                            font.hintingPreference: Font.PreferNoHinting
                            renderType: Text.NativeRendering
                            textFormat: TextEdit.RichText
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            onLinkHovered: root.hoveredLink = hoveredLink
                            transform: Translate { x: bg.x }
                            rightPadding: isOutgoing ? padding * 1.5 : 0
                            color: isOutgoing ? "#353637" : "white"
                        }
                        Loader {
                            id: extraContentLoader

                            anchors.right: isOutgoing ? msgContent.right : undefined

                            width: sourceComponent.width
                            height: sourceComponent.height
                            active: linkPreviewInfo.url !== undefined &&
                                    !isAnimatedImage && !isImage
                            sourceComponent: ColumnLayout {
                                id: previewContent
                                Image {
                                    cache: true
                                    visible: linkPreviewInfo.image !== null
                                    source: linkPreviewInfo.image !== null ?
                                                linkPreviewInfo.image :
                                                ""
                                    fillMode: Image.PreserveAspectCrop
                                    mipmap: true
                                    antialiasing: true
                                    property real maxSize: 256
                                    property real aspectRatio: implicitWidth / implicitHeight
                                    property real adjustedWidth: Math.max(bg.width, maxSize)
                                    Layout.preferredWidth: adjustedWidth
                                    Layout.preferredHeight: adjustedWidth / aspectRatio
                                    Layout.topMargin: 6
                                    Layout.bottomMargin: 18
                                    Rectangle {
                                        z: -1
                                        color: "white"
                                        anchors.fill: parent
                                    }
                                }
                                TextArea {
                                    Layout.preferredWidth: parent.width
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    text: linkPreviewInfo.title
                                }
                                TextArea {
                                    Layout.preferredWidth: parent.width
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    text: linkPreviewInfo.description
                                }
                                TextArea {
                                    Layout.preferredWidth: parent.width
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    text: linkPreviewInfo.domain
                                }
                            }
                        }
                    }
                    background: MessageBubble {
                        id: bg

                        out: isOutgoing
                        type: seq
                        anchors.right: isOutgoing ? msgContent.right : undefined
                        width: Math.max(msgContent.txtWidth, extraContentLoader.width)
                        radius: 18
                        color: isOutgoing ?
                                   Qt.lighter("darkslateblue", 1.8) :
                                   Qt.lighter("cornflowerblue", 1.0)
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
                    visible: !isOutgoing &&
                             (seq === MsgSeq.single || seq === MsgSeq.last)
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

        text: formattedTime
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
