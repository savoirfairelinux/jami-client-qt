import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Controls.impl
import QtQuick.Controls.Universal.impl as UniversalImpl
import QtQuick.Templates as T
import net.jami.Constants 1.1

T.TextField {
    id: control

    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
                   || Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    padding: 0
    leftPadding: JamiTheme.newMaterialTextFieldHorizontalPadding
    rightPadding: JamiTheme.newMaterialTextFieldHorizontalPadding
    font.family: JamiTheme.ubuntuFontFamily
    font.pixelSize: JamiTheme.materialLineEditPixelSize
    hoverEnabled: true
    selectByMouse: true
    verticalAlignment: TextInput.AlignVCenter
    color: enabled ? JamiTheme.textColor : JamiTheme.faddedFontColor
    placeholderTextColor: color
    selectionColor: JamiTheme.selectionBlue
    selectedTextColor: JamiTheme.whiteColor

    ContextMenu.menu: Controls.Menu {
        objectName: "textFieldContextMenu"

        UniversalImpl.UndoAction {
            editor: control
        }
        UniversalImpl.RedoAction {
            editor: control
        }
        Controls.MenuSeparator {}
        UniversalImpl.CutAction {
            editor: control
        }
        UniversalImpl.CopyAction {
            editor: control
        }
        UniversalImpl.PasteAction {
            editor: control
        }
        UniversalImpl.DeleteAction {
            editor: control
        }
        Controls.MenuSeparator {}
        UniversalImpl.SelectAllAction {
            editor: control
        }
    }

    PlaceholderText {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - control.leftPadding - control.rightPadding
        height: control.height - control.topPadding - control.bottomPadding
        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        horizontalAlignment: control.effectiveHorizontalAlignment
        verticalAlignment: control.verticalAlignment
        elide: Text.ElideRight
        renderType: control.renderType
    }

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: JamiTheme.newMaterialTextFieldHeight
        radius: height / 2
        color: JamiTheme.newMaterialTextFieldColor
        opacity: control.enabled ? 1 : 0.5
        border.width: 1
        border.color: control.enabled && control.activeFocus && !control.readOnly ? JamiTheme.tintedBlue : JamiTheme.transparentColor

        Behavior on border.color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
}