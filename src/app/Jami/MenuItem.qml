import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T
import net.jami.Constants 1.1

T.MenuItem {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: JamiTheme.generalMenuItemHeight
    padding: JamiTheme.generalMenuItemPadding * 2
    spacing: JamiTheme.generalMenuItemPadding
    hoverEnabled: true
    palette.text: JamiTheme.textColor
    icon.width: JamiTheme.iconButtonMedium
    icon.height: JamiTheme.iconButtonMedium
    icon.color: enabled ? palette.text : JamiTheme.faddedFontColor

    contentItem: MenuItemIconLabel {
        readonly property real checkPadding: control.checkable ? control.indicator.width + control.spacing : 0
        readonly property real arrowPadding: control.subMenu ? control.arrow.width + control.spacing : 0
        leftPadding: control.mirrored ? arrowPadding : checkPadding
        rightPadding: control.mirrored ? checkPadding : arrowPadding
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display
        alignment: Qt.AlignLeft
        icon: control.icon
        defaultIconColor: control.icon.color
        text: control.text
        font: control.font
        color: control.enabled ? control.palette.text : JamiTheme.faddedFontColor
        menuItem: control
    }

    indicator: IconImage {
        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: (control.height - height) / 2
        width: JamiTheme.iconButtonSmall
        height: JamiTheme.iconButtonSmall
        source: JamiResources.check_black_24dp_svg
        color: control.icon.color
        visible: control.checkable && control.checked
    }

    arrow: IconImage {
        x: control.mirrored ? control.leftPadding : control.width - width - control.rightPadding
        y: (control.height - height) / 2
        width: JamiTheme.iconButtonSmall
        height: JamiTheme.iconButtonSmall
        source: JamiResources.expand_more_24dp_svg
        rotation: control.mirrored ? 90 : -90
        color: control.icon.color
        visible: control.subMenu !== null
    }

    background: Rectangle {
        x: JamiTheme.generalMenuItemPadding
        width: control.width - 2 * JamiTheme.generalMenuItemPadding
        implicitWidth: JamiTheme.menuItemsPreferredWidth
        radius: JamiTheme.generalMenuItemRadius
        color: control.enabled && (control.hovered || control.activeFocus || control.highlighted)
               ? JamiTheme.hoveredButtonColor : JamiTheme.globalIslandColor

        Behavior on color {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
}