import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T
import net.jami.Constants 1.1

T.Button {
    id: root

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: JamiTheme.newMaterialButtonHeight

    padding: JamiTheme.newMaterialButtonPadding
    horizontalPadding: JamiTheme.newMaterialButtonHorizontalPadding
    spacing: JamiTheme.newMaterialButtonSpacing
    font.pixelSize: JamiTheme.buttontextFontPixelSize

    palette.button: JamiTheme.buttonTintedBlue
    palette.buttonText: flat ? JamiTheme.textColor : JamiTheme.whiteColor
    palette.mid: JamiTheme.transparentColor

    icon.width: JamiTheme.iconButtonMedium
    icon.height: JamiTheme.iconButtonMedium
    icon.color: buttonState.highlighted ? JamiTheme.whiteColor : palette.buttonText

    QtObject {
        id: buttonState
        readonly property bool highlighted: root.enabled && (root.hovered || (root.activeFocus
                                            && (root.focusReason === Qt.TabFocusReason || root.focusReason === Qt.BacktabFocusReason)))
    }

    Behavior on icon.color {
        ColorAnimation {
            duration: JamiTheme.shortFadeDuration
        }
    }

    contentItem: IconLabel {
        spacing: root.spacing
        mirrored: root.mirrored
        display: root.display
        icon: root.icon
        text: root.text
        font: root.font
        color: buttonState.highlighted ? JamiTheme.whiteColor : root.palette.buttonText

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    background: Rectangle {
        radius: height / 2
        color: {
            const fill = root.palette.button;
            if (!root.enabled)
                return Qt.rgba(fill.r, fill.g, fill.b, 0.64);
            if (root.pressed || root.down)
                return Qt.rgba(fill.r, fill.g, fill.b, 0.80);
            if (buttonState.highlighted)
                return Qt.rgba(fill.r, fill.g, fill.b, 0.92);
            return root.flat ? JamiTheme.transparentColor : fill;
        }
        border.width: root.palette.mid.a > 0 ? 1 : 0
        border.color: root.palette.mid

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: root.hovered && root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}