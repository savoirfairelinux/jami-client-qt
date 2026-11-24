/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../../commoncomponents/contextmenu"

BaseModalDialog {
    id: root

    required property var viewCoordinator
    property bool loading: true
    property bool loadFailed: false
    property real requestId: 0
    property var sharedFiles: []
    // Bumped after a deletion so tiles re-query whether their file is still local.
    property int localFilesRevision: 0

    titleText: JamiStrings.photoLibrary
    title: titleText
    implicitWidth: parent ? Math.min(720, Math.max(0, parent.width - 64)) : 720
    height: parent ? Math.min(implicitHeight, parent.height * 0.7, Math.max(0, parent.height - 64))
                   : implicitHeight

    onAboutToShow: {
        loading = true;
        loadFailed = false;
        searchBar.text = "";
        sharedFiles = [];
    }

    onOpened: {
        requestId = MessagesAdapter.requestPhotoLibrary();
        if (requestId)
            loadDeadline.start();
        else
            failLoading();
    }

    onAboutToHide: {
        fileMenu.close();
        infoDialog.close();
        removeDialog.close();
        loadDeadline.stop();
        cancelRequest();
        sharedFiles = [];
    }

    function cancelRequest() {
        if (requestId)
            MessagesAdapter.cancelPhotoLibraryRequest(requestId);
        requestId = 0;
    }

    function failLoading() {
        cancelRequest();
        loadFailed = true;
        loading = false;
    }

    function openFile(tile) {
        const path = MessagesAdapter.photoLibraryLocalFile(tile.modelData.conversationId, tile.modelData.fileId);
        if (path) {
            MessagesAdapter.openUrl(UtilsAdapter.urlFromLocalPath(path));
        } else {
            tile.showUnavailable();
        }
    }

    function goToConversation(conversationId) {
        viewCoordinator.dismiss("SettingsView");
        LRCInstance.selectConversation(conversationId, CurrentAccount.id);
        close();
    }

    Timer {
        id: loadDeadline
        interval: 60000
        onTriggered: root.failLoading()
    }

    Connections {
        target: CurrentAccount
        function onIdChanged() {
            root.close();
        }
    }

    Connections {
        target: MessagesAdapter
        function onPhotoLibraryLoaded(requestId, files) {
            if (!root.requestId || requestId !== root.requestId)
                return;
            loadDeadline.stop();
            root.requestId = 0;
            root.sharedFiles = files;
            root.loading = false;
        }
    }

    BaseContextMenu {
        id: fileMenu
        objectName: "photoLibraryFileMenu"

        property var file: null

        // The menu's parent is the whole grid, so outside-parent presses would never close it.
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        GeneralMenuItem {
            objectName: "photoLibraryGoToConversation"
            parentMenu: fileMenu
            text: JamiStrings.goToConversation
            itemName: text
            iconSource: JamiResources.chat_24dp_svg
            onTriggered: root.goToConversation(fileMenu.file.conversationId)
        }

        GeneralMenuSeparator {}

        GeneralMenuItem {
            parentMenu: fileMenu
            text: JamiStrings.sharedFileInfo
            itemName: text
            iconSource: JamiResources.informations_black_24dp_svg
            onTriggered: {
                fileMenu.close();
                infoDialog.showFile(fileMenu.file);
            }
        }

        GeneralMenuItem {
            objectName: "photoLibraryRemoveFile"
            parentMenu: fileMenu
            visible: fileMenu.file !== null && root.localFilesRevision >= 0
                     && MessagesAdapter.photoLibraryLocalFile(fileMenu.file.conversationId, fileMenu.file.fileId) !== ""
            height: visible ? JamiTheme.generalMenuItemHeight : 0
            text: JamiStrings.removeLocally
            itemName: text
            iconSource: JamiResources.delete_24dp_svg
            onTriggered: {
                fileMenu.close();
                removeDialog.file = fileMenu.file;
                removeDialog.open();
            }
        }
    }

    ConfirmDialog {
        id: removeDialog
        objectName: "photoLibraryRemoveDialog"

        property var file: null

        titleText: JamiStrings.removeLocally
        textLabel: file ? JamiStrings.confirmRemoveSharedFile.arg(file.name || JamiStrings.unnamedSharedFile) : ""
        confirmLabel: JamiStrings.optionDelete
        onAccepted: {
            MessagesAdapter.removePhotoLibraryFile(file.conversationId, file.messageId, file.fileId);
            root.localFilesRevision++;
        }
    }

    BaseModalDialog {
        id: infoDialog

        property var fileFields: []

        parent: root.contentItem
        titleText: JamiStrings.sharedFileInfo
        title: titleText
        implicitWidth: Math.min(380, root.width)
        height: Math.min(implicitHeight, root.parent ? Math.max(0, root.parent.height - 64) : implicitHeight)

        function showFile(file) {
            const details = MessagesAdapter.photoLibraryFileInfo(file.conversationId, file.fileId, file.name);
            const unknown = JamiStrings.sharedFileUnknown;
            const sender = file.author === CurrentAccount.uri ? CurrentAccount.bestName
                : file.author ? UtilsAdapter.getBestNameForUri(CurrentAccount.id, file.author) || file.author : unknown;
            const fields = [
                [JamiStrings.sharedFileName, file.name || JamiStrings.unnamedSharedFile],
                [JamiStrings.sharedFileType, details.mimeType || unknown],
                [JamiStrings.sharedFileSender, sender],
                [JamiStrings.sharedFileDate, file.timestamp > 0
                    ? new Date(file.timestamp * 1000).toLocaleString(Qt.locale(), Locale.ShortFormat) : unknown],
                [JamiStrings.sharedFileSize, file.size >= 0 ? UtilsAdapter.humanFileSize(file.size) : unknown]
            ];
            if (details.width > 0 && details.height > 0)
                fields.push([JamiStrings.sharedFileDimensions, JamiStrings.sharedFilePixelSize.arg(details.width).arg(details.height)]);
            fileFields = fields;
            open();
        }

        popupContent: Column {
            id: infoColumn

            width: Math.max(0, infoDialog.availableWidth - JamiTheme.scrollBarHandleSize)
            spacing: 6

            Repeater {
                model: infoDialog.fileFields

                delegate: Row {
                    required property var modelData

                    width: infoColumn.width
                    spacing: 8

                    Label {
                        width: parent.width / 3
                        color: JamiTheme.textColor
                        text: parent.modelData[0]
                        wrapMode: Text.Wrap
                    }

                    Label {
                        width: Math.max(0, parent.width - parent.width / 3 - parent.spacing)
                        color: JamiTheme.textColor
                        text: parent.modelData[1]
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    contentItem: ColumnLayout {
        id: contentLayout

        spacing: 8

        Searchbar {
            id: searchBar
            objectName: "photoLibrarySearch"

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
            placeHolderText: JamiStrings.searchSharedFiles
            textField.Accessible.name: placeHolderText
            textField.Accessible.description: ""
        }
    }

    GridView {
        id: filesList
        objectName: "photoLibraryGrid"

        parent: contentLayout
        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property int columns: Math.max(1, Math.floor(width / 154))

        model: {
            const query = searchBar.text.trim().toLocaleLowerCase();
            return query ? root.sharedFiles.filter(file =>
                (file.name || JamiStrings.unnamedSharedFile).toLocaleLowerCase().includes(query)
                || (file.conversationTitle || file.conversationId).toLocaleLowerCase().includes(query)) : root.sharedFiles;
        }
        onModelChanged: {
            currentIndex = -1;
            positionViewAtBeginning();
        }

        cellWidth: width / columns
        cellHeight: cellWidth
        implicitHeight: count ? Math.ceil(count / columns) * cellHeight : (headerItem?.implicitHeight ?? 0)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        maximumFlickVelocity: 1024
        activeFocusOnTab: true
        keyNavigationWraps: false
        keyNavigationEnabled: true
        Accessible.name: JamiStrings.photoLibrary

        Keys.onReturnPressed: if (currentItem) root.openFile(currentItem)
        Keys.onEnterPressed: if (currentItem) root.openFile(currentItem)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers === Qt.ShiftModifier)) {
                if (currentItem)
                    currentItem.openMenu(currentItem.width / 2, currentItem.height / 2);
                event.accepted = true;
            } else if (currentIndex < 0 && count > 0
                       && [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)) {
                currentIndex = 0;
                event.accepted = true;
            }
        }

        ScrollBar.vertical: JamiScrollBar {
            attachedFlickableMoving: filesList.moving
            z: 2
        }

        ScrollFadeGradient {
            parent: filesList
            flickable: filesList
            atTop: true
        }

        ScrollFadeGradient {
            parent: filesList
            flickable: filesList
        }

        header: root.loading || root.loadFailed || count === 0 ? statusState : null

        Component {
            id: statusState

            ColumnLayout {
                width: filesList.width

                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.loading
                    running: visible
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.loading ? JamiStrings.loadingSharedFiles
                        : root.loadFailed ? JamiStrings.couldNotLoadSharedFiles
                        : root.sharedFiles.length ? JamiStrings.noMatchingSharedFiles : JamiStrings.noSharedFiles
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                }
            }
        }

        delegate: ItemDelegate {
            id: tile

            required property int index
            required property var modelData
            readonly property string conversationTitle: modelData.conversationTitle || modelData.conversationId

            width: Math.max(0, filesList.cellWidth - 8)
            height: Math.max(0, filesList.cellHeight - 8)
            padding: 0
            focusPolicy: Qt.NoFocus
            hoverEnabled: true
            highlighted: GridView.isCurrentItem
            text: modelData.name || JamiStrings.unnamedSharedFile
            Accessible.description: preview.filePath ? conversationTitle
                : conversationTitle + ". " + JamiStrings.sharedFileNotOnThisDevice

            function showUnavailable() {
                ToolTip.show(JamiStrings.sharedFileNotOnThisDevice, 2500);
            }

            function openMenu(x, y) {
                fileMenu.file = modelData;
                const point = mapToItem(filesList, x, y);
                fileMenu.popup(filesList, point.x, point.y);
            }

            onClicked: {
                filesList.currentIndex = index;
                root.openFile(tile);
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: point => tile.openMenu(point.position.x, point.position.y)
            }

            contentItem: Item {
                AttachmentPreview {
                    id: preview

                    anchors.fill: parent
                    radius: JamiTheme.messageBubbleRadius
                    margin: 0
                    videoStills: true
                    thumbnailSize: 320
                    filePath: root.localFilesRevision >= 0
                              ? MessagesAdapter.photoLibraryLocalFile(tile.modelData.conversationId, tile.modelData.fileId) : ""
                }

                Label {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: JamiTheme.iconButtonLarge / 2 + 6
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    visible: !preview.showingPreview
                    text: tile.text
                    textFormat: Text.PlainText
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: JamiTheme.textColor
                }

                JamiChip {
                    id: conversationChip

                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    width: Math.min(implicitWidth, Math.max(0, parent.width - 12))
                    visible: tile.hovered || tile.highlighted
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                    activeFocusOnTab: false
                    variant: JamiChip.Variant.Neutral
                    avatarId: tile.modelData.conversationId
                    text: tile.conversationTitle

                    background: Rectangle {
                        radius: height / 2
                        color: JamiTheme.globalIslandColor
                    }
                }

                JamiChip {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: Math.min(implicitWidth, Math.max(0, parent.width - 12))
                    visible: conversationChip.visible && tile.modelData.size >= 0
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                    activeFocusOnTab: false
                    variant: JamiChip.Variant.Neutral
                    text: visible ? UtilsAdapter.humanFileSize(tile.modelData.size) : ""

                    background: Rectangle {
                        radius: height / 2
                        color: JamiTheme.globalIslandColor
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    visible: tile.highlighted && filesList.activeFocus
                    color: JamiTheme.transparentColor
                    border.color: JamiTheme.textColor
                    border.width: 2
                    radius: preview.radius
                }
            }

            background: null
        }
    }
}
