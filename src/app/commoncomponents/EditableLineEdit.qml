/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
 * Author: Sébastien blin <sebastien.blin@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import net.jami.Adapters 1.1

Item {
    id: root
    property alias backgroundColor: lineEdit.backgroundColor
    property color borderColor: lineEdit.borderColor
    property var cancelIconColor: UtilsAdapter.luma(root.color) ? JamiTheme.buttonTintedBlue : "white"
    property alias color: lineEdit.color
    property alias echoMode: lineEdit.echoMode
    property var editIconColor: "transparent"
    property bool editable: false
    property bool error: false
    property string errorColor: "#CC0022"
    property string firstIco: ""
    property string firstIcoColor: "#005699"
    property alias font: lineEdit.font
    property alias fontSize: lineEdit.fontSize
    property alias horizontalAlignment: lineEdit.horizontalAlignment
    property bool hovered: false
    property string hoveredColor: "#03B9E9"
    property bool inactive: true
    property string inactiveColor: JamiTheme.tintedBlue
    property string informationToolTip: ""
    property alias lineEdit: lineEdit
    property alias loseFocusWhenEnterPressed: lineEdit.loseFocusWhenEnterPressed
    property alias padding: lineEdit.padding
    property var placeholderText: ""
    property alias placeholderTextColor: lineEdit.placeholderTextColor
    property int preferredWidth: JamiTheme.preferredFieldWidth
    property bool readOnly: false
    property string secondIco: ""
    property string secondIcoColor: "#005699"
    property alias selectByMouse: lineEdit.selectByMouse
    property bool selected: false
    property string selectedColor: "#03B9E9"
    property alias text: lineEdit.text
    property string thirdIco: ""
    property string thirdIcoColor: "#005699"
    property string tooltipText: ""
    property alias underlined: lineEdit.underlined
    property bool validated: false
    property string validatedColor: "#009980"
    property alias validator: lineEdit.validator
    property alias verticalAlignment: lineEdit.verticalAlignment
    property alias wrapMode: lineEdit.wrapMode

    Layout.preferredHeight: 50
    Layout.preferredWidth: 400
    height: lineEdit.height
    width: preferredWidth

    signal accepted
    function clear() {
        lineEdit.clear();
        lineEdit.focus = false;
    }
    signal editingFinished
    signal secondIcoClicked
    function toggleEchoMode() {
        if (echoMode == TextInput.Normal) {
            echoMode = TextInput.Password;
            secondIco = JamiResources.eye_cross_svg;
        } else {
            echoMode = TextInput.Normal;
            secondIco = JamiResources.noun_eye_svg;
        }
    }

    onFocusChanged: function (focus) {
        if (focus)
            lineEdit.forceActiveFocus();
    }

    MaterialToolTip {
        delay: Qt.styleHints.mousePressAndHoldInterval
        parent: lineEdit
        text: tooltipText
        visible: tooltipText != "" && hovered
    }
    HoverHandler {
        enabled: !root.readOnly
        target: parent

        onHoveredChanged: {
            root.hovered = hovered;
        }
    }
    TapHandler {
        enabled: !root.readOnly
        target: parent

        onTapped: {
            lineEdit.focus = true;
        }
    }
    Item {
        id: row
        anchors.fill: parent
        z: 1

        ResponsiveImage {
            id: firstIco_
            anchors.bottom: row.bottom
            anchors.bottomMargin: row.height / 5
            anchors.left: row.left
            height: 18
            opacity: editable && !root.readOnly && firstIco !== ""
            source: firstIco
            visible: opacity
            width: visible ? 18 : 0

            layer {
                enabled: true

                effect: ColorOverlay {
                    color: firstIcoColor
                }
            }

            Behavior on opacity  {
                NumberAnimation {
                    duration: JamiTheme.longFadeDuration
                    from: 0
                }
            }
        }
        MaterialLineEdit {
            id: lineEdit
            anchors.bottom: row.bottom
            anchors.horizontalCenter: row.horizontalCenter
            borderColor: root.editIconColor
            horizontalAlignment: !readOnly || text !== "" ? Qt.AlignLeft : Qt.AlignHCenter
            placeholderText: readOnly ? root.placeholderText : ""
            readOnly: !editable || root.readOnly
            underlined: true
            verticalAlignment: Text.AlignBottom
            width: row.width - firstIco_.width - thirdIco_.width - secIco_.width - thirdIco_.anchors.rightMargin
            wrapMode: readOnly ? TextEdit.WrapAnywhere : TextEdit.NoWrap

            onAccepted: {
                root.accepted();
                root.editingFinished();
                editable = !editable;
                focus = false;
            }
            onFocusChanged: function (focus) {
                if (root.readOnly)
                    return;
                if (!focus && editable) {
                    editable = !editable;
                    root.editingFinished();
                } else if (focus && !editable) {
                    editable = !editable;
                    lineEdit.forceActiveFocus();
                }
            }
        }
        ResponsiveImage {
            id: thirdIco_
            anchors.bottom: row.bottom
            anchors.bottomMargin: 12
            anchors.right: secIco_.left
            anchors.rightMargin: 12
            height: 18
            source: thirdIco
            visible: thirdIco !== ""
            width: visible ? 18 : 0

            layer {
                enabled: true

                effect: ColorOverlay {
                    color: thirdIcoColor
                }
            }

            Behavior on opacity  {
                NumberAnimation {
                    duration: JamiTheme.longFadeDuration
                    from: 0
                }
            }
        }
        ResponsiveImage {
            id: secIco_
            anchors.bottom: row.bottom
            anchors.bottomMargin: 12
            anchors.right: row.right
            height: 18
            source: secondIco
            visible: (editable && !root.readOnly) || secondIco !== ""
            width: visible ? 18 : 0

            MaterialToolTip {
                id: toolTip
                backGroundColor: "white"
                delay: Qt.styleHints.mousePressAndHoldInterval
                parent: secIco_
                text: informationToolTip
                textColor: "black"
                visible: parent.hovered && informationToolTip !== ""
            }
            layer {
                enabled: true

                effect: ColorOverlay {
                    color: secondIcoColor
                }
            }
            TapHandler {
                enabled: !root.readOnly
                target: parent

                onTapped: {
                    root.secondIcoClicked();
                }
            }

            Behavior on opacity  {
                NumberAnimation {
                    duration: JamiTheme.longFadeDuration
                    from: 0
                }
            }
        }
    }
    Rectangle {
        id: barColor
        anchors.fill: root
        color: {
            if (root.error)
                return errorColor;
            if (root.validated)
                return validatedColor;
            if (root.hovered || root.editable)
                return hoveredColor;
            if (root.inactive)
                return inactiveColor;
            if (root.editable)
                return selectedColor;
            return "black";
        }
        radius: JamiTheme.primaryRadius
        visible: !readOnly

        Rectangle {
            color: root.backgroundColor
            visible: !readOnly && parent.visible

            anchors {
                bottomMargin: 1
                fill: parent
                leftMargin: -1
                rightMargin: -1
                topMargin: 0
            }
        }
    }
}
