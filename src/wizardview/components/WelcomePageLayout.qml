/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.15

import "../../constant"
import "../../commoncomponents"

ColumnLayout {
    property alias connectAccountManagerButtonAlias: connectAccountManagerButton
    property alias newSIPAccountButtonAlias: newSIPAccountButton

    Layout.fillWidth: false
    Layout.fillHeight: false
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter

    signal welcomePageRedirectPage(int toPageIndex)

    Item {
        // put a spacer to make the buttons closs to the middle
        Layout.minimumHeight: 57
        Layout.maximumHeight: 57
        Layout.preferredHeight: 57
        Layout.fillWidth: true
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Label {
            id: welcomeLabel
            Layout.maximumHeight: 40
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Welcome to")
            font.pointSize: 30
            font.kerning: true
        }
    }
    Item {
        Layout.minimumHeight: 17
        Layout.maximumHeight: 17
        Layout.preferredHeight: 17
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Label {
            id: welcomeLogo
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 100
            Layout.minimumHeight: 100
            Layout.maximumWidth: 16777215
            Layout.maximumHeight: 16777215
            Layout.preferredWidth: 300
            Layout.preferredHeight: 150
            color: "transparent"
            background: Image {
                id: logoIMG
                source: "qrc:/images/logo-jami-standard-coul.png"
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
        }
    }
    Item {
        // put a spacer to make the buttons closs to the middle
        Layout.preferredHeight: 57
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Layout.maximumHeight: 36
        Layout.alignment: Qt.AlignHCenter
        Button {
            id: newAccountButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 36
            text: qsTr("CREATE A JAMI ACCOUNT")
            display: AbstractButton.TextBesideIcon

            font.kerning: true

            icon.source: "qrc:/images/default_avatar_overlay.svg"
            icon.height: 18
            icon.width: 18

            contentItem: Item {
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight
                Row {
                    anchors.fill: parent
                    Image {
                        source: newAccountButton.icon.source
                        width: newAccountButton.icon.width
                        height: newAccountButton.icon.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        layer {
                            enabled: true
                            effect: ColorOverlay {
                                id: overlay
                                color: "white"
                            }
                        }
                    }
                    Text {
                        text: newAccountButton.text
                        color: "white"
                        font: newAccountButton.font
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Create new Jami account")

            onClicked: {
                welcomePageRedirectPage(1)
            }

            background: Rectangle {
                anchors.fill: parent
                color: JamiTheme.buttonTintedBlue
                radius: 4
            }
        }
    }
    RowLayout {
        spacing: 8
        Layout.fillWidth: true

        Layout.maximumHeight: 36
        Layout.alignment: Qt.AlignHCenter
        Button {
            id: fromDeviceButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 36
            text: qsTr("IMPORT FROM ANOTHER DEVICE")
            display: AbstractButton.TextBesideIcon

            font.kerning: true

            icon.source: "qrc:/images/icons/devices-24px.svg"
            icon.height: 18
            icon.width: 18

            contentItem: Item {
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight
                Row {
                    anchors.fill: parent
                    Image {
                        source: fromDeviceButton.icon.source
                        width: fromDeviceButton.icon.width
                        height: fromDeviceButton.icon.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        layer {
                            enabled: true
                            effect: ColorOverlay {
                                id: overlay
                                color: "white"
                            }
                        }
                    }
                    Text {
                        text: fromDeviceButton.text
                        color: "white"
                        font: fromDeviceButton.font
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Import account from other device")

            onClicked: {
                welcomePageRedirectPage(5)
            }

            background: Rectangle {
                anchors.fill: parent
                color: JamiTheme.buttonTintedBlue
                radius: 4
            }
        }
    }
    RowLayout {
        spacing: 8
        Layout.fillWidth: true

        Layout.maximumHeight: 36
        Layout.alignment: Qt.AlignHCenter
        Button {
            id: fromBackupButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 36
            text: qsTr("CONNECT FROM BACKUP")
            display: AbstractButton.TextBesideIcon

            font.kerning: true

            icon.source: "qrc:/images/icons/backup-24px.svg"
            icon.height: 18
            icon.width: 18

            contentItem: Item {
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight
                Row {
                    anchors.fill: parent
                    Image {
                        source: fromBackupButton.icon.source
                        width: fromBackupButton.icon.width
                        height: fromBackupButton.icon.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        layer {
                            enabled: true
                            effect: ColorOverlay {
                                id: overlay
                                color: "white"
                            }
                        }
                    }
                    Text {
                        text: fromBackupButton.text
                        color: "white"
                        font: fromBackupButton.font
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Import account from backup file")

            onClicked: {
                welcomePageRedirectPage(3)
            }

            background: Rectangle {
                anchors.fill: parent
                color: JamiTheme.buttonTintedBlue
                radius: 4
            }
        }
    }
    RowLayout {
        spacing: 8
        Layout.fillWidth: true

        Layout.maximumHeight: 36
        Layout.alignment: Qt.AlignHCenter

        Button {
            id: showAdvancedButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 36
            text: qsTr("SHOW ADVANCED")
            display: AbstractButton.TextBesideIcon

            font.kerning: true

            palette.buttonText: JamiTheme.buttonTintedBlue

            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Show advanced options")

            onClicked: {
                connectAccountManagerButton.visible = !connectAccountManagerButton.visible
                newSIPAccountButton.visible = !newSIPAccountButton.visible
            }

            background: Rectangle {
                anchors.fill: parent
                border.color: JamiTheme.buttonTintedBlue
                radius: 4
            }
        }
    }
    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter

        Layout.maximumHeight: 36
        Button {
            id: connectAccountManagerButton

            visible: false

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 36
            text: qsTr("CONNECT TO MANAGEMENT SERVER")
            display: AbstractButton.TextBesideIcon

            font.kerning: true

            icon.source: "qrc:/images/icons/router-24px.svg"
            icon.height: 18
            icon.width: 18

            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Login to account manager")

            contentItem: Item {
                implicitWidth: connectAccountManagerButton.implicitWidth
                implicitHeight: connectAccountManagerButton.implicitHeight
                Row {
                    anchors.fill: parent
                    Image {
                        source: connectAccountManagerButton.icon.source
                        width: connectAccountManagerButton.icon.width
                        height: connectAccountManagerButton.icon.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        layer {
                            enabled: true
                            effect: ColorOverlay {
                                id: overlay
                                color: "white"
                            }
                        }
                    }
                    Text {
                        text: connectAccountManagerButton.text
                        color: "white"
                        font: connectAccountManagerButton.font
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            onClicked: {
                welcomePageRedirectPage(6)
            }

            background: Rectangle {
                anchors.fill: parent
                color: JamiTheme.buttonTintedBlue
                radius: 4
            }
        }
    }
    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumHeight: 36
        Button {
            id: newSIPAccountButton

            visible: false

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 36
            text: qsTr("CREATE A SIP ACCOUNT")
            display: AbstractButton.TextBesideIcon

            font.kerning: true

            icon.source: "qrc:/images/default_avatar_overlay.svg"
            icon.height: 18
            icon.width: 18

            contentItem: Item {
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight
                Row {
                    anchors.fill: parent
                    Image {
                        source: newSIPAccountButton.icon.source
                        width: newSIPAccountButton.icon.width
                        height: newSIPAccountButton.icon.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        layer {
                            enabled: true
                            effect: ColorOverlay {
                                id: overlay
                                color: "white"
                            }
                        }
                    }
                    Text {
                        text: newSIPAccountButton.text
                        color: "white"
                        font: newSIPAccountButton.font
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Create new SIP account")

            onClicked: {
                welcomePageRedirectPage(2)
            }

            background: Rectangle {
                anchors.fill: parent
                color: JamiTheme.buttonTintedBlue
                radius: 4
            }
        }
    }
    Item {
        // put a spacer to make the buttons closs to the middle
        Layout.fillHeight: true
        Layout.preferredHeight: 65
        Layout.fillWidth: true
    }
}
