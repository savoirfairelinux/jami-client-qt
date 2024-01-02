/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import Qt5Compat.GraphicalEffects
import SortFilterProxyModel 0.2
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    width: JamiTheme.secondaryDialogDimension

    property string currentDeviceId

    title: JamiStrings.defaultCallHost

    button1.text: JamiStrings.selectDevice
    button1Role: DialogButtonBox.AcceptRole
    button1.toolTipText: JamiStrings.selectThisDevice
    button1.enabled: false
    button1.onClicked : {
        CurrentConversation.setInfo("rdvAccount", CurrentAccount.uri);
        CurrentConversation.setInfo("rdvDevice", currentDeviceId);
        root.close();
    }

    button2.text: JamiStrings.removeDevice
    button2Role: DialogButtonBox.ResetRole
    button2.toolTipText: JamiStrings.removeCurrentDevice
    button2.enabled: CurrentConversation.rdvAccount !== ""
    button2.onClicked: {
        CurrentConversation.setInfo("rdvAccount", "");
        CurrentConversation.setInfo("rdvDevice", "");
        close();
    }

    popupContent: ColumnLayout {
            id: mainLayout

            anchors.centerIn: parent
            spacing: 10
            width: JamiTheme.preferredDialogWidth

            Label {
                id: informativeLabel

                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true

                wrapMode: Text.Wrap
                text: JamiStrings.selectHost
                color: JamiTheme.primaryForegroundColor
            }

            JamiListView {
                id: devicesListView

                Layout.fillWidth: true
                Layout.preferredHeight: 160

                model: SortFilterProxyModel {
                    sourceModel: DeviceItemListModel
                    sorters: [
                        RoleSorter {
                            roleName: "IsCurrent"
                            sortOrder: Qt.DescendingOrder
                        },
                        StringSorter {
                            roleName: "DeviceName"
                            caseSensitivity: Qt.CaseInsensitive
                        }
                    ]
                }

                delegate: ItemDelegate {
                    id: item

                    property string deviceName: DeviceName
                    property string deviceId: DeviceID
                    property bool isCurrent: DeviceName

                    implicitWidth: devicesListView.width
                    height: 70

                    highlighted: CurrentConversation.rdvDevice === deviceId

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (!highlighted){
                                devicesListView.currentIndex = index;
                                for (var i = 0; i < devicesListView.count; i++) {
                                    devicesListView.itemAtIndex(i).highlighted = false;
                                }
                                currentDeviceId = deviceId;
                                button1.enabled = true;
                            }
                            else {
                                devicesListView.currentIndex = -1;
                                button1.enabled = false;
                            }

                            item.highlighted = !item.highlighted;
                        }
                    }

                    background: Rectangle {
                        color: highlighted ? JamiTheme.selectedColor : JamiTheme.editBackgroundColor
                    }

                    RowLayout {
                        anchors.fill: item

                        Image {
                            id: deviceImage

                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.leftMargin: JamiTheme.preferredMarginSize

                            layer {
                                enabled: true
                                effect: ColorOverlay {
                                    color: JamiTheme.textColor
                                }
                            }
                            source: JamiResources.baseline_desktop_windows_24dp_svg
                        }

                        ColumnLayout {
                            id: deviceInfoColumnLayout

                            Layout.fillHeight: true
                            Layout.leftMargin: JamiTheme.preferredMarginSize

                            Text {
                                id: labelDeviceName

                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                                elide: Text.ElideRight
                                color: JamiTheme.textColor
                                text: deviceName
                            }

                            Text {
                                id: labelDeviceId

                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.preferredWidth: root.width - 200

                                elide: Text.ElideRight
                                color: JamiTheme.textColor
                                text: deviceId === "" ? JamiStrings.deviceId : deviceId
                            }
                        }
                    }

                    CustomBorder {
                        commonBorder: false
                        lBorderwidth: 0
                        rBorderwidth: 0
                        tBorderwidth: 0
                        bBorderwidth: 2
                        borderColor: JamiTheme.selectedColor
                    }
                }
            }
        }
}

