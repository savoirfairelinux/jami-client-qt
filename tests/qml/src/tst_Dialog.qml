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
        id: dialogComponent
        Dialog {
            parent: Overlay.overlay
            width: 360
            title: "Member permissions"
            modal: true
            focus: true
            contentItem: Label {
                objectName: "dialogBody"
                text: "Choose member permissions"
                wrapMode: Text.Wrap
            }
        }
    }

    Component {
        id: legacyDialogComponent
        BaseModalDialog {
            parent: Overlay.overlay
            width: 360
            titleText: "Member permissions"
            button1.text: "Create"
            button2.text: "Cancel"
            popupContent: Label {
                objectName: "dialogBody"
                text: "Choose member permissions"
                color: JamiTheme.textColor
            }
        }
    }

    Component {
        id: spyComponent
        SignalSpy {}
    }

    TestCase {
        name: "Dialog"
        when: windowShown
        property bool originalDarkTheme

        function initTestCase() {
            originalDarkTheme = JamiTheme.darkTheme;
        }

        function cleanupTestCase() {
            JamiTheme.darkTheme = originalDarkTheme;
        }

        function test_theme_data() {
            return [
                {tag: "standard-light", component: dialogComponent, dark: false},
                {tag: "standard-dark", component: dialogComponent, dark: true},
                {tag: "legacy-light", component: legacyDialogComponent, dark: false},
                {tag: "legacy-dark", component: legacyDialogComponent, dark: true}
            ];
        }

        function test_theme(data) {
            JamiTheme.darkTheme = data.dark;
            const dialog = createTemporaryObject(data.component, root);
            verify(dialog !== null);
            dialog.open();
            tryCompare(dialog, "opened", true);
            compare(dialog.background.color, JamiTheme.globalIslandColor);
            compare(dialog.title, "Member permissions");
            const title = findChild(dialog, "dialogTitle");
            verify(title !== null);
            compare(title.text, dialog.title);
            compare(title.color, JamiTheme.textColor);
            const body = findChild(dialog, "dialogBody");
            verify(body !== null);
            compare(body.color, JamiTheme.textColor);
            const closeButton = findChild(dialog, "dialogCloseButton");
            verify(closeButton !== null);
            verify(closeButton.visible);
            compare(closeButton.iconSize, JamiTheme.iconButtonMedium);
            JamiTheme.darkTheme = !data.dark;
            tryCompare(dialog.background, "color", JamiTheme.globalIslandColor);
            tryCompare(title, "color", JamiTheme.textColor);
            tryCompare(body, "color", JamiTheme.textColor);
            mouseClick(closeButton);
            tryCompare(dialog, "opened", false);
        }

        function test_standardButtons_data() {
            return [
                {tag: "accept", button: Dialog.Ok, signalName: "accepted", result: Dialog.Accepted},
                {tag: "reject", button: Dialog.Cancel, signalName: "rejected", result: Dialog.Rejected}
            ];
        }

        function test_standardButtons(data) {
            const dialog = createTemporaryObject(dialogComponent, root,
                                                 {standardButtons: Dialog.Ok | Dialog.Cancel});
            verify(dialog !== null);
            const spy = createTemporaryObject(spyComponent, root,
                                              {target: dialog, signalName: data.signalName});
            verify(spy.valid);
            dialog.open();
            tryCompare(dialog, "opened", true);
            const button = dialog.standardButton(data.button);
            verify(button !== null);
            compare(button.implicitHeight, JamiTheme.newMaterialButtonHeight);
            verify(button.flat);
            mouseClick(button);
            tryCompare(spy, "count", 1);
            tryCompare(dialog, "opened", false);
            compare(dialog.visible, false);
            compare(dialog.result, data.result);
        }

        function test_legacyApi() {
            const dialog = createTemporaryObject(legacyDialogComponent, root, {autoClose: false});
            verify(dialog !== null);
            compare(dialog.title, dialog.titleText);
            compare(dialog.closePolicy, Popup.NoAutoClose);
            dialog.closeButtonVisible = false;
            dialog.button1.toolTipText = "Create a circle";
            dialog.button1.iconSource = JamiResources.add_24dp_svg;
            dialog.button1.color = JamiTheme.redButtonColor;
            dialog.open();
            tryCompare(dialog, "opened", true);
            verify(!findChild(dialog, "dialogCloseButton").visible);
            compare(dialog.button1.toolTipText, "Create a circle");
            compare(dialog.button1.icon.source, JamiResources.add_24dp_svg);
            compare(dialog.button1.palette.button, JamiTheme.redButtonColor);
            dialog.close();
            tryCompare(dialog, "opened", false);
        }

        function test_escapeDismissal_data() {
            return [
                {tag: "standard", component: dialogComponent},
                {tag: "legacy", component: legacyDialogComponent}
            ];
        }

        function test_escapeDismissal(data) {
            const dialog = createTemporaryObject(data.component, root);
            verify(dialog !== null);
            dialog.open();
            tryCompare(dialog, "opened", true);
            keyClick(Qt.Key_Escape);
            tryCompare(dialog, "opened", false);
        }
    }
}