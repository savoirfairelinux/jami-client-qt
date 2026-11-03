import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.impl


import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

ComboBox {
    id: root

    implicitWidth: root.background.implicitWidth
    implicitHeight: root.background.implicitHeight

    padding: 0

    property var convContext: CurrentConversation
    readonly property string conversationId: convContext.id
    property var documentsModel: []
    property bool newDocumentHovered: false
    readonly property bool hasDocumentUpdate: {
        for (var i = 0; i < documentsModel.length; ++i) {
            if (documentsModel[i].hasUpdate === true)
                return true;
        }
        return false;
    }

    model: documentsModel

    function refresh() {
        documentsModel = CollaborativeAdapter.documents(conversationId);
    }

    Component.onCompleted: refresh()
    onConversationIdChanged: refresh()

    Connections {
        target: CurrentAccount
        function onIdChanged() {
            root.refresh();
        }
    }

    Connections {
        target: MessagesAdapter
        enabled: root.convContext === CurrentConversation
        function onNewInteraction(id, interactionType) {
            if (interactionType === Interaction.Type.COLLAB_DOC)
                root.refresh();
        }
    }

    Connections {
        target: root.convContext !== CurrentConversation ? root.convContext : null
        function onNewInteraction(id, interactionType) {
            if (interactionType === Interaction.Type.COLLAB_DOC)
                root.refresh();
        }
    }

    // Keep the snapshot current even while the popup is closed: hasUpdate drives
    // the indicator shown in each document delegate when the popup opens.
    Connections {
        target: CollaborativeAdapter
        function onDocumentRenamed(accId, convId, docId, name) {
            if (accId === CurrentAccount.id && convId === root.conversationId)
                root.refresh();
        }
        function onDocumentUpdateIndicatorChanged(convId) {
            if (convId === root.conversationId)
                root.refresh();
        }
        function onDocumentRemoved(accId, convId, docId, everywhere) {
            if (accId === CurrentAccount.id && convId === root.conversationId)
                root.refresh();
        }
    }

    delegate: ItemDelegate {
        id: documentDelegate

        required property var modelData
        required property int index
        readonly property string documentName: modelData.name || JamiStrings.untitledDocument

        width: ListView.view.width
        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding,
                                 implicitIndicatorHeight + topPadding + bottomPadding)

        padding: 4
        rightPadding: documentDelegate.background.radius - JamiTheme.iconButtonMedium / 2

        highlighted: root.highlightedIndex === index && !(index === 0 && root.newDocumentHovered)

        contentItem: RowLayout {
            spacing: 4

            IconImage {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 6
                Layout.topMargin: 6
                Layout.bottomMargin: 6

                width: JamiTheme.iconButtonMedium
                height: JamiTheme.iconButtonMedium

                source: JamiResources.description_24dp_svg

                sourceSize.width: JamiTheme.iconButtonMedium
                sourceSize.height: JamiTheme.iconButtonMedium

                color: JamiTheme.textColor

                Rectangle {
                    id: redDotIndicator

                    anchors.top: parent.top
                    anchors.topMargin: JamiTheme.redDotIndicatorMargin / 2
                    anchors.right: parent.right
                    anchors.rightMargin: JamiTheme.redDotIndicatorMargin / 2

                    width: JamiTheme.redDotIndicatorSize
                    height: JamiTheme.redDotIndicatorSize
                    radius: height / 2

                    z: parent.z + 2

                    color: JamiTheme.redDotIndicatorColor

                    visible: documentDelegate.modelData.hasUpdate

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: redDotIndicator.visible
                        NumberAnimation {
                            from: 1.0
                            to: 1.2
                            duration: JamiTheme.recordBlinkDuration
                        }
                        NumberAnimation {
                            from: 1.2
                            to: 1.0
                            duration: JamiTheme.recordBlinkDuration
                        }
                    }
                }
            }

            Column {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true


                Text {
                    width: parent.width

                    text: documentDelegate.documentName
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: JamiTheme.textColor

                    font.pixelSize: JamiTheme.sharedServicesDelegateTitlePixelSize
                }

                Row {
                    width: parent.width

                    spacing: 2

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter

                        width: JamiTheme.iconButtonSmall
                        height: JamiTheme.iconButtonSmall

                        source: JamiResources.person_24dp_svg
                        sourceSize.width: JamiTheme.iconButtonSmall
                        sourceSize.height: JamiTheme.iconButtonSmall

                        color: JamiTheme.textColor
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        width: parent.width - JamiTheme.iconButtonSmall

                        text: {
                            const author = UtilsAdapter.getBestNameForUri(CurrentAccount.id, documentDelegate.modelData.author);
                            return documentDelegate.modelData.storedLocally === false
                                    ? JamiStrings.documentNotOnThisDevice.arg(author) : author;
                        }
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: JamiTheme.textColor

                        font.pixelSize: JamiTheme.sharedServicesDelegateDescriptionPixelSize
                        font.italic: true

                        visible: text.length > 0
                    }
                }
            }

            NewIconButton {
                id: removeFromDevice

                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.delete_24dp_svg
                iconColor: removeFromDevice.hovered ? JamiTheme.red_ : JamiTheme.textColor
                toolTipText: JamiStrings.removeDocumentFromDevice

                background: null

                visible: documentDelegate.modelData.storedLocally !== false

                onClicked: {
                    const accountId = CurrentAccount.id;
                    const conversationId = root.conversationId;
                    const documentId = documentDelegate.modelData.documentId;
                    var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                                                                "titleText": JamiStrings.removeDocumentFromDevice,
                                                                "textLabel": JamiStrings.confirmRemoveDocumentFromDevice.arg(documentDelegate.documentName),
                                                                "confirmLabel": JamiStrings.optionRemove,
                                                                "rejectLabel": JamiStrings.optionCancel
                                                            });
                    dlg.accepted.connect(function () {
                        CollaborativeAdapter.removeDocumentLocally(accountId, conversationId, documentId);
                    });}
            }

            NewIconButton {
                id: removeDocument

                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.delete_forever_24dp_svg
                iconColor: removeDocument.hovered ? JamiTheme.red_ : JamiTheme.textColor
                toolTipText: JamiStrings.removeDocument

                background: null

                visible: documentDelegate.modelData.author === CurrentAccount.uri

                onClicked: {
                    const accountId = CurrentAccount.id;
                    const conversationId = root.conversationId;
                    const documentId = documentDelegate.modelData.documentId;
                    var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                                                                "titleText": JamiStrings.removeDocument,
                                                                "textLabel": JamiStrings.confirmRemoveDocument.arg(documentDelegate.documentName),
                                                                "confirmLabel": JamiStrings.optionRemove,
                                                                "rejectLabel": JamiStrings.optionCancel
                                                            });
                    dlg.accepted.connect(function () {
                        CollaborativeAdapter.removeDocument(accountId, conversationId, documentId);
                    });}
            }
        }

        background: Rectangle {
            radius: height / 2

            color: documentDelegate.enabled && (documentDelegate.hovered || documentDelegate.activeFocus || documentDelegate.highlighted)
                   && !(index === 0 && root.newDocumentHovered)
                   ? JamiTheme.smartListHoveredColor
                   : JamiTheme.globalIslandColor

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

        onClicked: appWindow.openCollabEditor(root.conversationId,
                                              documentDelegate.modelData.documentId,
                                              documentDelegate.documentName,
                                              root.convContext.title,
                                              documentDelegate.modelData.author);

        MaterialToolTip {
            parent: parent

            text: JamiStrings.openDocument

            visible: (documentDelegate.hovered || documentDelegate.activeFocus)
                     && !removeFromDevice.hovered && !removeFromDevice.activeFocus
                     && !removeDocument.hovered && !removeDocument.activeFocus
                     && text.length > 0
            delay: Qt.styleHints.mousePressAndHoldInterval
        }
    }

    indicator: null

    Accessible.name: JamiStrings.collaborativeDocuments

    MaterialToolTip {
        parent: root
        text: JamiStrings.collaborativeDocuments
        visible: (root.hovered || root.activeFocus) && !collaborativeDocumentsPopup.visible
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    contentItem: IconImage {
        anchors.centerIn: parent

        width: JamiTheme.iconButtonMedium
        height: JamiTheme.iconButtonMedium

        source: collaborativeDocumentsPopup.opened ? JamiResources.folder_open_24dp_svg : JamiResources.round_folder_24dp_svg
        sourceSize.width: JamiTheme.iconButtonMedium
        sourceSize.height: JamiTheme.iconButtonMedium

        color: root.count > 0
               ? (root.hovered ? Qt.lighter(root.convContext.color, 1.5) : Qt.darker(root.convContext.color, 1.5))
               : (root.enabled && (root.hovered || collaborativeDocumentsPopup.opened)
                  ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered)

        Rectangle {
            id: documentUpdateIndicator

            visible: root.count > 0 && root.hasDocumentUpdate
            anchors.top: parent.top
            anchors.topMargin: 4
            anchors.right: parent.right
            anchors.rightMargin: 4
            width: JamiTheme.redDotIndicatorSize
            height: JamiTheme.redDotIndicatorSize
            radius: height / 2
            color: JamiTheme.redDotIndicatorColor
            z: 2

            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: documentUpdateIndicator.visible
                NumberAnimation {
                    from: 1.0
                    to: 1.2
                    duration: JamiTheme.recordBlinkDuration
                }
                NumberAnimation {
                    from: 1.2
                    to: 1.0
                    duration: JamiTheme.recordBlinkDuration
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    background: Rectangle {
        implicitWidth: JamiTheme.iconButtonMedium * 1.5
        implicitHeight: JamiTheme.iconButtonMedium * 1.5

        radius: height / 2
        color: root.count > 0
               ? (root.hovered ? Qt.darker(root.convContext.color, 1.5) : Qt.lighter(root.convContext.color, 1.5))
               : (root.down ? JamiTheme.pressedButtonColor : JamiTheme.hoveredButtonColor)
        opacity: root.count > 0 || root.hovered || root.down || collaborativeDocumentsPopup.opened ? 1.0 : 0.0

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    popup: Popup {
        id: collaborativeDocumentsPopup

        parent: root
        x: viewCoordinator.isInSinglePaneMode ? root.width - JamiTheme.iconButtonLarge : root.width - width
        y: root.height
        width: 300
        padding: 4

        opacity: opened ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }

        contentItem: ListView {
            id: documentListView

            implicitHeight: Math.min(contentHeight, 320)

            spacing: 8

            clip: true

            header: Item {
                width: documentListView.width
                height: newEditableDocument.height + (root.count > 0 ? documentListView.spacing : 0)

                ItemDelegate {
                    id: newEditableDocument

                    width: parent.width
                    height: implicitHeight
                    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                             implicitContentHeight + topPadding + bottomPadding,
                                             implicitIndicatorHeight + topPadding + bottomPadding)

                    padding: 4
                    rightPadding: newEditableDocument.background.radius - JamiTheme.iconButtonMedium / 2

                    Accessible.name: JamiStrings.newEditableDocument
                    focusPolicy: Qt.StrongFocus
                    Keys.onReturnPressed: clicked()
                    onHoveredChanged: root.newDocumentHovered = hovered

                    contentItem: RowLayout {
                        spacing: 4

                        IconImage {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: 6
                            Layout.topMargin: 6
                            Layout.bottomMargin: 6

                            width: JamiTheme.iconButtonMedium
                            height: JamiTheme.iconButtonMedium

                            source: JamiResources.round_edit_24dp_svg
                            sourceSize.width: JamiTheme.iconButtonMedium
                            sourceSize.height: JamiTheme.iconButtonMedium

                            color: JamiTheme.textColor
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true

                            text: JamiStrings.newEditableDocument
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: JamiTheme.textColor

                            font.pixelSize: JamiTheme.sharedServicesDelegateTitlePixelSize
                        }
                    }

                    background: Rectangle {
                        radius: height / 2

                        color: newEditableDocument.enabled && (newEditableDocument.hovered
                                                               || newEditableDocument.activeFocus
                                                               || newEditableDocument.highlighted)
                               ? JamiTheme.smartListHoveredColor
                               : JamiTheme.globalIslandColor

                        Behavior on color {
                            ColorAnimation {
                                duration: JamiTheme.shortFadeDuration
                            }
                        }
                    }

                    onClicked: {
                        viewCoordinator.presentDialog(appWindow, "commoncomponents/CollabNewDocPopup.qml", {
                                                            "conversationId": root.conversationId
                                                        });
                        collaborativeDocumentsPopup.close();
                    }
                }
            }

            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator {}
        }

        onAboutToShow: {
            root.refresh();
            root.currentIndex = -1;
        }

        onClosed: root.newDocumentHovered = false

        background: Rectangle {
            color: JamiTheme.globalIslandColor
            radius: 22 + collaborativeDocumentsPopup.padding

            layer.enabled: true
            layer.effect: MultiEffect {
                anchors.fill: parent
                shadowEnabled: true
                shadowBlur: JamiTheme.shadowBlur
                shadowColor: JamiTheme.shadowColor
                shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
                shadowVerticalOffset: JamiTheme.shadowVerticalOffset
                shadowOpacity: JamiTheme.shadowOpacity
            }
        }
    }
}