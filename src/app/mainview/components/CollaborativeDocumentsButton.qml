import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.impl


import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ComboBox {
    id: root

    implicitWidth: root.background.implicitWidth
    implicitHeight: root.background.implicitHeight

    padding: 0

    property string conversationId: CurrentConversation.id
    property var documentsModel: []
    readonly property bool hasDocumentUpdate: {
        for (var i = 0; i < documentsModel.length; ++i) {
            if (documentsModel[i].hasUpdate === true)
                return true;
        }
        return false;
    }

    model: documentsModel
    visible: root.count > 0

    function refresh() {
        documentsModel = CollaborativeAdapter.documents(conversationId);
    }

    Component.onCompleted: refresh()
    onConversationIdChanged: refresh()

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

        width: ListView.view.width
        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding,
                                 implicitIndicatorHeight + topPadding + bottomPadding)

        padding: 4
        rightPadding: documentDelegate.background.radius - JamiTheme.iconButtonMedium / 2

        highlighted: root.highlightedIndex === index

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

                    text: documentDelegate.modelData.name
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

                        text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, documentDelegate.modelData.author);
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
                    const conversationId = CurrentConversation.id;
                    const documentId = documentDelegate.modelData.documentId;
                    var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                                                                "titleText": JamiStrings.removeDocumentFromDevice,
                                                                "textLabel": JamiStrings.confirmRemoveDocumentFromDevice.arg(documentDelegate.modelData.name !== "" ? documentDelegate.modelData.name : JamiStrings.untitledDocument),
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
                    const conversationId = CurrentConversation.id;
                    const documentId = documentDelegate.modelData.documentId;
                    var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ConfirmDialog.qml", {
                                                                "titleText": JamiStrings.removeDocument,
                                                                "textLabel": JamiStrings.confirmRemoveDocument.arg(documentDelegate.modelData.name !== "" ? documentDelegate.modelData.name : JamiStrings.untitledDocument),
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
                   ? JamiTheme.smartListHoveredColor
                   : JamiTheme.globalIslandColor

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }
        }

        onClicked: appWindow.openCollabEditor(CurrentConversation.id,
                                              documentDelegate.modelData.documentId,
                                              documentDelegate.modelData.name,
                                              CurrentConversation.title,
                                              documentDelegate.modelData.author);

        MaterialToolTip {
            parent: parent

            text: JamiStrings.openDocument

            visible: (documentDelegate.hovered || documentDelegate.activeFocus) && (text.length > 0)
            delay: Qt.styleHints.mousePressAndHoldInterval
        }
    }

    indicator: null

    contentItem: IconImage {
        anchors.centerIn: parent

        width: JamiTheme.iconButtonMedium
        height: JamiTheme.iconButtonMedium

        source: collaborativeDocumentsPopup.opened ? JamiResources.folder_open_24dp_svg : JamiResources.round_folder_24dp_svg
        sourceSize.width: JamiTheme.iconButtonMedium
        sourceSize.height: JamiTheme.iconButtonMedium

        color: root.hovered ? Qt.lighter(CurrentConversation.color, 1.5) : Qt.darker(CurrentConversation.color, 1.5)

        Rectangle {
            id: documentUpdateIndicator

            visible: root.hasDocumentUpdate
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
        color: root.hovered ? Qt.darker(CurrentConversation.color, 1.5) : Qt.lighter(CurrentConversation.color, 1.5)

        Behavior on color {
            ColorAnimation {
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
            implicitHeight: Math.min(contentHeight, 320)

            spacing: 8

            clip: true

            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator {}
        }

        onAboutToShow: {
            root.refresh();
            root.currentIndex = 0;
        }

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