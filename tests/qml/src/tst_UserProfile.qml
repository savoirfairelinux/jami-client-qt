import QtQuick
import QtTest

import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../../src/app/mainview/components"
import "../../../src/app/settingsview/components"

TestWrapper {
    width: 640
    height: 640

    Component {
        id: userProfile

        UserProfile {
            convId: CurrentConversation.id
            aliasText: "Contact"
            registeredNameText: ""
            idText: ""
        }
    }

    Component {
        id: bannedContact

        ContactItemDelegate {
            width: 600
            contactName: "Banned contact"
            contactID: CurrentAccount.uri
            btnImgSource: JamiStrings.optionUnblock
        }
    }

    TestCase {
        name: "ContactDates"
        when: windowShown

        function test_profileAddedDate_data() {
            return [
                { tag: "active", isContact: true, addedTs: 1700000001, visible: true },
                { tag: "removed", isContact: false, addedTs: 1699999999, visible: false },
                { tag: "missing added date", isContact: true, addedTs: 0, visible: false }
            ];
        }

        function test_profileAddedDate(data) {
            const profile = createTemporaryObject(userProfile, parent, {
                isContact: data.isContact
            });
            verify(profile);

            const dates = findChild(profile.contentItem, "contactDatesControl");
            verify(dates);
            dates.addedTs = data.addedTs;

            profile.open();
            tryCompare(profile, "opened", true);

            const addedRow = dates.contentItem.children[0];
            compare(addedRow.visible, data.visible);
            compare(dates.visible, data.visible);
            for (const child of dates.contentItem.children)
                verify(!child.visible || !child.children.some(label => label.text === JamiStrings.contactRemovedOn));
        }

        function test_profileUsesContactModel() {
            const profile = createTemporaryObject(userProfile, parent, {
                idText: "missing-contact"
            });
            verify(profile);
            compare(profile.isContact, false);

            const dates = findChild(profile.contentItem, "contactDatesControl");
            verify(dates);
            dates.addedTs = 1700000000;
            profile.open();
            tryCompare(profile, "opened", true);
            compare(dates.visible, false);
        }

        function test_bannedContactRemovedDate_data() {
            return [
                { tag: "removed date", removedTs: 1700000000, visible: true },
                { tag: "missing removed date", removedTs: 0, visible: false }
            ];
        }

        function test_bannedContactRemovedDate(data) {
            const delegate = createTemporaryObject(bannedContact, parent, {
                removedTs: data.removedTs
            });
            verify(delegate);
            const label = findChild(delegate, "labelContactRemovedDate");
            verify(label);
            compare(label.visible, data.visible);
            if (data.visible) {
                compare(label.text, JamiStrings.contactRemovedOn + " " + UtilsAdapter.formatTimestamp(data.removedTs));
                waitForRendering(delegate);
                const position = label.mapToItem(delegate, 0, 0);
                verify(position.y >= 0);
                verify(position.y + label.height <= delegate.height);
            }
        }

        function test_contactSpacing_data() {
            return [
                { tag: "without date", removedTs: 0 },
                { tag: "with date", removedTs: 1700000000 },
                { tag: "narrow with date", removedTs: 1700000000, width: 320 }
            ];
        }

        function test_contactIdentifierFont() {
            const delegate = createTemporaryObject(bannedContact, parent);
            verify(delegate);
            const removedDate = findChild(delegate, "labelContactRemovedDate");
            verify(removedDate);
            const identifier = removedDate.parent.children[1];
            compare(identifier.font.family, JamiTheme.ubuntuMonoFontFamily);
        }

        function test_contactSpacing(data) {
            const delegate = createTemporaryObject(bannedContact, parent, {
                removedTs: data.removedTs,
                width: data.width || 600
            });
            verify(delegate);
            waitForRendering(delegate);

            const removedDate = findChild(delegate, "labelContactRemovedDate");
            verify(removedDate);
            const textColumn = removedDate.parent;
            const row = textColumn.parent;
            const avatar = row.children[0];
            const name = textColumn.children[0];
            const identifier = textColumn.children[1];
            const button = row.children[2];
            const background = delegate.background;
            const avatarInset = JamiTheme.itemMarginHorizontal + background.radius - avatar.width / 2;
            const buttonInset = JamiTheme.itemMarginHorizontal + background.radius - button.height / 2;
            const verticalInset = JamiTheme.itemMarginVertical + JamiTheme.itemPadding;

            compare(background.radius, background.height / 2);
            compare(avatar.width, JamiTheme.smartListAvatarSize);
            compare(avatar.height, JamiTheme.smartListAvatarSize);
            compare(avatar.mapToItem(delegate, 0, 0).x, avatarInset);
            compare(avatar.mapToItem(background, 0, avatar.height / 2).y, background.height / 2);
            compare(textColumn.x - avatar.x - avatar.width, 16);
            compare(button.x - textColumn.x - textColumn.width, 16);
            compare(delegate.width - button.mapToItem(delegate, button.width, 0).x, buttonInset);
            compare(button.mapToItem(background, 0, button.height / 2).y, background.height / 2);
            verify(avatarInset >= JamiTheme.itemMarginHorizontal + JamiTheme.itemPadding);
            verify(buttonInset >= JamiTheme.itemMarginHorizontal + JamiTheme.itemPadding);
            compare(identifier.y, name.y + name.height);
            if (data.removedTs > 0)
                compare(removedDate.y, identifier.y + identifier.height);
            verify(textColumn.mapToItem(delegate, 0, 0).y >= verticalInset);
            verify(textColumn.mapToItem(delegate, 0, textColumn.height).y <= delegate.height - verticalInset);
            compare(delegate.height, Math.max(JamiTheme.smartListItemHeight, textColumn.implicitHeight + 2 * verticalInset));
        }
    }
}
