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
    property var iconSize: 26
    property var margin: 5
    property var prefWidth: 170

    width: parent.width

    RowLayout {
        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: 15

        ResponsiveImage {
            id: icon
            Layout.alignment: Qt.AlignLeft
            Layout.preferredHeight: column.iconSize
            Layout.preferredWidth: column.iconSize
            Layout.topMargin: column.margin
            color: JamiTheme.buttonTintedBlue
            containerHeight: Layout.preferredHeight
            containerWidth: Layout.preferredWidth
            source: JamiResources.noun_paint_svg
            visible: !opened
        }
        Label {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: column.margin
            Layout.preferredWidth: column.prefWidth - 2 * column.margin - column.iconSize
            Layout.topMargin: column.margin
            color: JamiTheme.textColor
            elide: Qt.ElideRight
            font.pixelSize: JamiTheme.tipBoxTitleFontSize
            font.weight: Font.Medium
            text: JamiStrings.customize
            visible: !opened
        }
    }
    Text {
        Layout.bottomMargin: 15
        Layout.leftMargin: 20
        Layout.preferredWidth: 170
        Layout.topMargin: 8
        color: JamiTheme.textColor
        font.pixelSize: JamiTheme.tipBoxContentFontSize
        font.weight: Font.Normal
        text: JamiStrings.customizeText
        visible: !opened
        wrapMode: Text.WordWrap
    }
    PhotoboothView {
        id: setAvatarWidget
        Layout.alignment: Qt.AlignHCenter
        avatarSize: 53
        doubleEditAvatar: true
        enabled: true
        height: avatarSize + avatarSize / 2
        imageId: CurrentAccount.id
        visible: opened
        width: avatarSize + avatarSize / 2
    }
    ModalTextEdit {
        id: displayNameLineEdit
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: root.width - 32
        Layout.topMargin: -10
        placeholderText: JamiStrings.enterNickname
        staticText: CurrentAccount.alias
        visible: opened

        onAccepted: AccountAdapter.setCurrAccDisplayName(dynamicText)
    }
    Text {
        Layout.leftMargin: 20
        Layout.preferredWidth: root.width - 32
        Layout.topMargin: 6
        color: JamiTheme.textColor
        font.pixelSize: JamiTheme.tipBoxContentFontSize
        text: JamiStrings.customizationDescription2
        visible: opened
        wrapMode: Text.WordWrap
    }
}
