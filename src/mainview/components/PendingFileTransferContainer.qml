/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import net.jami.Models 1.0
import net.jami.Constants 1.0

Rectangle {
    id: root

    property alias pendingFilesToSendListModel: repeater.model
    property alias pendingFilesCount: repeater.count

    color: JamiTheme.messageOutBgColor

    ScrollView {
        id: pendingFilesToSendContainerScrollView

        anchors.fill: root

        contentHeight: root.height
        contentWidth: pendingFilesToSendContainerRow.width

        ScrollBar.horizontal.visible: {
            var ratio = pendingFilesToSendContainerRow.width / root.width
            return ratio > 1
        }
        ScrollBar.horizontal.contentItem: Rectangle {
            implicitHeight: 5
            radius: width / 2
            color: pendingFilesToSendContainerScrollView.ScrollBar.horizontal.pressed ?
                       JamiTheme.darkGreyColor : JamiTheme.whiteColor
        }
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        Row {
            id: pendingFilesToSendContainerRow

            anchors.centerIn: parent

            spacing: JamiTheme.pendingFilesToSendContainerSpacing
            padding: JamiTheme.pendingFilesToSendContainerPadding

            Repeater {
                id: repeater

                delegate: PendingFilesToSendDelegate {
                    anchors.verticalCenter: pendingFilesToSendContainerRow.verticalCenter

                    width: JamiTheme.pendingFilesToSendDelegateWidth
                    height: JamiTheme.pendingFilesToSendDelegateHeight

                    onRemoveFileButtonClicked: {
                        pendingFilesToSendListModel.removeFromPending(index)
                    }
                }
                model: PendingFilesToSendListModel {
                    id: pendingFilesToSendListModel
                }
            }
        }
    }
}
