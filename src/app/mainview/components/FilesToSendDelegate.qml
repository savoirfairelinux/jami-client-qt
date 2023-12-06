/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Item {
    id: root

    property real margin: 5
    signal removeFileButtonClicked(int index)

    width: JamiTheme.layoutWidthFileTransfer * 2

    RowLayout {

        anchors.fill: root
        spacing: 2

        Rectangle {
            id: mainRect

            radius: JamiTheme.filesToSendDelegateRadius
            Layout.preferredHeight: JamiTheme.layoutWidthFileTransfer
            Layout.preferredWidth: JamiTheme.layoutWidthFileTransfer
            color: JamiTheme.fileBackgroundColor

            ResponsiveImage {
                id: fileIcon
                visible: !IsImage
                anchors.fill: parent
                anchors.margins: 17
                containerHeight: 20
                source: JamiResources.link_black_24dp_svg
                cache: false
                color: JamiTheme.fileIconColor
            }

            AnimatedImage {
                id: name

                anchors.fill: parent
                cache: false

                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                source: {
                    if (!IsImage)
                        return "";

                    // :/ -> resource url for test purposes
                    var sourceUrl = FilePath;
                    if (!sourceUrl.startsWith(":/"))
                        return JamiQmlUtils.qmlFilePrefix + sourceUrl;
                    else
                        return "qrc" + sourceUrl;
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: mainRect.width
                        height: mainRect.height
                        radius: JamiTheme.filesToSendDelegateRadius
                    }
                }
            }

            JamiPushButton {
                id: removeFileButton

                anchors.right: mainRect.right
                anchors.top: mainRect.top

                preferredSize: 20

                source: JamiResources.round_close_24dp_svg

                normalColor: JamiTheme.secondaryBackgroundColor
                imageColor: JamiTheme.textColor
                hoveredColor: JamiTheme.removeFileButtonHoverColor

                onClicked: root.removeFileButtonClicked(index)
            }
        }

        Control {
            id: info

            Layout.leftMargin: 5

            contentItem: ColumnLayout {

                spacing: 7

                Text {
                    id: fileName

                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: Math.max(info.width, fileExtensionLayout.width)
                    font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                    color: JamiTheme.chatviewTextColor
                    text: FileName
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }

                RowLayout {
                    id: fileExtensionLayout

                    Layout.alignment: Qt.AlignLeft
                    spacing: FileExtension.length === 0 ? 0 : 1

                    Text {
                        id: fileExtension
                        Layout.alignment: Qt.AlignLeft
                        font.pointSize: JamiTheme.editedFontSize
                        font.capitalization: Font.AllUppercase
                        color: JamiTheme.chatviewTextColor
                        text: FileExtension

                        elide: Text.ElideMiddle
                    }

                    Text {
                        id: fileSize
                        font.pointSize: JamiTheme.editedFontSize
                        color: JamiTheme.chatviewTextColor
                        Layout.alignment: Qt.AlignLeft
                        text: FileSize
                        elide: Text.ElideMiddle

                        Component.onCompleted: {
                            text = text.toLowerCase();
                            text = text.replace(" ", "");
                        }
                    }
                }
            }
        }
    }
}
