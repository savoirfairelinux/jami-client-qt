/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

import "../../commoncomponents"

Item {
    id: root

    JamiListView {
        id: activeCalls
        anchors.fill: parent
        anchors.margins: JamiTheme.preferredMarginSize
        spacing: 16

        model: ActiveCallsModel

        delegate: Rectangle {
            width: activeCalls.width
            height: visible ? 100 : 0
            color: Qt.rgba(0, 0, 0, 0.5)

            visible: !Ignored

            ColumnLayout {
                anchors.fill: parent
                spacing: 16
                anchors.margins: 16

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: JamiStrings.aCallIsInProgress
                    color: "white"
                    font.pointSize: JamiTheme.headerFontSize
                    font.weight: Font.Bold
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    PushButton {
                        id: joinCallInAudio

                        source: JamiResources.place_audiocall_24dp_svg
                        toolTipText: JamiStrings.joinCall

                        normalColor: JamiTheme.chatviewBgColor
                        imageColor: JamiTheme.chatviewButtonColor

                        onClicked: MessagesAdapter.joinCall(Id, Uri, Device, true)
                    }

                    PushButton {
                        id: joinCallInVideo

                        visible: CurrentAccount.videoEnabled_Video
                        source: JamiResources.videocam_24dp_svg
                        toolTipText: JamiStrings.joinCall

                        normalColor: JamiTheme.chatviewBgColor
                        imageColor: JamiTheme.chatviewButtonColor

                        onClicked: MessagesAdapter.joinCall(Id, Uri, Device)
                    }
                }
            }

            PushButton {
                id: cancelBtn
                normalColor: "transparent"
                hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                imageColor: "white"
                preferredSize: 12
                source: JamiResources.round_close_24dp_svg
                toolTipText: JamiStrings.back
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                onClicked: {
                    ActiveCallsModel.ignore(Id, Uri, Device)
                }
            }

        }
    }
}