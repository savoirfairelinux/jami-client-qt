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
import net.jami.Constants 1.1
import "contextmenu"

BaseContextMenu {
    id: root

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: audioMessage

            canTrigger: true
            iconSource: JamiResources.message_audio_black_24dp_svg
            itemName: JamiStrings.leaveAudioMessage
            onClicked: {
                console.log("audioMessage clicked");
            }
        },
        GeneralMenuItem {
            id: videoMessage

            canTrigger: true
            iconSource: JamiResources.message_video_black_24dp_svg
            itemName: JamiStrings.leaveVideoMessage

            onClicked: {
                console.log("videoMessage clicked");
            }
        },
        GeneralMenuItem {
            id: shareLocation

            canTrigger: true
            iconSource: JamiResources.localisation_sharing_send_pin_svg
            itemName: JamiStrings.shareLocation
            onClicked: {
                console.log("shareLocation clicked");
            }
        }
    ]

    Component.onCompleted: {
        root.loadMenuItems(menuItems);
    }
}
