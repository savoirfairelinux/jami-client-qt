/*
 * Copyright (C) 2022-2025 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    property int preferredMargin: 15
    property bool success: true
    property string statusText: success ? JamiStrings.dictionaryDownloadSuccessfully : JamiStrings.downloadDictionaryFailed

    title: statusText
    width: 400
    height: 150
    visible: false

    Timer {
        id: timer
        interval: 2000
        repeat: false
        running: root.visible
        onTriggered: {
            root.visible = false;
            root.enabled = false;
        }
    }

    popupContent: ColumnLayout {
        id: popupContent
        anchors.fill: parent
        anchors.margins: preferredMargin
        spacing: 10

        Text {
            id: downloadText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            text: success ? JamiStrings.dictionaryDownloadSuccessfully : JamiStrings.downloadDictionaryFailed
            wrapMode: Text.WordWrap
            font.pixelSize: JamiTheme.infoBoxTitleFontSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor
        }

        Text {
            id: additionalInfo
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            text: success ?
                JamiStrings.dictionarySetAsCurrent :
                JamiStrings.checkInternetAndRetry
            wrapMode: Text.WordWrap
            font.pixelSize: JamiTheme.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor
            opacity: 0.8
        }
    }
}
