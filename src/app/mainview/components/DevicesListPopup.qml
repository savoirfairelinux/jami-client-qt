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

    width: 488
    height: 320

    popupContent: Rectangle {
        id: rect

        color: JamiTheme.transparentColor
        width: root.width


        PushButton {
            id: btnCancel
            imageColor: "grey"
            normalColor: "transparent"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.rightMargin: 10
            source: JamiResources.round_close_24dp_svg
            onClicked: { close(); }
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
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: JamiStrings.chooseHoster
                color: JamiTheme.primaryForegroundColor
            }

            JamiListView {
                id: devicesListView

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

                delegate: ItemDelegate {
                    id: item

                    property string deviceName : DeviceName
                    property string deviceId : DeviceID
                    property bool isCurrent : DeviceName

                    implicitWidth: devicesListView.width
                    width: devicesListView.width
                    height: 70

                    highlighted: ListView.isCurrentItem

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            devicesListView.currentIndex = index
                        }
                    }

                    background: Rectangle {
                        color: highlighted? JamiTheme.selectedColor : JamiTheme.editBackgroundColor
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

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.leftMargin: JamiTheme.preferredMarginSize

                            Text {
                                id: labelDeviceName

                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.fillWidth: true

                                elide: Text.ElideRight
                                color: JamiTheme.textColor
                                text: deviceName
                            }

                            Text {
                                id: labelDeviceId

                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.fillWidth: true

                                elide: Text.ElideRight
                                color: JamiTheme.textColor
                                text: deviceId === "" ? qsTr("Device Id") : deviceId
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

            RowLayout {
                spacing: JamiTheme.preferredMarginSize
                Layout.preferredWidth: parent.width

                MaterialButton {
                    id: chooseBtn

                    TextMetrics{
                        id: chooseBtnTextSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.capitalization: Font.AllUppercase
                        text: chooseBtn.text
                    }

                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    primary: true
                    preferredWidth: chooseBtnTextSize.width + 2*JamiTheme.buttontextWizzardPadding
                    enabled: devicesListView.currentItem

                    text: JamiStrings.chooseThisDevice
                    toolTipText: JamiStrings.chooseThisDevice

                    onClicked: {
                        CurrentConversation.setInfo("rdvAccount", CurrentAccount.uri)
                        CurrentConversation.setInfo("rdvDevice", devicesListView.currentItem.deviceId)
                        close()
                    }
                }

                MaterialButton {
                    id: rmDeviceBtn

                    TextMetrics{
                        id: rmDeviceBtnTextSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.capitalization: Font.AllUppercase
                        text: rmDeviceBtn.text
                    }

                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    primary: true
                    preferredWidth: rmDeviceBtnTextSize.width + 2*JamiTheme.buttontextWizzardPadding
                    enabled: devicesListView.currentItem

                    text: JamiStrings.removeCurrentDevice
                    toolTipText: JamiStrings.removeCurrentDevice

                    onClicked: {
                        CurrentConversation.setInfo("rdvAccount", "")
                        CurrentConversation.setInfo("rdvDevice", "")
                        close()
                    }
                }
            }
        }
    }
}
