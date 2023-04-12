/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

BaseModalDialog {
    id: root
    property var previousBodies: undefined

    height: 256
    width: 488

    popupContent: Item {
        id: rect
        width: root.width

        JamiListView {
            anchors.fill: parent
            anchors.margins: JamiTheme.preferredMarginSize
            model: root.previousBodies

            delegate: Rectangle {
                color: index % 2 === 0 ? JamiTheme.backgroundColor : JamiTheme.secondaryBackgroundColor
                height: Math.max(JamiTheme.menuItemsPreferredHeight, rowBody.implicitHeight)
                width: root.width - 2 * JamiTheme.preferredMarginSize

                RowLayout {
                    id: rowBody
                    anchors.centerIn: parent
                    spacing: JamiTheme.preferredMarginSize
                    width: parent.width

                    Text {
                        Layout.leftMargin: JamiTheme.settingsMarginSize
                        Layout.maximumWidth: root.width / 2
                        color: JamiTheme.textColor
                        elide: Text.ElideRight
                        opacity: 0.5
                        text: MessagesAdapter.getFormattedDay(modelData.timestamp.toString()) + " - " + MessagesAdapter.getFormattedTime(modelData.timestamp.toString())
                    }
                    Text {
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                        color: JamiTheme.textColor
                        text: metrics.elidedText

                        TextMetrics {
                            id: metrics
                            elide: Text.ElideRight
                            elideWidth: 3 * rowBody.width / 4 - 2 * JamiTheme.preferredMarginSize
                            text: modelData.body === "" ? JamiStrings.deletedMessage : modelData.body
                        }
                    }
                }
            }
        }
        PushButton {
            id: btnCancel
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 10
            imageColor: "grey"
            normalColor: "transparent"
            source: JamiResources.round_close_24dp_svg

            onClicked: close()
        }
    }
}
