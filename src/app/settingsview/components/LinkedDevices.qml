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

    Label {
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        text: JamiStrings.linkedDevices
        color: JamiTheme.textColor

        font.pointSize: JamiTheme.headerFontSize
        font.kerning: true
    }

    JamiListView {
        id: settingsListView

        Layout.fillWidth: true
        Layout.preferredHeight: 160

        model: SortFilterProxyModel {
            sourceModel: DeviceItemListModel
            sorters: [
                RoleSorter { roleName: "IsCurrent"; sortOrder: Qt.DescendingOrder },
                StringSorter {
                    roleName: "DeviceName"
                    caseSensitivity: Qt.CaseInsensitive
                }
            ]
        }

        delegate: DeviceItemDelegate {
            id: settingsListDelegate

            implicitWidth: settingsListView.width
            width: settingsListView.width
            height: 70

            deviceName: DeviceName
            deviceId: DeviceID
            isCurrent: IsCurrent

            onBtnRemoveDeviceClicked: removeDeviceSlot(index)
        }
    }

    MaterialButton {
        id: linkDevPushButton

        Layout.alignment: Qt.AlignCenter

        preferredWidth: JamiTheme.preferredFieldWidth

        visible: CurrentAccount.managerUri === "" && CurrentAccount.enabled

        color: JamiTheme.buttonTintedBlack
        hoveredColor: JamiTheme.buttonTintedBlackHovered
        pressedColor: JamiTheme.buttonTintedBlackPressed
        secondary: true
        toolTipText: JamiStrings.tipLinkNewDevice

        iconSource: JamiResources.round_add_24dp_svg

        text: JamiStrings.linkAnotherDevice

        onClicked: viewCoordinator.presentDialog(
                                   appWindow,
                                   "settingsview/components/LinkDeviceDialog.qml",
                                   { deviceId: deviceId })
    }
}
