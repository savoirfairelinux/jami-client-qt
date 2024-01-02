/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
    property bool opened: root.opened

    property color textColor: JamiTheme.textColor
    property color iconColor: JamiTheme.tintedBlue

    focus: true

    onOpenedChanged: {
        if (opened)
            displayNameLineEdit.forceActiveFocus();
    }

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
            color: column.iconColor
            focus: activeFocus
        }

        Label {
            text: JamiStrings.customize
            color: column.textColor
            font.weight: Font.Medium
            Layout.topMargin: column.margin
            Layout.preferredWidth: column.prefWidth - 2 * column.margin - column.iconSize
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: column.margin
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: JamiTheme.tipBoxTitleFontSize
            elide: Qt.ElideRight
        }
    }

    Text {
        Layout.preferredWidth: 170
        Layout.leftMargin: 20
        Layout.topMargin: 8
        Layout.bottomMargin: 15
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: JamiTheme.tipBoxContentFontSize
        visible: !opened
        wrapMode: Text.WordWrap
        font.weight: Font.Normal
        text: JamiStrings.customizeText
        color: column.textColor
    }

    PhotoboothView {
        id: setAvatarWidget
        width: avatarSize + avatarSize / 2
        height: avatarSize + avatarSize / 2
        Layout.alignment: Qt.AlignHCenter
        visible: opened
        enabled: true
        imageId: CurrentAccount.id
        avatarSize: 53
        doubleEditAvatar: true
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
        focus: activeFocus
    }

    Text {

        Layout.preferredWidth: root.width - 32
        Layout.leftMargin: 20
        Layout.topMargin: 15
        font.pixelSize: JamiTheme.tipBoxContentFontSize
        visible: opened
        wrapMode: Text.WordWrap
        text: JamiStrings.customizationDescription
        color: column.textColor
    }
}
