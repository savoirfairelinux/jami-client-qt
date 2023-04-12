/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
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
    property string colorUrl: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewLinkColorLight : JamiTheme.chatviewLinkColorDark
    property bool isEmojiOnly: IsEmojiOnly
    property bool isRemoteImage
    property real maxMsgWidth: root.width - senderMargin - 2 * hPadding - avatarBlockWidth

    author: Author
    extraHeight: extraContent.active && !isRemoteImage ? msgRadius : -isRemoteImage
    formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    isOutgoing: Author === CurrentAccount.uri
    opacity: 0
    readers: Readers
    textContentHeight: textEditId.height
    textContentWidth: textEditId.width
    textHovered: textHoverhandler.hovered
    timestamp: Timestamp

    Component.onCompleted: {
        if (Linkified.length === 0) {
            MessagesAdapter.parseMessageUrls(Id, Body, UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews), root.colorUrl);
        }
        opacity = 1;
    }

    innerContent.children: [
        TextEdit {
            id: textEditId
            anchors.right: isOutgoing ? parent.right : undefined
            color: getBaseColor()
            font.hintingPreference: Font.PreferNoHinting
            font.pixelSize: isEmojiOnly ? JamiTheme.chatviewEmojiSize : JamiTheme.emojiBubbleSize
            horizontalAlignment: Text.AlignLeft
            padding: isEmojiOnly ? 0 : JamiTheme.preferredMarginSize
            readOnly: true
            renderType: Text.NativeRendering
            selectByMouse: true
            text: {
                if (LinkifiedBody !== "" && Linkified.length === 0) {
                    MessagesAdapter.parseMessageUrls(Id, Body, UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews), root.colorUrl);
                }
                return (LinkifiedBody !== "") ? LinkifiedBody : "*(" + JamiStrings.deletedMessage + ")*";
            }
            textFormat: Text.MarkdownText
            width: {
                if (extraContent.active)
                    Math.max(extraContent.width, Math.min((2 / 3) * root.maxMsgWidth, implicitWidth - avatarBlockWidth, extraContent.minSize) - senderMargin);
                else if (isEmojiOnly)
                    Math.min((2 / 3) * root.maxMsgWidth, implicitWidth, innerContent.width - senderMargin - (innerContent.width - senderMargin) % (JamiTheme.chatviewEmojiSize + 2));
                else
                    Math.min((2 / 3) * root.maxMsgWidth, implicitWidth, innerContent.width - senderMargin);
            }
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere

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

            onLinkActivated: Qt.openUrlExternally(new URL(hoveredLink))
            onLinkHovered: root.hoveredLink = hoveredLink

            HoverHandler {
                id: textHoverhandler
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                enabled: parent.selectedText.length > 0

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
        RowLayout {
            id: editedRow
            anchors.right: isOutgoing ? parent.right : undefined
            visible: PreviousBodies.length !== 0

            ResponsiveImage {
                id: editedImage
                Layout.bottomMargin: JamiTheme.preferredMarginSize
                Layout.leftMargin: JamiTheme.preferredMarginSize
                height: JamiTheme.editedFontSize
                source: JamiResources.round_edit_24dp_svg
                width: JamiTheme.editedFontSize

                layer {
                    enabled: true

                    effect: ColorOverlay {
                        color: editedLabel.color
                    }
                }
            }
            Text {
                id: editedLabel
                Layout.bottomMargin: JamiTheme.preferredMarginSize
                Layout.rightMargin: JamiTheme.preferredMarginSize
                color: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                font.pointSize: JamiTheme.editedFontSize
                text: JamiStrings.edited

                TapHandler {
                    acceptedButtons: Qt.LeftButton

                    onTapped: {
                        viewCoordinator.presentDialog(appWindow, "commoncomponents/EditedPopup.qml", {
                                "previousBodies": PreviousBodies
                            });
                    }
                }
            }
        },
        Loader {
            id: extraContent
            property real maxSize: 320
            property real minSize: 192

            active: LinkPreviewInfo.url !== undefined
            anchors.right: isOutgoing ? parent.right : undefined

            sourceComponent: ColumnLayout {
                id: previewContent
                spacing: 12

                Component.onCompleted: {
                    isRemoteImage = MessagesAdapter.isRemoteImage(LinkPreviewInfo.url);
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    target: previewContent

                    onHoveredChanged: {
                        root.hoveredLink = hovered ? LinkPreviewInfo.url : "";
                    }
                }
                AnimatedImage {
                    id: img
                    property real adjustedWidth: Math.min(extraContent.maxSize, Math.max(extraContent.minSize, maxMsgWidth))
                    property real aspectRatio: implicitWidth / implicitHeight
                    readonly property bool hasImage: LinkPreviewInfo.image !== null

                    Layout.preferredHeight: Math.ceil(adjustedWidth / aspectRatio)
                    Layout.preferredWidth: adjustedWidth
                    antialiasing: true
                    asynchronous: true
                    autoTransform: true
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: isRemoteImage
                    mipmap: true
                    source: isRemoteImage ? LinkPreviewInfo.url : (hasImage ? LinkPreviewInfo.image : "")

                    Rectangle {
                        anchors.fill: parent
                        color: JamiTheme.previewImageBackgroundColor
                        z: -1
                    }

                    layer.effect: OpacityMask {
                        maskSource: MessageBubble {
                            height: img.height
                            out: isOutgoing
                            radius: msgRadius
                            type: seq
                            width: img.width

                            Rectangle {
                                height: msgRadius
                                width: parent.width
                            }
                        }
                    }
                }
                Column {
                    Layout.leftMargin: hPadding
                    Layout.preferredWidth: img.width - 2 * hPadding
                    Layout.rightMargin: hPadding
                    opacity: img.status !== Image.Loading
                    spacing: 6
                    visible: !isRemoteImage

                    Label {
                        color: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                        font.hintingPreference: Font.PreferNoHinting
                        font.pointSize: 10
                        renderType: Text.NativeRendering
                        text: LinkPreviewInfo.title
                        textFormat: TextEdit.RichText
                        visible: LinkPreviewInfo.title !== null
                        width: parent.width
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    }
                    Label {
                        color: root.colorUrl
                        font.hintingPreference: Font.PreferNoHinting
                        font.pointSize: 11
                        font.underline: root.hoveredLink
                        renderType: Text.NativeRendering
                        text: LinkPreviewInfo.description
                        textFormat: TextEdit.RichText
                        visible: LinkPreviewInfo.description !== null
                        width: parent.width
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    }
                    Label {
                        color: UtilsAdapter.luma(bubble.color) ? JamiTheme.chatviewTextColorLight : JamiTheme.chatviewTextColorDark
                        font.hintingPreference: Font.PreferNoHinting
                        font.pointSize: 10
                        renderType: Text.NativeRendering
                        text: LinkPreviewInfo.domain
                        textFormat: TextEdit.RichText
                        width: parent.width
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    }
                }
            }
        }
    ]
    Behavior on opacity  {
        NumberAnimation {
            duration: 100
        }
    }
}
