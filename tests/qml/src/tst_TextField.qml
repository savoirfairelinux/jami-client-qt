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
        id: fieldComponent
        TextField {
            width: 240
            placeholderText: "Channel name"
        }
    }

    Component {
        id: legacyComponent
        NewMaterialTextField {
            width: 300
            placeholderText: "Channel name"
            leadingIconSource: JamiResources.search_24dp_svg
            trailingIconSource: JamiResources.check_black_24dp_svg
            supportingText: "Channel details"
        }
    }

    Component {
        id: underlineComponent
        MaterialTextField {
            width: 240
            placeholderText: "Username"
        }
    }

    Component {
        id: spyComponent
        SignalSpy {}
    }

    TestCase {
        name: "TextField"
        when: windowShown
        property bool originalDarkTheme

        function initTestCase() {
            originalDarkTheme = JamiTheme.darkTheme;
        }

        function cleanupTestCase() {
            JamiTheme.darkTheme = originalDarkTheme;
        }

        function test_appearance_data() {
            return [{tag: "light", dark: false}, {tag: "dark", dark: true}];
        }

        function test_appearance(data) {
            JamiTheme.darkTheme = data.dark;
            const field = createTemporaryObject(fieldComponent, root);
            verify(field !== null);
            compare(field.color, JamiTheme.textColor);
            compare(field.placeholderTextColor, JamiTheme.textColor);
            compare(field.background.color, JamiTheme.newMaterialTextFieldColor);
            compare(field.background.radius, field.background.height / 2);
            compare(field.height, JamiTheme.newMaterialTextFieldHeight);
            compare(field.leftPadding, JamiTheme.newMaterialTextFieldHorizontalPadding);
            compare(field.rightPadding, JamiTheme.newMaterialTextFieldHorizontalPadding);
            compare(field.background.border.color, JamiTheme.transparentColor);
            verify(waitForRendering(field));
            const image = grabImage(root);
            const scale = image.width / root.width;
            compare(image.pixel(0, 0), backdrop.color);
            compare(image.pixel(Math.floor((field.width - field.rightPadding * 2) * scale),
                Math.floor(field.height / 2 * scale)), JamiTheme.newMaterialTextFieldColor);
            let textPixels = 0;
            for (let pixelY = 0; pixelY < field.height; ++pixelY) {
                for (let pixelX = field.leftPadding; pixelX < field.width / 2; ++pixelX) {
                    if (image.pixel(Math.floor(pixelX * scale), Math.floor(pixelY * scale)).toString() === field.placeholderTextColor.toString())
                        ++textPixels;
                }
            }
            verify(textPixels > 10, "Text field placeholder must remain visible");
            field.forceActiveFocus(Qt.TabFocusReason);
            tryCompare(field.background.border, "color", JamiTheme.tintedBlue);
            JamiTheme.darkTheme = !data.dark;
            tryCompare(field, "color", JamiTheme.textColor);
            tryCompare(field.background, "color", JamiTheme.newMaterialTextFieldColor);
            tryCompare(field, "placeholderTextColor", JamiTheme.textColor);
        }

        function test_editingAndSelection() {
            const field = createTemporaryObject(fieldComponent, root, {text: "Channel"});
            verify(field !== null);
            mouseClick(field);
            verify(field.activeFocus);
            verify(field.selectByMouse);
            field.selectAll();
            compare(field.selectedText, "Channel");
            compare(field.selectionColor, JamiTheme.selectionBlue);
            compare(field.selectedTextColor, JamiTheme.whiteColor);
            keyClick(Qt.Key_A);
            compare(field.text, "a");
            const accepted = createTemporaryObject(spyComponent, root, {target: field, signalName: "accepted"});
            keyClick(Qt.Key_Return);
            compare(accepted.count, 1);
        }

        function test_validationAndReadOnly() {
            const field = createTemporaryObject(fieldComponent, root,
                {maximumLength: 3, validator: Qt.createQmlObject('import QtQuick; IntValidator { bottom: 1; top: 999 }', root)});
            verify(field !== null);
            field.forceActiveFocus();
            keyClick(Qt.Key_1);
            keyClick(Qt.Key_2);
            keyClick(Qt.Key_3);
            keyClick(Qt.Key_4);
            compare(field.text, "123");
            verify(field.acceptableInput);
            field.readOnly = true;
            field.selectAll();
            keyClick(Qt.Key_5);
            compare(field.text, "123");
            tryCompare(field.background.border, "color", JamiTheme.transparentColor);
            field.readOnly = false;
            field.enabled = false;
            keyClick(Qt.Key_6);
            compare(field.text, "123");
        }

        function test_passwordAndFont() {
            const field = createTemporaryObject(fieldComponent, root,
                {text: "secret", echoMode: TextInput.Password, "font.pixelSize": 28});
            verify(field !== null);
            verify(field.displayText !== field.text);
            compare(field.font.pixelSize, 28);
            verify(field.height >= field.contentHeight + field.topPadding + field.bottomPadding);
            field.LayoutMirroring.enabled = true;
            compare(field.leftPadding, field.rightPadding);
        }

        function test_contextMenu() {
            const field = createTemporaryObject(fieldComponent, root);
            verify(field !== null);
            field.forceActiveFocus();
            keyClick(Qt.Key_A);
            keyClick(Qt.Key_B);
            field.selectAll();
            const menu = field.ContextMenu.menu;
            verify(menu !== null);
            compare(menu.count, 9);
            const cut = menu.actionAt(3);
            const copy = menu.actionAt(4);
            const paste = menu.actionAt(5);
            verify(cut.enabled);
            verify(copy.enabled);
            copy.trigger();
            cut.trigger();
            compare(field.text, "");
            verify(menu.actionAt(0).enabled);
            menu.actionAt(0).trigger();
            compare(field.text, "ab");
            menu.actionAt(1).trigger();
            compare(field.text, "");
            verify(paste.enabled);
            paste.trigger();
            compare(field.text, "ab");
            field.selectAll();
            field.readOnly = true;
            tryCompare(cut, "enabled", false);
            tryCompare(paste, "enabled", false);
            mouseClick(field, field.width / 2, field.height / 2, Qt.RightButton);
            tryCompare(menu, "opened", true);
            menu.close();
            tryCompare(menu, "opened", false);
        }

        function test_underlineCompatibility() {
            const field = createTemporaryObject(underlineComponent, root);
            verify(field !== null);
            compare(field.background, null);
            compare(field.leftPadding, 0);
            compare(field.topPadding, 2);
            compare(field.bottomPadding, 7);
            compare(field.ContextMenu.menu, null);
            field.forceActiveFocus();
            keyClick(Qt.Key_A);
            compare(field.text, "a");
        }

        function test_legacyApi() {
            const control = createTemporaryObject(legacyComponent, root, {maxCharacters: 20});
            verify(control !== null);
            const field = findChild(control, "textField");
            verify(field !== null);
            verify(waitForRendering(control));
            verify(field.width > 0);
            compare(field.maximumLength, 20);
            compare(field.background, null);
            control.forceTextFieldActiveFocus();
            verify(field.activeFocus);
            keyClick(Qt.Key_A);
            compare(control.modifiedTextFieldContent, "a");
            compare(control.textFieldContent, "");
            control.modifiedTextFieldContent = "Updated";
            compare(field.text, "Updated");
            control.readOnly = true;
            keyClick(Qt.Key_B);
            compare(field.text, "Updated");
        }
    }
}