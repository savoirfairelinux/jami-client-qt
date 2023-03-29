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
        spacing : 2

        Rectangle {
            id: mainRect

            radius: JamiTheme.filesToSendDelegateRadius
            Layout.preferredHeight: root.height - 4 * margin
            Layout.preferredWidth: JamiTheme.layoutWidthFileTransfer
            color: JamiTheme.transparentColor

            Rectangle {
                id: rect

                anchors.fill: parent
                color: CurrentConversation.color // "#E5E5E5"
                layer.enabled: true

                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: rect.width
                        height: rect.height
                        Rectangle {
                            anchors.centerIn: parent
                            width:  rect.width
                            height:  rect.height
                            radius: JamiTheme.chatViewFooterButtonRadius
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    anchors.bottom: parent.bottom
                    height: 3/4 * mainRect.height
                    color: CurrentConversation.color
                }

                Rectangle {

                    anchors.fill: parent
                    anchors.margins: margin
                    radius: JamiTheme.chatViewFooterButtonRadius
                    color: JamiTheme.whiteColor

                    ResponsiveImage {
                        id: fileIcon
                        visible : !IsImage
                        anchors.fill: parent
                        anchors.margins: margin
                        source: JamiResources.file_black_24dp_svg
                    }

                    AnimatedImage {
                        id: name

                        anchors.fill: parent
                        anchors.margins: margin
                        cache: false

                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        source: {
                            if (!IsImage)
                                return ""

                            // :/ -> resource url for test purposes
                            var sourceUrl = FilePath
                            if (!sourceUrl.startsWith(":/"))
                                return JamiQmlUtils.qmlFilePrefix + sourceUrl
                            else
                                return "qrc" + sourceUrl
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
                }
            }

            PushButton {
                id: removeFileButton

                anchors.right: mainRect.right
                anchors.rightMargin: -margin
                anchors.top: mainRect.top
                anchors.topMargin: -margin

                radius: 24

                preferredSize: 30
                imageContainerWidth: 52
                imageContainerHeight: 52
                toolTipText: JamiStrings.optionRemove

                source: JamiResources.cross_black_24dp_svg

                normalColor: JamiTheme.backgroundColor
                imageColor: JamiTheme.textColor

                onClicked: root.removeFileButtonClicked(index)
            }
        }

        Rectangle {

            id: info
            Layout.preferredHeight: root.height -margin
            Layout.preferredWidth: JamiTheme.layoutWidthFileTransfer
            color : JamiTheme.transparentColor
            Layout.alignment: Qt.AlignLeft

            ColumnLayout {

                anchors.margins: margin
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left

                Text {
                    id: fileName

                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: info.width
                    font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                    color: JamiTheme.chatviewTextColor
                    font.bold : true
                    text: FileName
                    elide: Text.ElideRight
                }

                RowLayout {

                    Layout.alignment: Qt.AlignLeft
                    spacing: FileExtension.length === 0 ? 0 : 1

                    Text {
                        id: fileExtension
                        Layout.alignment: Qt.AlignLeft
                        font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                        font.capitalization: Font.AllUppercase
                        color: JamiTheme.chatviewTextColor
                        text: FileExtension

                        elide: Text.ElideMiddle
                    }

                    Text {
                        id: fileSize
                        font.pointSize: JamiTheme.filesToSendDelegateFontPointSize
                        color: JamiTheme.chatviewTextColor
                        Layout.alignment: Qt.AlignLeft
                        text: FileSize
                        elide: Text.ElideMiddle
                    }
                }
            }
        }
    }
}
