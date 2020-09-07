/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
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
import QtQuick.Window 2.15
import net.jami.Models 1.0

import "../../commoncomponents"

Window {
    id: root

    property string deviceId : ""

    signal revokeDeviceWithPassword(string idOfDevice, string password)

    function openRevokeDeviceDialog(deviceIdIn){
        deviceId = deviceIdIn
        passwordEdit.clear()
        show()
    }

    title: qsTr("Remove device")
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
            id: contentLayout
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: JamiTheme.preferredMarginSize
            spacing: 16

            Label {
                id: labelDeletion

                Layout.alignment: Qt.AlignHCenter
                Layout.minimumWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.preferredWidth: root.width - JamiTheme.preferredMarginSize * 2
                Layout.maximumWidth: root.width - JamiTheme.preferredMarginSize * 2

                text: qsTr("Enter this account's password to confirm the removal of this device")
                font.pointSize: JamiTheme.textFontSize
                font.kerning: true
                wrapMode: Text.Wrap

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MaterialLineEdit {
                id: passwordEdit

                Layout.alignment: Qt.AlignHCenter
                Layout.minimumWidth: JamiTheme.preferredFieldWidth
                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                Layout.maximumWidth: JamiTheme.preferredFieldWidth
                Layout.minimumHeight: visible ? 48 : 0
                Layout.preferredHeight: visible ? 48 : 0
                Layout.maximumHeight: visible ? 48 : 0

                echoMode: TextInput.Password
                placeholderText: qsTr("Enter Current Password")
                borderColorMode: InfoLineEdit.NORMAL

                onTextChanged: {
                    // TODO: Validate password?
                }
            }

            RowLayout {
                spacing: 16
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true

                Button {
                    id: btnRemove

                    contentItem: Text {
                        text: qsTr("REMOVE")
                        color: JamiTheme.buttonTintedBlue
                    }

                    background: Rectangle {
                        color: "transparent"
                    }

                    onClicked: {
                        revokeDeviceWithPassword(deviceId, passwordEdit.text)
                        close()
                    }
                }

                Button {
                    id: btnCancel

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
