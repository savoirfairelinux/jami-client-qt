/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

    property var buttonCallBacks: []
    property var buttonStyles: []
    property var buttonTitles: []
    property string infoText: ""
    property var innerContentData: []

    height: JamiTheme.preferredDialogHeight / 2 - JamiTheme.preferredMarginSize
    width: Math.max(JamiTheme.preferredDialogWidth, buttonTitles.length * (JamiTheme.preferredFieldWidth / 2 + JamiTheme.preferredMarginSize))

    function openWithParameters(title, info = "") {
        root.title = title;
        if (info !== "")
            root.infoText = info;
        open();
    }

    popupContent: ColumnLayout {
        Label {
            id: infoTextLabel
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: implicitHeight
            Layout.preferredWidth: JamiTheme.preferredDialogWidth - JamiTheme.preferredMarginSize
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.menuFontSize - 2
            horizontalAlignment: Text.AlignHCenter
            text: infoText
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        Item {
            id: innerContent
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            Layout.topMargin: JamiTheme.preferredMarginSize / 2
            data: innerContentData
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.bottomMargin: JamiTheme.preferredMarginSize
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            spacing: JamiTheme.preferredMarginSize

            Repeater {
                model: buttonTitles.length

                MaterialButton {
                    Layout.alignment: Qt.AlignVCenter
                    autoAccelerator: true
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    color: {
                        switch (buttonStyles[modelData]) {
                        case SimpleMessageDialog.ButtonStyle.TintedBlue:
                            return JamiTheme.buttonTintedBlue;
                        case SimpleMessageDialog.ButtonStyle.TintedBlack:
                            return JamiTheme.buttonTintedBlack;
                        case SimpleMessageDialog.ButtonStyle.TintedRed:
                            return JamiTheme.buttonTintedRed;
                        }
                    }
                    hoveredColor: {
                        switch (buttonStyles[modelData]) {
                        case SimpleMessageDialog.ButtonStyle.TintedBlue:
                            return JamiTheme.buttonTintedBlueHovered;
                        case SimpleMessageDialog.ButtonStyle.TintedBlack:
                            return JamiTheme.buttonTintedBlackHovered;
                        case SimpleMessageDialog.ButtonStyle.TintedRed:
                            return JamiTheme.buttonTintedRedHovered;
                        }
                    }
                    preferredWidth: JamiTheme.preferredFieldWidth / 2
                    pressedColor: {
                        switch (buttonStyles[modelData]) {
                        case SimpleMessageDialog.ButtonStyle.TintedBlue:
                            return JamiTheme.buttonTintedBluePressed;
                        case SimpleMessageDialog.ButtonStyle.TintedBlack:
                            return JamiTheme.buttonTintedBlackPressed;
                        case SimpleMessageDialog.ButtonStyle.TintedRed:
                            return JamiTheme.buttonTintedRedPressed;
                        }
                    }
                    secondary: true
                    text: buttonTitles[modelData]

                    onClicked: {
                        if (buttonCallBacks[modelData])
                            buttonCallBacks[modelData]();
                        close();
                    }
                }
            }
        }
    }
}
