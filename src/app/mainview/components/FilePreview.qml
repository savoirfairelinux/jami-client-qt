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
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"
import "../../settingsview/components"

Component {
    id: root
    Rectangle {
        id: dataTransferRect
        clip: true
        color: "transparent"
        height: width
        width: (contentWidth - spacingLength) / numberElementsPerRow

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins

            Text {
                id: myText
                Layout.fillWidth: true
                color: JamiTheme.textColor
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: TransferName
            }
            Rectangle {
                Layout.bottomMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                Layout.preferredHeight: parent.height - myText.height - JamiTheme.swarmDetailsPageDocumentsMargins
                Layout.preferredWidth: parent.width
                Layout.rightMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                color: "transparent"

                Rectangle {
                    id: rectContent
                    anchors.fill: parent
                    anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins
                    border.color: themeColor
                    border.width: 2
                    color: "transparent"
                    layer.enabled: true
                    radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius

                    ResponsiveImage {
                        id: paperClipImage
                        anchors.centerIn: parent
                        color: JamiTheme.textColor
                        height: parent.height / 2
                        source: JamiResources.link_black_24dp_svg
                        width: parent.width / 2

                        MouseArea {
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: function (mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    ctxMenu.x = mouse.x;
                                    ctxMenu.y = mouse.y;
                                    ctxMenu.openMenu();
                                } else {
                                    Qt.openUrlExternally(new Url("file://" + Body));
                                }
                            }
                            onEntered: {
                                cursorShape = Qt.PointingHandCursor;
                            }
                        }
                        SBSContextMenu {
                            id: ctxMenu
                            location: Body
                            msgId: Id
                            transferId: Id
                            transferName: TransferName
                        }
                    }
                }
            }
        }
    }
}
