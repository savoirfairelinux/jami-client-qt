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

    width: parent.width
    property bool inverted: false
    property string title
    property bool isCurrent: true

    visible: settingsListView.model.count > 0

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
                        }],
                    "buttonRoles": [DialogButtonBox.AcceptRole, DialogButtonBox.RejectRole]
                });
        }
    }

    Text {
        id: title

        Layout.alignment: Qt.AlignLeft
        Layout.preferredWidth: parent.width

        text: root.title
        color: JamiTheme.textColor
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap

        font.weight: Font.Medium
        font.pixelSize: JamiTheme.settingsDescriptionPixelSize
        font.kerning: true
    }

    ListView {
        id: settingsListView

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(model.count, 3) * (70 + spacing)
        Layout.maximumHeight: Layout.preferredHeight

        spacing: JamiTheme.settingsListViewsSpacing
        interactive: !isCurrent

        Component.onCompleted: {
            positionViewAtIndex(0, ListView.Beginning);
        }

        model: SortFilterProxyModel {
            sourceModel: DeviceItemListModel
            sorters: [
                RoleSorter {
                    roleName: "DeviceName"
                    sortOrder: Qt.DescendingOrder
                }
            ]

            filters: ValueFilter {
                roleName: "DeviceID"
                value: CurrentAccount.deviceId
                inverted: root.inverted
            }
        }

        delegate: DeviceItemDelegate {
            id: settingsListDelegate

            Layout.fillWidth: true
            implicitWidth: root.width
            height: 70
            deviceName: root.isCurrent ? DeviceName : JamiStrings.deviceName + " " + DeviceName
            deviceId: DeviceID
            onBtnRemoveDeviceClicked: removeDeviceSlot(index)
            isCurrent: root.isCurrent

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
