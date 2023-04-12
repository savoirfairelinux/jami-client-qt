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
    property alias animatedIconSource: icon.animatedSource_
    property bool autoAccelerator: false
    property bool boldFont: false
    property real buttontextHeightMargin: JamiTheme.wizardButtonHeightMargin
    property var color: JamiTheme.buttonTintedBlue
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
    property real fontSize: JamiTheme.buttontextFontPixelSize
    property bool hasIcon: animatedIconSource.length !== 0 || iconSource.length !== 0
    property var hoveredColor: JamiTheme.buttonTintedBlueHovered
    property real iconSize: 18
    property alias iconSource: icon.source_
    property var keysNavigationFocusColor: Qt.darker(hoveredColor, 2)
    property var preferredWidth
    property var pressedColor: JamiTheme.buttonTintedBluePressed
    property bool primary: false
    property var secHoveredColor: JamiTheme.secAndTertiHoveredBackgroundColor
    property bool secondary: false
    property bool tertiary: false
    property real textAlignment: Text.AlignHCenter
    property real textLeftPadding
    property real textRightPadding
    property alias toolTipText: toolTip.text

    Accessible.description: toolTipText
    Accessible.name: root.text
    Accessible.role: Accessible.Button
    Layout.preferredHeight: height
    focusPolicy: Qt.TabFocus
    height: buttontextHeightMargin + textButton.height
    hoverEnabled: true

    Keys.onPressed: function (keyEvent) {
        if (keyEvent.key === Qt.Key_Enter || keyEvent.key === Qt.Key_Return) {
            clicked();
            keyEvent.accepted = true;
        }
    }

    MaterialToolTip {
        id: toolTip
        delay: Qt.styleHints.mousePressAndHoldInterval
        parent: root
        visible: hovered && (toolTipText.length > 0)
    }
    MouseArea {

        // We don't want to eat clicks on the Text.
        acceptedButtons: Qt.NoButton
        anchors.fill: parent
        cursorShape: (root.hovered && root.hoverEnabled) ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        enabled: text.length > 0 && parent.visible && autoAccelerator
        sequence: {
            if (text.length === 0)
                return "";
            return "Alt+" + text[0];
        }

        onActivated: clicked()
    }

    Binding on Layout.minimumHeight  {
        value: height
        when: root.preferredHeight !== undefined
    }
    Binding on Layout.preferredWidth  {
        value: width
        when: root.preferredWidth !== undefined || root.Layout.fillWidth
    }
    background: Rectangle {
        border.color: {
            if (root.primary || root.tertiary)
                return JamiTheme.transparentColor;
            if (root.secondary && root.hovered && root.hoverEnabled)
                return JamiTheme.secondaryButtonHoveredBorderColor;
            if (root.secondary)
                return JamiTheme.secondaryButtonBorderColor;
            if (root.down)
                return root.pressedColor;
            return root.focus ? root.keysNavigationFocusColor : root.color;
        }
        color: {
            var baseColor = root.focus ? root.keysNavigationFocusColor : root.color;
            if (root.primary) {
                if (root.hovered && root.hoverEnabled)
                    return root.hoveredColor;
                return baseColor;
            }
            if (root.secondary || root.tertiary) {
                if ((root.hovered && root.hoverEnabled) || root.focus)
                    return root.secHoveredColor;
                return JamiTheme.transparentColor;
            }
            if (root.down)
                return root.pressedColor;
            if (root.hovered && root.hoverEnabled)
                return root.hoveredColor;
            return baseColor;
        }
        radius: JamiTheme.primaryRadius
    }
    contentItem: Item {
        id: item
        implicitHeight: childrenRect.height

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: hasIcon ? JamiTheme.preferredMarginSize : 0

            Component {
                id: iconComponent
                ResponsiveImage {
                    Layout.preferredHeight: iconSize
                    Layout.preferredWidth: iconSize
                    color: contentColorProvider
                    source: source_
                }
            }
            Component {
                id: animatedIconComponent
                AnimatedImage {
                    Layout.preferredHeight: iconSize
                    Layout.preferredWidth: iconSize
                    fillMode: Image.PreserveAspectFit
                    height: iconSize
                    mipmap: true
                    playing: true
                    source: animatedSource_
                    width: iconSize
                }
            }
            Loader {
                id: icon
                property string animatedSource_
                property string source_

                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: hasIcon ? JamiTheme.preferredMarginSize : undefined
                Layout.preferredWidth: active * width
                active: hasIcon
                sourceComponent: animatedSource_.length !== 0 ? animatedIconComponent : iconComponent
            }
            Text {
                id: textButton
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.rightMargin: {
                    if ((!hasIcon || root.preferredWidth === undefined) && !root.Layout.fillWidth)
                        return undefined;
                    return icon.width + JamiTheme.preferredMarginSize / 2 + parent.spacing;
                }
                color: contentColorProvider
                elide: Text.ElideRight
                font.pixelSize: fontSize
                font.weight: (root.hovered && root.hoverEnabled) || boldFont ? Font.Bold : Font.Medium
                horizontalAlignment: root.textAlignment
                leftPadding: root.primary ? JamiTheme.buttontextWizzardPadding : textLeftPadding
                rightPadding: root.primary ? JamiTheme.buttontextWizzardPadding : textRightPadding
                text: root.text
                verticalAlignment: Text.AlignVCenter
            }

            Binding on width  {
                value: root.availableWidth
                when: root.preferredWidth !== undefined || root.Layout.fillWidth
            }
        }

        Binding on implicitWidth  {
            value: item.childrenRect.width
            when: root.preferredWidth === undefined || !root.Layout.fillWidth
        }
    }
    Binding on width  {
        value: root.preferredWidth
        when: root.preferredWidth !== undefined || root.Layout.fillWidth
    }
}
