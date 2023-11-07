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

    title: JamiStrings.removeDevice

    closeButtonVisible: false

    button1.text: JamiStrings.optionRemove
    button1Role: DialogButtonBox.DestructiveRole
    button1.enabled: false
    button1.onClicked: {
        DeviceItemListModel.revokeDevice(deviceId, passwordEdit.dynamicText);
        close();
    }
    button2.text: JamiStrings.optionCancel
    button2Role: DialogButtonBox.RejectRole
    button2.onClicked: close()

    popupContent: ColumnLayout {
        id: revokeDeviceContentColumnLayout

        spacing: 16

        Label {
            id: labelDeletion

            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.parent.width - JamiTheme.preferredMarginSize * 4

            text: JamiStrings.confirmRemoval
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.textFontSize
            font.kerning: true
            wrapMode: Text.Wrap

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        PasswordTextEdit {
            id: passwordEdit

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: JamiTheme.preferredFieldWidth
            Layout.preferredHeight: visible ? 48 : 0

            placeholderText: JamiStrings.enterCurrentPassword

            onDynamicTextChanged: root.button1.enabled = dynamicText.length > 0
        }
    }
}
