﻿/*
 * Copyright (C) 2021-2022 Savoir-faire Linux Inc.
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
    id : root

    property bool isRemoteImage
    property bool isEmojiOnly: IsEmojiOnly
    property real maxMsgWidth: root.width - senderMargin - 2 * hPadding - avatarBlockWidth

    isOutgoing: Author === ""
    author: Author
    readers: Readers
    timestamp: Timestamp
    formattedTime: MessagesAdapter.getFormattedTime(Timestamp)
    formattedDay: MessagesAdapter.getFormattedDay(Timestamp)
    extraHeight: extraContent.active && !isRemoteImage ? msgRadius : -isRemoteImage

    EditedPopup {
        id: editedPopup

        previousBodies: PreviousBodies
    }

    innerContent.children: [
        TextEdit {
            id: textEditId

            padding: isEmojiOnly ? 0 : JamiTheme.preferredMarginSize
            anchors.right: isOutgoing ? parent.right : undefined

            text: Body

            horizontalAlignment: Text.AlignLeft

            width: {
                if (extraContent.active)
                    Math.max(extraContent.width,
                             Math.min(implicitWidth - avatarBlockWidth,
                                      extraContent.minSize) - senderMargin )
                else
                    Math.min(implicitWidth, innerContent.width - senderMargin)
            }

            height: implicitHeight
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            selectByMouse: true
            font.pixelSize: isEmojiOnly? JamiTheme.chatviewEmojiSize : JamiTheme.chatviewFontSize

            font.hintingPreference: Font.PreferNoHinting
            renderType: Text.NativeRendering
            textFormat: Text.MarkdownText
            onLinkHovered: root.hoveredLink = hoveredLink
            onLinkActivated: Qt.openUrlExternally(hoveredLink)
            readOnly: true
            color: getBaseColor()

            function getBaseColor() {
                var baseColor
                if (isEmojiOnly) {
                    if (JamiTheme.darkTheme)
                        baseColor = JamiTheme.chatviewTextColorLight
                    else
                        baseColor = JamiTheme.chatviewTextColorDark
                } else {
                    if (UtilsAdapter.luma(bubble.color))
                        baseColor = JamiTheme.chatviewTextColorLight
                    else
                        baseColor = JamiTheme.chatviewTextColorDark
                }
                return baseColor
            }

            TapHandler {
                enabled: parent.selectedText.length > 0
                acceptedButtons: Qt.RightButton
                onTapped: function onTapped(eventPoint) {
                    ctxMenu.openMenuAt(eventPoint.position)
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

            ResponsiveImage  {
                id: editedImage

                Layout.leftMargin: JamiTheme.preferredMarginSize
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                source: JamiResources.round_edit_24dp_svg
                width: JamiTheme.editedFontSize
                height: JamiTheme.editedFontSize
                layer {
                    enabled: true
                    effect: ColorOverlay {
                        color: editedLabel.color
                    }
                }
            }

            Text {
                id: editedLabel

                Layout.rightMargin: JamiTheme.preferredMarginSize
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                text: JamiStrings.edited
                color: UtilsAdapter.luma(bubble.color) ?
                        JamiTheme.chatviewTextColorLight :
                        JamiTheme.chatviewTextColorDark
                font.pointSize: JamiTheme.editedFontSize

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: {
                        editedPopup.open()
                    }
                }
            }
        },
        Loader {
            id: extraContent
            anchors.right: isOutgoing ? parent.right : undefined
            property real minSize: 192
            property real maxSize: 320
            active: LinkPreviewInfo.url !== undefined
            sourceComponent: ColumnLayout {
                id: previewContent
                spacing: 12
                Component.onCompleted: {
                    isRemoteImage = MessagesAdapter.isRemoteImage(LinkPreviewInfo.url)
                }
                HoverHandler {
                    target: previewContent
                    onHoveredChanged: {
                        root.hoveredLink = hovered ? LinkPreviewInfo.url : ""
                    }
                    cursorShape: Qt.PointingHandCursor
                }
                AnimatedImage {
                    id: img

                    cache: false
                    source: isRemoteImage ?
                                LinkPreviewInfo.url :
                                (hasImage ? LinkPreviewInfo.image : "")

                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    antialiasing: true
                    autoTransform: true
                    asynchronous: true
                    readonly property bool hasImage: LinkPreviewInfo.image !== null
                    property real aspectRatio: implicitWidth / implicitHeight
                    property real adjustedWidth: Math.min(extraContent.maxSize,
                                                          Math.max(extraContent.minSize,
                                                                   maxMsgWidth))
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
                            Rectangle { height: msgRadius; width: parent.width }
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
                    spacing: 6
                    Label {
                        width: parent.width
                        font.pointSize: 10
                        font.hintingPreference: Font.PreferNoHinting
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                        renderType: Text.NativeRendering
                        textFormat: TextEdit.RichText
                        color: UtilsAdapter.luma(bubble.color) ?
                                JamiTheme.chatviewTextColorLight :
                                JamiTheme.chatviewTextColorDark
                        visible: LinkPreviewInfo.title !== null
                        text: LinkPreviewInfo.title
                    }
                    Label {
                        width: parent.width
                        font.pointSize: 11
                        font.hintingPreference: Font.PreferNoHinting
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                        renderType: Text.NativeRendering
                        textFormat: TextEdit.RichText
                        color: UtilsAdapter.luma(bubble.color) ?
                                JamiTheme.chatviewTextColorLight :
                                JamiTheme.chatviewTextColorDark
                        visible: LinkPreviewInfo.description !== null
                        text: '<a href=" " style="text-decoration: ' +
                              ( hoveredLink ? 'underline' : 'none') + ';"' +
                              '>' + LinkPreviewInfo.description + '</a>'
                    }
                    Label {
                        width: parent.width
                        font.pointSize: 10
                        font.hintingPreference: Font.PreferNoHinting
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                        renderType: Text.NativeRendering
                        textFormat: TextEdit.RichText
                        color: UtilsAdapter.luma(bubble.color) ?
                                JamiTheme.chatviewTextColorLight :
                                JamiTheme.chatviewTextColorDark
                        text: LinkPreviewInfo.domain
                    }
                }
            }
        }
    ]

    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 100 } }
    Component.onCompleted: {
        if (!Linkified) {
            MessagesAdapter.parseMessageUrls(Id, Body, UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews))
        }
        opacity = 1
    }
}
