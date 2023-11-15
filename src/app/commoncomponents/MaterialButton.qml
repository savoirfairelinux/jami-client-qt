/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Sébastien blin <sebastien.blin@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1

// TODO: this component suffers from excessive responsibility
// and should have fixed width and content width defined variations
// as well as better handling for the animated icon
AbstractButton {
    id: root

    property bool autoAccelerator: false
    property bool primary: false
    property bool secondary: false
    property bool tertiary: false
    property alias toolTipText: toolTip.text
    property alias iconSource: icon.source_
    property alias animatedIconSource: icon.animatedSource_
    property alias radius: background.radius
    property real iconSize: 18
    property var color: JamiTheme.buttonTintedBlue
    property var hoveredColor: JamiTheme.buttonTintedBlueHovered
    property var secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
    property var pressedColor: JamiTheme.buttonTintedBluePressed
    property var checkedColor: JamiTheme.secAndTertiHoveredBackgroundColor
    property bool hasIcon: animatedIconSource.length !== 0 || iconSource.length !== 0
    property var preferredWidth
    property real textLeftPadding
    property real textRightPadding
    property real fontSize: JamiTheme.buttontextFontPixelSize
    property real textAlignment: Text.AlignHCenter
    checkable: false
    checked: false

    property real buttontextHeightMargin: JamiTheme.wizardButtonHeightMargin
    height: buttontextHeightMargin + textButton.height
    Layout.preferredHeight: height

    Binding on width {
        when: root.preferredWidth !== undefined || root.Layout.fillWidth
        value: root.preferredWidth
    }

    Binding on Layout.preferredWidth {
        when: root.preferredWidth !== undefined || root.Layout.fillWidth
        value: width
    }

    Binding on Layout.minimumHeight  {
        when: root.preferredHeight !== undefined
        value: height
    }

    focusPolicy: Qt.StrongFocus

    Accessible.role: Accessible.Button
    Accessible.name: root.text
    Accessible.description: toolTipText

    MaterialToolTip {
        id: toolTip

        parent: root
        visible: hovered && (toolTipText.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }

    property string contentColorProvider: {
        if (root.primary)
            return JamiTheme.primaryTextColor;
        if (root.tertiary || root.secondary)
            return JamiTheme.secAndTertiTextColor;
        if (root.down)
            return root.pressedColor;
        if (!root.secondary)
            return "white";
        return root.color;
    }

    contentItem: Item {
        id: item

        Binding on implicitWidth {
            when: root.preferredWidth === undefined || !root.Layout.fillWidth
            value: item.childrenRect.width
        }

        implicitHeight: childrenRect.height

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            Binding on width {
                when: root.preferredWidth !== undefined || root.Layout.fillWidth
                value: root.availableWidth
            }

            spacing: hasIcon ? JamiTheme.preferredMarginSize : 0

            Component {
                id: iconComponent

                ResponsiveImage {
                    source: source_
                    Layout.preferredWidth: iconSize
                    Layout.preferredHeight: iconSize
                    color: contentColorProvider
                }
            }

            Component {
                id: animatedIconComponent

                AnimatedImage {
                    source: animatedSource_
                    Layout.preferredWidth: iconSize
                    Layout.preferredHeight: iconSize
                    width: iconSize
                    height: iconSize
                    playing: true
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
            }

            Loader {
                id: icon

                property string source_
                property string animatedSource_

                active: hasIcon

                Layout.preferredWidth: active * width

                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: hasIcon ? JamiTheme.preferredMarginSize : undefined
                sourceComponent: animatedSource_.length !== 0 ? animatedIconComponent : iconComponent
            }

            Text {
                id: textButton

                Layout.rightMargin: {
                    if ((!hasIcon || root.preferredWidth === undefined) && !root.Layout.fillWidth)
                        return undefined;
                    return icon.width + JamiTheme.preferredMarginSize / 2 + parent.spacing;
                }

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                leftPadding: root.primary ? JamiTheme.buttontextWizzardPadding : textLeftPadding
                rightPadding: root.primary ? JamiTheme.buttontextWizzardPadding : textRightPadding
                text: root.text
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: root.textAlignment
                color: contentColorProvider
                font.pixelSize: fontSize
            }
        }
    }

    background: Rectangle {
        id: background
        color: {
            var baseColor = root.color;
            if (root.primary) {
                if (root.hovered && root.enabled)
                    return root.hoveredColor;
                return baseColor;
            }
            if (root.secondary || root.tertiary) {
                if (root.hovered && root.enabled)
                    return root.secHoveredColor;
                if (root.checked && root.checkable)
                    return root.checkedColor;
                return JamiTheme.transparentColor;
            }
            if (root.down)
                return root.pressedColor;
            if (root.hovered && root.enabled)
                return root.hoveredColor;
            return baseColor;
        }

        border.color: {
            if (root.primary || root.tertiary)
                return JamiTheme.transparentColor;
            if (root.secondary && root.hovered && root.enabled)
                return JamiTheme.secondaryButtonHoveredBorderColor;
            if (root.secondary)
                return JamiTheme.secondaryButtonBorderColor;
            if (root.down)
                return root.pressedColor;
            return root.color;
        }

        radius: JamiTheme.primaryRadius
    }

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            clicked();
            keyEvent.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent

        // We don't want to eat clicks on the Text.
        acceptedButtons: Qt.NoButton
        cursorShape: (root.hovered && root.enabled) ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    Shortcut {
        enabled: text.length > 0 && parent.visible && autoAccelerator
        sequence: {
            if (text.length === 0)
                return "";
            return "Alt+" + text[0];
        }
        context: Qt.ApplicationShortcut
        onActivated: clicked()
    }
}
