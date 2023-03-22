/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

ColumnLayout {
    id: column
    width: parent.width

    property var iconSize: 26
    property var margin: 5
    property var prefWidth: 170

    RowLayout {

        Layout.leftMargin: 15
        Layout.alignment: Qt.AlignLeft

        ResponsiveImage {
            id: icon

            visible: !opened

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: column.margin
            Layout.preferredWidth: column.iconSize
            Layout.preferredHeight: column.iconSize

            containerHeight: Layout.preferredHeight
            containerWidth: Layout.preferredWidth

            source: JamiResources.noun_paint_svg
            color: JamiTheme.buttonTintedBlue
        }

        Label {
            text: JamiStrings.customize
            color: JamiTheme.textColor
            font.weight: Font.Medium
            Layout.topMargin: column.margin
            Layout.preferredWidth: column.prefWidth - 2 * column.margin - column.iconSize
            visible: !opened
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: column.margin
            font.pixelSize: JamiTheme.tipBoxTitleFontSize
            elide: Qt.ElideRight
        }
    }

    Text {
        Layout.preferredWidth: 170
        Layout.leftMargin: 20
        Layout.topMargin: 8
        Layout.bottomMargin: 15
        font.pixelSize: JamiTheme.tipBoxContentFontSize
        visible: !opened
        wrapMode: Text.WordWrap
        font.weight: Font.Normal
        text: JamiStrings.customizeText
        color: JamiTheme.textColor
    }


    PhotoboothView {
        id: setAvatarWidget
        width: avatarSize + avatarSize / 2
        height: avatarSize + avatarSize / 2
        Layout.alignment: Qt.AlignHCenter
        darkTheme: UtilsAdapter.luma(JamiTheme.primaryBackgroundColor)
        visible: opened
        enabled: true
        buttonSize: 35
        imageId: CurrentAccount.id
        avatarSize: 53
        doubleEditAvatar: true
        cancelButton: false

    }

    ModalTextEdit {
        id: displayNameLineEdit

        visible: opened

        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: root.width - 32
        Layout.topMargin: -10

        staticText: CurrentAccount.alias
        placeholderText: JamiStrings.enterNickname

        onAccepted: AccountAdapter.setCurrAccDisplayName(dynamicText)
    }

    Text {

        Layout.preferredWidth: root.width - 32
        Layout.leftMargin: 20
        Layout.topMargin: 6
        font.pixelSize: JamiTheme.tipBoxContentFontSize
        visible: opened
        wrapMode: Text.WordWrap
        text: JamiStrings.customizationDescription2
        color: JamiTheme.textColor
    }
}
