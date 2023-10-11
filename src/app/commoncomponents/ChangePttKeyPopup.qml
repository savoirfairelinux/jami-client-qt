/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

BaseModalDialog {
    id: pttPage

    property bool isSIP: false
    property string bestName: ""
    property string accountId: ""
    property int pressedKey: Qt.Key_unknown

    signal accepted
    signal choiceMade(int chosenKey)

    title: JamiStrings.changeKey





    popupContent: ColumnLayout {
        id: deleteAccountContentColumnLayout
        anchors.centerIn: parent
        spacing: JamiTheme.preferredMarginSize

        Component.onCompleted: keyItem.forceActiveFocus()
        Label {
            id: instructionLabel

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: JamiTheme.preferredDialogWidth - 4*JamiTheme.preferredMarginSize
            color: JamiTheme.textColor
            text: JamiStrings.assignmentIndication

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            wrapMode: Text.Wrap
        }

        Label {
            id: keyLabel
            Layout.alignment: Qt.AlignCenter

            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            text: ""
            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            background: Rectangle {
                 id: backgroundRect

                 anchors.centerIn: parent

                 width: keyLabel.width + 2 * JamiTheme.preferredMarginSize
                 height: keyLabel.height + JamiTheme.preferredMarginSize
                 color: JamiTheme.lightGrey_
                 border.color: JamiTheme.darkGreyColor
                 radius: 4
            }

        }

        MaterialButton {
            id: btnAssign

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: JamiTheme.preferredMarginSize

            preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
            buttontextHeightMargin: JamiTheme.buttontextHeightMargin

            color: JamiTheme.buttonTintedBlack
            hoveredColor: JamiTheme.buttonTintedBlackHovered
            pressedColor: JamiTheme.buttonTintedBlackPressed
            secondary: true

            text: JamiStrings.assign
            autoAccelerator: true

            onClicked: {
                if (!(pressedKey === Qt.Key_unknown)){
                    pttListener.setPttKey(pressedKey);
                    choiceMade(pressedKey);
                    close();
                }

            }
        }



        Item {
            id: keyItem

//            function handleKeyPressed(event){
//                keyLabel.text = pttListener.keyToString(event.key);
//                pressedKey = event.key;
//            }

            Keys.onPressed: (event)=>{
                keyLabel.text = pttListener.keyToString(event.key);
                pressedKey = event.key;
            }
        }
    }


}
