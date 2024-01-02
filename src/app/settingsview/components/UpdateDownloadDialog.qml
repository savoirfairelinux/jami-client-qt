/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
    property int totalBytes: 0
    property string hSizeRead: UtilsAdapter.humanFileSize(bytesRead)
    property string hTotalBytes: UtilsAdapter.humanFileSize(totalBytes)
    property alias progressBarValue: progressBar.value

    closeButtonVisible: false

    button1.text: JamiStrings.optionCancel
    button1Role: DialogButtonBox.RejectRole
    button1.onClicked: function () { AppVersionManager.cancelUpdate();}

    Connections {
        target: AppVersionManager

        function onNetworkErrorOccurred(error) {
            downloadDialog.close();
        }

        function onDownloadProgressChanged(bytesRead, totalBytes) {
            downloadDialog.setDownloadProgress(bytesRead, totalBytes);
        }

        function onDownloadFinished() {
            downloadDialog.close();
        }
    }

    function setDownloadProgress(bytesRead, totalBytes) {
        downloadDialog.bytesRead = bytesRead;
        downloadDialog.totalBytes = totalBytes;
    }

    infoText: JamiStrings.updateDownloading + " (%1 / %2)".arg(hSizeRead).arg(hTotalBytes)

    innerContentData: ProgressBar {
        id: progressBar

        value: downloadDialog.bytesRead / downloadDialog.totalBytes

        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredMarginSize
        anchors.right: parent.right
        anchors.rightMargin: JamiTheme.preferredMarginSize

        background: Rectangle {
            implicitWidth: parent.width
            implicitHeight: 24
            color: JamiTheme.darkGrey
        }

        contentItem: Item {
            implicitWidth: parent.width
            implicitHeight: 22

            Rectangle {
                width: progressBar.visualPosition * parent.width
                height: parent.height
                color: JamiTheme.selectionBlue
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                color: JamiTheme.whiteColor
                font.bold: true
                font.pointSize: JamiTheme.textFontSize + 1
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Math.ceil(progressBar.value * 100).toString() + "%"
            }
        }
    }

    buttonTitles: [JamiStrings.optionCancel]
    buttonStyles: [SimpleMessageDialog.ButtonStyle.TintedBlue]
    buttonCallBacks: [function () {
            AppVersionManager.cancelUpdate();
        }]
    onVisibleChanged: {
        if (!visible)
            AppVersionManager.cancelUpdate();
    }
}
