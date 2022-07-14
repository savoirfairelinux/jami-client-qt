/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import Qt5Compat.GraphicalEffects

import "../../commoncomponents"

Item {

    id: root
    property bool tips_ : true
    property bool hovered: false
    property bool clicked : false
    property bool opened : false
    width: 200
    height: opened ? 170 : 105

    Rectangle {

        id: rect
        anchors.fill: parent

        border.color: Qt.rgba(0, 0.34,0.6,0.16)
        radius: 20

        ColumnLayout {

            anchors.fill: parent
            anchors.topMargin: 5

            RowLayout {

                Layout.leftMargin: 20
                Layout.alignment: Qt.AlignLeft

                PushButton {
                    id: btnClose

                    width: 20
                    height: 20
                    imageContainerWidth: 20
                    imageContainerHeight : 20
                    Layout.rightMargin: 8
                    Layout.alignment: Qt.AlignRight
                    visible: opened
                    radius : 5

                    imageColor: "grey"
                    normalColor: JamiTheme.transparentColor

                    source: JamiResources.round_close_24dp_svg

                    onClicked: { root.destroy();}
                }

                ResponsiveImage {
                    id: icon

                    visible: !opened

                    Layout.alignment: Qt.AlignLeft
                    Layout.topMargin: 5
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26

                    containerHeight: Layout.preferredHeight
                    containerWidth: Layout.preferredWidth

                    source: tips_ ?  JamiResources.noun_paint_svg : JamiResources.glasses_tips_svg
                    color: JamiTheme.mainColor
                }

                Label {

                    text: tips_ ? JamiStrings.customize : JamiStrings.tips
                    font.weight: Font.Medium
                    Layout.topMargin: 5
                    visible: !opened
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: tips_ ? 8 : 5
                    font.pixelSize: 13

                }

            }

            Text {

                Layout.preferredWidth: 170
                Layout.leftMargin: 20
                Layout.topMargin: 8
                Layout.bottomMargin: 15
                font.pixelSize: 12
                visible: !opened
                wrapMode: Text.WordWrap
                text: tips_ ? JamiStrings.customizeText : "Why should I save my account ?"
            }


            PhotoboothView {
                id: setAvatarWidget
                Layout.preferredWidth: JamiTheme.accountListAvatarSize
                Layout.preferredHeight: JamiTheme.accountListAvatarSize

                Layout.alignment: Qt.AlignHCenter
                darkTheme: UtilsAdapter.luma(JamiTheme.primaryBackgroundColor)
                visible: opened && tips_
                enabled: true
                imageId: CurrentAccount.id
                avatarSize: 53
                buttonSize: 53

            }

            MaterialLineEdit {
                id: aliasEdit

                property string lastFirstChar

                Layout.preferredHeight: fieldLayoutHeight
                Layout.preferredWidth: fieldLayoutWidth
                Layout.alignment: Qt.AlignCenter

                focus: visible
                visible: tips_ && opened
                selectByMouse: true
                enabled: visible
                placeholderText: {
                    if (WizardViewStepModel.accountCreationOption !==
                            WizardViewStepModel.AccountCreationOption.CreateRendezVous)
                        return JamiStrings.enterYourName
                    else
                        return JamiStrings.enterRVName
                }
                font.pointSize: JamiTheme.textFontSize
                font.kerning: true


            }

            Text {

                Layout.preferredWidth: 170
                Layout.leftMargin: 20
                Layout.topMargin: 8
                font.pixelSize: 12
                visible: opened && tips_
                wrapMode: Text.WrapAnywhere
                text: JamiStrings.customizationDescription
            }

            Text {

                Layout.preferredWidth: 170
                Layout.leftMargin: 20
                Layout.topMargin: 8
                font.pixelSize: 12
                visible: opened && !tips_
                wrapMode: Text.WrapAnywhere
                text: "Ceci est le texte affiché lorsqu'on ouvre une box tips"
            }

        }

    }

    HoverHandler {
        target : rect
        onHoveredChanged: {
            root.hovered = hovered
        }
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        target: rect
        onTapped: {
            opened = !opened
        }
    }


    DropShadow {
        z: -1
        visible: hovered || opened
        width: root.width
        height: root.height
        horizontalOffset: 3.0
        verticalOffset: 3.0
        radius: 16
        color: Qt.rgba(0, 0.34,0.6,0.16)
        source: rect
        transparentBorder: true
    }

}


