/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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

    signal editingFinished

    property alias borderColor: lineEdit.borderColor
    property alias underlined: lineEdit.underlined
    property alias wizardInput: lineEdit.wizardInput
    property alias wrapMode: lineEdit.wrapMode
    property alias padding: lineEdit.padding
    property alias fieldLayoutWidth: lineEdit.fieldLayoutWidth
    property alias fieldLayoutHeight: lineEdit.fieldLayoutHeight
    property alias echoMode: lineEdit.echoMode
    property string inactiveColor: JamiTheme.tintedBlue
    property string hoveredColor: "#03B9E9"
    property string selectedColor: "#03B9E9"
    property string validatedColor: "#009980"
    property string errorColor: "#CC0022"
    property alias selectByMouse:lineEdit.selectByMouse
    property alias loseFocusWhenEnterPressed: lineEdit.loseFocusWhenEnterPressed
    property alias validator: lineEdit.validator
    property alias text: lineEdit.text
    property alias color: lineEdit.color
    property alias verticalAlignment: lineEdit.verticalAlignment
    property alias horizontalAlignment: lineEdit.horizontalAlignment
    property alias font: lineEdit.font
    property alias placeholderText: lineEdit.placeholderText
    property alias placeholderTextColor: lineEdit.placeholderTextColor
    property alias backgroundColor: lineEdit.backgroundColor
    property var editIconColor:  UtilsAdapter.luma(root.color) ? JamiTheme.editLineColor : "white"
    property var cancelIconColor: UtilsAdapter.luma(root.color) ? JamiTheme.buttonTintedBlue : "white"
    property string informationToolTip: ""

    property string firstIco: ""
    property string secondIco: "" //JamiResources.outline_info_24dp_svg
    property string thirdIco: ""

    property string firstIcoColor: "#005699"
    property string secondIcoColor: "#005699"
    property string thirdIcoColor: "#005699"

    property bool readOnly: false
    property bool editable: false
    property bool hovered: false
    property bool selected: false
    property bool inactive: true
    property bool validated: false
    property bool error: false

    property string tooltipText: ""
    property int preferredWidth: JamiTheme.preferredFieldWidth

    function clear(){ lineEdit.clear() }
    height: lineEdit.height
    width: preferredWidth

    Layout.preferredHeight: 50
    Layout.preferredWidth:  400

    MaterialToolTip {
        parent: lineEdit
        visible: tooltipText != "" && hovered
        delay: Qt.styleHints.mousePressAndHoldInterval
        text: tooltipText
    }

    HoverHandler {
        target : parent
        onHoveredChanged: {
            root.hovered = hovered

        }
        //cursorShape: Qt.PointingHandCursor
    }

    RowLayout {
        id: row
        anchors.fill: parent

        z: 1

        ResponsiveImage  {
            id: firstIco_
            opacity: firstIco!=="" && (editable && !root.readOnly)

            Layout.alignment: Qt.AlignLeft
            width: 18
            height: 18

            layer {
                enabled: true
                effect: ColorOverlay {
                    color:  firstIcoColor
                }
            }

            source: firstIco //JamiResources.round_edit_24dp_svg

            Behavior on opacity {
                NumberAnimation {
                    from: 0
                    duration: JamiTheme.longFadeDuration
                }
            }
        }

        MaterialLineEdit {
            id: lineEdit

            readOnly: !editable || root.readOnly
            underlined: true

            borderColor: root.editIconColor
            fieldLayoutHeight: 24

            maximumLength: 20


            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: root.preferredFieldWidth - 18
            Layout.leftMargin: 18
            Layout.fillHeight: true

            wrapMode: Text.NoWrap


            onFocusChanged: function(focus) {
                if (!focus && editable) {
                    editable = !editable
                    root.editingFinished()
                } else if (focus && !editable) {
                    editable = !editable
                    lineEdit.forceActiveFocus()
                }
            }
            onAccepted: {
                editable = !editable
                root.editingFinished()
            }
        }

        //        PushButton {
        //            id: btnCancel
        //            visible: !wizardInput

        //            Layout.alignment: Qt.AlignVCenter

        //            enabled: editable && !root.readOnly
        //            preferredSize: lineEdit.height * 2 / 3
        //            opacity: enabled ? 0.8 : 0
        //            imageColor: root.cancelIconColor
        //            normalColor: "transparent"
        //            hoveredColor: JamiTheme.hoveredButtonColor

        //            source: JamiResources.round_close_24dp_svg

        //            onClicked: {

        //                root.selected = !root.selected

        //                root.editingFinished()
        //                root.editable = !root.editable
        //                lineEdit.forceActiveFocus()
        //            }

        //            Behavior on opacity {
        //                NumberAnimation {
        //                    from: 0
        //                    duration: JamiTheme.longFadeDuration
        //                }
        //            }
        //        }

        ResponsiveImage  {
            id: thirdICO_
            opacity: thirdIco!=="" && (editable && !root.readOnly)

            Layout.alignment: Qt.AlignRight
            width: 18
            height: 18

            layer {
                enabled: true
                effect: ColorOverlay {
                    color: thirdIcoColor
                }
            }

            source: thirdIco //JamiResources.round_edit_24dp_svg

            Behavior on opacity {
                NumberAnimation {
                    from: 0
                    duration: JamiTheme.longFadeDuration
                }
            }
        }

        ResponsiveImage  {
            id: secICO_
            opacity: secondIco!=="" // && (editable && !root.readOnly) pourauoi pas visible, a tester
            source: secondIco
            Layout.alignment: Qt.AlignRight
            width: 18
            height: 18

            MaterialToolTip {
                id: toolTip
                parent: secICO_
                visible: parent.hovered && informationToolTip!==""
                delay: Qt.styleHints.mousePressAndHoldInterval
            }


            layer {
                enabled: true
                effect: ColorOverlay {
                    color: secondIcoColor
                }
            }



            Behavior on opacity {
                NumberAnimation {
                    from: 0
                    duration: JamiTheme.longFadeDuration
                }
            }

        }


    }


    Rectangle {
        id: barColor
        anchors.fill: root//row
        radius: JamiTheme.primaryRadius

        visible: true
        color: {

            if(root.error)
                return errorColor
            if(root.validated)
                return validatedColor
            if(root.hovered || root.editable)
                return hoveredColor
            if(root.inactive)
                return inactiveColor
            if(root.editable)
                return selectedColor
            return "black"

        }

        Rectangle {
            visible: parent.visible
            anchors {
                fill: parent
                topMargin: 0
                rightMargin: 0
                bottomMargin: 1
                leftMargin: 0
            }
            color: root.backgroundColor
        }
    }

}
