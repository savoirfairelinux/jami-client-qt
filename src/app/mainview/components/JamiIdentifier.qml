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

        onAccepted: usernameTextEdit.nameRegistrationState =
                    UsernameLineEdit.NameRegistrationState.BLANK
    }

    property bool editable: false
    property bool editing: false

    radius: 20
    Layout.bottomMargin: JamiTheme.jamiIdMargins
    Layout.leftMargin: JamiTheme.jamiIdMargins
    property real minWidth: mainRectangle.width + secondLine.implicitWidth
    width: Math.max(minWidth, usernameTextEdit.width + 2 * JamiTheme.preferredMarginSize)
    height: firstLine.implicitHeight + usernameTextEdit.height + 12
    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
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

                    preferredSize : 30
                    imageContainerWidth: JamiTheme.pushButtonSize
                    imageContainerHeight: JamiTheme.pushButtonSize

                    Layout.topMargin: JamiTheme.pushButtonMargin

                    imageColor: enabled ? JamiTheme.buttonTintedBlue :  JamiTheme.buttonTintedBlack
                    normalColor: JamiTheme.transparentColor
                    hoveredColor: JamiTheme.transparentColor
                    visible: editable && CurrentAccount.registeredName === ""
                    border.color: enabled ? JamiTheme.buttonTintedBlue :  JamiTheme.buttonTintedBlack

                    enabled: {
                        switch(usernameTextEdit.nameRegistrationState) {
                        case UsernameLineEdit.NameRegistrationState.BLANK:
                        case UsernameLineEdit.NameRegistrationState.FREE:
                            return true
                        case UsernameLineEdit.NameRegistrationState.SEARCHING:
                        case UsernameLineEdit.NameRegistrationState.INVALID:
                        case UsernameLineEdit.NameRegistrationState.TAKEN:
                            return false
                        }
                    }

                    source: usernameTextEdit.editMode
                            ? JamiResources.check_black_24dp_svg
                            : JamiResources.round_edit_24dp_svg

                    toolTipText: JamiStrings.chooseUsername

                    onClicked: {
                        if (!usernameTextEdit.editMode) {
                            usernameTextEdit.startEditing()
                        } else {
                            usernameTextEdit.accepted()
                        }
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

        UsernameTextEdit {
            id: usernameTextEdit

            infohash: CurrentAccount.uri
            registeredName: CurrentAccount.registeredName

            function startEditing() {
                if (!hasRegisteredName) {
                    usernameTextEdit.editMode = true
                    forceActiveFocus()
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus) {
                    usernameTextEdit.editMode = false
                }
            }

            Layout.preferredWidth: 330
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            fontPointSize: JamiTheme.textFontSize + 1
        }

//        UsernameLineEdit {
//            id: jamiRegisteredNameText
//            readOnly: !root.editing
//            Layout.preferredWidth: 330

//            horizontalAlignment: Qt.AlignHCenter
//            Layout.leftMargin: JamiTheme.preferredMarginSize
//            Layout.rightMargin: JamiTheme.preferredMarginSize
//            backgroundColor: JamiTheme.secondaryBackgroundColor

//            font.pointSize: JamiTheme.textFontSize + 1

//            text: CurrentAccount.bestId
//            color: JamiTheme.textColor

//            onAccepted: {
//                if (!btnEdit.enabled)
//                    return
//                if (text.length === 0) {
//                    text = CurrentAccount.bestId
//                } else {
//                    nameRegistrationDialog.openNameRegistrationDialog(text)
//                }
//            }
//        }
    }
}

