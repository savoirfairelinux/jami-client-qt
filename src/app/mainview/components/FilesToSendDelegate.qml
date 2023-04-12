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
import Qt5Compat.GraphicalEffects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Item {
    id: root
    property real margin: 5

    signal removeFileButtonClicked(int index)

    RowLayout {
        anchors.fill: root
        spacing: 2

        Rectangle {
            id: mainRect
            Layout.preferredHeight: root.height - 4 * margin
            Layout.preferredWidth: JamiTheme.layoutWidthFileTransfer
            color: JamiTheme.transparentColor
            radius: JamiTheme.filesToSendDelegateRadius

            Rectangle {
                id: rect
                anchors.fill: parent
                color: fileIcon.visible ? CurrentConversation.color : JamiTheme.transparentColor
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: fileIcon.visible ? margin : 0
                    color: JamiTheme.secondaryBackgroundColor
                    radius: JamiTheme.chatViewFooterButtonRadius

                    ResponsiveImage {
                        id: fileIcon
                        anchors.fill: parent
                        anchors.margins: 14
                        cache: false
                        color: JamiTheme.textColor
                        source: JamiResources.file_black_24dp_svg
                        visible: !IsImage
                    }
                    AnimatedImage {
                        id: name
                        anchors.fill: parent
                        asynchronous: true
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
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

                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                height: mainRect.height
                                radius: JamiTheme.filesToSendDelegateRadius
                                width: mainRect.width
                            }
                        }
                    }
                }

                layer.effect: OpacityMask {
                    maskSource: Item {
                        height: rect.height
                        width: rect.width

                        Rectangle {
                            anchors.centerIn: parent
                            height: rect.height
                            radius: JamiTheme.chatViewFooterButtonRadius
                            width: rect.width
                        }
                    }
                }
            }
            PushButton {
                id: removeFileButton
                anchors.right: mainRect.right
                anchors.rightMargin: -margin
                anchors.top: mainRect.top
                anchors.topMargin: -margin
                imageColor: JamiTheme.textColor
                imageContainerHeight: 52
                imageContainerWidth: 52
                normalColor: JamiTheme.backgroundColor
                preferredSize: 30
                radius: 24
                source: JamiResources.cross_black_24dp_svg
                toolTipText: JamiStrings.optionRemove

                onClicked: root.removeFileButtonClicked(index)
            }
        }
        Rectangle {
            id: info
            Layout.alignment: Qt.AlignLeft
            Layout.preferredHeight: root.height - margin
            Layout.preferredWidth: JamiTheme.layoutWidthFileTransfer
            color: JamiTheme.transparentColor

            ColumnLayout {
                anchors.left: parent.left
                anchors.margins: 5
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: fileName
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: info.width
                    color: JamiTheme.chatviewTextColor
                    elide: Text.ElideRight
                    font.bold: true
                    font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                    text: FileName
                }
                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing: FileExtension.length === 0 ? 0 : 1

                    Text {
                        id: fileExtension
                        Layout.alignment: Qt.AlignLeft
                        color: JamiTheme.chatviewTextColor
                        elide: Text.ElideMiddle
                        font.capitalization: Font.AllUppercase
                        font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                        text: FileExtension
                    }
                    Text {
                        id: fileSize
                        Layout.alignment: Qt.AlignLeft
                        color: JamiTheme.chatviewTextColor
                        elide: Text.ElideMiddle
                        font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                        text: FileSize
                    }
                }
            }
        }
    }
}
