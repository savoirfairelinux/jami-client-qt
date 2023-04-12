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
    id: root
    property bool inverted: false
    property bool isCurrent: true
    property string title

    visible: settingsListView.model.count > 0
    width: parent.width

    function removeDeviceSlot(index) {
        var deviceId = settingsListView.model.data(settingsListView.model.index(index, 0), DeviceItemListModel.DeviceID);
        if (CurrentAccount.hasArchivePassword) {
            viewCoordinator.presentDialog(appWindow, "settingsview/components/RevokeDevicePasswordDialog.qml", {
                    "deviceId": deviceId
                });
        } else {
            viewCoordinator.presentDialog(appWindow, "commoncomponents/SimpleMessageDialog.qml", {
                    "title": JamiStrings.removeDevice,
                    "infoText": JamiStrings.sureToRemoveDevice,
                    "buttonTitles": [JamiStrings.optionOk, JamiStrings.optionCancel],
                    "buttonStyles": [SimpleMessageDialog.ButtonStyle.TintedBlue, SimpleMessageDialog.ButtonStyle.TintedBlack],
                    "buttonCallBacks": [function () {
                            DeviceItemListModel.revokeDevice(deviceId, "");
                        }]
                });
        }
    }

    Text {
        id: title
        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: parent.width
        color: JamiTheme.textColor
        font.kerning: true
        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignLeft
        text: root.title
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    JamiListView {
        id: settingsListView
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(model.count, 5) * (70 + spacing)
        interactive: !isCurrent
        spacing: JamiTheme.settingsListViewsSpacing

        delegate: DeviceItemDelegate {
            id: settingsListDelegate
            Layout.fillWidth: true
            deviceId: DeviceID
            deviceName: root.isCurrent ? DeviceName : "Device name: " + DeviceName
            height: 70
            implicitWidth: root.width
            isCurrent: root.isCurrent

            onBtnRemoveDeviceClicked: removeDeviceSlot(index)
        }
        model: SortFilterProxyModel {
            sourceModel: DeviceItemListModel

            filters: ValueFilter {
                inverted: root.inverted
                roleName: "DeviceID"
                value: CurrentAccount.deviceId
            }
            sorters: [
                RoleSorter {
                    roleName: "DeviceName"
                    sortOrder: Qt.DescendingOrder
                }
            ]
        }
    }
}
