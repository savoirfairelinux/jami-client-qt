/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

// The text of a feed post or comment, with its link preview.
ColumnLayout {
    id: root

    property string messageId
    property string author
    property string body
    property string parsedBody
    property var linkPreviewInfo
    property color backgroundColor: JamiTheme.feedPostBgColor
    property real fontSize: JamiTheme.mediumFontSize
    property bool showLinkPreview: true

    readonly property bool isDeleted: body === "" && parsedBody === ""
    readonly property color linkColor: UtilsAdapter.luma(backgroundColor) ? JamiTheme.chatviewLinkColorLight : JamiTheme.chatviewLinkColorDark
    readonly property bool hasLinkPreview: showLinkPreview && !!linkPreviewInfo && linkPreviewInfo.url !== undefined

    spacing: 8

    TextEdit {
        id: textEdit
        objectName: "feedText"

        Layout.fillWidth: true

        text: {
            if (root.isDeleted)
                return JamiStrings.deletedMessage.arg(UtilsAdapter.getBestNameForUri(CurrentAccount.id, root.author));
            if (root.parsedBody === "") {
                MessagesAdapter.parseMessage(root.messageId, root.body, UtilsAdapter.getAppValue(Settings.DisplayHyperlinkPreviews), root.linkColor, root.backgroundColor);
                return "";
            }
            return root.parsedBody;
        }
        textFormat: Text.RichText
        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
        readOnly: true
        selectByMouse: true
        color: JamiTheme.textColor
        opacity: root.isDeleted ? 0.5 : 1
        font.pointSize: root.isDeleted ? JamiTheme.smallFontSize : root.fontSize
        font.hintingPreference: Font.PreferNoHinting
        renderType: Text.NativeRendering

        onLinkActivated: link => Qt.openUrlExternally(new URL(link))

        HoverHandler {
            enabled: textEdit.hoveredLink !== ""
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            enabled: textEdit.selectedText.length > 0
            acceptedButtons: Qt.RightButton
            onTapped: eventPoint => {
                ctxMenuLoader.active = true;
                ctxMenuLoader.item.openMenuAt(eventPoint.position);
            }
        }

        Loader {
            id: ctxMenuLoader

            active: false
            sourceComponent: LineEditContextMenu {
                lineEditObj: textEdit
                selectOnly: true
            }
        }
    }

    Loader {
        objectName: "feedLinkPreview"

        Layout.fillWidth: true
        active: root.hasLinkPreview
        visible: active

        sourceComponent: Rectangle {
            id: preview

            readonly property bool isRemoteImage: MessagesAdapter.isRemoteImage(root.linkPreviewInfo.url)

            implicitHeight: previewColumn.implicitHeight
            radius: 12
            color: JamiTheme.messageInBgColor
            clip: true

            ColumnLayout {
                id: previewColumn

                width: parent.width
                spacing: 4

                AnimatedImage {
                    readonly property bool hasImage: root.linkPreviewInfo.image !== null

                    Layout.fillWidth: true
                    Layout.preferredHeight: status === Image.Ready ? Math.min(Math.ceil(width * implicitHeight / implicitWidth), JamiTheme.maxImageHeight) : 0
                    visible: Layout.preferredHeight > 0
                    // Remote movies can't be rewound; cached frames loop without rewinding.
                    cache: true
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    source: preview.isRemoteImage ? root.linkPreviewInfo.url : (hasImage ? root.linkPreviewInfo.image : "")
                }

                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.topMargin: 4
                    visible: !preview.isRemoteImage && text.length > 0
                    text: root.linkPreviewInfo.title
                    textFormat: Text.RichText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font.bold: true
                    color: JamiTheme.textColor
                }

                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    visible: !preview.isRemoteImage && text.length > 0
                    text: root.linkPreviewInfo.description
                    textFormat: Text.RichText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    color: JamiTheme.textColor
                    opacity: 0.8
                }

                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.bottomMargin: 8
                    visible: !preview.isRemoteImage
                    text: root.linkPreviewInfo.domain
                    color: JamiTheme.chatviewSecondaryInformationColor
                    font.pointSize: JamiTheme.smallFontSize
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Qt.openUrlExternally(root.linkPreviewInfo.url)
            }
        }
    }
}
