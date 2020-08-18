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

import QtQuick 2.15
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Styles 1.4
import net.jami.Models 1.0

Dialog {
    id: deleteAccountDialog

    property int profileType: ClientWrapper.settingsAdaptor.getCurrentAccount_Profile_Info_Type()

    property bool isSIP: {
        switch (profileType) {
        case Profile.Type.SIP:
            return true;
        default:
            return false;
        }
    }

    onOpened: {
        profileType = ClientWrapper.settingsAdaptor.getCurrentAccount_Profile_Info_Type()
        labelBestId.text = ClientWrapper.settingsAdaptor.getAccountBestName()
        labelAccountHash.text = ClientWrapper.settingsAdaptor.getCurrentAccount_Profile_Info_Uri()
    }

    onVisibleChanged: {
        if(!visible){
            reject()
        }
    }

    visible: false

    header : Rectangle {
        width: parent.width
        height: 64
        color: "transparent"
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24

            text: qsTr("Account deletion")
            font.pointSize: JamiTheme.headerFontSize
        }
    }

    height: contentLayout.implicitHeight + 64 + 16
    width: contentLayout.implicitWidth + 24

    contentItem: Rectangle {

        ColumnLayout{
            id: contentLayout
            implicitWidth: 280
            anchors.fill: parent
            spacing: 8

            Layout.alignment: Qt.AlignCenter

            Label {
                id: labelDeletion

                Layout.leftMargin: 12
                Layout.rightMargin: 12

                Layout.alignment: Qt.AlignLeft
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                text: qsTr("Are you sure you want to delete this account?")
            }

            Label {
                id: labelWarning

                Layout.leftMargin: 12
                Layout.rightMargin: 12

                visible: !isSIP
                Layout.alignment: Qt.AlignLeft
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                text: qsTr("If this account hasn't been exported, or added to another device, it will be irrevocably lost.")
                color: "red"
            }

            Item {
                Layout.fillWidth: true

                Layout.minimumHeight: 8
                Layout.preferredHeight: 8
                Layout.maximumHeight: 8
            }

            RowLayout {
                spacing: 8

                Layout.fillWidth: true

                Layout.alignment: Qt.AlignRight

                Button {
                    id: btnDeleteAccept

                    contentItem: Text {
                        text: qsTr("DELETE")
                        color: "red"
                    }

                    background: Rectangle {
                        color: "transparent"
                    }

                    onClicked: {
                        ClientWrapper.accountAdaptor.deleteCurrentAccount()
                        accept()
                    }
                }


                Button {
                    id: btnDeleteCancel

                    contentItem: Text {
                        text: qsTr("CANCEL")
                        color: JamiTheme.buttonTintedGrey
                    }

                    background: Rectangle {
                        color: "transparent"
                    }

                    onClicked: {
                        reject()
                    }
                }
            }
        }
    }
}
