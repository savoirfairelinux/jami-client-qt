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
import QtQuick.Controls.impl
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    property bool loading: true
    property var documents: []
    property int documentsRequestId: 0

    titleText: JamiStrings.documents
    title: titleText
    implicitWidth: parent ? Math.min(720, Math.max(0, parent.width - 64)) : 720
    height: parent ? Math.min(implicitHeight, parent.height * 0.7, Math.max(0, parent.height - 64))
                   : implicitHeight

    onAboutToShow: {
        loading = true;
        searchBar.text = "";
        documents = [];
    }
    onOpened: documentsRequestId = CollaborativeAdapter.requestAllDocuments()
    onAboutToHide: documentsRequestId = 0

    Connections {
        target: CurrentAccount
        function onIdChanged() {
            root.close();
        }
    }

    Connections {
        target: CollaborativeAdapter
        enabled: root.visible
        function onAllDocumentsLoaded(requestId, documents) {
            if (requestId !== root.documentsRequestId)
                return;
            root.documents = documents;
            root.loading = false;
        }
        function onDocumentUpdateIndicatorChanged() {
            documentsGrid.updateRevision++;
        }
    }

    function openDocument(document) {
        close();
        appWindow.openCollabEditor(document.conversationId, document.documentId,
                                   document.name || JamiStrings.untitledDocument,
                                   document.conversationTitle || document.conversationId, document.author);
    }

    contentItem: ColumnLayout {
        spacing: 8

        Searchbar {
            id: searchBar
            objectName: "documentsSearch"

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.searchBarPreferredHeight
            placeHolderText: JamiStrings.searchDocuments
            textField.Accessible.name: placeHolderText
            textField.Accessible.description: ""
        }

        GridView {
            id: documentsGrid
            objectName: "documentsGrid"

            property int updateRevision: 0
            readonly property int columns: Math.max(1, Math.floor(width / 154))

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: {
                const query = searchBar.text.trim().toLocaleLowerCase();
                return query ? root.documents.filter(document =>
                    (document.name || JamiStrings.untitledDocument).toLocaleLowerCase().includes(query)
                    || (document.conversationTitle || document.conversationId).toLocaleLowerCase().includes(query)) : root.documents;
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
            Accessible.name: JamiStrings.documents

            Keys.onReturnPressed: if (currentItem) root.openDocument(model[currentIndex])
            Keys.onEnterPressed: if (currentItem) root.openDocument(model[currentIndex])
            Keys.onPressed: event => {
                if (currentIndex < 0 && count > 0
                        && [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)) {
                    currentIndex = 0;
                    event.accepted = true;
                }
            }

            ScrollBar.vertical: JamiScrollBar {
                attachedFlickableMoving: documentsGrid.moving
                z: 2
            }

            ScrollFadeGradient {
                parent: documentsGrid
                flickable: documentsGrid
                atTop: true
            }

            ScrollFadeGradient {
                parent: documentsGrid
                flickable: documentsGrid
            }

            header: root.loading || count === 0 ? statusState : null

            Component {
                id: statusState

                ColumnLayout {
                    width: documentsGrid.width

                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.loading
                        running: visible
                    }

                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: root.loading ? JamiStrings.loadingDocuments
                            : root.documents.length ? JamiStrings.noMatchingDocuments : JamiStrings.noEditableDocuments
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
                readonly property string authorUri: modelData.author
                readonly property bool isOwnDocument: authorUri === CurrentAccount.uri
                readonly property string authorName: isOwnDocument ? CurrentAccount.bestName
                                                                    : (authorUri ? UtilsAdapter.getBestNameForUri(CurrentAccount.id, authorUri) || authorUri : "")
                readonly property bool hasUpdate: {
                    documentsGrid.updateRevision;
                    return CollaborativeAdapter.hasUnreadDocumentUpdateForDocument(modelData.conversationId, modelData.documentId);
                }
                readonly property real radius: JamiTheme.messageBubbleRadius
                width: Math.max(0, documentsGrid.cellWidth - 8)
                height: Math.max(0, documentsGrid.cellHeight - 8)
                padding: 0
                focusPolicy: Qt.NoFocus
                hoverEnabled: true
                highlighted: GridView.isCurrentItem
                text: modelData.name || JamiStrings.untitledDocument
                Accessible.description: {
                    const details = authorName ? authorName + ", " + conversationTitle : conversationTitle;
                    return hasUpdate ? details + ". " + JamiStrings.unreadDocumentUpdate : details;
                }

                onClicked: {
                    documentsGrid.currentIndex = index;
                    root.openDocument(modelData);
                }

                contentItem: Item {
                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -banner.height / 2
                        width: JamiTheme.iconButtonLarge
                        height: JamiTheme.iconButtonLarge

                        source: JamiResources.description_24dp_svg
                        sourceSize.width: width
                        sourceSize.height: height
                        color: JamiTheme.textColor
                    }

                    Rectangle {
                        id: banner

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom

                        height: bannerContent.implicitHeight + 16

                        bottomLeftRadius: tile.radius
                        bottomRightRadius: tile.radius

                        color: JamiTheme.transparentColor

                        Column {
                            id: bannerContent

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            spacing: 2

                            RowLayout {
                                width: parent.width

                                spacing: 4

                                IconImage {
                                    Layout.preferredWidth: JamiTheme.iconButtonSmall
                                    Layout.preferredHeight: JamiTheme.iconButtonSmall

                                    source: JamiResources.description_24dp_svg
                                    sourceSize.width: JamiTheme.iconButtonSmall
                                    sourceSize.height: JamiTheme.iconButtonSmall
                                    color: JamiTheme.textColor
                                }

                                Rectangle {
                                    Layout.preferredWidth: JamiTheme.redDotIndicatorSize
                                    Layout.preferredHeight: JamiTheme.redDotIndicatorSize

                                    radius: width / 2
                                    color: JamiTheme.redDotIndicatorColor
                                    visible: tile.hasUpdate
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: tile.modelData.storedLocally ? tile.text
                                                                       : JamiStrings.documentNotOnThisDevice.arg(tile.text)
                                    textFormat: Text.PlainText
                                    color: JamiTheme.textColor
                                    elide: Text.ElideRight

                                    font.pixelSize: JamiTheme.sharedServicesDelegateTitlePixelSize
                                }
                            }

                            RowLayout {
                                width: parent.width

                                spacing: 4

                                visible: tile.authorName.length > 0

                                Avatar {
                                    Layout.preferredWidth: JamiTheme.iconButtonSmall
                                    Layout.preferredHeight: JamiTheme.iconButtonSmall

                                    mode: tile.isOwnDocument ? Avatar.Mode.Account : Avatar.Mode.Contact
                                    imageId: tile.isOwnDocument ? CurrentAccount.id : tile.authorUri
                                    showPresenceIndicator: false
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: tile.authorName
                                    textFormat: Text.PlainText
                                    color: JamiTheme.textColor
                                    elide: Text.ElideRight

                                    font.pixelSize: JamiTheme.sharedServicesDelegateDescriptionPixelSize
                                }
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: JamiTheme.grey_
                        }
                    }
                }

                background: Rectangle {
                    radius: tile.radius
                    color: JamiTheme.globalBackgroundColor

                    border.width: 1
                    border.color: tile.hovered ? JamiTheme.tintedBlue : JamiTheme.grey_

                    Behavior on border.color {
                        ColorAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }
            }
        }
    }
}
