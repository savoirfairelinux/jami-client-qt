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
import Qt.labs.lottieqt

import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

Rectangle {

    id: root
    color: JamiTheme.secondaryBackgroundColor

    MouseArea {
        anchors.fill: parent
        enabled: visible
        onClicked: {
            for (var c in tipsFlow.children) {
                tipsFlow.children[c].opened = false
            }
        }
    }

    Item {
        width: Math.max(300, root.width)
        anchors.bottom: root.bottom
        height: aboutJami.height
        anchors.margins: JamiTheme.preferredMarginSize

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

    ColumnLayout{

        anchors.centerIn: parent

        Item {

            Layout.alignment: Qt.AlignCenter


            width: 630
            height: 263

            ResponsiveImage {
                id: welcomeLogo

                visible: root.width > 630

                width: 212
                height: 244
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 20
                opacity: 1

                source: JamiResources.welcome_illustration_2_svg

            }

            Rectangle {

                radius: 30
                color: JamiTheme.rectColor
                anchors.topMargin: 25
                anchors.horizontalCenter: parent.horizontalCenter
                width: welcomeLogo.visible ? 630 : Math.min(350, root.width - 2* JamiTheme.preferredMarginSize)
                height: leftPanel.implicitHeight
                opacity:1

                Behavior on width {
                    NumberAnimation { duration: JamiTheme.shortFadeDuration }
                }

                ColumnLayout {
                    id: leftPanel
                    Label {
                        id: welcome

                        Layout.alignment: Qt.AlignLeft
                        Layout.preferredWidth: 180
                        Layout.bottomMargin: 5
                        font.pixelSize: JamiTheme.bigFontSize
                        Layout.leftMargin: 40
                        Layout.topMargin: 26

                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        text: JamiStrings.welcomeToJami
                        color: JamiTheme.textColor
                    }

                    Label {
                        id: identifierDescription

                        Layout.alignment: Qt.AlignLeft
                        Layout.leftMargin: 40
                        Layout.preferredWidth: 300
                        Layout.bottomMargin: 5
                        font.pixelSize: JamiTheme.headerFontSize

                        wrapMode: Text.WordWrap

                        text: JamiStrings.hereIsIdentifier
                        color: JamiTheme.textColor
                    }

                    JamiIdentifier {
                        id: identifier
                        editable: true
                    }

                }

            }

        }

        Flow {
            id: tipsFlow

            spacing: JamiTheme.preferredMarginSize
            Layout.preferredWidth: Math.min(root.width - 2 * JamiTheme.preferredMarginSize, 600 + 3 * JamiTheme.preferredMarginSize)
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            Layout.bottomMargin: 50

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


    CustomBorder {
        commonBorder: false
        lBorderwidth: 1
        rBorderwidth: 0
        tBorderwidth: 0
        bBorderwidth: 0
        borderColor: JamiTheme.tabbarBorderColor
    }


}
