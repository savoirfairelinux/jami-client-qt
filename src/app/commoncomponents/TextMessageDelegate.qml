/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
    id: root

    property bool isRemoteImage
    property bool isEmojiOnly: IsEmojiOnly
    property string colorUrl: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewLinkColorLight : JamiTheme.chatviewLinkColorDark
    property string colorText: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark



    Connections {
        target: bubble
        function onColorChanged(color) {
            root.colorUrl = UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewLinkColorLight : JamiTheme.chatviewLinkColorDark;
            root.colorText = UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark;
            // Update parsed body with correct colors
            if (Body !== "")
                MessagesAdapter.parseMessage(Id, Body, UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews), root.colorUrl, bubble.color);
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

    bigMsg: textContentWidth >= (2 / 3) * root.maxMsgWidth || extraContent.active

    innerContent.children: [
        TextEdit {
            id: textEditId

            padding: isEmojiOnly ? 5 : 10
            topPadding: bubble.isDeleted ? 6 : 10
            bottomPadding: bubble.isDeleted ? 6 : 10
            anchors.right: isOutgoing ? parent.right : undefined
            anchors.rightMargin: isOutgoing && !isEmojiOnly ? root.timeWidth + root.editedWidth : 0
            text: {
                if (Body !== "" && ParsedBody.length === 0) {
                    MessagesAdapter.parseMessage(Id, Body, UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews), root.colorUrl, bubble.color);
                    return "";
                }
                if (ParsedBody !== "")
                    return ParsedBody;
                bubble.isDeleted = true;
                return UtilsAdapter.getBestNameForUri(CurrentAccount.id, Author) + " " + JamiStrings.deletedMessage ;
            }
            horizontalAlignment: Text.AlignLeft

            HoverHandler {
                id: textHoverhandler
            }

            width: {
                if (extraContent.active)
                    Math.max(extraContent.width, Math.min((2 / 3) * root.maxMsgWidth, implicitWidth - avatarBlockWidth, extraContent.minSize) - senderMargin);
                else if (isEmojiOnly)
                    Math.min((2 / 3) * root.maxMsgWidth, implicitWidth, innerContent.width - senderMargin - (innerContent.width - senderMargin) % (JamiTheme.chatviewEmojiSize + 2));
                else
                    Math.min((2 / 3) * root.maxMsgWidth, implicitWidth + 5, innerContent.width - senderMargin + 5);
            }

            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            selectByMouse: true
            font.pointSize: isEmojiOnly ? JamiTheme.chatviewEmojiSize : (ParsedBody === "" ? JamiTheme.smallFontSize : JamiTheme.mediumFontSize)
            font.hintingPreference: Font.PreferNoHinting
            renderType: Text.NativeRendering
            textFormat: Text.RichText
            clip: true
            onLinkHovered: root.hoveredLink = hoveredLink
            onLinkActivated: Qt.openUrlExternally(new URL(hoveredLink))
            readOnly: true
            color: (ParsedBody !== "") ? getBaseColor() : (UtilsAdapter.luma(bubble.color) ? "white" : "dark")
            opacity:(ParsedBody !== "") ? 1 :  0.5

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
                        root.hoveredLink = hovered ? LinkPreviewInfo.url : "";
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
                        color: root.colorText
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
                        font.underline: root.hoveredLink
                        text: LinkPreviewInfo.description
                        color: root.colorUrl
                        lineHeight: 1.3
                    }
                    Label {
                        width: parent.width
                        font.pointSize: 10
                        font.hintingPreference: Font.PreferNoHinting
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                        renderType: Text.NativeRendering
                        textFormat: TextEdit.RichText
                        color: root.colorText
                        text: LinkPreviewInfo.domain
                        lineHeight: 1.3
                    }
                }
            }
        }
    ]

    opacity: 0
    Behavior on opacity  {
        NumberAnimation {
            duration: 100
        }
    }
    Component.onCompleted: opacity = 1
}
