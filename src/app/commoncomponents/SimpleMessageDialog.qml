/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

BaseModalDialog {
    id: root

    // TODO: make MaterialButton ButtonStyle
    enum ButtonStyle {
        TintedBlue,
        TintedBlack,
        TintedRed
    }

    property var buttonTitles: []
    property var buttonCallBacks: []
    property var buttonStyles: []
    property string infoText: ""
    property var innerContentData: []
    property int buttonRoles: []

    function openWithParameters(title, info = "") {
        root.title = title;
        if (info !== "")
            root.infoText = info;
        open();
    }

    buttonsModel: [
        {
            text: buttonTitles[0],
            role: buttonRoles[0],
            onClicked: function() {
                if (buttonCallBacks[0])
                    buttonCallBacks[0]();
                close();
            }
        },
        {
            text: buttonTitles[1] ? buttonTitles[1] : "",
            role: buttonRoles[1],
            onClicked: function() {
                if (buttonCallBacks[1])
                    buttonCallBacks[1]();
                close();
            }
        }
    ]

    Component.onCompleted: {
        const button1 = buttons[0];
        for (var i = 0; i < buttonStyles.length; i++){
            switch (buttonStyles[i]) {
            case SimpleMessageDialog.ButtonStyle.TintedBlue:
                button1.color = JamiTheme.buttonTintedBlue;
                button1.hoveredColor = JamiTheme.buttonTintedBlueHovered;
                button1.pressedColor = JamiTheme.buttonTintedBluePressed;
                break;
            case SimpleMessageDialog.ButtonStyle.TintedBlack:
                button1.color = JamiTheme.buttonTintedBlack;
                button1.hoveredColor = JamiTheme.buttonTintedBlackHovered;
                button1.pressedColor = JamiTheme.buttonTintedBlackPressed;
                break;
            case SimpleMessageDialog.ButtonStyle.TintedRed:
                button1.color = JamiTheme.buttonTintedRed;
                button1.hoveredColor = JamiTheme.buttonTintedRedHovered;
                button1.pressedColor = JamiTheme.buttonTintedRedPressed;
                break;
            }
        }
    }

    popupContent: ColumnLayout {
        Label {
            id: infoTextLabel

            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: JamiTheme.preferredDialogWidth - JamiTheme.preferredMarginSize
            Layout.preferredHeight: implicitHeight

            text: infoText
            font.pointSize: JamiTheme.menuFontSize - 2
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor
        }

        Item {
            id: innerContent

            Layout.topMargin: JamiTheme.preferredMarginSize / 2
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height

            data: innerContentData
        }
    }
}
