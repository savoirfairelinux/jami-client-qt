import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Jami.Modern 1.0

ApplicationWindow {
    visible: true
    width: 1024
    height: 768
    title: qsTr("Jami Modern Client")

    AccountListModel {
        id: accountModel
    }

    ConversationListModel {
        id: conversationModel
        accountId: accountCombo.currentValue || ""
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Side Panel
        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "#f0f0f0"
            border.color: "#d0d0d0"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: "Account"
                    font.bold: true
                }

                ComboBox {
                    id: accountCombo
                    Layout.fillWidth: true
                    model: accountModel
                    textRole: "alias"
                    valueRole: "accountId"
                }

                Text {
                    text: "Conversations"
                    font.bold: true
                }

                ListView {
                    id: conversationListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: conversationModel
                    spacing: 2

                    delegate: ItemDelegate {
                        width: ListView.view.width
                        height: 60
                        highlighted: ListView.isCurrentItem

                        contentItem: ColumnLayout {
                            spacing: 2
                            Text {
                                text: title
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: description || conversationId
                                font.pixelSize: 12
                                color: "gray"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        onClicked: conversationListView.currentIndex = index
                    }

                    onCountChanged: {
                         console.log("ListView Count: " + count);
                         if (count > 0 && currentIndex === -1) {
                             console.log("Auto-selecting first conversation");
                             currentIndex = 0;
                         }
                    }
                    
                    onCurrentIndexChanged: {
                        console.log("ListView Index Changed: " + currentIndex);
                        contentPanel.updateConversationId();
                    }
                }
            }
        }

        // Content Panel
        Rectangle {
            id: contentPanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"

            property string currentAccountId: accountCombo.currentValue || ""
            property string currentConversationId: ""

            function updateConversationId() {
                if (conversationListView.currentIndex >= 0) {
                     var cid = conversationModel.getConversationId(conversationListView.currentIndex);
                     console.log("Got CID: " + cid);
                     currentConversationId = cid || "";
                } else {
                     currentConversationId = "";
                }
            }

            Connections {
                target: conversationListView
                function onCurrentIndexChanged() { contentPanel.updateConversationId(); }
            }

            MessageListModel {
                id: messageModel
                accountId: contentPanel.currentAccountId
                conversationId: contentPanel.currentConversationId
            }

            ListView {
                id: messageListView
                anchors.fill: parent
                anchors.margins: 10
                model: messageModel
                clip: true
                spacing: 8
                
                // Keep view at bottom for new messages
                onCountChanged: {
                    Qt.callLater(positionViewAtEnd)
                }

                delegate: Rectangle {
                    width: ListView.view.width * 0.8
                    height: msgColumn.implicitHeight + 20
                    color: "#f0f0f0"
                    radius: 8
                    // Align based on sender? We don't have "isMe" yet. Default to left.
                    anchors.left: parent.left
                    
                    ColumnLayout {
                        id: msgColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Text {
                            text: sender
                            font.pixelSize: 10
                            color: "gray"
                            Layout.fillWidth: true
                        }
                        
                        Text {
                            text: body
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        
            Text {
                text: "Select a conversation to view messages"
                anchors.centerIn: parent
                visible: !parent.currentConversationId
                font.pixelSize: 16
                color: "gray"
            }

            Text {
                text: "No messages in this conversation"
                anchors.centerIn: parent
                visible: parent.currentConversationId && messageListView.count === 0
                font.pixelSize: 16
                color: "gray"
            }
        }
    }
}

