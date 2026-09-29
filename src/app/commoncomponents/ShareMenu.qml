/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

    property var convContext: CurrentConversation
    property var modelList
    signal audioRecordMessageButtonClicked
    signal videoRecordMessageButtonClicked
    signal showMapClicked
    signal newEditableDocumentClicked

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: newEditableDocument
            objectName: "newEditableDocumentMenuItem"

            Accessible.role: Accessible.MenuItem
            Accessible.name: itemName
            focusPolicy: Qt.StrongFocus
            Keys.onReturnPressed: clicked()

            readonly property bool allowed: !!(root.convContext && root.convContext.canCreateDocument)

            canTrigger: true
            visible: allowed
            height: allowed ? JamiTheme.generalMenuItemHeight : 0
            implicitHeight: height
            iconSource: JamiResources.round_edit_24dp_svg
            itemName: qsTr("New editable document")
            onClicked: {
                root.newEditableDocumentClicked();
                root.close()
            }

            KeyNavigation.tab: audioMessage
            KeyNavigation.backtab: shareLocation
        },
        GeneralMenuItem {
            id: audioMessage
            objectName: "audioMessageMenuItem"

            Accessible.role: Accessible.MenuItem
            Accessible.name: itemName
            focusPolicy: Qt.StrongFocus
            Keys.onReturnPressed: clicked()

            readonly property bool allowed: !!(root.convContext
                                               && (MessagesAdapter.replyToId ? root.convContext.canReplyFile
                                                                             : root.convContext.canSendFile))

            canTrigger: true
            visible: allowed
            height: allowed ? JamiTheme.generalMenuItemHeight : 0
            implicitHeight: height
            iconSource: JamiResources.message_audio_black_24dp_svg
            itemName: JamiStrings.leaveAudioMessage
            onClicked: {
                root.audioRecordMessageButtonClicked();
                root.close()
            }

            KeyNavigation.tab: videoMessage
            KeyNavigation.backtab: newEditableDocument
        },
        GeneralMenuItem {
            id: videoMessage
            objectName: "videoMessageMenuItem"

            Accessible.role: Accessible.MenuItem
            Accessible.name: itemName

            focusPolicy: Qt.StrongFocus
            Keys.onReturnPressed: clicked()

            readonly property bool allowed: !!(root.convContext
                                               && (MessagesAdapter.replyToId ? root.convContext.canReplyFile
                                                                             : root.convContext.canSendFile))

            canTrigger: true
            visible: allowed
            height: allowed ? JamiTheme.generalMenuItemHeight : 0
            implicitHeight: height
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
            iconSource: JamiResources.location_sharing_send_pin_24dp_svg
            itemName: JamiStrings.shareLocation
            onClicked: {
                root.showMapClicked();
                root.close()
            }

            KeyNavigation.tab: newEditableDocument
            KeyNavigation.backtab: videoMessage
        }
    ]

    Component.onCompleted: {
        root.loadMenuItems(menuItems);
        const createActionSeparator = root.generalMenuSeparatorList[0];
        const audioMessageSeparator = root.generalMenuSeparatorList[1];
        const videoMessageSeparator = root.generalMenuSeparatorList[2];

        createActionSeparator.visible = Qt.binding(() => newEditableDocument.allowed
                                                             && (audioMessage.allowed || videoMessage.allowed || shareLocation.visible));
        createActionSeparator.implicitHeight = Qt.binding(() => createActionSeparator.visible
                                                                   ? createActionSeparator.contentItem.implicitHeight
                                                                         + createActionSeparator.topPadding
                                                                         + createActionSeparator.bottomPadding
                                                                   : 0);
        createActionSeparator.height = Qt.binding(() => createActionSeparator.implicitHeight);

        audioMessageSeparator.visible = Qt.binding(() => audioMessage.allowed
                                                             && (videoMessage.allowed || shareLocation.visible));
        audioMessageSeparator.implicitHeight = Qt.binding(() => audioMessageSeparator.visible
                                                                   ? audioMessageSeparator.contentItem.implicitHeight
                                                                         + audioMessageSeparator.topPadding
                                                                         + audioMessageSeparator.bottomPadding
                                                                   : 0);
        audioMessageSeparator.height = Qt.binding(() => audioMessageSeparator.implicitHeight);

        videoMessageSeparator.visible = Qt.binding(() => videoMessage.allowed && shareLocation.visible);
        videoMessageSeparator.implicitHeight = Qt.binding(() => videoMessageSeparator.visible
                                                                   ? videoMessageSeparator.contentItem.implicitHeight
                                                                         + videoMessageSeparator.topPadding
                                                                         + videoMessageSeparator.bottomPadding
                                                                   : 0);
        videoMessageSeparator.height = Qt.binding(() => videoMessageSeparator.implicitHeight);
    }
}
