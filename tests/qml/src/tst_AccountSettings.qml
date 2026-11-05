/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
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
import QtTest
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import "../../../src/app/settingsview/components"

Item {
    width: 600
    height: 60

    ToggleSwitch {
        id: toggle
        anchors.fill: parent
        property string settingKey: "backgroundBlurEnabled"
        checked: AccountSettingsManager.accountSettingsPropertyMap[settingKey]
        onSwitchToggled: AccountSettingsManager.accountSettingsPropertyMap[settingKey] = checked
    }

    TestCase {
        name: "Test account settings"
        when: windowShown

        function initTestCase() {
            AccountSettingsManager.initalizeAccountSettings();
        }

        function init() {
            AccountSettingsManager.accountSettingsPropertyMap.backgroundBlurEnabled = true;
            AccountSettingsManager.accountSettingsPropertyMap.backgroundScrimEnabled = true;
        }

        function test_savedBackgroundFlags_data() {
            return [
                {tag: "blur-startup", key: "backgroundBlurEnabled", accountSwitch: false},
                {tag: "contrast-startup", key: "backgroundScrimEnabled", accountSwitch: false},
                {tag: "blur-account-switch", key: "backgroundBlurEnabled", accountSwitch: true},
                {tag: "contrast-account-switch", key: "backgroundScrimEnabled", accountSwitch: true}
            ];
        }

        function test_savedBackgroundFlags(data) {
            toggle.settingKey = data.key;
            AccountSettingsManager.setValue(data.key, "false");
            if (data.accountSwitch) {
                AccountSettingsManager.updateCurrentAccount("background-settings-test");
                AccountSettingsManager.updateCurrentAccount(CurrentAccount.id);
            } else {
                AccountSettingsManager.initalizeAccountSettings();
            }
            compare(toggle.checked, false, "A saved false value must disable the switch");
            compare(AccountSettingsManager.accountSettingsPropertyMap[data.key], false);

            mouseClick(toggle.toggleSwitch);
            compare(toggle.checked, true);
            compare(AccountSettingsManager.accountSettingsPropertyMap[data.key], true);

            mouseClick(toggle.toggleSwitch);
            compare(toggle.checked, false);
            compare(AccountSettingsManager.accountSettingsPropertyMap[data.key], false);
        }
    }
}
