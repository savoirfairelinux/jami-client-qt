/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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
import QtTest

import net.jami.Adapters 1.1
import net.jami.Models 1.1

import "../../../src/app/mainview/components"

TestWrapper {
    id: root

    width: 600
    height: 640

    Component {
        id: dialogComponent

        CreateConversationDialog {
            viewCoordinator: root.viewCoordinator
        }
    }

    TestCase {
        name: "CreateConversationDialog"
        when: windowShown

        function openDialog(isFeed) {
            const dialog = createTemporaryObject(dialogComponent, root, {isFeed: isFeed});
            verify(dialog);
            dialog.open();
            tryCompare(dialog, "opened", true);
            return dialog;
        }

        function field(dialog, name) {
            const editor = findChild(dialog.contentItem, name);
            verify(editor);
            return editor;
        }

        function test_detailsFocusAndDraft() {
            const dialog = openDialog(false);
            const search = field(dialog, "creationConversationSearch");
            tryCompare(search.textField, "activeFocus", true);

            mouseClick(dialog.button3);
            const title = field(dialog, "titleLineEdit");
            const description = field(dialog, "descriptionLineEdit");
            tryCompare(title, "textFieldActiveFocus", true);
            findChild(title, "textField").text = "Group draft";
            keyClick(Qt.Key_Return);
            tryCompare(description, "textFieldActiveFocus", true);
            findChild(description, "textField").text = "Draft description";

            mouseClick(dialog.button1);
            tryCompare(search.textField, "activeFocus", true);
            mouseClick(dialog.button3);
            compare(title.modifiedTextFieldContent, "Group draft");
            compare(description.modifiedTextFieldContent, "Draft description");

            keyClick(Qt.Key_Escape);
            tryCompare(dialog, "visible", false);

            const freshDialog = openDialog(false);
            mouseClick(freshDialog.button3);
            compare(findChild(field(freshDialog, "titleLineEdit"), "textField").text, "");
            compare(findChild(field(freshDialog, "descriptionLineEdit"), "textField").text, "");
        }

        function test_createsAndSelectsConversation_data() {
            return [
                {tag: "group", isFeed: false, title: "Test group"},
                {tag: "feed", isFeed: true, title: "Announcements"}
            ];
        }

        function test_createsAndSelectsConversation(data) {
            const previousId = LRCInstance.selectedConvUid;
            const dialog = openDialog(data.isFeed);
            const description = "Team updates";

            try {
                mouseClick(dialog.button3);
                findChild(field(dialog, "titleLineEdit"), "textField").text = data.title;
                findChild(field(dialog, "descriptionLineEdit"), "textField").text = description;
                mouseClick(dialog.button3);

                tryVerify(() => !!LRCInstance.selectedConvUid && LRCInstance.selectedConvUid !== previousId);
                tryCompare(dialog, "visible", false);
                tryCompare(CurrentConversation, "title", data.title);
                tryCompare(CurrentConversation, "description", description);
                tryCompare(CurrentConversation, "isFeedMode", data.isFeed);
            } finally {
                const createdId = LRCInstance.selectedConvUid;
                if (dialog.created && createdId && createdId !== previousId) {
                    LRCInstance.selectConversation(previousId);
                    MessagesAdapter.removeConversation(createdId);
                }
            }
        }
    }
}
