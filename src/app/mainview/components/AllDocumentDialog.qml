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
    implicitWidth: Math.min(400, parent ? Math.max(0, parent.width - 64) : 400)

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
            documentsList.updateRevision++;
        }
    }

    function openDocument(document) {
        close();
        appWindow.openCollabEditor(document.conversationId, document.documentId,
                                   document.name || JamiStrings.untitledDocument,
                                   document.conversationTitle || document.conversationId, document.author);
    }

    function goToConversation(conversationId) {
        close();
        appWindow.viewCoordinator?.dismiss("SettingsView");
        LRCInstance.selectConversation(conversationId, CurrentAccount.id);
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

        ListView {
            id: documentsList
            objectName: "documentsList"

            property int updateRevision: 0

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 360)
            model: {
                const query = searchBar.text.trim().toLocaleLowerCase();
                return query ? root.documents.filter(document =>
                    (document.name || JamiStrings.untitledDocument).toLocaleLowerCase().includes(query)
                    || (document.conversationTitle || document.conversationId).toLocaleLowerCase().includes(query)) : root.documents;
            }
            onModelChanged: currentIndex = -1
            clip: true
            keyNavigationEnabled: true
            activeFocusOnTab: true

            Keys.onReturnPressed: if (currentItem) root.openDocument(model[currentIndex])
            Keys.onEnterPressed: if (currentItem) root.openDocument(model[currentIndex])

            ScrollBar.vertical: ScrollBar {}

            header: root.loading ? loadingState : (count === 0 ? emptyState : null)

            Component {
                id: loadingState

                ColumnLayout {
                    width: ListView.view.width

                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: JamiStrings.loadingDocuments
                        color: JamiTheme.textColor
                    }
                }
            }

            Component {
                id: emptyState

                Label {
                    width: ListView.view.width
                    text: root.documents.length ? JamiStrings.noMatchingDocuments : JamiStrings.noEditableDocuments
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                }
            }

            delegate: ItemDelegate {
                id: documentDelegate

                required property var modelData
                readonly property string conversationTitle: modelData.conversationTitle || modelData.conversationId
                readonly property string authorUri: modelData.author
                readonly property bool isOwnDocument: authorUri === CurrentAccount.uri
                readonly property string authorName: isOwnDocument ? CurrentAccount.bestName
                                                                    : (authorUri ? UtilsAdapter.getBestNameForUri(CurrentAccount.id, authorUri) || authorUri : "")
                readonly property bool hasUpdate: {
                    documentsList.updateRevision;
                    return CollaborativeAdapter.hasUnreadDocumentUpdateForDocument(modelData.conversationId, modelData.documentId);
                }

                width: ListView.view.width
                padding: 4
                rightPadding: Math.max(padding, background.radius - JamiTheme.iconButtonMedium / 2)
                highlighted: ListView.isCurrentItem
                text: modelData.name || JamiStrings.untitledDocument
                Accessible.description: {
                    const details = authorName ? authorName + ", " + conversationTitle : conversationTitle;
                    return hasUpdate ? details + ". " + JamiStrings.unreadDocumentUpdate : details;
                }

                contentItem: RowLayout {
                    spacing: 4

                    IconImage {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 6
                        Layout.topMargin: 6
                        Layout.bottomMargin: 6
                        Layout.preferredWidth: JamiTheme.iconButtonMedium
                        Layout.preferredHeight: JamiTheme.iconButtonMedium

                        source: JamiResources.description_24dp_svg
                        sourceSize.width: JamiTheme.iconButtonMedium
                        sourceSize.height: JamiTheme.iconButtonMedium
                        color: JamiTheme.textColor

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: JamiTheme.redDotIndicatorMargin / 2
                            anchors.rightMargin: JamiTheme.redDotIndicatorMargin / 2

                            width: JamiTheme.redDotIndicatorSize
                            height: width
                            radius: width / 2
                            color: JamiTheme.redDotIndicatorColor
                            visible: documentDelegate.hasUpdate
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            width: parent.width
                            text: documentDelegate.modelData.storedLocally ? documentDelegate.text
                                                                           : JamiStrings.documentNotOnThisDevice.arg(documentDelegate.text)
                            textFormat: Text.PlainText
                            color: JamiTheme.textColor
                            elide: Text.ElideRight
                            font.pixelSize: JamiTheme.sharedServicesDelegateTitlePixelSize
                        }

                        RowLayout {
                            width: parent.width
                            spacing: 4
                            visible: documentDelegate.authorName.length > 0

                            Avatar {
                                Layout.preferredWidth: JamiTheme.iconButtonSmall
                                Layout.preferredHeight: JamiTheme.iconButtonSmall
                                mode: documentDelegate.isOwnDocument ? Avatar.Mode.Account : Avatar.Mode.Contact
                                imageId: documentDelegate.isOwnDocument ? CurrentAccount.id : documentDelegate.authorUri
                                showPresenceIndicator: false
                            }

                            Text {
                                Layout.fillWidth: true
                                text: documentDelegate.authorName
                                textFormat: Text.PlainText
                                color: JamiTheme.textColor
                                elide: Text.ElideRight
                                font.pixelSize: JamiTheme.sharedServicesDelegateDescriptionPixelSize
                                font.italic: true
                            }
                        }
                    }

                    NewIconButton {
                        id: conversationButton
                        objectName: "documentConversationButton"

                        Layout.alignment: Qt.AlignVCenter
                        iconSize: JamiTheme.iconButtonMedium
                        iconSource: JamiResources.chat_24dp_svg
                        toolTipText: JamiStrings.goToConversation

                        background.enabled: false

                        Accessible.description: documentDelegate.conversationTitle

                        Keys.onReturnPressed: conversationButton.clicked()
                        Keys.onEnterPressed: conversationButton.clicked()
                        onClicked: root.goToConversation(documentDelegate.modelData.conversationId)
                    }
                }

                background: Rectangle {
                    radius: height / 2
                    color: documentDelegate.hovered || documentDelegate.activeFocus || documentDelegate.highlighted
                           ? JamiTheme.smartListHoveredColor : JamiTheme.globalIslandColor

                    Behavior on color {
                        ColorAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }

                onClicked: root.openDocument(modelData)
            }
        }
    }
}
