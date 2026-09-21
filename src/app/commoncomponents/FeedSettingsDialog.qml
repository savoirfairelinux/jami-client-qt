/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

BaseModalDialog {
    id: root
    objectName: "feedSettingsDialog"

    property string accountId: ""
    property string feedId: ""
    property string feedName: ""
    property string avatar: ""
    property bool replies: false
    property var authorized: []
    property var contactEntries: []
    property bool initialized: false
    property var service: FeedAdapter

    titleText: feedId === "" ? qsTr("Create a Feed") : qsTr("Manage Feed")
    button1.text: feedId === "" ? qsTr("Create") : qsTr("Save")
    button1.enabled: feedName.trim().length > 0
    button1.onClicked: {
        if (feedId === "") {
            const id = service.createFeed(accountId, feedName, avatar, replies);
            if (id !== "") {
                feedId = id;
                initialized = true;
            }
        } else if (service.update(accountId, feedId, feedName, avatar, replies)) {
            root.close();
        }
    }
    button2.text: qsTr("Close")
    button2.onClicked: root.close()

    function updateDetails() {
        if (feedId === "")
            return;
        const item = service.details(feedId);
        if (!item.id)
            return;
        authorized = item.feedAccess ? item.feedAccess.split(",") : [];
        if (!initialized) {
            feedName = item.title || "";
            avatar = item.avatar || "";
            replies = !!item.feedReplies;
            initialized = true;
        }
        if (item.feedClosed)
            root.close();
    }

    Component.onCompleted: {
        service.clearError();
        contactEntries = service.contacts(accountId);
        updateDetails();
    }

    Connections {
        target: root.service
        function onFeedsChanged() { root.updateDetails(); }
    }
    Connections {
        target: CurrentAccount
        function onIdChanged() {
            if (CurrentAccount.id !== root.accountId)
                root.close();
        }
    }

    FileDialog {
        id: avatarPicker
        title: qsTr("Choose a Feed avatar")
        nameFilters: [qsTr("Images (*.png *.jpg *.jpeg *.webp)")]
        onAccepted: {
            const image = root.service.readAvatar(selectedFile);
            if (image !== "")
                root.avatar = image;
        }
    }

    popupContent: ColumnLayout {
        width: 440
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Rectangle {
                width: 56
                height: 56
                radius: 28
                color: JamiTheme.secondaryBackgroundColor
                Image {
                    anchors.fill: parent
                    sourceSize: Qt.size(128, 128)
                    fillMode: Image.PreserveAspectFit
                    source: root.avatar ? "data:image/png;base64," + root.avatar : ""
                }
                Label {
                    anchors.centerIn: parent
                    text: root.feedName ? root.feedName.charAt(0).toUpperCase() : "F"
                    color: JamiTheme.textColor
                    visible: root.avatar === ""
                }
            }
            Button {
                text: qsTr("Choose avatar")
                onClicked: avatarPicker.open()
            }
            Button {
                text: qsTr("Remove avatar")
                enabled: root.avatar !== ""
                onClicked: root.avatar = ""
            }
        }
        TextField {
            objectName: "feedNameField"
            Layout.fillWidth: true
            placeholderText: qsTr("Feed name")
            maximumLength: 256
            text: root.feedName
            onTextEdited: root.feedName = text
            Accessible.name: qsTr("Feed name")
        }
        CheckBox {
            objectName: "feedRepliesToggle"
            text: qsTr("Allow subscribers to reply")
            checked: root.replies
            onToggled: root.replies = checked
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: JamiTheme.faddedLastInteractionFontColor
            text: qsTr("Only you can create publications. Subscribers may reply to a publication when replies are enabled.")
        }
        Label {
            text: qsTr("Authorized contacts")
            font.bold: true
            color: JamiTheme.textColor
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: JamiTheme.textColor
            visible: root.feedId === ""
            text: qsTr("Create the Feed first, then choose the contacts allowed to subscribe.")
        }
        TextField {
            id: contactSearch
            Layout.fillWidth: true
            placeholderText: qsTr("Find a contact")
            visible: root.feedId !== ""
        }
        ListView {
            id: contactsList
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            clip: true
            visible: root.feedId !== ""
            model: root.contactEntries.filter(item =>
                (item.name + " " + item.uri).toLowerCase().includes(contactSearch.text.toLowerCase()))
            ScrollBar.vertical: ScrollBar {}
            delegate: CheckDelegate {
                required property var modelData
                width: contactsList.width
                text: modelData.name
                checked: root.authorized.indexOf(modelData.uri) >= 0
                onClicked: {
                    root.service.authorize(root.accountId, root.feedId, modelData.uri, checked);
                    checked = Qt.binding(() => root.authorized.indexOf(modelData.uri) >= 0);
                }
            }
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: JamiTheme.textColor
            text: qsTr("Authorization does not subscribe a contact automatically. Access changes are saved immediately.")
            visible: root.feedId !== ""
        }
        Label {
            objectName: "feedSettingsError"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: JamiTheme.textColor
            visible: root.service.error !== ""
            text: root.service.error
        }
        Button {
            text: qsTr("Delete Feed")
            visible: root.feedId !== ""
            onClicked: deletionConfirmation.open()
        }
    }

    Dialog {
        id: deletionConfirmation
        anchors.centerIn: parent
        width: 380
        modal: true
        title: qsTr("Delete this Feed?")
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: Label {
            width: 320
            wrapMode: Text.Wrap
            text: qsTr("This permanently closes the Feed for all subscribers. Copies already received cannot be erased remotely.")
        }
        onAccepted: {
            if (root.service.closeFeed(root.accountId, root.feedId))
                root.close();
        }
    }
}
