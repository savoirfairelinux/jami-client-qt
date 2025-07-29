import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T
import net.jami.Constants 1.1

T.RadioButton {
    id: jamiRadioButton

    property bool showText: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: 6
    spacing: 6

    indicator: Rectangle {
        id: outerCircle

        implicitWidth: 20
        implicitHeight: 20


        x: jamiRadioButton.text ? (jamiRadioButton.mirrored ? jamiRadioButton.width - width - jamiRadioButton.rightPadding : jamiRadioButton.leftPadding) : jamiRadioButton.leftPadding + (jamiRadioButton.availableWidth - width) / 2
        y: jamiRadioButton.topPadding + (jamiRadioButton.availableHeight - height) / 2

        radius: width / 2
        color: enabled ? JamiTheme.transparentColor : JamiTheme.darkGreyColorOpacity
        border.color: enabled ? JamiTheme.radioBorderColor : JamiTheme.darkGreyColorOpacity
        border.width: jamiRadioButton.visualFocus ? 2 : 1

        Rectangle {
            id: innerCircle
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            width: 12
            height: 12
            radius: width / 2
            color: JamiTheme.radioCheckedColor
            visible: jamiRadioButton.checked
        }
    }

    contentItem: CheckLabel {
        leftPadding: jamiRadioButton.indicator && !jamiRadioButton.mirrored ? jamiRadioButton.indicator.width + jamiRadioButton.spacing : 0
        rightPadding: jamiRadioButton.indicator && jamiRadioButton.mirrored ? jamiRadioButton.indicator.width + jamiRadioButton.spacing : 0

        text: jamiRadioButton.text
        font: jamiRadioButton.font
        color: JamiTheme.textColor
        visible: jamiRadioButton.showText
    }
}
