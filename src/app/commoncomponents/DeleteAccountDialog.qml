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

    property bool isSIP: false
    property string bestName: ""
    property string accountId: ""

    signal accepted

    title: JamiStrings.deleteAccount

    popupContent: ColumnLayout {
        id: deleteAccountContentColumnLayout
        anchors.centerIn: parent

        Label {
            id: labelDeletion

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width - 4*JamiTheme.preferredMarginSize

            color: JamiTheme.textColor
            text: JamiStrings.confirmDeleteQuestion

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            wrapMode: Text.Wrap
        }

        Label {
            id: labelBestId

            Layout.alignment: Qt.AlignHCenter

            color: JamiTheme.textColor
            text: bestName

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true
            font.bold: true
            wrapMode: Text.Wrap
        }

        Label {
            id: labelAccountHash

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width - 4*JamiTheme.preferredMarginSize

            color: JamiTheme.textColor
            text: accountId

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Label {
            id: labelWarning

            visible: !isSIP

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width - 4*JamiTheme.preferredMarginSize

            text: JamiStrings.deleteAccountInfos

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap

            color: JamiTheme.redColor
        }

        RowLayout {
            spacing: 16
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            MaterialButton {
                id: btnDelete

                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                color: JamiTheme.buttonTintedRed
                hoveredColor: JamiTheme.buttonTintedRedHovered
                pressedColor: JamiTheme.buttonTintedRedPressed
                secondary: true
                autoAccelerator: true

                text: JamiStrings.optionDelete

                Connections {
                    target: root
                    function onClosed() {
                        btnDelete.enabled = true;
                    }
                }

                onClicked: {
                    btnDelete.enabled = false;
                    busyInd.running = true;
                    AccountAdapter.deleteCurrentAccount();
                    close();
                    accepted();
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
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true

                text: JamiStrings.optionCancel
                autoAccelerator: true

                onClicked: close()
            }
        }
    }
}
