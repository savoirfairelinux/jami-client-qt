import QtQuick
import QtQuick.Controls
import QtTest
import net.jami.Constants 1.1

Item {
    id: root
    width: 640
    height: 480

    Component {
        id: checkBoxComponent
        CheckBox {
            text: "Show archived channels"
        }
    }

    Component {
        id: spyComponent
        SignalSpy {}
    }

    TestCase {
        name: "CheckBox"
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
            const control = createTemporaryObject(checkBoxComponent, root);
            verify(control !== null);
            compare(control.contentItem.text, control.text);
            compare(control.contentItem.color, JamiTheme.textColor);
            compare(control.indicator.color.toString(), JamiTheme.tintedBlue.toString());
            compare(control.indicator.source.toString(), JamiResources.check_box_outline_blank_24dp_svg.toString());
            verify(control.implicitWidth > control.indicator.width);
            verify(control.implicitHeight >= control.indicator.height);
            control.checked = true;
            compare(control.indicator.source.toString(), JamiResources.check_box_24dp_svg.toString());
            JamiTheme.darkTheme = !data.dark;
            tryCompare(control.contentItem, "color", JamiTheme.textColor);
            compare(control.indicator.color.toString(), JamiTheme.tintedBlue.toString());
        }

        function test_pointerAndKeyboard() {
            const control = createTemporaryObject(checkBoxComponent, root);
            verify(control !== null);
            const spy = createTemporaryObject(spyComponent, root, {target: control, signalName: "toggled"});
            mouseClick(control.contentItem, control.contentItem.width - 4, control.contentItem.height / 2);
            compare(control.checked, true);
            compare(spy.count, 1);
            control.forceActiveFocus(Qt.TabFocusReason);
            verify(control.visualFocus);
            keyClick(Qt.Key_Space);
            compare(control.checked, false);
            compare(spy.count, 2);
        }

        function test_tristate() {
            const control = createTemporaryObject(checkBoxComponent, root, {tristate: true});
            verify(control !== null);
            mouseClick(control);
            compare(control.checkState, Qt.PartiallyChecked);
            const partialSource = control.indicator.source.toString();
            verify(partialSource !== JamiResources.check_box_outline_blank_24dp_svg.toString());
            verify(partialSource !== JamiResources.check_box_24dp_svg.toString());
            mouseClick(control);
            compare(control.checkState, Qt.Checked);
            mouseClick(control);
            compare(control.checkState, Qt.Unchecked);
        }

        function test_disabled() {
            const control = createTemporaryObject(checkBoxComponent, root, {enabled: false});
            verify(control !== null);
            mouseClick(control);
            verify(!control.checked);
            compare(control.contentItem.color, JamiTheme.faddedFontColor);
            compare(control.indicator.color.toString(), JamiTheme.faddedFontColor.toString());
        }

        function test_rendering_data() {
            return [
                {tag: "light-unchecked", dark: false, state: Qt.Unchecked},
                {tag: "light-checked", dark: false, state: Qt.Checked},
                {tag: "light-partial", dark: false, state: Qt.PartiallyChecked},
                {tag: "dark-unchecked", dark: true, state: Qt.Unchecked},
                {tag: "dark-checked", dark: true, state: Qt.Checked},
                {tag: "dark-partial", dark: true, state: Qt.PartiallyChecked}
            ];
        }

        function test_rendering(data) {
            JamiTheme.darkTheme = data.dark;
            const control = createTemporaryObject(checkBoxComponent, root, {checkState: data.state});
            verify(control !== null);
            tryCompare(control.indicator, "status", Image.Ready);
            verify(waitForRendering(control));
            const image = grabImage(root);
            const position = control.indicator.mapToItem(root, 0, 0);
            const scale = image.width / root.width;
            let coloredPixels = 0;
            for (let pixelY = 0; pixelY < control.indicator.height; ++pixelY) {
                for (let pixelX = 0; pixelX < control.indicator.width; ++pixelX) {
                    if (image.pixel(Math.floor((position.x + pixelX) * scale),
                        Math.floor((position.y + pixelY) * scale)).toString() === JamiTheme.tintedBlue.toString())
                        ++coloredPixels;
                }
            }
            verify(coloredPixels > 10, "Checkbox state indicator must render in the Jami accent color");
        }

        function test_geometry_data() {
            return [{tag: "ltr", mirrored: false}, {tag: "rtl", mirrored: true}];
        }

        function test_geometry(data) {
            const control = createTemporaryObject(checkBoxComponent, root, {"font.pointSize": 24});
            verify(control !== null);
            control.LayoutMirroring.enabled = data.mirrored;
            compare(control.contentItem.font.pointSize, 24);
            if (data.mirrored) {
                verify(control.indicator.x >= control.contentItem.x + control.contentItem.width - control.contentItem.rightPadding);
            } else {
                verify(control.indicator.x + control.indicator.width <= control.contentItem.x + control.contentItem.leftPadding);
            }
            control.text = "";
            compare(control.indicator.x + control.indicator.width / 2, control.width / 2);
        }
    }
}