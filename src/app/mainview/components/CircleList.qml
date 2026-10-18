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
    objectName: "circleList"
    property var circles: []
    property string sectionTitle: qsTr("Circles")
    signal createRequested()
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
        NewIconButton {
            objectName: "createCircleButton"
            iconSource: JamiResources.add_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            toolTipText: qsTr("Create a Circle")
            onClicked: root.createRequested()
        }
    }
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 180)
        clip: true
        model: root.circles
        ScrollBar.vertical: ScrollBar {}
        delegate: ItemDelegate {
            required property var modelData
            objectName: "circleEntry-" + modelData.id
            width: list.width
            height: 46
            Accessible.name: modelData.name
            contentItem: RowLayout {
                spacing: 10
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: "#266366F1"
                    border.width: 1
                    border.color: "#6366F1"
                    Label {
                        anchors.centerIn: parent
                        text: (modelData.name || "C").charAt(0).toUpperCase()
                        color: "#6366F1"
                        font.bold: true
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label {
                        Layout.fillWidth: true
                        text: modelData.name
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: JamiTheme.textColor
                        font.bold: true
                    }
                    Label {
                        Layout.fillWidth: true
                        text: modelData.count > 0
                              ? qsTr("%n member(s)", "", modelData.count)
                              : qsTr("No members")
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: JamiTheme.faddedLastInteractionFontColor
                        font.pointSize: 9
                    }
                }
                NewIconButton {
                    iconSource: JamiResources.settings_24dp_svg
                    iconSize: JamiTheme.iconButtonMedium
                    toolTipText: qsTr("Manage or broadcast to the Circle")
                    onClicked: root.manageRequested(modelData.id)
                }
            }
            onClicked: root.manageRequested(modelData.id)
        }
    }
}
