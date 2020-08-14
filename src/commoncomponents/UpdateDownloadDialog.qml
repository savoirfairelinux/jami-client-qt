/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Styles 1.4
import net.jami.Models 1.0

Dialog {
    id: updateConfirmDialog

    property real valueIn : 0.0
    property real maximum: -1
    property string textOfLabel: qsTr("Download Process")

    function slotDownloadProgress(bytesReceived, bytesTotal){
        if(bytesTotal < 0){
            console.log("Download File Size is Unknown")
            maximum = 0
            valueIn = 0
            textOfLabel = qsTr("0, File Size is Unknown")
            return
        }
        maximum = bytesTotal
        valueIn = bytesReceived

        textOfLabel = ClientWrapper.utilsAdaptor.humanFileSize(bytesReceived) + " / " + ClientWrapper.utilsAdaptor.humanFileSize(bytesTotal)
    }

    onOpened: {

    }

    onVisibleChanged: {
        if(!visible){
            reject()
        }
    }

    visible: false
    closePolicy: Popup.NoAutoClose
    title: qsTr("Download Process")

    modal: true

    anchors.centerIn: parent.Center
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    contentItem: Rectangle{
        implicitWidth: 300
        implicitHeight: 124

        ColumnLayout{
            anchors.fill: parent
            spacing: 0

            Layout.alignment: Qt.AlignCenter

            ColumnLayout{
                spacing: 7

                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 11
                Layout.bottomMargin: 11
                Layout.leftMargin: 11
                Layout.rightMargin: 11

                ColumnLayout{
                    spacing: 7

                    Layout.fillWidth: true

                    Label{
                        id: statusEdit

                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.minimumHeight: 19

                        font.pointSize: 9
                        font.kerning: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        text: textOfLabel
                    }

                    ProgressBar{
                        id: progressBar

                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true

                        indeterminate: false

                        from: 0.0
                        to: maximum
                        value: valueIn

                        background: Rectangle {
                                implicitWidth: 274
                                implicitHeight: 24
                                color: "#e6e6e6"
                                radius: 3
                            }

                            contentItem: Item {
                                implicitWidth: 274
                                implicitHeight: 24

                                Rectangle {
                                    width: progressBar.visualPosition * parent.width
                                    height: parent.height
                                    radius: 2
                                    color: "#17a81a"
                                }

                                Label{
                                    id: percentageLabel

                                    anchors.fill: parent
                                    font.pointSize: 9
                                    font.kerning: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.Wrap
                                    text: Math.round(progressBar.position * 100) + "%"
                                }
                            }
                    }
                }

                Item{
                    Layout.minimumWidth: 20
                    Layout.preferredWidth: 20
                    Layout.maximumWidth: 20

                    Layout.fillHeight: true
                    Layout.minimumHeight: 10
                }

                RowLayout{
                    spacing: 7

                    Layout.fillWidth: true

                    Item{
                        Layout.alignment: Qt.AlignLeft

                        Layout.fillWidth: true

                        Layout.minimumHeight: 20
                        Layout.preferredHeight: 20
                        Layout.maximumHeight: 20
                    }

                    HoverableButtonTextItem{
                        id: updateCancelButton

                        Layout.alignment: Qt.AlignRight
                        Layout.maximumWidth: 90
                        Layout.preferredWidth: 90
                        Layout.minimumWidth: 90

                        Layout.maximumHeight: 30
                        Layout.preferredHeight: 30
                        Layout.minimumHeight: 30

                        backgroundColor: "red"
                        onEnterColor: Qt.rgba(150 / 256, 0, 0, 0.7)
                        onDisabledBackgroundColor: Qt.rgba(
                                                       255 / 256,
                                                       0, 0, 0.8)
                        onPressColor: backgroundColor
                        textColor: "white"

                        radius: height /2

                        text: qsTr("Cancel")
                        font.pointSize: 10
                        font.kerning: true

                        onClicked: {
                            reject()
                        }
                    }
                }
            }
        }
    }
}
