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
import net.jami.Adapters 1.0

Dialog {
    id: root

    property int profileType: SettingsAdapter.getCurrentAccount_Profile_Info_Type()

    property bool isSIP: {
        switch (profileType) {
        case Profile.Type.SIP:
            return true;
        default:
            return false;
        }
    }

    onOpened: {
        profileType = SettingsAdapter.getCurrentAccount_Profile_Info_Type()
        labelBestId.text = SettingsAdapter.getAccountBestName()
        labelAccountHash.text = SettingsAdapter.getCurrentAccount_Profile_Info_Uri()
    }

    onVisibleChanged: {
        if(!visible){
            reject()
        }
    }

    visible: false
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    title: qsTr("Account deletion")

    contentItem: Rectangle{
        implicitWidth: 400
        implicitHeight: 300

        ColumnLayout{
            anchors.fill: parent
            Layout.alignment: Qt.AlignCenter

            Label{
                id: labelDeletion

                Layout.topMargin: 11
                Layout.leftMargin: 11
                Layout.rightMargin: 11
                Layout.alignment: Qt.AlignHCenter

                font.pointSize: 8
                font.kerning: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text:qsTr("Do you really want to delete the following account?")
            }

            Label{
                id: labelBestId

                Layout.leftMargin: 11
                Layout.rightMargin: 11
                Layout.alignment: Qt.AlignHCenter

                font.pointSize: 8
                font.kerning: true
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap

                text: SettingsAdapter.getAccountBestName()
            }

            Label{
                id: labelAccountHash

                Layout.leftMargin: 11
                Layout.rightMargin: 11
                Layout.alignment: Qt.AlignHCenter

                font.pointSize: 8
                font.kerning: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: SettingsAdapter.getCurrentAccount_Profile_Info_Uri()
            }

            Label{
                id: labelWarning

                Layout.topMargin: 5
                Layout.leftMargin: 11
                Layout.rightMargin: 11
                Layout.preferredWidth: 300
                Layout.alignment: Qt.AlignHCenter

                visible: ! isSIP

                wrapMode: Text.Wrap
                text: qsTr("If this account hasn't been exported, or added to another device, it will be irrevocably lost.")
                font.pointSize: 8
                font.kerning: true
                horizontalAlignment: Text.AlignHCenter
                color: "red"
            }

            RowLayout{
                Layout.topMargin: 10
                Layout.bottomMargin: 5
                Layout.leftMargin: 11
                Layout.rightMargin: 11
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                HoverableRadiusButton{
                    id: btnDeleteAccept

                    Layout.maximumWidth: 130
                    Layout.preferredWidth: 130
                    Layout.preferredHeight: 30

                    radius: height /2

                    text: qsTr("Delete")
                    font.pointSize: 10
                    font.kerning: true

                    onClicked: {
                        ClientWrapper.accountAdaptor.deleteCurrentAccount()
                        accept()
                    }
                }

                HoverableButtonTextItem{
                    id: btnDeleteCancel

                    Layout.leftMargin: 20
                    Layout.maximumWidth: 130
                    Layout.preferredWidth: 130
                    Layout.preferredHeight: 30

                    backgroundColor: "red"
                    onEnterColor: Qt.rgba(150 / 256, 0, 0, 0.7)
                    onDisabledBackgroundColor: Qt.rgba(
                                                   255 / 256,
                                                   0, 0, 0.8)
                    onPressColor: backgroundColor
                    textColor: "white"

                    radius: height /2

                    text: qsTr("Cancel")
                    font.pointSize: 10
                    font.kerning: true

                    onClicked: {
                        reject()
                    }
                }
            }
        }
    }
}
