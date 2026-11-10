import QtQuick
import QtQuick.Templates as T
import net.jami.Constants 1.1

T.MenuSeparator {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)
    padding: JamiTheme.generalMenuItemPadding * 2
    topPadding: 1
    bottomPadding: 1

    contentItem: Rectangle {
        implicitWidth: JamiTheme.menuItemsPreferredWidth - control.leftPadding - control.rightPadding
        implicitHeight: 1
        color: JamiTheme.menuSeparatorColor
        radius: height / 2
    }
}