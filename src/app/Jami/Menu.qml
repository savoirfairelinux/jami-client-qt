import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Controls.Universal as UniversalStyle
import QtQuick.Templates as T
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1

T.Menu {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)
    topPadding: JamiTheme.menuBorderPreferredHeight
    bottomPadding: JamiTheme.menuBorderPreferredHeight
    margins: 0
    overlap: 1
    popupType: T.Popup.Item
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside | T.Popup.CloseOnPressOutsideParent
    font.pointSize: JamiTheme.textFontSize
    UniversalStyle.Universal.theme: JamiTheme.darkTheme ? UniversalStyle.Universal.Dark : UniversalStyle.Universal.Light

    delegate: Controls.MenuItem {}

    contentItem: ListView {
        implicitHeight: contentHeight
        model: control.contentModel
        currentIndex: control.currentIndex
        interactive: contentHeight > height
        clip: true
        Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
    }

    background: Rectangle {
        implicitWidth: JamiTheme.menuItemsPreferredWidth
        color: JamiTheme.globalIslandColor
        radius: JamiTheme.baseContextMenuRadius
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 3
            radius: 6
            color: "#29000000"
            transparentBorder: true
            samples: radius + 1
        }
    }
}