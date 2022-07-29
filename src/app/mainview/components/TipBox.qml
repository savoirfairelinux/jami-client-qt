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
    property var title: ""
    property var description: ""
    property int tipId: 0
    property bool isTip : true
    property bool hovered: false
    property bool clicked : false
    property bool opened : false
    width: 200
    height: opened ? 170 : 105

    signal ignoreClicked

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


                ResponsiveImage {
                    id: icon

                    visible: !opened

                    Layout.alignment: Qt.AlignLeft
                    Layout.topMargin: 5
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26

                    containerHeight: Layout.preferredHeight
                    containerWidth: Layout.preferredWidth

                    source: !isTip ?  JamiResources.noun_paint_svg : JamiResources.glasses_tips_svg
                    color: "#005699"
                }

                Label {

                    text: root.title
                    font.weight: Font.Medium
                    Layout.topMargin: 5
                    visible: !opened
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: isTip ? 8 : 5
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
                text: !isTip ? JamiStrings.customizeText : root.title
            }


            PhotoboothView {
                id: setAvatarWidget
                Layout.preferredWidth: JamiTheme.accountListAvatarSize
                Layout.preferredHeight: JamiTheme.accountListAvatarSize

                Layout.alignment: Qt.AlignHCenter
                darkTheme: UtilsAdapter.luma(JamiTheme.primaryBackgroundColor)
                visible: opened &&! isTip
                enabled: true
                imageId: CurrentAccount.id
                avatarSize: 53
                buttonSize: 53

            }

            EditableLineEdit {

                id: displayNameLineEdit

                visible: !isTip && opened

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: root.width - 32
                fieldLayoutHeight: 10

                placeholderText: {
                    if (WizardViewStepModel.accountCreationOption !==
                            WizardViewStepModel.AccountCreationOption.CreateRendezVous)
                        return JamiStrings.enterNickname
                    else
                        return JamiStrings.enterRVName
                }

                fontSize: 12

                onEditingFinished: root.alias = text

            }

            Text {

                Layout.preferredWidth: 170
                Layout.leftMargin: 20
                Layout.topMargin: 6
                font.pixelSize: 12
                visible: opened && !isTip
                wrapMode: Text.WrapAnywhere
                text: JamiStrings.customizationDescription2
            }

            Text {

                Layout.preferredWidth: 170
                Layout.leftMargin: 20
                Layout.topMargin: 6
                font.pixelSize: 12
                visible: opened && isTip
                wrapMode: Text.WrapAnywhere
                text: root.description
            }

        }

    }

    HoverHandler {
        target : rect
        onHoveredChanged: root.hovered = hovered
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        target: rect
        onTapped: opened = !opened
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

    PushButton {
        id: btnClose

        width: 20
        height: 20
        imageContainerWidth: 20
        imageContainerHeight : 20
        anchors.margins: 14
        anchors.top: parent.top
        anchors.right: parent.right
        visible: opened
        circled: true

        imageColor: Qt.rgba(0, 86/255, 153/255, 1)
        normalColor: "transparent"

        source: JamiResources.round_close_24dp_svg

        onClicked: root.ignoreClicked()
    }

}


