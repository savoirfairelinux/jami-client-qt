import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import net.jami.Constants 1.0

Button {
    id: root

    property bool outlined: false
    property alias toolTipText: toolTip.text
    property alias iconSource: icon.source
    property real iconSize: 18
    property var color: JamiTheme.buttonTintedBlue
    property var hoveredColor: JamiTheme.buttonTintedBlueHovered
    property var pressedColor: JamiTheme.buttonTintedBluePressed
    property var keysNavigationFocusColor: Qt.darker(hoveredColor, 2)

    property var preferredWidth
    Binding on width {
        when: root.preferredWidth !== undefined
        value: root.preferredWidth
    }
    Layout.preferredWidth: width
    property real preferredHeight: 36
    height: preferredHeight
    Layout.preferredHeight: height

    focusPolicy: Qt.TabFocus
    padding: 8

    MaterialToolTip {
        id: toolTip

        parent: root
        visible: hovered && (toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    contentItem: Item {
        id: item

        Binding on implicitWidth {
            when: root.preferredWidth === undefined
            value: item.childrenRect.width
        }
        implicitHeight: childrenRect.height
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            width: root.preferredWidth !== undefined ?
                       root.availableWidth :
                       childrenRect.width
            spacing: Math.min(4, root.padding) + 4
            property string colorProvider: {
                if (!root.outlined)
                    return "white"
                if (root.hovered)
                    return root.hoveredColor
                if (root.down)
                    return root.pressedColor
                return root.color
            }
            ResponsiveImage {
                id: icon
                Layout.leftMargin: JamiTheme.preferredMarginSize / 2
                Layout.preferredWidth: iconSize
                Layout.preferredHeight: iconSize
                Layout.alignment: Qt.AlignVCenter
                color: parent.colorProvider
            }
            Text {
                // this right margin will make the text visually
                // centered within button
                Layout.rightMargin: root.preferredWidth !== undefined ?
                           iconSize + 12 + parent.spacing + root.padding :
                           0
                Layout.alignment: Qt.AlignHCenter
                text: root.text
                font: root.font
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: parent.colorProvider
            }
        }
    }

    background: Rectangle {
        anchors.fill: parent

        property string colorProvider: {
            if (root.outlined)
                return "transparent"
            if (root.hovered)
                return root.hoveredColor
            if (root.down)
                return root.pressedColor
            return root.focus ?
                        root.keysNavigationFocusColor :
                        root.color
        }
        color: colorProvider
        border.color: colorProvider
        radius: JamiTheme.primaryRadius
    }

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.matches(StandardKey.InsertParagraphSeparator)) {
            clicked()
            keyEvent.accepted = true
        }
    }
}
