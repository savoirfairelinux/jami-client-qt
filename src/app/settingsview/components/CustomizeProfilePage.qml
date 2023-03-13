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

    signal navigateToMainView
    signal navigateToNewWizardView
    title: JamiStrings.customizeProfileSettingsTitle

    function stopBooth() {
        currentAccountAvatar.stopBooth()
    }


    flickableContent: ColumnLayout {
        id: currentAccountEnableColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        RowLayout {

            spacing: 40
            Layout.preferredWidth: parent.width
            Layout.topMargin: JamiTheme.preferredSettingsContentMarginSize

            Connections {
                target: settingsViewRect

                function onStopBooth() {
                    stopBooth()
                }
            }

            PhotoboothView {
                id: currentAccountAvatar
                darkTheme: UtilsAdapter.luma(JamiTheme.primaryBackgroundColor)
                width: avatarSize
                height: avatarSize

                Layout.alignment: Qt.AlignCenter

                imageId: LRCInstance.currentAccountId
                avatarSize: 150
                buttonSize: JamiTheme.smartListAvatarSize
            }

            ModalTextEdit {
                id: displayNameLineEdit

                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: JamiTheme.preferredFieldHeight + 8
                Layout.fillWidth: true

                staticText: CurrentAccount.alias
                placeholderText: JamiStrings.enterNickname

                onAccepted: AccountAdapter.setCurrAccDisplayName(dynamicText)
            }
        }

        Text {
            id: description

            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: parent.width
            Layout.bottomMargin: JamiTheme.preferredSettingsBottomMarginSize

            text: JamiStrings.customizeAccountDescription
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode : Text.WordWrap

            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            font.kerning: true
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }
    }
}
