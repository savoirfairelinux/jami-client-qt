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
import "../../constant"
import "../../commoncomponents"

Window {
    id: root

    property string deviceId : ""

    signal revokeDeviceWithPassword(string idOfDevice, string password)

    function openRevokeDeviceDialog(deviceIdIn) {
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
                    btnRemove.enabled = text.length > 0
                }
            }

            RowLayout {
                spacing: 16
                Layout.alignment: Qt.AlignHCenter

                Layout.fillWidth: true

                MaterialButton {
                    id: btnRemove

                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.maximumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.minimumHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.maximumHeight: JamiTheme.preferredFieldHeight

                    color: enabled? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    enabled: false

                    text: qsTr("Remove")

                    onClicked: {
                        revokeDeviceWithPassword(deviceId, passwordEdit.text)
                        close()
                    }
                }

                MaterialButton {
                    id: btnCancel

                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.maximumWidth: JamiTheme.preferredFieldWidth / 2 - 8
                    Layout.minimumHeight: JamiTheme.preferredFieldHeight
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight
                    Layout.maximumHeight: JamiTheme.preferredFieldHeight

                    color: JamiTheme.buttonTintedBlack
                    hoveredColor: JamiTheme.buttonTintedBlackHovered
                    pressedColor: JamiTheme.buttonTintedBlackPressed
                    outlined: true
                    enabled: true

                    text: qsTr("Cancel")

                    onClicked: {
                        close()
                    }
                }
	    }
        }
    }
}
