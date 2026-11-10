import QtQuick
import QtQuick.Controls
import QtTest
import net.jami.Constants 1.1
import "../../../src/app/commoncomponents"

Item {
    id: root
    width: 640
    height: 480

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#f000a0"
        z: -1
    }

    Component {
        id: comboComponent
        ComboBox {
            width: 240
            model: ["Not set", "Allow", "Deny"]
        }
    }

    Component {
        id: legacyComboComponent
        JamiComboBox {
            width: 240
            model: [{label: "Not set"}, {label: "Allow"}, {label: "Deny"}]
            textRole: "label"
            accessibilityName: "Member permission"
            accessibilityDescription: "Permission: %1"
            comboBoxPointSize: JamiTheme.textFontSize
        }
    }

    ListModel {
        id: roleModel
        ListElement { label: "Not set"; code: "unset" }
        ListElement { label: "Allow"; code: "allow" }
        ListElement { label: "Deny"; code: "deny" }
    }

    Component {
        id: spyComponent
        SignalSpy {}
    }

    Component {
        id: dialogComponent
        Dialog {
            parent: Overlay.overlay
            width: 360
            modal: true
            focus: true
            contentItem: ComboBox {
                model: ["Not set", "Allow", "Deny"]
            }
        }
    }

    TestCase {
        name: "ComboBox"
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
                {tag: "standard-light", component: comboComponent, dark: false},
                {tag: "standard-dark", component: comboComponent, dark: true},
                {tag: "legacy-light", component: legacyComboComponent, dark: false},
                {tag: "legacy-dark", component: legacyComboComponent, dark: true}
            ];
        }

        function test_appearance(data) {
            JamiTheme.darkTheme = data.dark;
            const combo = createTemporaryObject(data.component, root);
            verify(combo !== null);
            compare(combo.background.color, JamiTheme.globalBackgroundColor);
            compare(combo.background.border.color, JamiTheme.comboboxBorderColor);
            compare(combo.background.radius, combo.background.height / 2);
            compare(combo.contentItem.color, JamiTheme.comboboxTextColor);
            compare(combo.indicator.color.toString(), JamiTheme.comboboxIconColor.toString());
            compare(combo.currentText, "Not set");
            compare(combo.contentItem.text, combo.displayText);
            verify(combo.implicitWidth > 0);
            verify(combo.implicitHeight > 0);
                compare(combo.popup.background.color, JamiTheme.primaryBackgroundColor);
            compare(combo.popup.background.border.color, JamiTheme.comboboxBorderColorActive);
                compare(combo.popup.background.radius, combo.background.radius);
                compare(combo.popup.padding, 1);
            combo.popup.open();
            tryCompare(combo.popup, "opened", true);
            verify(waitForRendering(combo.popup.contentItem));
            compare(combo.popup.y, combo.height - 1);
                compare(combo.background.border.color, JamiTheme.comboboxBorderColorActive);
            tryVerify(() => combo.popup.contentItem.itemAtIndex(0) !== null);
            const option = combo.popup.contentItem.itemAtIndex(0);
            compare(option.contentItem.text, "Not set");
                compare(option.height, combo.background.height);
                compare(option.background.radius, option.background.height / 2);
                compare(option.background.color, option.hovered || option.highlighted
                    ? JamiTheme.comboboxBackgroundColorHovered : JamiTheme.globalBackgroundColor);
                compare(option.contentItem.color, option.hovered ? JamiTheme.comboboxTextColorHovered : JamiTheme.textColor);
                verify(combo.popup.contentItem.layer.enabled);
                const image = grabImage(combo.popup.contentItem);
                compare(image.pixel(0, 0), backdrop.color);
                verify(image.pixel(Math.floor(image.width / 2), Math.floor(image.height / 2)).toString() !== backdrop.color.toString());
            JamiTheme.darkTheme = !data.dark;
                tryCompare(combo.background, "color", JamiTheme.globalBackgroundColor);
                tryCompare(combo.background.border, "color", JamiTheme.comboboxBorderColorActive);
            tryCompare(combo.contentItem, "color", JamiTheme.comboboxTextColor);
                tryCompare(combo.popup.background, "color", JamiTheme.primaryBackgroundColor);
                tryCompare(option.contentItem, "color", option.hovered ? JamiTheme.comboboxTextColorHovered : JamiTheme.textColor);
            combo.popup.close();
            tryCompare(combo.popup, "opened", false);
        }

        function test_models_data() {
            return [
                {tag: "strings", model: ["Not set", "Allow", "Deny"], textRole: "", valueRole: "", expected: "Allow", value: "Allow"},
                {tag: "objects", model: [{label: "Not set", code: "unset"}, {label: "Allow", code: "allow"}, {label: "Deny", code: "deny"}], textRole: "label", valueRole: "code", expected: "Allow", value: "allow"},
                {tag: "list-model", model: roleModel, textRole: "label", valueRole: "code", expected: "Allow", value: "allow"},
                {tag: "integer", model: 3, textRole: "", valueRole: "", expected: "1", value: 1}
            ];
        }

        function test_models(data) {
            const combo = createTemporaryObject(comboComponent, root,
                                                 {model: data.model, textRole: data.textRole, valueRole: data.valueRole});
            verify(combo !== null);
            compare(combo.count, 3);
            const spy = createTemporaryObject(spyComponent, root, {target: combo, signalName: "activated"});
            verify(spy.valid);
            mouseClick(combo);
            tryCompare(combo.popup, "opened", true);
            verify(waitForRendering(combo.popup.contentItem));
            tryVerify(() => combo.popup.contentItem.itemAtIndex(1) !== null);
            const option = combo.popup.contentItem.itemAtIndex(1);
            compare(option.contentItem.text, data.expected);
            mouseClick(option);
            tryCompare(combo, "currentIndex", 1);
            compare(combo.currentText, data.expected);
            compare(combo.currentValue, data.value);
            tryCompare(combo.popup, "opened", false);
            compare(spy.count, 1);
        }

        function test_keyboard_data() {
            return [
                {tag: "standard", component: comboComponent},
                {tag: "legacy", component: legacyComboComponent}
            ];
        }

        function test_keyboard(data) {
            const combo = createTemporaryObject(data.component, root);
            verify(combo !== null);
            combo.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Space);
            tryCompare(combo.popup, "opened", true);
            keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Return);
            tryCompare(combo, "currentIndex", 1);
            compare(combo.currentText, "Allow");
            tryCompare(combo.popup, "opened", false);
            keyClick(Qt.Key_Space);
            tryCompare(combo.popup, "opened", true);
            keyClick(Qt.Key_Escape);
            tryCompare(combo.popup, "opened", false);
            compare(combo.currentIndex, 1);
        }

        function test_editable() {
            const combo = createTemporaryObject(comboComponent, root, {editable: true, selectTextByMouse: true});
            verify(combo !== null);
            const spy = createTemporaryObject(spyComponent, root, {target: combo, signalName: "accepted"});
            verify(spy.valid);
            combo.editText = "Deny";
            compare(combo.contentItem.text, "Deny");
            verify(combo.contentItem.selectByMouse);
            combo.contentItem.forceActiveFocus();
            keyClick(Qt.Key_Return);
            tryCompare(combo, "currentIndex", 2);
            compare(spy.count, 1);
            combo.selectAll();
            keyClick(Qt.Key_X);
            tryCompare(combo, "editText", "x");
        }

        function test_escapeInsideDialog() {
            const dialog = createTemporaryObject(dialogComponent, root);
            verify(dialog !== null);
            dialog.open();
            tryCompare(dialog, "opened", true);
            const combo = dialog.contentItem;
            combo.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Space);
            tryCompare(combo.popup, "opened", true);
            keyClick(Qt.Key_Escape);
            tryCompare(combo.popup, "opened", false);
            verify(dialog.opened);
            keyClick(Qt.Key_Escape);
            tryCompare(dialog, "opened", false);
        }

        function test_geometryAndFont_data() {
            return [{tag: "ltr", mirrored: false}, {tag: "rtl", mirrored: true}];
        }

        function test_geometryAndFont(data) {
            const options = [];
            for (let index = 0; index < 20; ++index)
                options.push("A long channel name with more text than the field can display " + index);
            const combo = createTemporaryObject(comboComponent, root,
                                                 {model: options, width: 160, "font.pointSize": 18});
            verify(combo !== null);
            combo.LayoutMirroring.enabled = data.mirrored;
            compare(combo.mirrored, data.mirrored);
            compare(combo.contentItem.font.pointSize, 18);
            verify(combo.indicator.x >= 0);
            verify(combo.indicator.x + combo.indicator.width <= combo.width);
            if (data.mirrored)
                verify(combo.contentItem.x >= combo.indicator.x + combo.indicator.width);
            else
                verify(combo.contentItem.x + combo.contentItem.width <= combo.indicator.x);
            combo.popup.open();
            tryCompare(combo.popup, "opened", true);
            compare(combo.popup.width, combo.width);
            verify(combo.popup.height <= 5 * combo.implicitHeight);
            verify(combo.popup.contentItem.contentHeight > combo.popup.height);
            tryVerify(() => combo.popup.contentItem.itemAtIndex(0) !== null);
            compare(combo.popup.contentItem.itemAtIndex(0).contentItem.font.pointSize, 18);
            combo.popup.close();
            tryCompare(combo.popup, "opened", false);
        }

        function test_disabledAndFlat() {
            const combo = createTemporaryObject(comboComponent, root, {enabled: false});
            verify(combo !== null);
            mouseClick(combo);
            verify(!combo.popup.visible);
            compare(combo.indicator.color.toString(), JamiTheme.grey_.toString());
            compare(combo.indicator.opacity, 0.3);
            combo.enabled = true;
            combo.flat = true;
            verify(!combo.background.visible);
            combo.down = true;
            verify(combo.background.visible);
        }

        function test_legacyApi() {
            const combo = createTemporaryObject(legacyComboComponent, root, {comboBoxPointSize: 17});
            verify(combo !== null);
            compare(combo.Accessible.name, "Member permission");
            compare(combo.Accessible.description, "Permission: Not set");
            compare(combo.contentItem.font.pointSize, 17);
            combo.currentIndex = 2;
            compare(combo.Accessible.description, "Permission: Deny");
            combo.popup.open();
            tryCompare(combo.popup, "opened", true);
            tryVerify(() => combo.popup.contentItem.itemAtIndex(2) !== null);
            const option = combo.popup.contentItem.itemAtIndex(2);
            compare(option.contentItem.font.pointSize, 17);
            compare(option.Accessible.name, "Deny");
            compare(option.contentItem.font.weight, Font.DemiBold);
            combo.popup.close();
            tryCompare(combo.popup, "opened", false);
        }
    }
}