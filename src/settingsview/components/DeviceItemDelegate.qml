/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.14
import QtQuick.Controls.Styles 1.4
import net.jami.Models 1.0

import "../../commoncomponents"

ItemDelegate {
    id: deviceItemDelegate

    property string deviceName : ""
    property string deviceId : ""
    property bool isCurrent : false

    property bool editable : false

    signal btnRemoveDeviceClicked

    function btnEditDeviceEnter() {
        btnEditDevice.enterBtn()
    }

    function btnEditDeviceExit() {
        btnEditDevice.exitBtn()
    }

    function btnEditPress() {
        btnEditDevice.pressBtn()
    }

    function btnEditRelease() {
        btnEditDevice.releaseBtn()
    }

    function toggleEditable() {
        editable = !editable
        if(editable){
            ClientWrapper.settingsAdaptor.setDeviceName(elidedTextDeviceName.text)
        }
    }

    highlighted: ListView.isCurrentItem

    RowLayout {
        anchors.fill: parent

        spacing: 8

        Image {
            Layout.leftMargin: 16
            Layout.alignment: Qt.AlignVCenter

            Layout.minimumWidth: 24
            Layout.preferredWidth: 24
            Layout.maximumWidth: 24

            Layout.minimumHeight: 24
            Layout.preferredHeight: 24
            Layout.maximumHeight: 24
            source: "qrc:/images/icons/baseline-desktop_windows-24px.svg"
        }

        ColumnLayout {
            //Layout.fillWidth: true
            //Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft

            RowLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                Layout.topMargin: 16
                Layout.leftMargin: 16
                Layout.fillWidth: true

                InfoLineEdit {
                    id: editDeviceName

                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: 120

                    Layout.minimumHeight: 24
                    Layout.preferredHeight: 24
                    Layout.maximumHeight: 24

                    //Layout.leftMargin: 16
                    Layout.alignment: Qt.AlignLeft
                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter

                    readOnly: !editable

                    text: elidedTextDeviceName.elidedText
                }

                TextMetrics {
                    id: elidedTextDeviceName

                    elide: Text.ElideRight
                    elideWidth: deviceItemDelegate.width - 40

                    text: "fhsfk jghdsgdfkjas hdfkjhgkjdash gkjshgkl" //deviceName
                }



                Label {
                    id: labelThisDevice
                    Layout.minimumHeight: 24
                    Layout.preferredHeight: 24
                    Layout.maximumHeight: 24
                    //Layout.minimumWidth: 80
                    //Layout.minimumHeight: 30
                    Layout.alignment: Qt.AlignRight
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter

                    visible: isCurrent

                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                    font.italic: true
                    color: "green"
                    text:  qsTr("this device")
                }
            }

            Label {
                id: labelDeviceId

                Layout.minimumWidth: 72
                Layout.minimumHeight: 32

                font.pointSize: 8
                font.kerning: true
                text: elidedTextDeviceId.elidedText //deviceId === "" ? qsTr("Device Id") : deviceId
            }

            TextMetrics {
                id: elidedTextDeviceId

                elide: Text.ElideRight
                elideWidth: deviceItemDelegate.width - 40

                text: deviceId === "" ? qsTr("Device Id") : deviceId
            }

        }

        HoverableRadiusButton {
            id: btnEditDevice

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.rightMargin: 16

            Layout.minimumWidth: 24
            Layout.preferredWidth: 24
            Layout.maximumWidth: 24

            Layout.minimumHeight: 24
            Layout.preferredHeight: 24
            Layout.maximumHeight: 24

            buttonImageHeight: height
            buttonImageWidth: height

            source: {
                if(isCurrent) {
                    var path = editable ? "qrc:/images/icons/round-edit-24px.svg" : "qrc:/images/icons/round-save_alt-24px.svg"
                    return path
                } else {
                    return "qrc:/images/icons/round-remove_circle-24px.svg"
                }
            }

            ToolTip.visible: isHovering
            ToolTip.text: {
                if(isCurrent) {
                    if(editable){
                        return qsTr("Edit Device Name")
                    } else {
                        return qsTr("Save new device name")
                    }
                } else {
                    return qsTr("Unlink Device From Account")
                }
            }

            onClicked: {
                if(isCurrent) {
                    toggleEditable()
                } else {
                    btnRemoveDeviceClicked()
                }
            }
        }
    }
}
