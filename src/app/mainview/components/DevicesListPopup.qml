/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
    height: 320
    width: 488

    popupContent: Rectangle {
        id: rect
        color: JamiTheme.transparentColor
        width: root.width

        PushButton {
            id: btnCancel
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 10
            imageColor: "grey"
            normalColor: "transparent"
            source: JamiResources.round_close_24dp_svg

            onClicked: {
                close();
            }
        }
        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: JamiTheme.preferredMarginSize
            spacing: JamiTheme.preferredMarginSize

            Label {
                id: informativeLabel
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.topMargin: 26
                color: JamiTheme.primaryForegroundColor
                horizontalAlignment: Text.AlignHCenter
                text: JamiStrings.chooseHoster
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            JamiListView {
                id: devicesListView
                Layout.fillWidth: true
                Layout.preferredHeight: 160

                delegate: ItemDelegate {
                    id: item
                    property string deviceId: DeviceID
                    property string deviceName: DeviceName
                    property bool isCurrent: DeviceName

                    height: 70
                    highlighted: ListView.isCurrentItem
                    implicitWidth: devicesListView.width
                    width: devicesListView.width

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            devicesListView.currentIndex = index;
                        }
                    }
                    RowLayout {
                        anchors.fill: item

                        Image {
                            id: deviceImage
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: JamiTheme.preferredMarginSize
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: 24
                            source: JamiResources.baseline_desktop_windows_24dp_svg

                            layer {
                                enabled: true

                                effect: ColorOverlay {
                                    color: JamiTheme.textColor
                                }
                            }
                        }
                        ColumnLayout {
                            id: deviceInfoColumnLayout
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.leftMargin: JamiTheme.preferredMarginSize

                            Text {
                                id: labelDeviceName
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.fillWidth: true
                                color: JamiTheme.textColor
                                elide: Text.ElideRight
                                text: deviceName
                            }
                            Text {
                                id: labelDeviceId
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.fillWidth: true
                                color: JamiTheme.textColor
                                elide: Text.ElideRight
                                text: deviceId === "" ? qsTr("Device Id") : deviceId
                            }
                        }
                    }
                    CustomBorder {
                        bBorderwidth: 2
                        borderColor: JamiTheme.selectedColor
                        commonBorder: false
                        lBorderwidth: 0
                        rBorderwidth: 0
                        tBorderwidth: 0
                    }

                    background: Rectangle {
                        color: highlighted ? JamiTheme.selectedColor : JamiTheme.editBackgroundColor
                    }
                }
                model: SortFilterProxyModel {
                    sourceModel: DeviceItemListModel

                    sorters: [
                        RoleSorter {
                            roleName: "IsCurrent"
                            sortOrder: Qt.DescendingOrder
                        },
                        StringSorter {
                            caseSensitivity: Qt.CaseInsensitive
                            roleName: "DeviceName"
                        }
                    ]
                }
            }
            RowLayout {
                Layout.preferredWidth: parent.width
                spacing: JamiTheme.preferredMarginSize

                MaterialButton {
                    id: chooseBtn
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    enabled: devicesListView.currentItem
                    preferredWidth: chooseBtnTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
                    primary: true
                    text: JamiStrings.chooseThisDevice
                    toolTipText: JamiStrings.chooseThisDevice

                    onClicked: {
                        CurrentConversation.setInfo("rdvAccount", CurrentAccount.uri);
                        CurrentConversation.setInfo("rdvDevice", devicesListView.currentItem.deviceId);
                        close();
                    }

                    TextMetrics {
                        id: chooseBtnTextSize
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.weight: Font.Bold
                        text: chooseBtn.text
                    }
                }
                MaterialButton {
                    id: rmDeviceBtn
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    enabled: devicesListView.currentItem
                    preferredWidth: rmDeviceBtnTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
                    primary: true
                    text: JamiStrings.removeCurrentDevice
                    toolTipText: JamiStrings.removeCurrentDevice

                    onClicked: {
                        CurrentConversation.setInfo("rdvAccount", "");
                        CurrentConversation.setInfo("rdvDevice", "");
                        close();
                    }

                    TextMetrics {
                        id: rmDeviceBtnTextSize
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.weight: Font.Bold
                        text: rmDeviceBtn.text
                    }
                }
            }
        }
    }
}
