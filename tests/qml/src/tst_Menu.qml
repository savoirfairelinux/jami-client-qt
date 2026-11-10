import QtQuick
import QtQuick.Controls
import QtTest
import net.jami.Constants 1.1
import "../../../src/app/commoncomponents/contextmenu"

Item {
    id: root
    width: 640
    height: 480

    Component {
        id: menuComponent
        Menu {
            width: 240
            MenuItem {
                text: "Create"
                icon.source: JamiResources.add_24dp_svg
            }
            MenuSeparator {}
            MenuItem { text: "Archive" }
        }
    }

    Component {
        id: legacyMenuComponent
        BaseContextMenu {
            width: 240
            GeneralMenuItem {
                itemName: "Create"
                iconSource: JamiResources.add_24dp_svg
            }
            GeneralMenuSeparator {}
            GeneralMenuItem { itemName: "Archive" }
        }
    }

    Component {
        id: actionMenuComponent
        Menu {
            width: 260
            Action {
                text: "Create"
                icon.source: JamiResources.add_24dp_svg
            }
            MenuSeparator {}
            Action { text: "Pin"; checkable: true }
            Menu {
                title: "More"
                Action { text: "Nested action" }
            }
            Action { text: "Unavailable"; enabled: false }
        }
    }

    Component {
        id: spyComponent
        SignalSpy {}
    }

    TestCase {
        name: "Menu"
        when: windowShown
        property bool originalDarkTheme

        function initTestCase() {
            originalDarkTheme = JamiTheme.darkTheme;
        }

        function cleanupTestCase() {
            JamiTheme.darkTheme = originalDarkTheme;
        }

        function test_appearance_data() {
            return [
                {tag: "standard-light", component: menuComponent, dark: false},
                {tag: "standard-dark", component: menuComponent, dark: true},
                {tag: "legacy-light", component: legacyMenuComponent, dark: false},
                {tag: "legacy-dark", component: legacyMenuComponent, dark: true}
            ];
        }

        function test_appearance(data) {
            JamiTheme.darkTheme = data.dark;
            const menu = createTemporaryObject(data.component, root);
            verify(menu !== null);
            menu.popup(40, 40);
            tryCompare(menu, "opened", true);
            verify(waitForRendering(menu.contentItem));
            compare(menu.background.color, JamiTheme.globalIslandColor);
            compare(menu.background.radius, JamiTheme.baseContextMenuRadius);
            compare(menu.topPadding, JamiTheme.menuBorderPreferredHeight);
            compare(menu.bottomPadding, JamiTheme.menuBorderPreferredHeight);
            const item = menu.itemAt(0);
            compare(item.height, JamiTheme.generalMenuItemHeight);
            compare(item.contentItem.text, "Create");
            compare(item.contentItem.color, JamiTheme.textColor);
            compare(item.background.radius, JamiTheme.generalMenuItemRadius);
            compare(item.background.x, JamiTheme.generalMenuItemPadding);
            compare(item.background.width, item.width - 2 * JamiTheme.generalMenuItemPadding);
            compare(item.background.color, item.hovered || item.activeFocus || item.highlighted
                    ? JamiTheme.hoveredButtonColor : JamiTheme.globalIslandColor);
            JamiTheme.darkTheme = !data.dark;
            tryCompare(menu.background, "color", JamiTheme.globalIslandColor);
            tryCompare(item.contentItem, "color", JamiTheme.textColor);
            menu.close();
            tryCompare(menu, "opened", false);
        }

        function test_actionActivation() {
            const menu = createTemporaryObject(actionMenuComponent, root);
            verify(menu !== null);
            compare(menu.count, 5);
            const item = menu.itemAt(0);
            compare(item.text, "Create");
            compare(item.icon.source, JamiResources.add_24dp_svg);
            const spy = createTemporaryObject(spyComponent, root, {target: item.action, signalName: "triggered"});
            verify(spy.valid);
            menu.popup(40, 40);
            tryCompare(menu, "opened", true);
            verify(waitForRendering(menu.contentItem));
            mouseClick(item);
            compare(spy.count, 1);
            tryCompare(menu, "opened", false);
        }

        function test_checkedAndDisabledActions() {
            const menu = createTemporaryObject(actionMenuComponent, root);
            verify(menu !== null);
            const disabled = menu.itemAt(4);
            const disabledSpy = createTemporaryObject(spyComponent, root, {target: disabled.action, signalName: "triggered"});
            verify(disabledSpy.valid);
            menu.popup(40, 40);
            tryCompare(menu, "opened", true);
            verify(waitForRendering(menu.contentItem));
            verify(!disabled.enabled);
            compare(disabled.contentItem.color, JamiTheme.faddedFontColor);
            mouseClick(disabled);
            compare(disabledSpy.count, 0);
            verify(menu.opened);
            const checked = menu.itemAt(2);
            verify(checked.checkable);
            verify(!checked.indicator.visible);
            mouseClick(checked);
            verify(checked.checked);
            verify(checked.action.checked);
            tryCompare(menu, "opened", false);
            menu.popup(40, 40);
            tryCompare(menu, "opened", true);
            verify(checked.indicator.visible);
            menu.close();
            tryCompare(menu, "opened", false);
        }

        function test_keyboardNavigation() {
            const menu = createTemporaryObject(actionMenuComponent, root);
            verify(menu !== null);
            menu.popup(40, 40);
            tryCompare(menu, "opened", true);
            menu.currentIndex = 0;
            menu.itemAt(0).forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Down);
            compare(menu.currentIndex, 2);
            const item = menu.itemAt(2);
            const spy = createTemporaryObject(spyComponent, root, {target: item.action, signalName: "triggered"});
            verify(spy.valid);
            keyClick(Qt.Key_Return);
            compare(spy.count, 1);
            verify(item.checked);
            tryCompare(menu, "opened", false);
            menu.popup(40, 40);
            tryCompare(menu, "opened", true);
            keyClick(Qt.Key_Escape);
            tryCompare(menu, "opened", false);
        }

        function test_submenu() {
            const menu = createTemporaryObject(actionMenuComponent, root);
            verify(menu !== null);
            const item = menu.itemAt(3);
            const child = item.subMenu;
            verify(child !== null);
            menu.popup(40, 40);
            tryCompare(menu, "opened", true);
            verify(item.arrow.visible);
            menu.currentIndex = 3;
            item.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Right);
            tryCompare(child, "opened", true);
            compare(child.background.radius, JamiTheme.baseContextMenuRadius);
            keyClick(Qt.Key_Escape);
            tryCompare(child, "opened", false);
            verify(menu.opened);
            item.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Right);
            tryCompare(child, "opened", true);
            child.currentIndex = 0;
            child.itemAt(0).forceActiveFocus(Qt.TabFocusReason);
            const spy = createTemporaryObject(spyComponent, root, {target: child.itemAt(0).action, signalName: "triggered"});
            verify(spy.valid);
            keyClick(Qt.Key_Return);
            compare(spy.count, 1);
            tryCompare(child, "opened", false);
            tryCompare(menu, "opened", false);
        }

        function test_fontAndMirroring_data() {
            return [{tag: "ltr", mirrored: false}, {tag: "rtl", mirrored: true}];
        }

        function test_fontAndMirroring(data) {
            const menu = createTemporaryObject(actionMenuComponent, root, {"font.pointSize": 18});
            verify(menu !== null);
            menu.popup(40, 40);
            tryCompare(menu, "opened", true);
            const item = menu.itemAt(3);
            item.LayoutMirroring.enabled = data.mirrored;
            compare(item.mirrored, data.mirrored);
            compare(item.contentItem.font.pointSize, 18);
            verify(item.contentItem.x >= item.background.x);
            verify(item.contentItem.x + item.contentItem.width <= item.background.x + item.background.width);
            compare(item.arrow.rotation, data.mirrored ? 90 : -90);
            if (data.mirrored)
                verify(item.arrow.x < item.width / 2);
            else
                verify(item.arrow.x > item.width / 2);
            compare(menu.itemAt(1).contentItem.color, JamiTheme.menuSeparatorColor);
            compare(menu.itemAt(1).contentItem.implicitHeight, 1);
            menu.close();
            tryCompare(menu, "opened", false);
        }

        function test_legacyApi() {
            const menu = createTemporaryObject(legacyMenuComponent, root, {menuPreferredWidth: 310});
            verify(menu !== null);
            compare(menu.background.implicitWidth, 310);
            const item = menu.itemAt(0);
            item.bold = true;
            item.dangerous = true;
            item.iconSource = JamiResources.refresh_24dp_svg;
            compare(item.text, item.itemName);
            compare(item.contentItem.color, JamiTheme.redColor);
            verify(item.contentItem.font.bold);
            compare(item.icon.source, JamiResources.refresh_24dp_svg);
            item.isActif = false;
            verify(!item.enabled);
            const separator = menu.itemAt(1);
            separator.separatorPreferredHeight = 3;
            separator.separatorColor = "#127c63";
            compare(separator.contentItem.implicitHeight, 3);
            compare(separator.contentItem.color.toString(), "#127c63");
        }
    }
}