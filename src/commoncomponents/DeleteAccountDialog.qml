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
import QtQuick.Window 2.15
import net.jami.Adapters 1.0

Window {
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

    signal accepted

    Component.onCompleted: {
        profileType = SettingsAdapter.getCurrentAccount_Profile_Info_Type()
        labelBestId.text = SettingsAdapter.getAccountBestName()
        labelAccountHash.text = SettingsAdapter.getCurrentAccount_Profile_Info_Uri()
    }

    title: qsTr("Account deletion")

    visible: false

    modality: Qt.WindowModal
    flags: Qt.WindowStaysOnTopHint

    width: JamiTheme.preferredDialogWidth
    height: JamiTheme.preferredDialogHeight

    minimumWidth: JamiTheme.preferredDialogWidth
    minimumHeight: JamiTheme.preferredDialogHeight


    ColumnLayout {
        anchors.fill: parent
        anchors.centerIn: parent

        ColumnLayout {
            Layout.margins: JamiTheme.preferredMarginSize
            spacing: 16
            Layout.alignment: Qt.AlignCenter

            Label {
                id: labelDeletion

                Layout.alignment: Qt.AlignHCenter

                Layout.minimumWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.preferredWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.maximumWidth: root.width - JamiTheme.preferredMarginSize * 2

                text: qsTr("Do you really want to delete the following account?")

                font.pointSize: JamiTheme.textFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }

            Label {
                id: labelBestId

                Layout.alignment: Qt.AlignHCenter

                Layout.minimumWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.preferredWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.maximumWidth: root.width - JamiTheme.preferredMarginSize * 2

                text: SettingsAdapter.getAccountBestName()

                font.pointSize: JamiTheme.textFontSize
                font.kerning: true
                font.bold: true

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                wrapMode: Text.Wrap
            }

            Label {
                id: labelAccountHash

                Layout.alignment: Qt.AlignHCenter

                Layout.minimumWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.preferredWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.maximumWidth: root.width - JamiTheme.preferredMarginSize * 2

                text: SettingsAdapter.getCurrentAccount_Profile_Info_Uri()

                font.pointSize: JamiTheme.textFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }

            Label {
                id: labelWarning

                visible: !isSIP

                Layout.alignment: Qt.AlignHCenter

                Layout.minimumWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.preferredWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.maximumWidth: root.width - JamiTheme.preferredMarginSize * 2


                text: qsTr("If this account hasn't been exported, or added to another device, it will be irrevocably lost.")

                font.pointSize: JamiTheme.textFontSize
                font.kerning: true

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap

                color: "red"
            }

            RowLayout {
                spacing: 16
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter

                Button {
                    id: btnDeleteAccept

                    contentItem: Text {
                        text: qsTr("DELETE")
                        color: JamiTheme.buttonTintedBlue
                    }

                    background: Rectangle {
                        color: "transparent"
                    }

                    onClicked: {
                        ClientWrapper.accountAdaptor.deleteCurrentAccount()
                        accepted()
                    }
                }

                Button {
                    id: btnDeleteCancel

                    /*Layout.maximumWidth: 130
                    Layout.preferredWidth: 130
                    Layout.minimumWidth: 130

                    Layout.maximumHeight: 30
                    Layout.preferredHeight: 30
                    Layout.minimumHeight: 30

                    backgroundColor: "red"
                    onEnterColor: Qt.rgba(150 / 256, 0, 0, 0.7)
                    onDisabledBackgroundColor: Qt.rgba(
                                                   255 / 256,
                                                   0, 0, 0.8)
                    onPressColor: backgroundColor
                    textColor: "white"

                    radius: height /2
                    */

                    contentItem: Text {
                        text: qsTr("CANCEL")
                        color: JamiTheme.buttonTintedBlue
                    }

                    background: Rectangle {
                        color: "transparent"
                    }

                    onClicked: {
                        close()
                    }
                }
            }
        }
    }
}
