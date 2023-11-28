/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.

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

    property string bestName: ""
    property string accountId: ""
    property int pressedKey: Qt.Key_unknown

    closeButtonVisible: false

    button1.text: JamiStrings.assign
    button2.text: JamiStrings.cancel

    button1Role: DialogButtonBox.ApplyRole
    button2Role: DialogButtonBox.RejectRole
    button1.onClicked: {
        if (!(pressedKey === Qt.Key_unknown)){
            PttListener.setPttKey(pressedKey);
            choiceMade(pressedKey);
        }
        close();
    }
    button2.onClicked: close();

    signal accepted
    signal choiceMade(int chosenKey)

    title: JamiStrings.changeShortcut

    popupContent: ColumnLayout {
        id: deleteAccountContentColumnLayout
        anchors.centerIn: parent
        spacing: 20

        Component.onCompleted: keyItem.forceActiveFocus()
        Label {
            id: instructionLabel

            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: JamiTheme.preferredDialogWidth - 4*JamiTheme.preferredMarginSize
            color: JamiTheme.textColor
            text: JamiStrings.assignmentIndication
            lineHeight: 1.3

            verticalAlignment: Text.AlignVCenter

            font.pointSize: JamiTheme.settingsFontSize
            font.kerning: true

            wrapMode: Text.Wrap
        }

        Label {
            id: keyLabel
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: JamiTheme.preferredMarginSize

            color: JamiTheme.blackColor
            wrapMode: Text.WordWrap
            text: ""
            font.pointSize: JamiTheme.textFontSize
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

        Item {
            id: keyItem

            Keys.onPressed: (event)=>{
                keyLabel.text = PttListener.keyToString(event.key);
                pressedKey = event.key;
            }
        }
    }
}
