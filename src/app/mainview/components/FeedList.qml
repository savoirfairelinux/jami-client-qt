/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root
    objectName: "feedList"
    property var feeds: []
    property string selectedId: ""
    property string sectionTitle: qsTr("Feeds")
    property bool showCreate: true
    property bool showCatalogue: true
    signal openRequested(string id)
    signal createRequested()
    signal catalogueRequested()
    signal manageRequested(string id)

    spacing: 2
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        color: JamiTheme.greyBorderColor
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 12
        Label {
            Layout.fillWidth: true
            text: root.sectionTitle
            font.bold: true
            color: JamiTheme.textColor
        }
        ToolButton {
            objectName: "feedCatalogueButton"
            text: qsTr("Browse")
            Accessible.name: qsTr("Available Feeds")
            onClicked: root.catalogueRequested()
            visible: root.showCatalogue
        }
        NewIconButton {
            objectName: "createFeedButton"
            iconSource: JamiResources.add_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            toolTipText: qsTr("Create a Feed")
            onClicked: root.createRequested()
            visible: root.showCreate
        }
    }
    Button {
        objectName: "firstFeedButton"
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        visible: root.showCreate && root.feeds.length === 0
        text: qsTr("Create my first Feed")
        onClicked: root.createRequested()
    }
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 220)
        clip: true
        model: root.feeds
        ScrollBar.vertical: ScrollBar {}
        delegate: ItemDelegate {
            required property var modelData
            objectName: "feedEntry-" + modelData.id
            width: list.width
            height: JamiTheme.smartListItemHeight
            highlighted: root.selectedId === modelData.id
            Accessible.name: modelData.title
            contentItem: RowLayout {
                spacing: 12
                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 21
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
                        elide: Text.ElideRight
                        color: JamiTheme.textColor
                        font.bold: modelData.unread > 0
                    }
                    Label {
                        Layout.fillWidth: true
                        text: modelData.owned ? qsTr("Your Feed") : (modelData.ownerName || qsTr("Subscribed"))
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: JamiTheme.faddedLastInteractionFontColor
                    }
                }
                Label {
                    text: modelData.unread || ""
                    visible: modelData.unread > 0
                    color: JamiTheme.textColor
                }
                NewIconButton {
                    visible: modelData.owned
                    iconSource: JamiResources.settings_24dp_svg
                    iconSize: JamiTheme.iconButtonMedium
                    toolTipText: qsTr("Manage Feed")
                    onClicked: root.manageRequested(modelData.id)
                }
            }
            onClicked: root.openRequested(modelData.id)
        }
    }
}
