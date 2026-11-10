pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Templates as T
import net.jami.Constants 1.1
import "../commoncomponents" as Common

T.ComboBox {
    id: control

    hoverEnabled: true
    font.pointSize: JamiTheme.textFontSize

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)
    leftPadding: padding + (!mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)

    delegate: Controls.ItemDelegate {
        id: option
        required property int index

        width: ListView.view.width
        height: control.background.height
        topPadding: 0
        bottomPadding: 0
        leftPadding: control.padding + 12 - control.popup.leftPadding
        rightPadding: control.padding + 12 - control.popup.rightPadding
        text: control.textAt(index)
        font.weight: control.currentIndex === index ? Font.DemiBold : control.font.weight
        highlighted: control.highlightedIndex === index
        hoverEnabled: control.hoverEnabled

        Accessible.role: Accessible.ListItem
        Accessible.name: text
        Accessible.description: control.currentIndex === index
                                ? JamiStrings.selectedDescription.arg(control.Accessible.name || control.displayText)
                                : JamiStrings.availableOptionDescription.arg(control.Accessible.name || control.displayText)
        Accessible.focused: control.highlightedIndex === index

        contentItem: Text {
            text: option.text
            color: option.hovered ? JamiTheme.comboboxTextColorHovered : JamiTheme.textColor
            font: option.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            clip: true
        }

        background: Rectangle {
            color: option.hovered || option.highlighted ? JamiTheme.comboboxBackgroundColorHovered : JamiTheme.globalBackgroundColor
            radius: height / 2
        }
    }

    indicator: Common.ResponsiveImage {
        x: control.mirrored ? control.padding : control.width - width - control.padding
        y: control.topPadding + (control.availableHeight - height) / 2
        color: control.enabled ? JamiTheme.comboboxIconColor : JamiTheme.grey_
        source: control.popup.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg
        opacity: control.enabled ? 1 : 0.3
    }

    contentItem: T.TextField {
        implicitHeight: contentHeight + topPadding + bottomPadding
        leftPadding: control.mirrored ? 1 : 12
        rightPadding: control.mirrored ? 12 : 1
        text: control.editable ? control.editText : control.displayText
        font: control.font
        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: control.selectTextByMouse
        color: JamiTheme.comboboxTextColor
        selectionColor: JamiTheme.selectionBlue
        selectedTextColor: JamiTheme.whiteColor
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: control.contentItem.implicitHeight + JamiTheme.buttontextHeightMargin
        color: JamiTheme.globalBackgroundColor
        border.width: control.visualFocus ? 2 : 1
        border.color: !control.enabled ? JamiTheme.grey_
                      : control.popup.visible ? JamiTheme.comboboxBorderColorActive : JamiTheme.comboboxBorderColor
        visible: !control.flat || control.down
        radius: height / 2
    }

    popup: T.Popup {
        y: control.height - 1
        width: control.width
        padding: 1
        height: Math.min(contentItem.implicitHeight, 5 * control.implicitHeight)
        topMargin: 6
        bottomMargin: 6
        font: control.font

        background: Rectangle {
            color: JamiTheme.primaryBackgroundColor
            border.color: JamiTheme.comboboxBorderColorActive
            border.width: 1
            radius: control.background.radius
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
            Controls.ScrollBar.vertical: Common.JamiScrollBar {}
        }
    }

    Keys.onShortcutOverride: event => {
        if (event.key === Qt.Key_Escape && popup.visible)
            event.accepted = true;
    }

    Keys.onEscapePressed: event => {
        if (popup.visible) {
            event.accepted = true;
            popup.close();
        } else
            event.accepted = false;
    }
}