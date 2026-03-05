/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

SBSMessageBase {
    id: rootDelegate

    Accessible.role: Accessible.StaticText
    Accessible.name: {
        let name = isOutgoing ? JamiStrings.inReplyToYou : UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author);
        return name + ": " + Body + " " + formattedTime;
    }
    Accessible.description: {
        let status = "";
        if (bubble.isEdited)
            status += JamiStrings.edited + " ";
        return status + (readers.length > 0 ? JamiStrings.readBy + " " + readers.map(function (uri) {
                    return UtilsAdapter.getBestNameForUri(CurrentAccount.id, uri);
                }).join(", ") : "");
    }

    property bool isRemoteImage
    property bool isEmojiOnly: IsEmojiOnly
    property string colorUrl: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewLinkColorLight : JamiTheme.chatviewLinkColorDark
    property string colorText: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark


    readonly property real longMsgCollapsedHeight: 240
    property bool isLongMessage: !isEmojiOnly && textEditId.implicitHeight > longMsgCollapsedHeight

    // IMPORTANT: the assignment is deferred via Qt.callLater so that the
    // resulting textEditId.height change propagates AFTER the delegate has
    // been fully inserted into the ListView.  An immediate binding triggers
    // a height-cascade during delegate initialisation that crashes the
    // ListView layout engine (SIGSEGV) when real model data is present.
    property bool longMsgCollapsed: false
    
    onIsLongMessageChanged: {
        if (isLongMessage && !longMsgCollapsed)
            Qt.callLater(function () {
                rootDelegate.longMsgCollapsed = true;
            });
        else if (!isLongMessage)
            rootDelegate.longMsgCollapsed = false;
    }

    Connections {
        target: bubble
        function onColorChanged(color) {
            rootDelegate.colorUrl = UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewLinkColorLight : JamiTheme.chatviewLinkColorDark;
            rootDelegate.colorText = UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark;
            // Update parsed body with correct colors
            if (Body !== "")
                MessagesAdapter.parseMessage(Id, Body, UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews), rootDelegate.colorUrl, bubble.color);
        }
    }

    isOutgoing: Author === CurrentAccount.uri
    author: Author
    readers: Readers
    timestamp: Timestamp
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
    extraHeight: extraContent.active && !isRemoteImage ? msgRadius : -isRemoteImage
    textHovered: textHoverhandler.hovered
    textContentWidth: textEditId.width
    textContentHeight: textEditId.height

    bigMsg: textContentWidth >= (2 / 3) * rootDelegate.maxMsgWidth || extraContent.active || rootDelegate.isLongMessage

    innerContent.children: [
        TextEdit {
            id: textEditId

            padding: isEmojiOnly ? 5 : 10
            topPadding: bubble.isDeleted ? 6 : 10
            bottomPadding: bubble.isDeleted ? 6 : 10
            anchors.right: isOutgoing ? parent.right : undefined
            anchors.rightMargin: isOutgoing && !isEmojiOnly && !bigMsg ? rootDelegate.timeWidth + rootDelegate.editedWidth : 0
            text: {
                if (Body !== "" && ParsedBody.length === 0) {
                    MessagesAdapter.parseMessage(Id, Body, UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews), rootDelegate.colorUrl, bubble.color);
                    return "";
                }
                if (ParsedBody !== "")
                    return ParsedBody;
                bubble.isDeleted = true;
                return JamiStrings.deletedMessage.arg(UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author));
            }
            horizontalAlignment: Text.AlignLeft

            HoverHandler {
                id: textHoverhandler
            }

            width: {
                if (extraContent.active)
                    Math.max(extraContent.width, Math.min((2 / 3) * rootDelegate.maxMsgWidth, implicitWidth - avatarBlockWidth, extraContent.minSize) - senderMargin);
                else if (isEmojiOnly)
                    Math.min((2 / 3) * rootDelegate.maxMsgWidth, implicitWidth, innerContent.width - senderMargin - (innerContent.width - senderMargin) % (JamiTheme.chatviewEmojiSize + 2));
                else
                    Math.min((2 / 3) * rootDelegate.maxMsgWidth, implicitWidth + 5, innerContent.width - senderMargin + 5);
            }

            height: rootDelegate.longMsgCollapsed
                    ? rootDelegate.longMsgCollapsedHeight
                    : implicitHeight

            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            selectByMouse: true
            font.pointSize: isEmojiOnly ? JamiTheme.chatviewEmojiSize : (ParsedBody === "" ? JamiTheme.smallFontSize : JamiTheme.mediumFontSize)
            font.hintingPreference: Font.PreferNoHinting
            renderType: Text.NativeRendering
            textFormat: Text.RichText
            clip: true
            onLinkHovered: rootDelegate.hoveredLink = hoveredLink
            onLinkActivated: Qt.openUrlExternally(new URL(hoveredLink))
            readOnly: true
            color: (ParsedBody !== "") ? getBaseColor() : (UtilsAdapter.luma(bubble.color) ? "white" : "dark")
            opacity: (ParsedBody !== "") ? 1 : 0.5

            function getBaseColor() {
                var baseColor;
                if (isEmojiOnly) {
                    if (JamiTheme.darkTheme)
                        baseColor = JamiTheme.chatviewTextColorLight;
                    else
                        baseColor = JamiTheme.chatviewTextColorDark;
                } else {
                    if (UtilsAdapter.luma(bubble.color))
                        baseColor = JamiTheme.chatviewTextColorLight;
                    else
                        baseColor = JamiTheme.chatviewTextColorDark;
                }
                return baseColor;
            }

            TapHandler {
                enabled: parent.selectedText.length > 0
                acceptedButtons: Qt.RightButton
                onTapped: function onTapped(eventPoint) {
                    ctxMenu.openMenuAt(eventPoint.position);
                }
            }

            LineEditContextMenu {
                id: ctxMenu

                lineEditObj: parent
                selectOnly: parent.readOnly
            }
        },
        Loader {
            id: extraContent

            objectName: "extraContent"
            anchors.right: isOutgoing ? parent.right : undefined
            property real minSize: 192
            property real maxSize: 400
            active: LinkPreviewInfo.url !== undefined
            sourceComponent: ColumnLayout {
                id: previewContent

                spacing: 12
                Component.onCompleted: {
                    isRemoteImage = MessagesAdapter.isRemoteImage(LinkPreviewInfo.url);
                }
                HoverHandler {
                    target: previewContent
                    onHoveredChanged: {
                        rootDelegate.hoveredLink = hovered ? LinkPreviewInfo.url : "";
                    }
                    cursorShape: Qt.PointingHandCursor
                }
                AnimatedImage {
                    id: img

                    cache: false
                    source: isRemoteImage ? LinkPreviewInfo.url : (hasImage ? LinkPreviewInfo.image : "")

                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    antialiasing: true
                    autoTransform: true
                    asynchronous: true
                    readonly property bool hasImage: LinkPreviewInfo.image !== null
                    property real aspectRatio: implicitWidth / implicitHeight
                    property real adjustedWidth: Math.min(extraContent.maxSize, Math.max(extraContent.minSize, maxMsgWidth))
                    Layout.preferredWidth: adjustedWidth
                    Layout.preferredHeight: Math.ceil(adjustedWidth / aspectRatio)
                    Rectangle {
                        color: JamiTheme.previewImageBackgroundColor
                        z: -1
                        anchors.fill: parent
                    }
                    layer.enabled: isRemoteImage
                    layer.effect: OpacityMask {
                        maskSource: MessageBubble {
                            Rectangle {
                                height: msgRadius
                                width: parent.width
                            }
                            out: isOutgoing
                            type: seq
                            width: img.width
                            height: img.height
                            radius: msgRadius
                        }
                    }
                }
                Column {
                    opacity: img.status !== Image.Loading
                    visible: !isRemoteImage
                    Layout.preferredWidth: img.width - 2 * hPadding
                    Layout.leftMargin: hPadding
                    Layout.rightMargin: hPadding
                    spacing: 4
                    Label {
                        width: parent.width
                        font.pointSize: 10
                        font.hintingPreference: Font.PreferNoHinting
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                        renderType: Text.NativeRendering
                        textFormat: TextEdit.RichText
                        color: rootDelegate.colorText
                        visible: LinkPreviewInfo.title.length > 0
                        text: LinkPreviewInfo.title
                        lineHeight: 1.3
                    }
                    Label {
                        width: parent.width
                        font.pointSize: 10
                        font.hintingPreference: Font.PreferNoHinting
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                        renderType: Text.NativeRendering
                        textFormat: TextEdit.RichText
                        visible: LinkPreviewInfo.description.length > 0
                        font.underline: rootDelegate.hoveredLink
                        text: LinkPreviewInfo.description
                        color: rootDelegate.colorUrl
                        lineHeight: 1.3
                    }
                    Label {
                        width: parent.width
                        font.pointSize: 10
                        font.hintingPreference: Font.PreferNoHinting
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                        renderType: Text.NativeRendering
                        textFormat: TextEdit.RichText
                        color: rootDelegate.colorText
                        text: LinkPreviewInfo.domain
                        lineHeight: 1.3
                    }
                }
            }
        },
        Item {
            id: longMsgFooter

            objectName: "longMsgFooter"
            visible: rootDelegate.isLongMessage && !extraContent.active
            width: textEditId.width
            height: visible ? collapseButton.implicitHeight + 4 : 0
            anchors.right: isOutgoing ? parent.right : undefined

            Rectangle {
                id: fadeOverlay

                anchors.bottom: collapseButton.top
                width: parent.width
                height: 24
                visible: rootDelegate.longMsgCollapsed
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1.0
                        color: bubble.color
                    }
                }
            }

            Label {
                id: collapseButton

                objectName: "collapseButton"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                bottomPadding: 4
                text: rootDelegate.longMsgCollapsed ? JamiStrings.showMore : JamiStrings.showLess
                font.pointSize: JamiTheme.smallFontSize
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                color: rootDelegate.colorUrl
                font.underline: true

                Accessible.role: Accessible.Button
                Accessible.name: text

                TapHandler {
                    onTapped: rootDelegate.longMsgCollapsed = !rootDelegate.longMsgCollapsed
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    ]

    opacity: 0
    Behavior on opacity {
        NumberAnimation {
            duration: 100
        }
    }
    Component.onCompleted: opacity = 1
}
