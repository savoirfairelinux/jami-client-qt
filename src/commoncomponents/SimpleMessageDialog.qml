/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

BaseDialog {
    id: root

    // TODO: make MaterialButton ButtonStyle

    property var buttonTitles: []
    property var buttonCallBacks: []
    property var buttonStyles: []
    property alias infoText: infoText.text
    property alias innerContentData: innerContent.data

    function openWithParameters(title, info) {
        root.title = title
        if (info !== undefined && info !== "")
            root.infoText = info
        open()
    }

    contentItem: Rectangle {
        id: container

        implicitWidth: Math.max(JamiTheme.preferredDialogWidth,
                                buttonTitles.length * (JamiTheme.preferredFieldWidth / 2
                                + JamiTheme.preferredMarginSize))
        implicitHeight: JamiTheme.preferredDialogHeight / 2 - JamiTheme.preferredMarginSize

        color: JamiTheme.secondaryBackgroundColor

        ColumnLayout {
            anchors.fill: parent

            Label {
                id: infoText

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: JamiTheme.preferredDialogWidth - JamiTheme.preferredMarginSize
                Layout.topMargin: JamiTheme.preferredMarginSize

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
                Layout.fillHeight: true
            }

            RowLayout {
                spacing: JamiTheme.preferredMarginSize

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                Repeater {
                    model: buttonTitles.length
                    MaterialButton {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: JamiTheme.preferredFieldWidth / 2
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight

                        color: {
                            switch(buttonStyles[modelData]) {
                            case 0:
                                return JamiTheme.buttonTintedBlue
                            case 1:
                                return JamiTheme.buttonTintedBlack
                            case 2:
                                return JamiTheme.buttonTintedRed
                            }
                        }
                        hoveredColor: {
                            switch(buttonStyles[modelData]) {
                            case 0:
                                return JamiTheme.buttonTintedBlueHovered
                            case 1:
                                return JamiTheme.buttonTintedBlackHovered
                            case 2:
                                return JamiTheme.buttonTintedRedHovered
                            }
                        }
                        pressedColor: {
                            switch(buttonStyles[modelData]) {
                            case 0:
                                return JamiTheme.buttonTintedBluePressed
                            case 1:
                                return JamiTheme.buttonTintedBlackPressed
                            case 2:
                                return JamiTheme.buttonTintedRedPressed
                            }
                        }
                        outlined: true

                        text: buttonTitles[modelData]

                        onClicked: {
                            if (buttonCallBacks[modelData])
                                buttonCallBacks[modelData]()
                            close()
                        }
                    }
                }
            }
        }
    }
}
