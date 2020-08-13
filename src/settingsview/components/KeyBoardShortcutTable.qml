import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3

Rectangle {
    id: root

    property int minWidth: 1002
    property int minHeight: 500

    implicitWidth: minWidth
    implicitHeight: minHeight
    color: "white"
    radius: 30

    Rectangle {
        width: 500
        height: t_metrics_title.tightBoundingRect.height + 15
        color: "#e0e0e0"
        radius: 8
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        Text {
            id : titleText
            anchors.centerIn: parent
            anchors.leftMargin: 10
            font.family: "Arial"
            font.pointSize: 12
            font.bold: true
            text: "Shortcuts"
            color: "black"
        }
        TextMetrics {
            id:     t_metrics_title
            font:   titleText.font
            text:   titleText.text
        }
    }

    ListModel {
        id: keyboardGeneralShortcutsModel
        ListElement {
            Shortcut: "Ctrl+J"
            Description: "Open account list"
            KeyLength: 2
        }
        ListElement {
            Shortcut: "Ctrl+L"
            Description: "Focus on the smart list"
            KeyLength: 2
        }
        ListElement {
            Shortcut: "Ctrl+↑"
            Description: "Focus the previous element on smart list"
            KeyLength: 2
        }
        ListElement {
            Shortcut: "Ctrl+↓"
            Description: "Focus the next element on smart list"
            KeyLength: 2
        }
        ListElement {
            Shortcut: "Ctrl+F"
            Description: "Focus on contact search bar"
            KeyLength: 2
        }
        ListElement {
            Shortcut: "F10"
            Description: "Open keyboard shortcuts table"
            KeyLength: 1
        }
        ListElement {
            Shortcut: "F11"
            Description: "Maximize Screen"
            KeyLength: 1
        }
    }
    ListModel {
        id: keyboardConversationShortcutsModel;
        ListElement {
            Shortcut: "Shift+Ctrl+C";
            Description: "Start an audio call";
            KeyLength: 3
        }
        ListElement {
            Shortcut: "Shift+Ctrl+X";
            Description: "Start an video call";
            KeyLength: 3
        }
        ListElement {
            Shortcut: "Shift+Ctrl+L";
            Description: "Clear history";
            KeyLength: 3
        }
        ListElement {
            Shortcut: "Shift+Ctrl+B";
            Description: "Block contact";
            KeyLength: 3
        }
        ListElement {
            Shortcut: "Shift+Ctrl+J";
            Description: "Copy contact name";
            KeyLength: 3
        }
    }
    ListModel {
        id: keyboardSettingsShortcutsModel;
        ListElement {
            Shortcut: "Ctrl+M";
            Description: "Toggle media settings";
            KeyLength: 2
        }
        ListElement {
            Shortcut: "Ctrl+G";
            Description: "Toggle general settings";
            KeyLength: 2
        }
        ListElement {
            Shortcut: "Ctrl+I";
            Description: "Toggle account settings";
            KeyLength: 2
        }
    }
    ListModel {
        id: keyboardCallsShortcutsModel
        ListElement {
            Shortcut: "Ctrl+Y"
            Description: "Answer an incoming call"
            KeyLength: 2
        }
        ListElement {
            Shortcut: "Ctrl+D"
            Description: "Decline the call"
            KeyLength: 2
        }
    }
    Component {
        /*trike: each table should have there own delegate, in order to make sure that
         *       the model parameter is used correctly, but since other three table are
         *       generally the same, so we used the same one
         */

        id: shortcutDelegate

        Rectangle {
            id: cellRect

            implicitWidth: minWidth /2
            implicitHeight: 50
            anchors.left: parent.left
            anchors.leftMargin: 50
            color: "white"
            border.color: "white"
            Rectangle {
                id: containerRect

                implicitWidth: parent.width / 2
                implicitHeight: 50
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                Component.onCompleted: {

                    // Create components at run time using javascript

                    var componentKeyOne = Qt.createComponent("KeyBoardShortcutKey.qml")
                    if (componentKeyOne.status === Component.Ready) {
                        var objectKeyOne = componentKeyOne.createObject(containerRect)
                        objectKeyOne.anchors.verticalCenter = containerRect.verticalCenter
                        objectKeyOne.anchors.left = containerRect.left
                        objectKeyOne.text = Qt.binding(function() { return styleData.value.split("+")[0] })
                    }
                    if (generalTableView.model.get(styleData.row).KeyLength === 2){
                        var componentPlusSign = Qt.createQmlObject('import QtQuick 2.0;' +
                                                                   'Text {anchors.verticalCenter: containerRect.verticalCenter;' +
                                                                   'anchors.verticalCenterOffset: -2;' +
                                                                   'anchors.left: containerRect.left;' +
                                                                   'anchors.leftMargin: 30;' +
                                                                   'color: "#525252";' +
                                                                   'font.bold: true;' +
                                                                   'font.pointSize : 12;' +
                                                                   'text: "+"}',
                                                                   containerRect)

                        var componentKeyTwo = Qt.createComponent("KeyBoardShortcutKey.qml")
                        if (componentKeyTwo.status === Component.Ready) {
                            var objectKeyTwo = componentKeyTwo.createObject(containerRect)
                            objectKeyTwo.anchors.verticalCenter = containerRect.verticalCenter
                            objectKeyTwo.anchors.left = containerRect.left
                            objectKeyTwo.anchors.leftMargin = componentPlusSign.anchors.leftMargin + 40
                            objectKeyTwo.text = Qt.binding(function() { return styleData.value.split("+")[1] })
                        }
                    }
                }
            }
        }
    }
    Component {
        id: shortcutDelegateWithThreeKeys

        Rectangle {
            id: cellRectWithThreeKeys

            implicitWidth: minWidth /2
            implicitHeight: 50
            anchors.left: parent.left
            anchors.leftMargin: 50
            color: "white"
            border.color: "white"
            Rectangle {
                id: containerRectWithThreeKeys

                implicitWidth: parent.width - 10
                implicitHeight: 50
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                Component.onCompleted: {
                    var componentKeyOne = Qt.createComponent("KeyBoardShortcutKey.qml")
                    if (componentKeyOne.status === Component.Ready) {
                        var objectKeyOne = componentKeyOne.createObject(containerRectWithThreeKeys)
                        objectKeyOne.anchors.verticalCenter = containerRectWithThreeKeys.verticalCenter
                        objectKeyOne.anchors.left = containerRectWithThreeKeys.left
                        objectKeyOne.text = Qt.binding(function() { return modelData.Shortcut.split("+")[0] })
                    }
                    var componentPlusSign = Qt.createQmlObject('import QtQuick 2.0;' +
                                                               'Text {anchors.verticalCenter: containerRectWithThreeKeys.verticalCenter;' +
                                                               'anchors.verticalCenterOffset: -2;' +
                                                               'anchors.left: containerRectWithThreeKeys.left;' +
                                                               'anchors.leftMargin: 30;' +
                                                               'color: "#525252";' +
                                                               'font.bold: true;' +
                                                               'font.pointSize : 12;' +
                                                               'text: "+"}',
                                                               containerRectWithThreeKeys)

                    var componentKeyTwo = Qt.createComponent("KeyBoardShortcutKey.qml")
                    if (componentKeyTwo.status === Component.Ready) {
                        var objectKeyTwo = componentKeyTwo.createObject(containerRectWithThreeKeys)
                        objectKeyTwo.anchors.verticalCenter = containerRectWithThreeKeys.verticalCenter
                        objectKeyTwo.anchors.left = containerRectWithThreeKeys.left
                        objectKeyTwo.anchors.leftMargin = componentPlusSign.anchors.leftMargin + 42
                        objectKeyTwo.text = Qt.binding(function() { return modelData.Shortcut.split("+")[1] })
                    }

                    var componentPlusSignTwo = Qt.createQmlObject('import QtQuick 2.0;' +
                                                                   'Text {anchors.verticalCenter: containerRectWithThreeKeys.verticalCenter;' +
                                                                   'anchors.verticalCenterOffset: -2;' +
                                                                   'anchors.left: containerRectWithThreeKeys.left;' +
                                                                   'anchors.leftMargin: 97;' +
                                                                   'color: "#525252";' +
                                                                   'font.bold: true;' +
                                                                   'font.pointSize : 12;' +
                                                                   'text: "+"}',
                                                                   containerRectWithThreeKeys)

                    var componentKeyThree = Qt.createComponent("KeyBoardShortcutKey.qml")
                    if (componentKeyThree.status === Component.Ready) {
                        var objectKeyThree = componentKeyThree.createObject(containerRectWithThreeKeys)
                        objectKeyThree.anchors.verticalCenter = containerRectWithThreeKeys.verticalCenter
                        objectKeyThree.anchors.left = containerRectWithThreeKeys.left
                        objectKeyThree.anchors.leftMargin = componentPlusSignTwo.anchors.leftMargin + 35
                        objectKeyThree.text = Qt.binding(function() { return modelData.Shortcut.split("+")[2] })
                    }
                }
            }
        }
    }
    Component {
        id: descriptionDelegate

        Rectangle {
            implicitWidth: minWidth /2
            implicitHeight: 50

            color: "white"
            border.color: "white"
            Text {
                id : descriptionText
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                font.family: "Arial"
                font.pointSize: 10
                text: styleData.value
            }
        }
    }

    Column {
        spacing: 2
        id: columnAll
        anchors.rightMargin: 20
        anchors.leftMargin: 20
        anchors.bottomMargin: 20
        anchors.topMargin: 50

        width: minWidth
        height: minHeight - 100
        anchors.fill: parent

        StackLayout {
            // pages
            implicitWidth: parent.width
            implicitHeight: parent.height - tabBar.height
            currentIndex: tabBar.currentIndex
            Item {
                id: tabOne
                Rectangle {
                    implicitWidth: parent.width / 2
                    implicitHeight: parent.height
                    anchors.left: parent.left
                    TableView {
                        id: generalTableView
                        anchors.fill: parent
                        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                        TableViewColumn {
                            role: "Description"
                            width: generalTableView.width / 2
                            delegate: descriptionDelegate
                        }
                        TableViewColumn {
                            role: "Shortcut"
                            width: generalTableView.width / 2
                            delegate: shortcutDelegate
                        }
                        model: keyboardGeneralShortcutsModel
                        rowDelegate: Rectangle {
                            height: 50
                            color: "white"
                         }
                        style: TableViewStyle {
                            alternateBackgroundColor: "white"
                            frame: Rectangle {
                                border{
                                    color: "transparent" // color of the border
                                }
                            }
                            headerDelegate: Rectangle {
                                // Only first column's header is shown
                                height: [t_metrics_general.tightBoundingRect.height + 10, 0][styleData.column % 2]
                                width: [parent.width, 0][styleData.column % 2]
                                color: "white"
                                radius: 10
                                anchors.top: parent.top
                                anchors.topMargin: 5
                                Text {
                                    id : generalShortcutText
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    font.family: "Arial"
                                    font.pointSize: 12
                                    text: styleData.column % 2 ? "" : "General"
                                    color: "black"
                                }
                                TextMetrics {
                                    id:     t_metrics_general
                                    font:   generalShortcutText.font
                                    text:   generalShortcutText.text
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    implicitWidth: parent.width / 2
                    implicitHeight: parent.height
                    anchors.right: parent.right

                    TableView {
                        id: conversationsTableView
                        anchors.fill: parent
                        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                        TableViewColumn {
                            role: "Description"
                            width: conversationsTableView.width / 2
                            delegate: descriptionDelegate
                        }
                        TableViewColumn {
                            role: "Shortcut"
                            width: conversationsTableView.width / 2
                            delegate: Component{
                                Loader {
                                    property variant modelData: model
                                    sourceComponent: shortcutDelegateWithThreeKeys
                                }
                            }
                        }
                        model: keyboardConversationShortcutsModel
                        rowDelegate: Rectangle {
                            height: 50
                            color: "white"
                         }
                        style: TableViewStyle {
                            alternateBackgroundColor: "white"
                            frame: Rectangle {
                                border{
                                    color: "transparent" // color of the border
                                }
                            }
                            headerDelegate: Rectangle {
                                // Only first column's header is shown
                                height: [t_metrics_conversations.tightBoundingRect.height + 10, 0][styleData.column % 2]
                                width: [parent.width, 0][styleData.column % 2]
                                color: "white"
                                radius: 10
                                anchors.top: parent.top
                                anchors.topMargin: 5
                                Text {
                                    id : conversationsShortcutText
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    font.family: "Arial"
                                    font.pointSize: 12
                                    text: styleData.column % 2 ? "" : "Conversations"
                                    color: "black"
                                }
                                TextMetrics {
                                    id:     t_metrics_conversations
                                    font:   conversationsShortcutText.font
                                    text:   conversationsShortcutText.text
                                }
                            }
                        }
                    }
                }
            }
            Item {
                id: tabTwo
                Rectangle {
                    implicitWidth: parent.width / 2
                    implicitHeight: parent.height
                    anchors.left: parent.left
                    TableView {
                        id: callsTableView
                        anchors.fill: parent
                        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                        TableViewColumn {
                            role: "Description"
                            width: callsTableView.width / 2
                            delegate: descriptionDelegate
                        }
                        TableViewColumn {
                            role: "Shortcut"
                            width: callsTableView.width / 2
                            delegate: shortcutDelegate
                        }
                        model: keyboardCallsShortcutsModel
                        rowDelegate: Rectangle {
                            height: 50
                            color: "white"
                         }
                        style: TableViewStyle {
                            alternateBackgroundColor: "white"
                            frame: Rectangle {
                                border{
                                    color: "transparent" // color of the border
                                }
                            }
                            headerDelegate: Rectangle {
                                // Only first column's header is shown
                                height: [t_metrics_calls.tightBoundingRect.height + 10, 0][styleData.column % 2]
                                width: [parent.width, 0][styleData.column % 2]
                                color: "white"
                                radius: 10
                                anchors.top: parent.top
                                anchors.topMargin: 5
                                Text {
                                    id : callsShortcutText
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    font.family: "Arial"
                                    font.pointSize: 12
                                    text: styleData.column % 2 ? "" : "Calls"
                                    color: "black"
                                }
                                // make sure that calls and settings header are parallel
                                TextMetrics {
                                    id:     t_metrics_calls
                                    font:   callsShortcutText.font
                                    text:   "Settings"
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    implicitWidth: parent.width / 2
                    implicitHeight: parent.height
                    anchors.right: parent.right
                    TableView {
                        id: settingsTableView
                        anchors.fill: parent
                        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                        TableViewColumn {
                            role: "Description"
                            width: settingsTableView.width / 2
                            delegate: descriptionDelegate
                        }
                        TableViewColumn {
                            role: "Shortcut"
                            width: settingsTableView.width / 2
                            delegate: shortcutDelegate
                        }
                        model: keyboardSettingsShortcutsModel
                        rowDelegate: Rectangle {
                            height: 50
                            color: "white"
                         }
                        style: TableViewStyle {
                            alternateBackgroundColor: "white"
                            frame: Rectangle {
                                border{
                                    color: "transparent" // color of the border
                                }
                            }
                            headerDelegate: Rectangle {
                                // Only first column's header is shown
                                height: [t_metrics_settings.tightBoundingRect.height + 10, 0][styleData.column % 2]
                                width: [parent.width, 0][styleData.column % 2]
                                color: "white"
                                radius: 10
                                anchors.top: parent.top
                                anchors.topMargin: 5
                                Text {
                                    id : settingsShortcutText
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    font.family: "Arial"
                                    font.pointSize: 12
                                    text: styleData.column % 2 ? "" : "Settings"
                                    color: "black"
                                }
                                TextMetrics {
                                    id:     t_metrics_settings
                                    font:   settingsShortcutText.font
                                    text:   settingsShortcutText.text
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    TabBar {
        id: tabBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 15
        width: 240
        currentIndex: 0
        TabButton {
            id: pageOne
            width: tabBar.width / 2
            text: qsTr("1")
            down: true
            // customize tab button
            contentItem: Text {
                text: pageOne.text
                font: pageOne.font
                opacity: enabled ? 1.0 : 0.3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            // customize tab button
            background: Rectangle {
                id: buttonRectOne
                implicitWidth: tabBar.width / 2
                implicitHeight: tabBar.height
                radius: 10
                color: pageOne.down ? "#e0e0e0" :"#fdfdfd"
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: { buttonRectOne.color = "#c0c0c0"; tabBar.currentIndex = 0; pageOne.down = true; pageTwo.down = false;}
                    onReleased: { buttonRectOne.color = "#e0e0e0"; }
                    onEntered: { buttonRectOne.color = "#c7c7c7"; }
                    onExited: { buttonRectOne.color = Qt.binding(function() { return pageOne.down ? "#e0e0e0" :"#fdfdfd" }); }
                }
            }
        }
        TabButton {
            id: pageTwo
            text: qsTr("2")
            width: tabBar.width / 2
            contentItem: Text {
                text: pageTwo.text
                font: pageTwo.font
                opacity: enabled ? 1.0 : 0.3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                id: buttonRectTwo
                implicitWidth: tabBar.width / 2
                implicitHeight: tabBar.height
                radius: 10
                color: pageTwo.down ? "#e0e0e0" :"#fdfdfd"
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: { buttonRectTwo.color = "#c0c0c0"; tabBar.currentIndex = 1; pageTwo.down = true; pageOne.down = false;}
                    onReleased: { buttonRectTwo.color = "#e0e0e0"; }
                    onEntered: { buttonRectTwo.color = "#c7c7c7"; }
                    onExited: { buttonRectTwo.color = Qt.binding(function() { return pageTwo.down ? "#e0e0e0" :"#fdfdfd" }); }
                }
            }
        }
    }
}
