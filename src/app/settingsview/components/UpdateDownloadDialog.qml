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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import net.jami.Helpers 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

SimpleMessageDialog {
    id: downloadDialog
    property int bytesRead: 0
    property string hSizeRead: UtilsAdapter.humanFileSize(bytesRead)
    property string hTotalBytes: UtilsAdapter.humanFileSize(totalBytes)
    property alias progressBarValue: progressBar.value
    property int totalBytes: 0

    buttonCallBacks: [function () {
            UpdateManager.cancelUpdate();
        }]
    buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue]
    buttonTitles: [JamiStrings.optionCancel]
    infoText: JamiStrings.updateDownloading + " (%1 / %2)".arg(hSizeRead).arg(hTotalBytes)

    function setDownloadProgress(bytesRead, totalBytes) {
        downloadDialog.bytesRead = bytesRead;
        downloadDialog.totalBytes = totalBytes;
    }

    onVisibleChanged: {
        if (!visible)
            UpdateManager.cancelUpdate();
    }

    Connections {
        target: UpdateManager

        function onUpdateDownloadErrorOccurred(error) {
            downloadDialog.close();
        }
        function onUpdateDownloadFinished() {
            downloadDialog.close();
        }
        function onUpdateDownloadProgressChanged(bytesRead, totalBytes) {
            downloadDialog.setDownloadProgress(bytesRead, totalBytes);
        }
    }

    innerContentData: ProgressBar {
        id: progressBar
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredMarginSize
        anchors.right: parent.right
        anchors.rightMargin: JamiTheme.preferredMarginSize
        value: downloadDialog.bytesRead / downloadDialog.totalBytes

        background: Rectangle {
            color: JamiTheme.darkGrey
            implicitHeight: 24
            implicitWidth: parent.width
        }
        contentItem: Item {
            implicitHeight: 22
            implicitWidth: parent.width

            Rectangle {
                color: JamiTheme.selectionBlue
                height: parent.height
                width: progressBar.visualPosition * parent.width
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                color: JamiTheme.whiteColor
                font.bold: true
                font.pointSize: JamiTheme.textFontSize + 1
                horizontalAlignment: Text.AlignHCenter
                text: Math.ceil(progressBar.value * 100).toString() + "%"
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
