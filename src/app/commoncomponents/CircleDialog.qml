/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1

BaseModalDialog {
    id: root
    objectName: "circleDialog"

    property string accountId: ""
    property string circleId: ""
    property string circleName: ""
    property var memberUris: []
    property var groupUris: []
    property var contactEntries: []
    property var groupEntries: []
    property string broadcastMessage: ""
    property string statusMessage: ""
    property bool initialized: false
    property var service: CircleAdapter

    titleText: circleId === "" ? qsTr("Create a Circle") : qsTr("Circle: %1").arg(circleName)
    button1.text: circleId === "" ? qsTr("Create") : qsTr("Save name")
    button1.enabled: circleName.trim().length > 0
    button1.onClicked: {
        if (circleId === "") {
            const id = service.createCircle(accountId, circleName);
            if (id !== "") {
                circleId = id;
                initialized = true;
                updateDetails();
            }
        } else if (service.renameCircle(accountId, circleId, circleName)) {
            root.close();
        }
    }
    button2.text: qsTr("Close")
    button2.onClicked: root.close()

    function updateDetails() {
        if (circleId === "")
            return;
        const item = service.details(circleId);
        if (!item.id)
            return;
        memberUris = item.members || [];
        groupUris = item.groups || [];
        if (!initialized) {
            circleName = item.name || "";
            initialized = true;
        }
    }

    Component.onCompleted: {
        service.clearError();
        contactEntries = service.contacts(accountId);
        groupEntries = service.groups(accountId);
        updateDetails();
    }

    Connections {
        target: root.service
        function onCirclesChanged() { root.updateDetails(); }
    }

    popupContent: ColumnLayout {
        width: 460
        spacing: 10

        TextField {
            Layout.fillWidth: true
            placeholderText: qsTr("Circle name (e.g. Friends, Family, Project)")
            maximumLength: 128
            text: root.circleName
            onTextEdited: root.circleName = text
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.circleId !== ""
            spacing: 8

            Label {
                text: qsTr("Broadcast a message to the whole Circle")
                font.bold: true
                color: JamiTheme.textColor
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    id: broadcastField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Your message to the Circle members…")
                    text: root.broadcastMessage
                    onTextEdited: root.broadcastMessage = text
                }
                Button {
                    text: qsTr("Broadcast")
                    enabled: root.broadcastMessage.trim().length > 0
                             && (root.memberUris.length + root.groupUris.length) > 0
                    onClicked: {
                        const n = root.service.broadcastText(root.accountId, root.circleId, root.broadcastMessage);
                        root.broadcastMessage = "";
                        broadcastField.text = "";
                        root.statusMessage = qsTr("Message sent to %n conversation(s).", "", n);
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                visible: root.statusMessage !== ""
                text: root.statusMessage
                color: JamiTheme.textColor
                wrapMode: Text.Wrap
            }

            Label {
                text: qsTr("Circle members (contacts and groups)")
                font.bold: true
                color: JamiTheme.textColor
            }
            ListView {
                id: membersList
                Layout.fillWidth: true
                Layout.preferredHeight: 190
                clip: true
                model: {
                    var combined = [];
                    for (var i = 0; i < root.contactEntries.length; ++i) {
                        var c = root.contactEntries[i];
                        combined.push({"name": c.name, "uri": c.uri, "isGroup": false});
                    }
                    for (var j = 0; j < root.groupEntries.length; ++j) {
                        var g = root.groupEntries[j];
                        combined.push({"name": qsTr("Group • %1").arg(g.name), "uri": g.uri, "isGroup": true});
                    }
                    return combined;
                }
                ScrollBar.vertical: ScrollBar {}
                delegate: CheckDelegate {
                    required property var modelData
                    width: membersList.width
                    text: modelData.name
                    checked: modelData.isGroup
                             ? root.groupUris.indexOf(modelData.uri) >= 0
                             : root.memberUris.indexOf(modelData.uri) >= 0
                    onClicked: {
                        root.service.setMember(root.accountId,
                                               root.circleId,
                                               modelData.uri,
                                               modelData.isGroup,
                                               checked);
                    }
                }
            }

            Button {
                text: qsTr("Delete this Circle")
                onClicked: {
                    if (root.service.deleteCircle(root.accountId, root.circleId))
                        root.close();
                }
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: JamiTheme.textColor
            visible: root.service.error !== ""
            text: root.service.error
        }
    }
}
