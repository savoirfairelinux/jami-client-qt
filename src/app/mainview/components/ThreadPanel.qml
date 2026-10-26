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
import QtQuick.Effects
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

// The open thread (its root and loaded replies) beside the conversation, with its own composer.
Item {
    id: root
    objectName: "threadPanel"

    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
        id: innerRect

        anchors.fill: parent
        anchors.margins: (typeof viewCoordinator !== "undefined" && viewCoordinator.isInSinglePaneMode) ? JamiTheme.sidePanelIslandsSinglePaneModePadding : JamiTheme.sidePanelIslandsPadding
        anchors.topMargin: JamiTheme.qwkTitleBarHeight + JamiTheme.sidePanelIslandsPadding * 2

        color: JamiTheme.globalIslandColor
        radius: JamiTheme.avatarBasedRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.bottomMargin: innerRect.radius / 2
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                Layout.leftMargin: 20
                Layout.rightMargin: 16

                spacing: 4

                Label {
                    text: JamiStrings.thread
                    color: JamiTheme.textColor
                    font.family: JamiTheme.ubuntuFontFamily
                    font.pointSize: JamiTheme.textFontSize + 2
                    font.bold: true
                }

                Rectangle {
                    implicitWidth: 1
                    Layout.preferredHeight: JamiTheme.iconButtonMedium
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    color: JamiTheme.textColor
                    opacity: 0.5
                }

                ElidedTextLabel {
                    objectName: "threadPanelTitle"
                    Layout.fillWidth: true
                    // Size from the row, not the text, since the elided text follows the width.
                    Layout.preferredWidth: 1
                    eText: CurrentConversation.title
                    maxWidth: width
                    font.family: CurrentConversation.isCoreDialog && CurrentConversation.title.length === 40 ? JamiTheme.ubuntuMonoFontFamily : JamiTheme.ubuntuFontFamily
                    font.pointSize: JamiTheme.textFontSize
                    color: JamiTheme.textColor
                    opacity: 0.6
                }

                NewIconButton {
                    objectName: "threadPanelCloseButton"
                    iconSize: JamiTheme.iconButtonMedium
                    iconSource: JamiResources.round_close_24dp_svg
                    iconColor: JamiTheme.textColor
                    toolTipText: JamiStrings.close
                    onClicked: MessagesAdapter.threadMessageListModel.threadId = ""
                }
            }

            MessageListView {
                id: threadListView
                objectName: "threadMessageList"

                Layout.fillWidth: true
                Layout.fillHeight: true
                topMargin: 0
                // A thread is complete once its root is loaded: replies are newer than their root.
                autoLoadHistory: false
                model: MessagesAdapter.threadMessageListModel
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            anchors.fill: innerRect

            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }
    }
}
