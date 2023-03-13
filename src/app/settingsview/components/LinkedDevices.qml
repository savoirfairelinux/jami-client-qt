/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import QtQuick.Layouts

import SortFilterProxyModel 0.2

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../commoncomponents"

ColumnLayout {
    id:root
    
    spacing: JamiTheme.settingsCategorySpacing

    function removeDeviceSlot(index){
        var deviceId = settingsListView.model.data(settingsListView.model.index(index,0),
                                                   DeviceItemListModel.DeviceID)
        if(CurrentAccount.hasArchivePassword){
            viewCoordinator.presentDialog(
                        appWindow,
                        "settingsview/components/RevokeDevicePasswordDialog.qml",
                        { deviceId: deviceId })
        } else {
            viewCoordinator.presentDialog(
                        appWindow,
                        "commoncomponents/SimpleMessageDialog.qml",
                        {
                            title: JamiStrings.removeDevice,
                            infoText: JamiStrings.sureToRemoveDevice,
                            buttonTitles: [JamiStrings.optionOk, JamiStrings.optionCancel],
                            buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue,
                                SimpleMessageDialog.ButtonStyle.TintedBlack],
                            buttonCallBacks: [
                                function() { DeviceItemListModel.revokeDevice(deviceId, "") }
                            ]
                        })
        }
    }

    width: parent.width

    Text {
        id: otherDevicesTitle

        visible: settingsListView.model.count > 0
        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: parent.width

        text: JamiStrings.linkedOtherDevices
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode : Text.WordWrap

        font.weight: Font.Medium
        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        font.kerning: true
    }

    JamiListView {
        id: settingsListView

        Layout.fillWidth: true
        Layout.preferredHeight: model.count * (70 + spacing)
        spacing: 10
        interactive: false

        model: SortFilterProxyModel {
            sourceModel: DeviceItemListModel
            sorters: [
                RoleSorter { roleName: "DeviceName"; sortOrder: Qt.DescendingOrder}
            ]

            filters: ValueFilter {
                roleName: "DeviceID"
                value: CurrentAccount.deviceId
                inverted: true
            }
        }

        delegate: DeviceItemDelegate {
            id: settingsListDelegate

            Layout.fillWidth: true
            implicitWidth: root.width
            height: 70
            deviceName: "Device name: " + DeviceName
            deviceId: DeviceID
            onBtnRemoveDeviceClicked: removeDeviceSlot(index)
        }

    }

    Text {
        id: linkedDevicesDescription

        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: parent.width
        visible: (CurrentAccount.managerUri === "" && CurrentAccount.enabled)

        text: JamiStrings.linkedAccountDescription
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode : Text.WordWrap

        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        font.kerning: true
        lineHeight: JamiTheme.wizardViewTextLineHeight
    }

    MaterialButton {
        id: linkDevPushButton

        TextMetrics{
            id: linkDevPushButtonTextSize
            font.weight: Font.Bold
            font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
            text: linkDevPushButton.text
        }

        Layout.alignment: Qt.AlignLeft
        preferredWidth: linkDevPushButtonTextSize.width + 2*JamiTheme.buttontextWizzardPadding

        visible: CurrentAccount.managerUri === "" && CurrentAccount.enabled

        primary: true
        toolTipText: JamiStrings.tipLinkNewDevice
        text: JamiStrings.linkAnotherDevice

        onClicked: viewCoordinator.presentDialog(
                       appWindow,
                       "settingsview/components/LinkDeviceDialog.qml",
                       { deviceId: deviceId })
    }
}
