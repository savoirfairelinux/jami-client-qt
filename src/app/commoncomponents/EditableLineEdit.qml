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
    signal accepted
    signal secondIcoClicked

    property alias fontSize: lineEdit.fontSize
    property color borderColor: lineEdit.borderColor
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
    property var editIconColor: "transparent"
    property var cancelIconColor: UtilsAdapter.luma(root.color) ? JamiTheme.buttonTintedBlue : "white"
    property string informationToolTip: ""

    property string firstIco: ""
    property string secondIco: ""
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
    function toggleEchoMode(){                 if (echoMode == TextInput.Normal) {
            echoMode = TextInput.Password
            secondIco = JamiResources.eye_cross_svg
        }
        else { echoMode = TextInput.Normal
            secondIco = JamiResources.noun_eye_svg
        }
    }

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

    Item {

        id: row
        anchors.fill: parent

        z: 1

        ResponsiveImage  {
            id: firstIco_
            opacity:  (editable && !root.readOnly) /*firstIco!=="" &&*/
            anchors.left: row.left
            anchors.verticalCenter: row.verticalCenter

            width: 18
            height: 18

            layer {
                enabled: true
                effect: ColorOverlay {
                    color:  firstIcoColor
                }
            }

            source: firstIco

            Behavior on opacity {
                NumberAnimation {
                    from: 0
                    duration: JamiTheme.longFadeDuration
                }
            }
        }

        MaterialLineEdit {
            id: lineEdit
            anchors.horizontalCenter: row.horizontalCenter
            height: row.height
            readOnly: !editable || root.readOnly
            underlined: true

            borderColor: root.editIconColor
            fieldLayoutHeight: 24

            maximumLength: 20

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
                root.accepted()
                root.editingFinished()
                focus = false //probleme avec licon de gauche
            }
        }



        ResponsiveImage  {
            id: thirdICO_
            //            visible:  (editable && !root.readOnly) /*thirdIco!==""*/
            anchors.right: secICO_.left
            anchors.rightMargin: 12
            anchors.verticalCenter: row.verticalCenter

            width: 18
            height: 18

            layer {
                enabled: true
                effect: ColorOverlay {
                    color: thirdIcoColor
                }
            }

            source: thirdIco

            Behavior on opacity {
                NumberAnimation {
                    from: 0
                    duration: JamiTheme.longFadeDuration
                }
            }
        }

        ResponsiveImage  {

            id: secICO_
            visible: (editable && !root.readOnly) || secondIco !==""
            source: secondIco
            anchors.right: row.right
            anchors.verticalCenter: row.verticalCenter
            width: 18
            height: 18

            MaterialToolTip {
                id: toolTip
                parent: secICO_
                text: informationToolTip
                textColor: "black"
                backGroundColor: "white"
                visible: parent.hovered && informationToolTip!==""
                delay: Qt.styleHints.mousePressAndHoldInterval
            }


            layer {
                enabled: true
                effect: ColorOverlay {
                    color: secondIcoColor
                }
            }

            TapHandler{
                target: parent
                onTapped: {

                    root.secondIcoClicked()

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
        anchors.fill: root
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
                rightMargin: -1
                bottomMargin: 1
                leftMargin: -1
            }
            color: root.backgroundColor
        }
    }

}
