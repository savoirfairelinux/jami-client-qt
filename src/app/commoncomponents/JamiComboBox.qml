pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Templates as T
import net.jami.Constants 1.1

T.ComboBox {
    id: jamiComboBox

    hoverEnabled: true

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, implicitContentHeight + topPadding + bottomPadding, implicitIndicatorHeight + topPadding + bottomPadding)

    leftPadding: padding + (!jamiComboBox.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (jamiComboBox.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)

    // Recommended to use ItemDelegate or AbstractButtons
    // The delegate defines a template for how each item in the dropdown should appear
    delegate: ItemDelegate {
        id: jamiComboBoxDelegate

        required property var model
        required property int index

        width: ListView.view.width

        contentItem: Text {
            text: jamiComboBoxDelegate.model[jamiComboBox.textRole]
            color: JamiTheme.textColor
            font.weight: jamiComboBox.currentIndex === index ? Font.DemiBold : Font.Normal
            font.pointSize: JamiTheme.settingsFontSize
        }

        background: Rectangle {
            color: jamiComboBoxDelegate.highlighted ? JamiTheme.hoverColor : "transparent"
            radius: 5
        }

        highlighted: jamiComboBox.highlightedIndex === index
        hoverEnabled: jamiComboBox.hoverEnabled
    }

    // Arrow symbol
    indicator: ResponsiveImage {
        x: jamiComboBox.mirrored ? jamiComboBox.padding : jamiComboBox.width - width - jamiComboBox.padding
        y: jamiComboBox.topPadding + (jamiComboBox.availableHeight - height) / 2
        color: jamiComboBox.enabled ? JamiTheme.comboboxIconColor : "grey"
        source: popup.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg
        opacity: enabled ? 1 : 0.3
    }

    // Defines the manner in which the current item appears
    contentItem: Text {
        leftPadding: !jamiComboBox.mirrored ? 12 : activeFocus ? 3 : 1
        rightPadding: jamiComboBox.mirrored ? 12 : activeFocus ? 3 : 1

        text: jamiComboBox.displayText
        color: JamiTheme.comboboxTextColor

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
    }

    // Defines how the actual background of the combobox appears
    background: Rectangle {
        implicitWidth: jamiComboBox.width
        implicitHeight: jamiComboBox.contentItem.implicitHeight + JamiTheme.buttontextHeightMargin

        color: JamiTheme.transparentColor
        border.width: jamiComboBox.visualFocus ? 2 : 1
        border.color: JamiTheme.comboboxBorderColor
        visible: !jamiComboBox.flat || jamiComboBox.down
        radius: 5
    }

    popup: T.Popup {
        y: jamiComboBox.height
        width: jamiComboBox.width
        height: Math.min(contentItem.implicitHeight, 5 * jamiComboBox.background.implicitHeight)//Math.min(contentItem.implicitHeight, jamiComboBox.Window.height - topMargin - bottomMargin)
        topMargin: 6
        bottomMargin: 6

        background: Rectangle {
            color: JamiTheme.backgroundColor // or appropriate theme color
            border.color: JamiTheme.comboboxBorderColorActive
            border.width: 1
            radius: 5
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: jamiComboBox.delegateModel
            currentIndex: jamiComboBox.highlightedIndex
            highlightMoveDuration: 0

            Rectangle {
                z: 10
                width: parent.width
                height: parent.height
                color: JamiTheme.transparentColor
                border.color: JamiTheme.comboboxBorderColorActive
                border.width: 1
                radius: 5
            }

            ScrollBar.vertical: JamiScrollBar {}
        }
    }

    Keys.onShortcutOverride: event => {
        if (event.key === Qt.Key_Escape && popup.visible) {
            event.accepted = true;
            popup.close();
        }
    }
}
