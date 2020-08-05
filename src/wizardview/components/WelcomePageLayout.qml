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

import "../../constant"
import "../../commoncomponents"

ColumnLayout {
    property alias connectAccountManagerButtonAlias: connectAccountManagerButton
    property alias newSIPAccountButtonAlias: newSIPAccountButton

    Layout.fillWidth: false
    Layout.fillHeight: false
    spacing: 48
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
        spacing: 6
        Layout.fillWidth: true
        Layout.maximumHeight: 48
        Layout.alignment: Qt.AlignHCenter
        Button {
            id: newAccountButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 48
            text: qsTr("CREATE A JAMI ACCOUNT")
            display: AbstractButton.TextBesideIcon

            font.pointSize: 12
            font.kerning: true

            icon.source: "qrc:/images/default_avatar_overlay.svg"
            icon.height: 24
            icon.width: 24

            palette.buttonText: "white"

            onClicked: {
                welcomePageRedirectPage(1)
            }

            background: Rectangle {
                anchors.fill: parent
                color: JamiTheme.buttonTintedBlue
                radius: parent.height / 2
            }
        }
    }
    RowLayout {
        spacing: 6
        Layout.fillWidth: true

        Layout.maximumHeight: 48
        Layout.alignment: Qt.AlignHCenter
        Button {
            id: fromDeviceButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 48
            text: qsTr("IMPORT FROM ANOTHER DEVICE")
            display: AbstractButton.TextBesideIcon

            font.pointSize: 12
            font.kerning: true

            icon.source: "qrc:/images/icons/devices-24px.svg"
            icon.height: 24
            icon.width: 24

            palette.buttonText: "white"

            onClicked: {
                welcomePageRedirectPage(5)
            }

            background: Rectangle {
                anchors.fill: parent
                color: JamiTheme.buttonTintedBlue
                radius: parent.height / 2
            }
        }
    }
    RowLayout {
        spacing: 6
        Layout.fillWidth: true

        Layout.maximumHeight: 48
        Layout.alignment: Qt.AlignHCenter
        Button {
            id: fromBackupButton

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 48
            text: qsTr("CONNECT FROM BACKUP")
            display: AbstractButton.TextBesideIcon

            font.pointSize: 12
            font.kerning: true

            icon.source: "qrc:/images/icons/backup-24px.svg"
            icon.height: 24
            icon.width: 24

            palette.buttonText: "white"

            onClicked: {
                welcomePageRedirectPage(3)
            }

            background: Rectangle {
                anchors.fill: parent
                color: JamiTheme.buttonTintedBlue
                radius: parent.height / 2
            }
        }
    }
    RowLayout {
        spacing: 6
        Layout.fillWidth: true

        Layout.maximumHeight: 30
        Layout.alignment: Qt.AlignHCenter
        Button {
            id: showAdvancedButton
            Layout.preferredWidth: 400
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Show Advanced")
            font.pointSize: 8
            font.kerning: true

            background: Rectangle{
                anchors.fill: parent

                color: "transparent"
                radius: height /2
            }

            onClicked: {
                connectAccountManagerButton.visible = !connectAccountManagerButton.visible
                newSIPAccountButton.visible = !newSIPAccountButton.visible
            }
        }
    }
    RowLayout {
        spacing: 6
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter

        Layout.maximumHeight: 30
        HoverableGradientButton {
            id: connectAccountManagerButton
            Layout.preferredWidth: 400
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Connect to account manager")
            visible: false
            font.pointSize: 10
            font.kerning: true

            backgroundColor: JamiTheme.releaseColor
            radius: height / 2

            onClicked: {
                welcomePageRedirectPage(6)
            }
        }
    }
    RowLayout {
        spacing: 6
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumHeight: 30

        HoverableGradientButton {
            id: newSIPAccountButton
            Layout.preferredWidth: 400
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignCenter
            text: qsTr("Add a new SIP account")
            visible: false
            font.pointSize: 10
            font.kerning: true

            radius: height / 2
            backgroundColor: JamiTheme.releaseColor

            onClicked: {
                welcomePageRedirectPage(2)
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
