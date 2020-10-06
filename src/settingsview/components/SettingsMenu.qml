/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import net.jami.Models 1.0

// TODO: these includes should generally be resource uris
import "../../commoncomponents"
import "../../settingsview"

Rectangle {
    id: root

    signal itemSelected(int index)

    Component.onCompleted: accountSettingsButton.checked = true

    anchors.fill: parent
    color: JamiTheme.backgroundColor

    ButtonGroup {
        buttons: buttons.children

        function getSelectionIndex(button) {
            switch (button) {
            case accountSettingsButton:
                return SettingsView.Account
            case generalSettingsButton:
                return SettingsView.General
            case mediaSettingsButton:
                return SettingsView.Media
            case accountSettingsButton:
                return SettingsView.Plugin
            }
        }

        onCheckedButtonChanged: {
            itemSelected(getSelectionIndex(checkedButton))
        }
    }

    ColumnLayout {
        id: buttons

        spacing: 0

        anchors.fill: parent

        PushButton {
            id: accountSettingsButton

            Layout.minimumHeight: 64
            Layout.preferredHeight: 64
            Layout.maximumHeight: 64
            Layout.fillWidth: true

            buttonText: qsTr("Account")
            source: "qrc:/images/icons/baseline-people-24px.svg"
            radius: 0
        }

        PushButton {
            id: generalSettingsButton

            Layout.minimumHeight: 64
            Layout.preferredHeight: 64
            Layout.maximumHeight: 64
            Layout.fillWidth: true

            buttonText: qsTr("General")
            source: "qrc:/images/icons/round-settings-24px.svg"
            radius: 0
        }

        PushButton {
            id: mediaSettingsButton

            Layout.minimumHeight: 64
            Layout.preferredHeight: 64
            Layout.maximumHeight: 64
            Layout.fillWidth: true

            buttonText: qsTr("Audio/Video")
            source: "qrc:/images/icons/baseline-desktop_windows-24px.svg"
            radius: 0
        }

        PushButton {
            id: pluginSettingsButton

            Layout.minimumHeight: 64
            Layout.preferredHeight: 64
            Layout.maximumHeight: 64
            Layout.fillWidth: true

            buttonText: qsTr("Plugins")
            source: "qrc:/images/icons/extension_24dp.svg"
            radius: 0
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}

