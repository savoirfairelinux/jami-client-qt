/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {

    id: root

    NameRegistrationDialog {
        id : nameRegistrationDialog

        onAccepted: jamiRegisteredNameText.nameRegistrationState =
                    UsernameLineEdit.NameRegistrationState.BLANK
    }

    property bool editable: false
    property bool editing: false

    radius: 20
    Layout.bottomMargin: JamiTheme.jamiIdMargins
    Layout.leftMargin: JamiTheme.jamiIdMargins
    property var minWidth: mainRectangle.width + secondLine.implicitWidth
    width: Math.max(minWidth, jamiRegisteredNameText.width + 2 * JamiTheme.preferredMarginSize)
    height: component.implicitHeight
    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: component

        RowLayout {
            id: firstLine
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.width

            Rectangle {
                id: mainRectangle

                width: 97
                height: 40
                color: JamiTheme.mainColor
                radius: 20


                Rectangle {
                    id: rectForRadius
                    anchors.bottom: parent.bottom
                    width: 20
                    height: 20
                    color: JamiTheme.mainColor
                }

                ResponsiveImage {
                    id: jamiIdLogo
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: JamiTheme.jamiIdLogoWidth
                    height: JamiTheme.jamiIdLogoHeight
                    opacity: 1

                    source: JamiResources.jamiid_svg

                }
            }

            RowLayout {
                id: secondLine
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                PushButton {
                    id: btnEdit

                    imageColor: enabled ? JamiTheme.buttonTintedBlue :  JamiTheme.buttonTintedBlack
                    normalColor: JamiTheme.transparentColor
                    Layout.topMargin: JamiTheme.pushButtonMargin
                    hoverEnabled: false
                    preferredSize : 30
                    imageContainerWidth: JamiTheme.pushButtonSize
                    imageContainerHeight: JamiTheme.pushButtonSize
                    visible: false // editable && CurrentAccount.registeredName === ""
                    border.color: enabled ? JamiTheme.buttonTintedBlue :  JamiTheme.buttonTintedBlack

                    enabled: {
                        /*switch(jamiRegisteredNameText.nameRegistrationState) {
                        case UsernameLineEdit.NameRegistrationState.BLANK:
                        case UsernameLineEdit.NameRegistrationState.FREE:
                            return true
                        case UsernameLineEdit.NameRegistrationState.SEARCHING:
                        case UsernameLineEdit.NameRegistrationState.INVALID:
                        case UsernameLineEdit.NameRegistrationState.TAKEN:
                            return false
                        }*/
                    }

                    source: JamiResources.round_edit_24dp_svg

                    onClicked: {
                        /*if (!root.editing) {
                            source = JamiResources.check_black_24dp_svg
                            jamiRegisteredNameText.text = ""
                            jamiRegisteredNameText.focus = true
                        } else {
                            source = JamiResources.round_edit_24dp_svg
                            jamiRegisteredNameText.accepted()
                            jamiRegisteredNameText.focus = false
                        }
                        root.editing = !root.editing*/
                    }
                }

                PushButton {
                    id: btnCopy

                    imageColor: JamiTheme.buttonTintedBlue
                    normalColor: JamiTheme.transparentColor
                    hoveredColor: JamiTheme.transparentColor
                    Layout.topMargin: JamiTheme.pushButtonMargin

                    preferredSize : 30
                    imageContainerWidth: JamiTheme.pushButtonSize
                    imageContainerHeight: JamiTheme.pushButtonSize

                    border.color: JamiTheme.tintedBlue

                    source: JamiResources.content_copy_24dp_svg
                    toolTipText: JamiStrings.copy

                    onClicked: UtilsAdapter.setClipboardText(CurrentAccount.bestId)
                }

                PushButton {
                    id: btnShare

                    imageColor: JamiTheme.buttonTintedBlue
                    normalColor: JamiTheme.transparentColor
                    hoveredColor: JamiTheme.transparentColor
                    Layout.topMargin: JamiTheme.pushButtonMargin
                    Layout.rightMargin: JamiTheme.pushButtonMargin
                    preferredSize : 30
                    imageContainerWidth: JamiTheme.pushButtonSize
                    imageContainerHeight: JamiTheme.pushButtonSize

                    border.color: JamiTheme.buttonTintedBlue

                    source: JamiResources.share_24dp_svg
                    toolTipText: JamiStrings.share

                    onClicked: qrDialog.open()
                }

            }
        }

        MaterialLineEdit {
            id: jamiRegisteredNameText
            readOnly: !root.editing
            Layout.preferredWidth: 320

            horizontalAlignment: Qt.AlignHCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            backgroundColor: JamiTheme.secondaryBackgroundColor

            font.pointSize: JamiTheme.textFontSize + 1

            text: CurrentAccount.bestId
            color: JamiTheme.textColor

            onAccepted: {
                if (!btnEdit.enabled)
                    return
                if (text.length === 0) {
                    text = CurrentAccount.bestId
                } else {
                    nameRegistrationDialog.openNameRegistrationDialog(text)
                }
            }
        }
    }

}

