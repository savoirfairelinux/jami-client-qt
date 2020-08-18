/**
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Aline Gondim Santos   <aline.gondimsantos@savoirfairelinux.com>
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
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import Qt.labs.platform 1.1
import QtGraphicalEffects 1.14
import net.jami.Models 1.0
import "../../commoncomponents"

Rectangle {
    id: editPreferenceViewRect

    enum Type {
        LIST,
        DEFAULT
    }

    signal setPreference

    property string preferenceKey: ""
    property string preferenceNewValue: ""

    property int size: 0

    visible: false

    function updateValuesDisplayed(show){
        // settings
        // getSize(pluginId, show)
        // preferenceItemListModel.pluginId = pluginId
        // preferenceItemListModel.reset()
    }

    function getSize(pluginId, show){
        size = 50 * 1
        if (visible) {
            height = 200 + size
            //pluginPreferenceView.height = size
        } else {
            height = 0
        }
    }

    // EditListPreferenceModel { //< will exist a differente model for each different type of preference
    //     id: editListPreferenceModel
    // }

    Layout.fillHeight: true
    Layout.fillWidth: true

    ColumnLayout {
        spacing: 6
        Layout.fillHeight: true
        Layout.maximumWidth: 580
        Layout.preferredWidth: 580
        Layout.minimumWidth: 580

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.minimumHeight: 25
            Layout.preferredHeight: 25
            Layout.maximumHeight: 25

            text: qsTr("preferences")
            font.pointSize: 13
            font.kerning: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // ListViewJami {
        //     id: pluginPreferenceView
            
        //     border.color: "white"
        //     color: "white"

        //     Layout.minimumWidth: 320
        //     Layout.preferredWidth: 320
        //     Layout.maximumWidth: 320

        //     Layout.minimumHeight: 0
        //     Layout.preferredHeight: height
        //     Layout.maximumHeight: 1000

        //     model: preferenceItemListModel

        //     delegate: PreferenceItemDelegate{
        //         id: preferenceItemDelegate

        //         width: pluginPreferenceView.width
        //         height: 50

        //         preferenceKey : PreferenceKey
        //         preferenceName: PreferenceName
        //         preferenceSummary: PreferenceSummary
        //         preferenceType: PreferenceType
        //         preferenceDefaultValue: PreferenceDefaultValue
        //         preferenceEntries: PreferenceEntries
        //         preferenceEntryValues: PreferenceEntryValues

        //         onClicked: {
        //             pluginPreferenceView.currentIndex = index
        //         }
        //         onBtnPreferenceClicked: {
        //             console.log("edit preference ", preferenceName)
        //             console.log("preference type ", preferenceType)
        //             console.log("preference entry values ", preferenceEntryValues.length)
        //             updateAndShowEditPreferenceSlot(preferenceType, preferenceName, preferenceEntryValues)
        //         }
        //     }
        // }
        // RowLayout {
        //     spacing: 6
        //     Layout.fillWidth: true
        //     Layout.topMargin: 10
        //     Layout.maximumHeight: 30
        //     Layout.preferredHeight: 30
        //     Layout.minimumHeight: 30

            // HoverableRadiusButton {
            //     //id: btnChangePreferenceConfirm
            //     visible : currentType === PreferenceDialog.LIST
            //     Layout.maximumWidth: 130
            //     Layout.preferredWidth: 130
            //     Layout.minimumWidth: 130

            //     Layout.minimumHeight: 30
            //     Layout.preferredHeight: 30
            //     Layout.maximumHeight: 30

            //     text: qsTr("Confirm")
            //     font.pointSize: 10
            //     font.kerning: true

            //     radius: height / 2

            //     onClicked: {
            //     }
            // }

        //     HoverableButtonTextItem {
                //     id: btnChangePreferenceCancel
                //     visible : currentType === PreferenceDialog.LIST
                //     Layout.maximumWidth: 130
                //     Layout.preferredWidth: 130
                //     Layout.minimumWidth: 130

                //     Layout.minimumHeight: 30
                //     Layout.preferredHeight: 30
                //     Layout.maximumHeight: 30

                //     backgroundColor: "red"
                //     onEnterColor: Qt.rgba(150 / 256, 0, 0, 0.7)
                //     onDisabledBackgroundColor: Qt.rgba(
                //                                 255 / 256,
                //                                 0, 0, 0.8)
                //     onPressColor: backgroundColor
                //     textColor: "white"

                //     text: qsTr("Cancel")
                //     font.pointSize: 10
                //     font.kerning: true

                //     radius: height / 2

                //     onClicked: {
                //         //preferenceDialog.reject()
                //     }
                // }
        // }
    }
}
