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
    property bool creationFailed: false
    readonly property bool canCreateDocument: CurrentConversation.id === conversationId
                                               && CurrentConversation.canCreateDocument

    function createAndOpen() {
        Qt.inputMethod.commit();
        Qt.inputMethod.reset();
        var name = root.docName.trim();
        if (name.length === 0)
            return;
        if (!root.canCreateDocument) {
            root.creationFailed = true;
            return;
        }
        if (CollaborativeAdapter.createDocument(root.conversationId, name) === "") {
            root.creationFailed = true;
            return;
        }
        root.creationFailed = false;
        close();
    }

    titleText: JamiStrings.newEditableDocument

    button1.text: JamiStrings.optionCreate
    button1Role: DialogButtonBox.AcceptRole
    button1.enabled: root.docName.trim().length > 0 && root.canCreateDocument
    button1.onClicked: createAndOpen()

    button2.text: JamiStrings.optionCancel
    button2Role: DialogButtonBox.RejectRole
    button2.onClicked: close()

    popupContent: ColumnLayout {
        width: JamiTheme.preferredDialogWidth
        spacing: JamiTheme.preferredMarginSize

        Component.onCompleted: nameField.forceTextFieldActiveFocus()

        Connections {
            target: root
            function onOpened() {
                nameField.forceTextFieldActiveFocus();
            }
        }

        NewMaterialTextField {
            id: nameField

            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            leadingIconSource: JamiResources.description_24dp_svg
            textFieldContent: ""
            placeholderText: JamiStrings.untitledDocument
            onModifiedTextFieldContentChanged: {
                root.docName = modifiedTextFieldContent;
                root.creationFailed = false;
            }
            onAccepted: root.createAndOpen()
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            visible: root.creationFailed
            text: qsTr("Could not create the collaborative document.")
            wrapMode: Text.WordWrap
            color: JamiTheme.redColor
            font.pointSize: JamiTheme.settingsFontSize
        }
    }
}
