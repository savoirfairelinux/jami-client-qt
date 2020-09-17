/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Sébastien blin <sebastien.blin@savoirfairelinux.com>
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
import net.jami.Models 1.0
import net.jami.Adapters 1.0

import "../../constant"
import "../../commoncomponents"

Rectangle {
    id: root

    signal welcomePageRedirectPage(int toPageIndex)
    signal leavePage

    color: JamiTheme.backgroundColor

    ColumnLayout {
        anchors.centerIn: parent

        spacing: layoutSpacing

        Text {
            id: welcomeLabel

            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: contentHeight

            text: qsTr("Welcome to")
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            font.pointSize: 30
            font.kerning: true
        }

        Label {
            id: welcomeLogo

            Layout.alignment: Qt.AlignCenter
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

        Flow {
            property int visibleButtonCounts: 0
            property int alwaysShownButtonCounts: 0

            spacing: layoutSpacing
            flow: Flow.TopToBottom

            Layout.preferredHeight: {
                var leftSpace = Math.min(
                            root.height - welcomeLabel.height - welcomeLogo.height - layoutSpacing * 2,
                            (newAccountButton.preferredHeight + layoutSpacing) * 7)
                if (visibleButtonCounts === 0)
                    return (newAccountButton.preferredHeight + layoutSpacing) * alwaysShownButtonCounts
                else
                    return leftSpace
            }

            MaterialButton {
                id: newAccountButton

                width: preferredWidth
                height: preferredHeight

                text: qsTr("Create a jami account")
                fontCapitalization: Font.AllUppercase
                toolTipText: qsTr("Create new Jami account")
                source: "qrc:/images/default_avatar_overlay.svg"
                color: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                onClicked: welcomePageRedirectPage(1)
                Component.onCompleted: parent.alwaysShownButtonCounts += visible ? 1 : 0
            }

            MaterialButton {
                id: newRdvButton

                width: preferredWidth
                height: preferredHeight

                text: JamiStrings.createRV
                fontCapitalization: Font.AllUppercase
                toolTipText: JamiStrings.createNewRV
                source: "qrc:/images/icons/groups-24px.svg"
                color: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                onClicked: welcomePageRedirectPage(8)
                Component.onCompleted: parent.alwaysShownButtonCounts += visible ? 1 : 0
            }

            MaterialButton {
                id: fromDeviceButton

                width: preferredWidth
                height: preferredHeight

                text: JamiStrings.linkFromAnotherDevice
                fontCapitalization: Font.AllUppercase
                toolTipText: qsTr("Import account from other device")
                source: "qrc:/images/icons/devices-24px.svg"
                color: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                onClicked: welcomePageRedirectPage(5)
                Component.onCompleted: parent.alwaysShownButtonCounts += visible ? 1 : 0
            }

            MaterialButton {
                id: fromBackupButton

                width: preferredWidth
                height: preferredHeight

                text: JamiStrings.connectFromBackup
                fontCapitalization: Font.AllUppercase
                toolTipText: qsTr("Import account from backup file")
                source: "qrc:/images/icons/backup-24px.svg"
                color: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                onClicked: welcomePageRedirectPage(3)
                Component.onCompleted: parent.alwaysShownButtonCounts += visible ? 1 : 0
            }

            MaterialButton {
                id: showAdvancedButton

                width: preferredWidth
                height: preferredHeight

                text: JamiStrings.advancedFeatures
                fontCapitalization: Font.AllUppercase
                toolTipText: JamiStrings.showAdvancedFeatures
                color: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed
                outlined: true

                hoverEnabled: true

                ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                ToolTip.visible: hovered
                ToolTip.text: JamiStrings.showAdvancedFeatures

                onClicked: {
                    connectAccountManagerButton.visible = !connectAccountManagerButton.visible
                    newSIPAccountButton.visible = !newSIPAccountButton.visible
                }

                Component.onCompleted: parent.alwaysShownButtonCounts += visible ? 1 : 0
            }

            MaterialButton {
                id: connectAccountManagerButton

                width: preferredWidth
                height: preferredHeight

                visible: false

                text: JamiStrings.connectJAMSServer
                fontCapitalization: Font.AllUppercase
                toolTipText: JamiStrings.createFromJAMS
                source: "qrc:/images/icons/router-24px.svg"
                color: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                onClicked: welcomePageRedirectPage(6)
                onVisibleChanged: parent.visibleButtonCounts += visible ? 1 : 0
            }

            MaterialButton {
                id: newSIPAccountButton

                width: preferredWidth
                height: preferredHeight

                visible: false

                text: JamiStrings.addSIPAccount
                fontCapitalization: Font.AllUppercase
                toolTipText: qsTr("Create new SIP account")
                source: "qrc:/images/default_avatar_overlay.svg"
                color: JamiTheme.buttonTintedBlue
                hoveredColor: JamiTheme.buttonTintedBlueHovered
                pressedColor: JamiTheme.buttonTintedBluePressed

                onClicked: welcomePageRedirectPage(2)
                onVisibleChanged: parent.visibleButtonCounts += visible ? 1 : 0
            }
        }
    }

    HoverableButton {
        id: backButton

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20

        Connections {
            target: LRCInstance

            function onAccountListChanged() {
                backButton.visible = UtilsAdapter.getAccountListSize()
            }
        }

        width: 35
        height: 35

        visible: UtilsAdapter.getAccountListSize()
        radius: 30

        backgroundColor: root.color
        onExitColor: root.color

        source: "qrc:/images/icons/ic_arrow_back_24px.svg"
        toolTipText: JamiStrings.back

        onClicked: leavePage()
    }
}
