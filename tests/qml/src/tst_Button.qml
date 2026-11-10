import QtQuick
import QtQuick.Controls
import QtTest
import net.jami.Constants 1.1
import "../../../src/app/commoncomponents"

Item {
    id: root
    width: 640
    height: 480

    Component {
        id: buttonComponent
        Button {
            text: "Create"
            icon.source: JamiResources.add_24dp_svg
        }
    }

    Component {
        id: materialButtonComponent
        NewMaterialButton {
            text: "Create"
            iconSource: JamiResources.add_24dp_svg
        }
    }

    Component {
        id: iconButtonComponent
        NewIconButton {
            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.add_24dp_svg
        }
    }

    TestCase {
        name: "Button"
        when: windowShown
        property bool originalDarkTheme
        property real originalBaseZoom

        function initTestCase() {
            originalDarkTheme = JamiTheme.darkTheme;
            originalBaseZoom = JamiTheme.baseZoom;
        }

        function init() {
            mouseMove(root, root.width - 1, root.height - 1);
            root.forceActiveFocus();
        }

        function cleanupTestCase() {
            JamiTheme.darkTheme = originalDarkTheme;
            JamiTheme.baseZoom = originalBaseZoom;
        }

        function test_materialAppearance_data() {
            return [
                {tag: "light-filled", dark: false, flat: false},
                {tag: "dark-filled", dark: true, flat: false},
                {tag: "light-flat", dark: false, flat: true},
                {tag: "dark-flat", dark: true, flat: true}
            ];
        }

        function test_materialAppearance(data) {
            JamiTheme.darkTheme = data.dark;
            const button = createTemporaryObject(buttonComponent, root, {flat: data.flat});
            const reference = createTemporaryObject(materialButtonComponent, root,
                                                    {y: 80, textButton: data.flat});
            verify(button !== null);
            verify(reference !== null);
            compare(button.implicitHeight, JamiTheme.newMaterialButtonHeight);
            compare(button.implicitHeight, reference.implicitHeight);
            compare(button.implicitWidth, reference.implicitWidth);
            compare(button.padding, reference.padding);
            compare(button.horizontalPadding, reference.horizontalPadding);
            compare(button.spacing, reference.spacing);
            compare(button.background.radius, reference.background.radius);
            compare(button.background.color, reference.background.color);
            compare(button.contentItem.color, reference.contentItem.color);
            compare(button.contentItem.font.pixelSize, reference.contentItem.font.pixelSize);
            compare(button.icon.color, reference.icon.color);
            compare(button.icon.width, reference.icon.width);
            compare(button.icon.height, reference.icon.height);
        }

        function test_interactionColors_data() {
            const rows = [];
            for (const dark of [false, true]) {
                for (const flat of [false, true]) {
                    for (const state of ["rest", "hover", "down", "disabled", "focus"]) {
                        rows.push({tag: [dark, flat, state].join("-"), dark, flat, state});
                    }
                }
            }
            return rows;
        }

        function test_interactionColors(data) {
            JamiTheme.darkTheme = data.dark;
            const button = createTemporaryObject(buttonComponent, root,
                                                 {flat: data.flat, hoverEnabled: true});
            verify(button !== null);
            if (data.state === "hover") {
                mouseMove(button);
                tryCompare(button, "hovered", true);
            } else if (data.state === "down") {
                button.down = true;
            } else if (data.state === "disabled") {
                button.enabled = false;
            } else if (data.state === "focus") {
                button.forceActiveFocus(Qt.TabFocusReason);
                verify(button.activeFocus);
            }

            const fill = JamiTheme.buttonTintedBlue;
            const highlighted = data.state === "hover" || data.state === "focus";
            const opacity = data.state === "disabled" ? 0.64 : data.state === "down" ? 0.80 : highlighted ? 0.92 : 1;
            const background = data.flat && data.state === "rest" ? JamiTheme.transparentColor
                             : Qt.rgba(fill.r, fill.g, fill.b, opacity);
            const foreground = highlighted || !data.flat ? JamiTheme.whiteColor : JamiTheme.textColor;
            tryCompare(button.background, "color", background);
            tryCompare(button.contentItem, "color", foreground);
            tryCompare(button.icon, "color", foreground);
        }

        function test_legacyVariants() {
            const button = createTemporaryObject(materialButtonComponent, root,
                                                 {outlinedButton: true, color: "#127c63"});
            verify(button !== null);
            verify(!button.filledButton);
            compare(button.background.color, JamiTheme.transparentColor);
            compare(button.background.border.width, 1);
            compare(button.background.border.color, button.color);
            compare(button.contentItem.color, button.color);
            compare(button.icon.color, button.color);
            button.outlinedButton = false;
            button.textButton = true;
            compare(button.background.border.width, 0);
            tryCompare(button.contentItem, "color", JamiTheme.textColor);
            button.textButton = false;
            verify(button.filledButton);
            tryCompare(button.background, "color", button.color);
            button.iconSource = JamiResources.refresh_24dp_svg;
            compare(button.icon.source, JamiResources.refresh_24dp_svg);
            button.icon.source = JamiResources.add_24dp_svg;
            compare(button.iconSource, JamiResources.add_24dp_svg);
        }

        function test_liveThemeAndZoom() {
            JamiTheme.darkTheme = false;
            JamiTheme.baseZoom = 1;
            const button = createTemporaryObject(buttonComponent, root);
            verify(button !== null);
            compare(button.background.color, JamiTheme.buttonTintedBlue);
            compare(button.contentItem.font.pixelSize, JamiTheme.buttontextFontPixelSize);
            JamiTheme.darkTheme = true;
            tryCompare(button.background, "color", JamiTheme.buttonTintedBlue);
            JamiTheme.baseZoom = 1.2;
            compare(button.contentItem.font.pixelSize, JamiTheme.buttontextFontPixelSize);
            compare(button.contentItem.font.pixelSize, 18);
        }

        function test_standardProperties() {
            const button = createTemporaryObject(buttonComponent, root,
                                                 {"font.pixelSize": 19, checkable: true});
            verify(button !== null);
            compare(button.contentItem.font.pixelSize, 19);
            compare(button.icon.source, JamiResources.add_24dp_svg);
            const clicks = createTemporaryQmlObject('import QtTest; SignalSpy {}', root);
            clicks.target = button;
            clicks.signalName = "clicked";
            verify(clicks.valid);
            mouseClick(button);
            compare(clicks.count, 1);
            verify(button.checked);
            button.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Space);
            compare(clicks.count, 2);
            verify(!button.checked);
            button.enabled = false;
            mouseClick(button);
            compare(clicks.count, 2);
        }

        function test_iconButtonCompatibility() {
            const button = createTemporaryObject(iconButtonComponent, root);
            verify(button !== null);
            compare(button.implicitWidth, JamiTheme.iconButtonMedium * 1.5);
            compare(button.implicitHeight, JamiTheme.iconButtonMedium * 1.5);
            compare(button.contentItem.source, JamiResources.add_24dp_svg);
            compare(button.contentItem.color, JamiTheme.buttonTintedGreyHovered);
            compare(button.background.opacity, 0);
        }
    }
}