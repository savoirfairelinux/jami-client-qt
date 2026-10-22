/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

// The collaborative documents of every conversation, most recent first. Each
// one tells where it comes from, and opens in the editor.
BaseModalDialog {
    id: root
    objectName: "documentsDialog"

    property var service: CollaborativeAdapter

    signal editRequested(var document)
    signal newDocumentRequested

    titleText: JamiStrings.functionDocuments

    function edit(document) {
        editRequested(document);
        close();
    }

    function provenance(document) {
        const author = document.authorIsSelf ? JamiStrings.documentCreatedByYou
                                             : JamiStrings.documentCreatedBy.arg(document.authorName);
        return author + " · " + MessagesAdapter.getBestFormattedDate(document.timestamp);
    }

    Component.onCompleted: service.refreshAllDocuments()

    Connections {
        target: root.service
        ignoreUnknownSignals: true

        function onDocumentRenamed() {
            root.service.refreshAllDocuments();
        }

        function onDocumentRemoved() {
            root.service.refreshAllDocuments();
        }
    }

    popupContent: ColumnLayout {
        width: 460
        height: 500
        spacing: 10

        NewMaterialButton {
            objectName: "newDocumentButton"

            Layout.alignment: Qt.AlignHCenter
            filledButton: true
            color: "#F59E0B"
            iconSource: JamiResources.add_24dp_svg
            text: JamiStrings.newDocument
            onClicked: {
                root.newDocumentRequested();
                root.close();
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                objectName: "documentList"

                anchors.fill: parent
                clip: true
                spacing: 2
                model: root.service.allDocuments
                ScrollBar.vertical: JamiScrollBar {}

                delegate: ItemDelegate {
                    id: row

                    required property var modelData

                    objectName: "document-" + modelData.documentId
                    width: list.width
                    height: 76
                    Accessible.name: nameText.text + ", " + row.modelData.conversationTitle

                    contentItem: RowLayout {
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 12
                            color: "#26F59E0B"

                            ResponsiveImage {
                                anchors.centerIn: parent
                                containerWidth: 22
                                containerHeight: 22
                                source: JamiResources.article_24dp_svg
                                color: "#F59E0B"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                id: nameText

                                Layout.fillWidth: true
                                text: row.modelData.name !== "" ? row.modelData.name : JamiStrings.untitledDocument
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: JamiTheme.textColor
                                font.bold: true
                                font.pointSize: JamiTheme.textFontSize
                            }

                            // Where the document comes from: the contact or the group it is shared with.
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                ConversationAvatar {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    imageId: row.modelData.convId
                                    showPresenceIndicator: false
                                }

                                ResponsiveImage {
                                    containerWidth: 14
                                    containerHeight: 14
                                    source: row.modelData.isCoreDialog ? JamiResources.person_24dp_svg
                                                                       : JamiResources.group_24dp_svg
                                    color: JamiTheme.faddedLastInteractionFontColor
                                }

                                Text {
                                    objectName: "documentConversation"

                                    Layout.fillWidth: true
                                    text: row.modelData.conversationTitle
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    color: JamiTheme.textColor
                                    font.pointSize: JamiTheme.textFontSize
                                }
                            }

                            Text {
                                objectName: "documentAuthor"

                                Layout.fillWidth: true
                                text: root.provenance(row.modelData)
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: JamiTheme.faddedLastInteractionFontColor
                                font.pointSize: JamiTheme.textFontSize
                            }
                        }

                        NewIconButton {
                            objectName: "editDocument"

                            iconSource: JamiResources.edit_24dp_svg
                            iconSize: JamiTheme.iconButtonMedium
                            toolTipText: JamiStrings.editDocument
                            onClicked: root.edit(row.modelData)
                        }
                    }

                    onClicked: root.edit(modelData)
                }
            }

            BusyIndicator {
                objectName: "documentsLoading"

                anchors.centerIn: parent
                visible: root.service.loadingAllDocuments && list.count === 0
                running: visible
            }

            Text {
                objectName: "noDocuments"

                anchors.centerIn: parent
                width: parent.width
                visible: !root.service.loadingAllDocuments && list.count === 0
                text: JamiStrings.noDocuments
                color: JamiTheme.faddedLastInteractionFontColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }
}
