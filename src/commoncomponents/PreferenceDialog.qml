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
import QtQuick.Dialogs 1.3

Dialog {
    id: preferenceDialog
    
    enum Type {
        LIST,
        DEFAULT
    }
    property int currentType : PreferenceDialog.DEFAULT

    function openDialog(){
        preferenceDialog.open()
    }

    contentItem: Rectangle{
        id: contentItemListRect
        implicitWidth: 440
        implicitHeight: 270

        ColumnLayout {
            anchors.fill: parent
            spacing: 7
            Layout.alignment: Qt.AlignHCenter

            RowLayout {
                spacing: 7

                Layout.bottomMargin: 11
                Layout.fillWidth: true

                Layout.leftMargin: 30
                Layout.rightMargin: 30
            for (int i = 0, i < 2, i++) {
                HoverableRadiusButton {
                    //id: btnChangePreferenceConfirm
                    visible : currentType === PreferenceDialog.LIST
                    Layout.maximumWidth: 130
                    Layout.preferredWidth: 130
                    Layout.minimumWidth: 130

                    Layout.minimumHeight: 30
                    Layout.preferredHeight: 30
                    Layout.maximumHeight: 30

                    text: qsTr("Confirm")
                    font.pointSize: 10
                    font.kerning: true

                    radius: height / 2

                    onClicked: {
                    }
                }
            }

                HoverableButtonTextItem {
                    id: btnChangePreferenceCancel
                    visible : currentType === PreferenceDialog.LIST
                    Layout.maximumWidth: 130
                    Layout.preferredWidth: 130
                    Layout.minimumWidth: 130

                    Layout.minimumHeight: 30
                    Layout.preferredHeight: 30
                    Layout.maximumHeight: 30

                    backgroundColor: "red"
                    onEnterColor: Qt.rgba(150 / 256, 0, 0, 0.7)
                    onDisabledBackgroundColor: Qt.rgba(
                                                255 / 256,
                                                0, 0, 0.8)
                    onPressColor: backgroundColor
                    textColor: "white"

                    text: qsTr("Cancel")
                    font.pointSize: 10
                    font.kerning: true

                    radius: height / 2

                    onClicked: {
                        //preferenceDialog.reject()
                    }
                }
            }
        }
    }
}
