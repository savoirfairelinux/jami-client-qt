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

        model: ActiveCallsModel

        delegate: Rectangle {
            width: activeCalls.width
            height: visible ? 100 : 0
            color: Qt.rgba(0, 0, 0, 0.5)

            visible: !Ignored

            RowLayout {

                anchors.fill: parent

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: JamiStrings.wantToJoin
                        color: "white"
                        font.pointSize: JamiTheme.headerFontSize
                        font.weight: Font.Bold
                    }

                    PushButton {
                        id: joinCallInAudio
                        Layout.alignment: Qt.AlignHCenter

                        source: JamiResources.place_audiocall_24dp_svg
                        toolTipText: JamiStrings.joinCall

                        preferredSize: 40
                        imageColor: "white"
                        normalColor: "transparent"
                        hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                        border.width: 1
                        border.color: "white"

                        onClicked: MessagesAdapter.joinCall(Id, Uri, Device, true)
                    }

                    PushButton {
                        id: joinCallInVideo
                        Layout.alignment: Qt.AlignHCenter

                        visible: CurrentAccount.videoEnabled_Video
                        source: JamiResources.videocam_24dp_svg
                        toolTipText: JamiStrings.joinCall

                        preferredSize: 40
                        imageColor: "white"
                        normalColor: "transparent"
                        hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                        border.width: 1
                        border.color: "white"

                        onClicked: MessagesAdapter.joinCall(Id, Uri, Device)
                    }
                }


                PushButton {
                    id: cancelBtn
                    normalColor: "transparent"
                    hoveredColor: Qt.rgba(255, 255, 255, 0.2)
                    imageColor: "white"
                    source: JamiResources.round_close_24dp_svg
                    toolTipText: JamiStrings.back
                    onClicked: ActiveCallsModel.ignore(Id, Uri, Device)
                    Layout.alignment: Qt.AlignRight
                    Layout.margins: JamiTheme.preferredMarginSize
                }
            }
        }

    }
}