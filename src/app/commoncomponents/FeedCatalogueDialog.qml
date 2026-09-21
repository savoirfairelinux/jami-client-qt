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
    objectName: "feedCatalogueDialog"
    property string accountId: ""
    property var service: FeedAdapter

    titleText: qsTr("Available Feeds")
    button1.text: qsTr("Refresh")
    button1.onClicked: service.refresh()
    button2.text: qsTr("Close")
    button2.onClicked: close()

    Component.onCompleted: service.refresh()
    Connections {
        target: CurrentAccount
        function onIdChanged() {
            if (CurrentAccount.id !== root.accountId)
                root.close();
        }
    }

    popupContent: ColumnLayout {
        width: 460
        spacing: 12
        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: JamiTheme.textColor
            text: qsTr("Feeds your contacts allow you to follow. The list updates when their devices are reachable.")
        }
        ListView {
            id: catalogue
            objectName: "feedCatalogueList"
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            clip: true
            spacing: 6
            model: root.service.feeds.filter(item => !item.owned)
            ScrollBar.vertical: ScrollBar {}
            delegate: ItemDelegate {
                required property var modelData
                width: catalogue.width
                implicitHeight: row.implicitHeight + 20
                contentItem: RowLayout {
                    id: row
                    spacing: 10
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: JamiTheme.secondaryBackgroundColor
                        Image {
                            anchors.fill: parent
                            sourceSize: Qt.size(128, 128)
                            fillMode: Image.PreserveAspectFit
                            source: modelData.avatar ? "data:image/png;base64," + modelData.avatar : ""
                        }
                        Label {
                            anchors.centerIn: parent
                            text: (modelData.title || "F").charAt(0).toUpperCase()
                            color: JamiTheme.textColor
                            visible: !modelData.avatar
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            text: modelData.title
                            textFormat: Text.PlainText
                            color: JamiTheme.textColor
                            elide: Text.ElideRight
                            font.bold: true
                        }
                        Label {
                            Layout.fillWidth: true
                            text: modelData.ownerName || modelData.feedOwner
                            textFormat: Text.PlainText
                            color: JamiTheme.faddedLastInteractionFontColor
                            elide: Text.ElideMiddle
                        }
                        Label {
                            text: modelData.feedClosed ? qsTr("Closed") :
                                  !modelData.available ? qsTr("Access withdrawn") :
                                  modelData.requested ? qsTr("Subscription pending") :
                                  modelData.feedReplies ? qsTr("Replies allowed") : qsTr("Read only")
                            color: JamiTheme.faddedLastInteractionFontColor
                        }
                    }
                    Button {
                        text: modelData.subscribed ? qsTr("Unsubscribe") :
                              modelData.requested ? qsTr("Cancel") : qsTr("Subscribe")
                        enabled: modelData.subscribed || modelData.requested || modelData.available
                        onClicked: root.service.subscribe(root.accountId, modelData.id,
                                                          !modelData.subscribed && !modelData.requested)
                    }
                }
                onClicked: {
                    if (modelData.subscribed && modelData.available) {
                        root.service.open(modelData.id);
                        root.close();
                    }
                }
            }
            Label {
                anchors.centerIn: parent
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: catalogue.count === 0
                color: JamiTheme.textColor
                text: qsTr("No available Feeds yet. A contact must authorize you before you can subscribe.")
            }
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: root.service.error !== ""
            text: root.service.error
            color: JamiTheme.textColor
        }
    }
}
