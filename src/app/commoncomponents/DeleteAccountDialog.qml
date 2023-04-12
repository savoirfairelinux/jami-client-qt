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
    id: root
    property string accountId: ""
    property string bestName: ""
    property bool isSIP: false

    height: Math.min(appWindow.height - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogHeight)
    title: JamiStrings.deleteAccount
    width: Math.min(appWindow.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.preferredDialogWidth)

    signal accepted

    popupContent: ColumnLayout {
        id: deleteAccountContentColumnLayout
        Label {
            id: labelDeletion
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: deleteAccountContentColumnLayout.width - JamiTheme.preferredMarginSize * 2
            color: JamiTheme.textColor
            font.kerning: true
            font.pointSize: JamiTheme.textFontSize
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.confirmDeleteQuestion
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        Label {
            id: labelBestId
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: deleteAccountContentColumnLayout.width - JamiTheme.preferredMarginSize * 2
            color: JamiTheme.textColor
            font.bold: true
            font.kerning: true
            font.pointSize: JamiTheme.textFontSize
            horizontalAlignment: Text.AlignHCenter
            text: bestName
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        Label {
            id: labelAccountHash
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: deleteAccountContentColumnLayout.width - JamiTheme.preferredMarginSize * 2
            color: JamiTheme.textColor
            font.kerning: true
            font.pointSize: JamiTheme.textFontSize
            horizontalAlignment: Text.AlignHCenter
            text: accountId
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        Label {
            id: labelWarning
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: deleteAccountContentColumnLayout.width - JamiTheme.preferredMarginSize * 2
            color: JamiTheme.redColor
            font.kerning: true
            font.pointSize: JamiTheme.textFontSize
            horizontalAlignment: Text.AlignHCenter
            text: JamiStrings.deleteAccountInfos
            verticalAlignment: Text.AlignVCenter
            visible: !isSIP
            wrapMode: Text.Wrap
        }
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            spacing: 16

            MaterialButton {
                id: btnDelete
                Layout.alignment: Qt.AlignHCenter
                autoAccelerator: true
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                color: JamiTheme.buttonTintedRed
                hoveredColor: JamiTheme.buttonTintedRedHovered
                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                pressedColor: JamiTheme.buttonTintedRedPressed
                secondary: true
                text: JamiStrings.optionDelete

                onClicked: {
                    btnDelete.enabled = false;
                    busyInd.running = true;
                    AccountAdapter.deleteCurrentAccount();
                    close();
                    accepted();
                }

                Connections {
                    target: root

                    function onClosed() {
                        btnDelete.enabled = true;
                    }
                }
            }
            BusyIndicator {
                id: busyInd
                running: false

                Connections {
                    target: root

                    function onClosed() {
                        busyInd.running = false;
                    }
                }
            }
            MaterialButton {
                id: btnCancel
                Layout.alignment: Qt.AlignHCenter
                autoAccelerator: true
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true
                text: JamiStrings.optionCancel

                onClicked: close()
            }
        }
    }
}
