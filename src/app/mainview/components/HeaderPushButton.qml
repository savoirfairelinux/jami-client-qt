import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

PushButton {
    pressedColor: JamiTheme.pressedButtonColor
    hoveredColor: JamiTheme.hoveredButtonColor
    radius: JamiTheme.chatViewHeaderButtonRectangleRadius

    normalColor: JamiTheme.chatviewBgColor
    imageColor: JamiTheme.chatviewButtonColor
}
