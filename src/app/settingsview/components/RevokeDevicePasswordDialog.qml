/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root
    required property string deviceId

    height: Math.min(appWindow.height - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogHeight)
    title: JamiStrings.removeDevice
    width: Math.min(appWindow.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogWidth)

    popupContent: ColumnLayout {
        id: revokeDeviceContentColumnLayout
        spacing: 16

        Label {
            id: labelDeletion
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: revokeDeviceContentColumnLayout.width - JamiTheme.preferredMarginSize * 2
            color: JamiTheme.textColor
            font.kerning: true
            font.pointSize: JamiTheme.textFontSize
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.confirmRemoval
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        PasswordTextEdit {
            id: passwordEdit
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: visible ? 48 : 0
            Layout.preferredWidth: JamiTheme.preferredFieldWidth
            placeholderText: JamiStrings.enterCurrentPassword

            onDynamicTextChanged: btnRemove.enabled = dynamicText.length > 0
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            spacing: 16

            MaterialButton {
                id: btnRemove
                Layout.alignment: Qt.AlignHCenter
                autoAccelerator: true
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                color: enabled ? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                enabled: false
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true
                text: JamiStrings.optionRemove

                onClicked: {
                    DeviceItemListModel.revokeDevice(deviceId, passwordEdit.text);
                    close();
                }
            }
            MaterialButton {
                id: btnCancel
                Layout.alignment: Qt.AlignHCenter
                autoAccelerator: true
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                color: JamiTheme.buttonTintedBlack
                enabled: true
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true
                text: JamiStrings.optionCancel

                onClicked: close()
            }
        }
    }
}
