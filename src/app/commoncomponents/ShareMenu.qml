/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

import "contextmenu"

BaseContextMenu {
    id: root

    property var modelList
    signal audioRecordMessageButtonClicked
    signal videoRecordMessageButtonClicked
    signal showMapClicked

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: audioMessage

            Accessible.role: Accessible.MenuItem
            Accessible.name: itemName
            focusPolicy: Qt.StrongFocus
            Keys.onReturnPressed: clicked()

            canTrigger: true
            iconSource: JamiResources.message_audio_black_24dp_svg
            itemName: JamiStrings.leaveAudioMessage
            onClicked: {
                root.audioRecordMessageButtonClicked();
                root.close()
            }

            KeyNavigation.tab: videoMessage
            KeyNavigation.backtab: shareLocation
        },
        GeneralMenuItem {
            id: videoMessage

            Accessible.role: Accessible.MenuItem
            Accessible.name: itemName

            focusPolicy: Qt.StrongFocus
            Keys.onReturnPressed: clicked()

            canTrigger: true
            iconSource: JamiResources.message_video_black_24dp_svg
            itemName: JamiStrings.leaveVideoMessage
            isActif: VideoDevices.listSize !== 0

            onClicked: {
                root.videoRecordMessageButtonClicked();
                root.close()
            }

            KeyNavigation.tab: shareLocation
            KeyNavigation.backtab: audioMessage
        },
        GeneralMenuItem {
            id: shareLocation

            Accessible.role: Accessible.MenuItem
            Accessible.name: itemName

            focusPolicy: Qt.StrongFocus
            Keys.onReturnPressed: clicked()

            canTrigger: true
            iconSource: JamiResources.localisation_sharing_send_pin_svg
            itemName: JamiStrings.shareLocation
            onClicked: {
                root.showMapClicked();
                root.close()
            }

            KeyNavigation.tab: audioMessage
            KeyNavigation.backtab: videoMessage
        }
    ]

    Component.onCompleted: {
        root.loadMenuItems(menuItems);
    }
}
