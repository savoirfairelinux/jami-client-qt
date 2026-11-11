import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T
import net.jami.Constants 1.1

T.CheckBox {
    id: control

    property bool useSystemFocusVisuals: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: 6
    spacing: 8
    hoverEnabled: true
    font.pointSize: JamiTheme.textFontSize

    indicator: IconImage {
        width: JamiTheme.iconButtonMedium
        height: JamiTheme.iconButtonMedium
        sourceSize.width: width
        sourceSize.height: height
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        color: control.enabled ? JamiTheme.tintedBlue : JamiTheme.faddedFontColor
        source: control.checkState === Qt.PartiallyChecked ? JamiResources.remove_24dp_svg
                : control.checked ? JamiResources.check_box_24dp_svg : JamiResources.check_box_outline_blank_24dp_svg

        Rectangle {
            anchors.fill: parent
            anchors.margins: parent.width / 8
            visible: control.checkState === Qt.PartiallyChecked
            color: JamiTheme.transparentColor
            radius: 2
            border.width: 2
            border.color: parent.color
        }
    }

    contentItem: CheckLabel {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
        text: control.text
        font: control.font
        color: control.enabled ? JamiTheme.textColor : JamiTheme.faddedFontColor
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: height / 2
        color: control.enabled && (control.hovered || control.down)
               ? Qt.rgba(JamiTheme.tintedBlue.r, JamiTheme.tintedBlue.g, JamiTheme.tintedBlue.b, control.down ? 0.16 : 0.08)
               : JamiTheme.transparentColor
        border.width: control.visualFocus ? 1 : 0
        border.color: JamiTheme.tintedBlue
    }
}