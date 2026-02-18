/*
 * Copyright (C) 2019-2026 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import net.jami.Constants 1.1

ComboBox {
    id: root

    property alias tooltipText: toolTip.text
    property string placeholderText
    property string currentSelectionText: currentText
    property string comboBoxBackgroundColor: JamiTheme.editBackgroundColor
    property bool selection: currentIndex < 0 && !count
    property bool popupShown: false

    displayText: {
        // If the index is -1 and the model is empty, display the placeholder text.
        // The placeholder text is either the placeholderText property or a default text.
        // Otherwise, display the currentSelectionText property.
        if (currentIndex < 0 && !count) {
            return placeholderText !== "" ? placeholderText : JamiStrings.notAvailable;
        }
        return currentSelectionText;
    }

    delegate: ItemDelegate {
        id: delegateItem

        width: root.width
        height: selectOption.height

        highlighted: root.highlightedIndex === index

        contentItem: Text {
            id: delegateText
            text: {
                if (index < 0 || !model)
                    return '';

                if (root.textRole && model[root.textRole] !== undefined) {
                    return model[root.textRole].toString();
                }

                return model.display !== undefined ? model.display.toString() : '';
            }

            color: hovered ? JamiTheme.comboboxTextColorHovered : JamiTheme.textColor
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter

            font.pointSize: JamiTheme.settingsFontSize

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                    easing.type: Easing.InOutCubic
                }
            }
        }

        background: Rectangle {
            color: hovered || highlighted ? JamiTheme.comboboxBackgroundColorHovered : JamiTheme.globalBackgroundColor
            radius: height / 2

            Behavior on color {
                ColorAnimation {
                    duration: JamiTheme.shortFadeDuration
                    easing.type: Easing.InOutCubic
                }
            }
        }
    }

    indicator: ResponsiveImage {
        containerHeight: 6
        containerWidth: 10
        width: 20
        height: 20

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 16

        source: JamiResources.expand_less_24dp_svg

        color: root.enabled ? JamiTheme.comboboxIconColor : JamiTheme.grey_

        transform: Rotation {
            id: rotation
            origin.x: indicator.width / 2
            origin.y: indicator.height / 2
            angle: popup.visible ? 0 : 180

            Behavior on angle {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    contentItem: Text {
        anchors.left: parent.left
        anchors.leftMargin: root.indicator.width
        anchors.right: parent.right
        anchors.rightMargin: root.indicator.width * 2

        width: parent.width - root.indicator.width * 2

        text: root.displayText
        color: root.enabled ? JamiTheme.comboboxTextColor : "grey"
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft

        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        font.weight: Font.Medium
    }

    background: Rectangle {
        id: selectOption

        implicitWidth: 120
        implicitHeight: contentItem.implicitHeight + JamiTheme.buttontextHeightMargin

        color: JamiTheme.globalBackgroundColor

        border.color: root.enabled ? (popup.visible ? JamiTheme.comboboxBorderColorActive : JamiTheme.comboboxBorderColor) : "grey"
        border.width: root.visualFocus ? 2 : 1

        radius: height / 2
    }

    popup: Popup {
        id: popup

        y: root.height - 1
        width: root.width
        padding: 1
        height: Math.min(contentItem.implicitHeight, 5 * selectOption.implicitHeight)

        contentItem: JamiListView {
            id: listView

            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
            clip: true

            delegate: root.delegate

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        width: listView.width
                        height: listView.height
                        radius: selectOption.radius
                    }
                }
            }
        }

        background: Rectangle {
            color: JamiTheme.primaryBackgroundColor
            border.color: JamiTheme.comboboxBorderColorActive

            radius: selectOption.radius
        }

        enter: Transition {
            NumberAnimation {
                property: "height"
                from: 0
                to: Math.min(popup.contentItem.implicitHeight, 5 * selectOption.implicitHeight)
                duration: JamiTheme.shortFadeDuration
                easing.type: Easing.InOutQuad
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "height"
                from: Math.min(popup.contentItem.implicitHeight, 5 * selectOption.implicitHeight)
                to: 0
                duration: JamiTheme.shortFadeDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    Accessible.role: Accessible.ComboBox
    Accessible.name: tooltipText

    MaterialToolTip {
        id: toolTip

        parent: root
        visible: hovered && (text.length > 0)
        delay: Qt.styleHints.mousePressAndHoldInterval
    }
}
