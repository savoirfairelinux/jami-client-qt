/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    property bool isSIP
    property int itemWidth
    property alias settingsVisible: advancedSettingsView.visible
    signal showAdvancedSettingsRequest

    RowLayout {
        id: rowAdvancedSettingsBtn
        Layout.fillWidth: true
        Layout.bottomMargin: 8

        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            font.pointSize: JamiTheme.headerFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            text: JamiStrings.advancedAccountSettings
            elide: Text.ElideRight
        }

        PushButton {
            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.alignment: Qt.AlignHCenter

            imageColor: JamiTheme.textColor
            toolTipText: advancedSettingsView.visible ? JamiStrings.tipAdvancedSettingsHide : JamiStrings.tipAdvancedSettingsDisplay

            preferredSize: 32
            source: advancedSettingsView.visible ? JamiResources.expand_less_24dp_svg : JamiResources.expand_more_24dp_svg

            onClicked: {
                advancedSettingsView.visible = !advancedSettingsView.visible;
                showAdvancedSettingsRequest();
            }
        }
    }

    ColumnLayout {
        id: advancedSettingsView

        Layout.fillWidth: true

        visible: false

        AdvancedCallSettings {
            id: advancedCallSettings

            Layout.fillWidth: true

            isSIP: LRCInstance.currentAccountType === Profile.Type.SIP
            itemWidth: root.itemWidth
        }

        AdvancedChatSettings {
            id: advancedChatSettings

            Layout.fillWidth: true

            visible: LRCInstance.currentAccountType === Profile.Type.JAMI
            itemWidth: root.itemWidth
        }

        AdvancedVoiceMailSettings {
            id: advancedVoiceMailSettings

            Layout.fillWidth: true

            visible: LRCInstance.currentAccountType === Profile.Type.SIP
            itemWidth: root.itemWidth
        }
    }
}
