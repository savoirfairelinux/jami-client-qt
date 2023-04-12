/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"

SettingsPageBase {
    id: root
    title: JamiStrings.customizeProfile

    function stopBooth() {
        currentAccountAvatar.stopBooth();
    }

    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        RowLayout {
            Layout.preferredWidth: parent.width
            spacing: 40

            Connections {
                target: settingsView

                function onStopBooth() {
                    stopBooth();
                }
            }
            PhotoboothView {
                id: currentAccountAvatar
                Layout.alignment: Qt.AlignCenter
                avatarSize: 150
                height: avatarSize
                imageId: LRCInstance.currentAccountId
                width: avatarSize
            }
            ModalTextEdit {
                id: displayNameLineEdit
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight + 8
                placeholderText: JamiStrings.enterNickname
                staticText: CurrentAccount.alias

                onAccepted: AccountAdapter.setCurrAccDisplayName(dynamicText)
            }
        }
        Text {
            id: description
            Layout.alignment: Qt.AlignLeft
            Layout.bottomMargin: JamiTheme.preferredSettingsBottomMarginSize
            Layout.preferredWidth: parent.width
            color: JamiTheme.textColor
            font.kerning: true
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            horizontalAlignment: Text.AlignLeft
            lineHeight: JamiTheme.wizardViewTextLineHeight
            text: JamiStrings.customizeAccountDescription
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
    }
}
