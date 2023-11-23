/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

    title: "Oops!"

    button1.text: "Send"
    button1Role: DialogButtonBox.YesRole
    button1.onClicked: {
        crashReportClient.uploadLastReport();
        close();
        accepted();
    }
    button1.contentColorProvider: JamiTheme.deleteRedButton

    button2.text: JamiStrings.optionCancel
    button2Role: DialogButtonBox.RejectRole
    button2.onClicked: close();

    popupContent: ColumnLayout {
        id: sendReportLayout
        anchors.centerIn: parent
        spacing: 10

        Label {
            id: infoMessage
            text: "Are you sure you want to send a report?"
        }
    }
}
