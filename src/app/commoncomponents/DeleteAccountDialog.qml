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

    closeButtonVisible: false
    button1.text: JamiStrings.optionDelete
    button1Role: DialogButtonBox.DestructiveRole
    button1.onClicked: {
        button1.enabled = false;
        busyInd.running = true;
        AccountAdapter.deleteCurrentAccount();
        close();
        accepted();
    }
    button2.text: JamiStrings.optionCancel
    button2Role: DialogButtonBox.RejectRole
    button2.onClicked: close();

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

    popupContent: ColumnLayout {
        id: deleteAccountContentColumnLayout
        anchors.centerIn: parent

        Label {
            id: labelDeletion

            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width - 4*JamiTheme.preferredMarginSize

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
    }
}
