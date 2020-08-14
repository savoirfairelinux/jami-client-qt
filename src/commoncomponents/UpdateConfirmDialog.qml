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

    enum UpdateType{Release,Beta}

    property int installType: UpdateConfirmDialog.Release

    onOpened: {

    }

    onVisibleChanged: {
        if(!visible){
            reject()
        }
    }

    visible: false
    title: switch (installType) {
           case UpdateConfirmDialog.Beta:
               return qsTr("Jami Beta Installation")
           default:
               return qsTr("Update to lastest version")
           }

    anchors.centerIn: parent.Center
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    contentItem: Rectangle{
        implicitWidth: 450
        implicitHeight: 200

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

                Item{
                    Layout.fillWidth: true
                    Layout.minimumWidth: 20
                    Layout.preferredWidth: 20

                    Layout.fillHeight: true
                    Layout.minimumHeight: 40
                }

                Label{
                    id: labelDeletion

                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumHeight: 40

                    font.pointSize: 10
                    font.kerning: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    text:switch (installType) {
                         case UpdateConfirmDialog.Beta:
                             return qsTr("Install the latest Beta version?")
                         default:
                             return qsTr("New version detected, do you want to update now?")
                    }
                }

                Item{
                    Layout.fillWidth: true
                    Layout.minimumWidth: 20
                    Layout.preferredWidth: 20

                    Layout.fillHeight: true
                    Layout.minimumHeight: 40
                }

                RowLayout{
                    spacing: 0

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true

                    Item{
                        Layout.fillWidth: true
                        Layout.minimumWidth: 20
                        Layout.preferredWidth: 20

                        Layout.fillHeight: true
                        Layout.minimumHeight: 10
                    }

                    Label{
                        id: labelWarning

                        Layout.alignment: Qt.AlignHCenter
                        Layout.minimumHeight: 40

                        font.pointSize: 10
                        font.kerning: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        text:switch (installType) {
                             case UpdateConfirmDialog.Beta:
                                 return qsTr("Install the latest Beta version?")
                             default:
                                 return qsTr("New version detected, do you want to update now?")
                        }

                        color: "darkorange"
                    }

                    Item{
                        Layout.fillWidth: true
                        Layout.minimumWidth: 20
                        Layout.preferredWidth: 20

                        Layout.fillHeight: true
                        Layout.minimumHeight: 10}
                }

                Item{
                    Layout.fillWidth: true
                    Layout.minimumWidth: 20
                    Layout.preferredWidth: 20

                    Layout.fillHeight: true
                    Layout.minimumHeight: 40
                }

                RowLayout{
                    spacing: 0

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true

                    Item{
                        Layout.fillWidth: true
                        Layout.minimumWidth: 40

                        Layout.maximumHeight: 20
                        Layout.preferredHeight: 20
                        Layout.minimumHeight: 20
                    }

                    HoverableButtonTextItem{
                        id: updateCancelBtn

                        Layout.maximumWidth: 130
                        Layout.preferredWidth: 130
                        Layout.minimumWidth: 130

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

                    Item{
                        Layout.fillWidth: true
                        Layout.minimumWidth: 40

                        Layout.maximumHeight: 20
                        Layout.preferredHeight: 20
                        Layout.minimumHeight: 20
                    }

                    HoverableRadiusButton{
                        id: updateAcceptBtn

                        Layout.maximumWidth: 130
                        Layout.preferredWidth: 130
                        Layout.minimumWidth: 130

                        Layout.maximumHeight: 30
                        Layout.preferredHeight: 30
                        Layout.minimumHeight: 30

                        radius: height /2

                        text: qsTr("Install")
                        font.pointSize: 10
                        font.kerning: true

                        onClicked: {
                            accept()
                        }
                    }

                    Item{
                        Layout.fillWidth: true
                        Layout.minimumWidth: 40

                        Layout.maximumHeight: 20
                        Layout.preferredHeight: 20
                        Layout.minimumHeight: 20
                    }
                }

                Item{
                    Layout.fillWidth: true
                    Layout.minimumWidth: 20
                    Layout.preferredWidth: 20

                    Layout.maximumHeight: 20
                    Layout.preferredHeight: 20
                    Layout.minimumHeight: 20
                }
            }
        }
    }
}
