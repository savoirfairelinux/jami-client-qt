/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1

import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

Rectangle {

    id: root
    color: JamiTheme.secondaryBackgroundColor


    JamiFlickable {
        id: welcomeView
        MouseArea {
            anchors.fill: parent
            enabled: visible
            onClicked: {
                for (var c in flow.children) {
                    flow.children[c].opened = false
                }
            }
        }

        anchors.fill: root

        contentHeight: Math.max(root.height, welcomePageLayout.implicitHeight)
        contentWidth: Math.max(300, root.width)

        Item {
            id: welcomePageLayout
            width: Math.max(300, root.width)
            height: parent.height

            Item {
                anchors.centerIn: parent
                height: childrenRect.height

                Rectangle {
                    id: welcomeInfo

                    radius: 30
                    color: JamiTheme.rectColor
                    anchors.topMargin: 25
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: identifier.width + 2 * JamiTheme.preferredMarginSize + (welcomeLogo.visible ?  welcomeLogo.width : 0)
                    height: childrenRect.height
                    opacity:1

                    Behavior on width {
                        NumberAnimation { duration: JamiTheme.shortFadeDuration }
                    }


                    Label {
                        id: welcome

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: JamiTheme.preferredMarginSize
                        anchors.leftMargin: JamiTheme.preferredMarginSize
                        width: 300

                        font.pixelSize: JamiTheme.bigFontSize

                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        text: JamiStrings.welcomeToJami
                        color: JamiTheme.textColor
                    }

                    Label {
                        id: identifierDescription

                        anchors.top: welcome.bottom
                        anchors.left: parent.left
                        anchors.topMargin: JamiTheme.preferredMarginSize
                        anchors.leftMargin: JamiTheme.preferredMarginSize
                        width: 300

                        font.pixelSize: JamiTheme.headerFontSize

                        wrapMode: Text.WordWrap

                        text: JamiStrings.hereIsIdentifier
                        color: JamiTheme.textColor
                    }

                    JamiIdentifier {
                        id: identifier
                        editable: true

                        anchors.top: identifierDescription.bottom
                        anchors.left: parent.left
                        anchors.margins: JamiTheme.preferredMarginSize
                    }



                    Image {
                        id: welcomeLogo

                        visible: root.width > 630
                        width: 212
                        height: 244
                        anchors.top: parent.top
                        anchors.left: identifier.right
                        anchors.margins: JamiTheme.preferredMarginSize
                        anchors.topMargin: -20
                        opacity: visible

                        source: JamiResources.welcome_illustration_2_svg

                        Behavior on opacity {
                            NumberAnimation { duration: JamiTheme.shortFadeDuration }
                        }
                    }
                }

                JamiFlickable {
                    id: tipsFlow

                    anchors.top: welcomeInfo.bottom
                    anchors.topMargin: JamiTheme.preferredMarginSize * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: welcomeInfo.width + JamiTheme.preferredMarginSize * 2
                    height: flow.height + JamiTheme.preferredMarginSize * 2

                    clip: true

                    Flow {
                        id: flow
                        spacing: 13

                        Repeater {
                            model: TipsModel
                            Layout.alignment: Qt.AlignCenter

                            delegate: TipBox {
                                tipId: TipId
                                title: Title
                                description: Description
                                isTip: IsTip
                                visible: index < 3

                                onIgnoreClicked: TipsModel.remove(TipId)
                            }
                        }
                    }
                }
            }


            Item {
                id: bottomRow
                width: Math.max(300, root.width)
                height: aboutJami.height + JamiTheme.preferredMarginSize
                anchors.bottom: parent.bottom

                MaterialButton {
                    id: aboutJami
                    tertiary: true

                    anchors.horizontalCenter: parent.horizontalCenter
                    preferredWidth: JamiTheme.aboutButtonPreferredWidthth
                    text: JamiStrings.aboutJami

                    onClicked: aboutPopUpDialog.open()
                }

                PushButton {
                    id: btnKeyboard

                    imageColor: JamiTheme.buttonTintedBlue
                    normalColor: JamiTheme.transparentColor
                    hoveredColor: JamiTheme.transparentColor
                    anchors.right: parent.right
                    anchors.rightMargin: JamiTheme.preferredMarginSize
                    preferredSize : 30
                    imageContainerWidth: JamiTheme.pushButtonSize
                    imageContainerHeight: JamiTheme.pushButtonSize

                    border.color: JamiTheme.buttonTintedBlue

                    source: JamiResources.keyboard_black_24dp_svg
                    toolTipText: JamiStrings.keyboardShortcuts

                    onClicked:  {
                        KeyboardShortcutTableCreation.createKeyboardShortcutTableWindowObject()
                        KeyboardShortcutTableCreation.showKeyboardShortcutTableWindow()
                    }
                }
            }
        }
    }

    CustomBorder {
        commonBorder: false
        lBorderwidth: 1
        rBorderwidth: 0
        tBorderwidth: 0
        bBorderwidth: 0
        borderColor: JamiTheme.tabbarBorderColor
    }


}
