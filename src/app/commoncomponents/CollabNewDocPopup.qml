/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

// Prompts for a document name, then creates the editable document interaction. The
// popupContent is loaded in a separate Loader, so the entered name is mirrored to
// root.docName to keep it reachable from the buttons.
BaseModalDialog {
    id: root

    property string conversationId: ""
    property string docName: ""
    property string docKind: "text"

    function createAndOpen() {
        Qt.inputMethod.commit();
        Qt.inputMethod.reset();
        var name = root.docName.trim();
        if (name.length === 0)
            return;
        CollaborativeAdapter.createDocument(root.conversationId, name, root.docKind);
        close();
    }

    titleText: qsTr("New editable document")

    button1.text: qsTr("Create")
    button1Role: DialogButtonBox.AcceptRole
    button1.enabled: root.docName.trim().length > 0
    button1.onClicked: createAndOpen()

    button2.text: qsTr("Cancel")
    button2Role: DialogButtonBox.RejectRole
    button2.onClicked: close()

    popupContent: ColumnLayout {
        width: JamiTheme.preferredDialogWidth
        spacing: JamiTheme.preferredMarginSize

        Component.onCompleted: nameField.forceActiveFocus()

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            text: qsTr("Document name")
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.settingsFontSize
        }

        TextField {
            id: nameField

            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            placeholderText: qsTr("Untitled document")
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.textFontSize
            selectByMouse: true
            background: Rectangle {
                color: JamiTheme.secondaryBackgroundColor
                border.width: 1
                border.color: JamiTheme.tabbarBorderColor
                radius: 8
            }
            onTextChanged: root.docName = text
            onAccepted: root.createAndOpen()
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            text: qsTr("Document type")
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.settingsFontSize
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            spacing: JamiTheme.preferredMarginSize

            RadioButton {
                text: qsTr("Plain text")
                checked: root.docKind === "text"
                onCheckedChanged: if (checked) root.docKind = "text"
                contentItem: Text {
                    text: parent.text
                    leftPadding: parent.indicator.width + 6
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                }
            }
            RadioButton {
                text: qsTr("Rich text (formatting)")
                checked: root.docKind === "rich"
                onCheckedChanged: if (checked) root.docKind = "rich"
                contentItem: Text {
                    text: parent.text
                    leftPadding: parent.indicator.width + 6
                    verticalAlignment: Text.AlignVCenter
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                }
            }
        }
    }
}
