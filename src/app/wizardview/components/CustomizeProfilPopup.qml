/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import QtQuick.Layouts
import "../../commoncomponents"

BaseModalDialog {
    id: root

    title: JamiStrings.customizeProfile


    button1.text: JamiStrings.optionSave
    button1.enabled: false

    button2.text: JamiStrings.optionCancel
    button2.onClicked: close()

    popupContent: ColumnLayout {
        id: customColumnLayout
        //anchors.fill: parent

        RowLayout {
            PhotoboothView {
                id: currentAccountAvatar

                width: avatarSize
                height: avatarSize

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: avatarSize

                newItem: true
                imageId: visible ? "temp" : ""
                avatarSize: 80
            }

            ModalTextEdit {
                id: displayNameLineEdit

                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.fillWidth: true

                placeholderText: JamiStrings.displayName
                onAccepted: root.alias = displayNameLineEdit.dynamicText
            }
        }

        Text {

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft

            wrapMode: Text.WordWrap
            color: JamiTheme.textColor
            text: JamiStrings.customizeProfileDescription
            font.pixelSize: JamiTheme.headerFontSize
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }
    }
}
