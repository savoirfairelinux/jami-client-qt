/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import Qt.labs.platform 1.1
import QtGraphicalEffects 1.14
import net.jami.Models 1.0
import "../../commoncomponents"

Rectangle {
    id: generalSettingsRect

    function populateGeneralSettings(){
        // settings
        closeOrMinCheckBox.checked = ClientWrapper.settingsAdaptor.getSettingsValue_CloseOrMinimized()
        applicationOnStartUpCheckBox.checked = ClientWrapper.utilsAdaptor.checkStartupLink()
        notificationCheckBox.checked = ClientWrapper.settingsAdaptor.getSettingsValue_EnableNotifications()

        alwaysRecordingCheckBox.checked = ClientWrapper.avmodel.getAlwaysRecord()
        recordPreviewCheckBox.checked = ClientWrapper.avmodel.getRecordPreview()
        recordQualityValueLabel.text = ClientWrapper.utilsAdaptor.getRecordQualityString(ClientWrapper.avmodel.getRecordQuality() / 100)
        recordQualitySlider.value = ClientWrapper.avmodel.getRecordQuality() / 100

        ClientWrapper.avmodel.setRecordPath(ClientWrapper.settingsAdaptor.getDir_Document())

        autoUpdateCheckBox.checked = ClientWrapper.settingsAdaptor.getSettingsValue_AutoUpdate()
    }

    function slotSetNotifications(state){
        ClientWrapper.settingsAdaptor.setNotifications(state)
    }

    function slotSetClosedOrMin(state){
        ClientWrapper.settingsAdaptor.setClosedOrMin(state)
    }

    function slotSetRunOnStartUp(state){
        ClientWrapper.settingsAdaptor.setRunOnStartUp(state)
    }

    function slotSetUpdateAutomatic(state){
        ClientWrapper.settingsAdaptor.setUpdateAutomatic(state)
    }

    function slotAlwaysRecordingClicked(state){
        ClientWrapper.avmodel.setAlwaysRecord(state)
    }

    function slotRecordPreviewClicked(state){
        ClientWrapper.avmodel.setRecordPreview(state)
    }

    function slotRecordQualitySliderValueChanged(value){
        recordQualityValueLabel.text = ClientWrapper.utilsAdaptor.getRecordQualityString(value)
        updateRecordQualityTimer.restart()
    }

    Timer{
        id: updateRecordQualityTimer

        interval: 500

        onTriggered: {
            slotRecordQualitySliderSliderReleased()
        }
    }

    function slotRecordQualitySliderSliderReleased(){
        var value = recordQualitySlider.value
        ClientWrapper.avmodel.setRecordQuality(value * 100)
    }

    function openDownloadFolderSlot(){
        downloadPathDialog.open()
    }

    FolderDialog {
        id: downloadPathDialog

        title: qsTr("Select A Folder For Your Downloads")
        currentFolder: StandardPaths.writableLocation(StandardPaths.DownloadLocation)

        onAccepted: {
            var dir = ClientWrapper.utilsAdaptor.getAbsPath(folder.toString())
            downloadPath = dir
        }

        onRejected: {}

        onVisibleChanged: {
            if (!visible) {
                rejected()
            }
        }
    }

    function openRecordFolderSlot(){
        recordPathDialog.open()
    }

    FolderDialog {
        id: recordPathDialog

        title: qsTr("Select A Folder For Your Recordings")
        currentFolder: StandardPaths.writableLocation(StandardPaths.HomeLocation)

        onAccepted: {
            var dir = ClientWrapper.utilsAdaptor.getAbsPath(folder.toString())
            recordPath = dir
        }

        onRejected: {}

        onVisibleChanged: {
            if (!visible) {
                rejected()
            }
        }
    }

    //TODO: complete check for update and check for Beta slot functions
    function checkForUpdateSlot(){}
    function installBetaSlot(){}

    // settings
    property string downloadPath: ClientWrapper.settingsAdaptor.getDir_Download()

    // recording
    property string recordPath: ClientWrapper.settingsAdaptor.getDir_Document()

    property int preferredColumnWidth : settingsViewWindow.width / 2 - 50
    property int preferredWidthOneCol : settingsViewWindow.width - 100


    signal navigateToSidePanelMenu

    onDownloadPathChanged: {
        if(downloadPath === "") return
        ClientWrapper.settingsAdaptor.setDownloadPath(downloadPath)
    }

    onRecordPathChanged: {
        if(recordPath === "") return

        if(ClientWrapper.avmodel){
            ClientWrapper.avmodel.setRecordPath(recordPath)
        }
    }

    Layout.fillHeight: true
    Layout.fillWidth: true

    ScrollView{
        anchors.fill: parent
        clip: true

        ColumnLayout {
            spacing: 8

            Layout.fillHeight: true
            Layout.fillWidth: true

            RowLayout {

                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.leftMargin: 16
                Layout.fillWidth: true
                Layout.maximumHeight: 64
                Layout.minimumHeight: 64
                Layout.preferredHeight: 64

                HoverableButton {
                    id: backToSettingsMenuButton

                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32

                    radius: 32
                    source: "qrc:/images/icons/ic_arrow_back_24px.svg"
                    backgroundColor: "white"
                    onExitColor: "white"

                    visible: mainViewWindow.sidePanelHidden

                    onClicked: {
                        navigateToSidePanelMenu()
                    }
                }

                Label {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 64
                    Layout.preferredHeight: 64
                    Layout.maximumHeight: 64

                    text: qsTr("General")
                    font.pointSize: JamiTheme.titleFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // system setting panel
            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.leftMargin: 16

                Label {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 21
                    Layout.preferredHeight: 21
                    Layout.maximumHeight: 21

                    text: qsTr("System")
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    ToggleSwitch {
                        id: notificationCheckBox

                        labelText: desktopNotificationsElidedText.elidedText
                        fontPointSize: 11

                        onSwitchToggled: {
                            slotSetNotifications(checked)
                        }
                    }

                    TextMetrics {
                        id: desktopNotificationsElidedText
                        elide: Text.ElideRight
                        elideWidth: preferredWidthOneCol
                        text:  qsTr("Enable desktop notifications")
                    }


                    ToggleSwitch {
                        id: closeOrMinCheckBox

                        labelText: keepMinimizeElidedText.elidedText
                        fontPointSize: 11

                        tooltipText: qsTr("toggle enable notifications")
                        onSwitchToggled: {
                            slotSetClosedOrMin(checked)
                        }
                    }

                    TextMetrics {
                        id: keepMinimizeElidedText
                        elide: Text.ElideRight
                        elideWidth: preferredWidthOneCol
                        text:  qsTr("Keep minimize on close")
                    }


                    ToggleSwitch {
                        id: applicationOnStartUpCheckBox

                        labelText: runOnStartupElidedText.elidedText
                        fontPointSize: 11

                        tooltipText: qsTr("toggle run application on system startup")
                        onSwitchToggled: {
                            slotSetRunOnStartUp(checked)
                        }
                    }

                    TextMetrics {
                        id: runOnStartupElidedText
                        elide: Text.ElideRight
                        elideWidth: preferredWidthOneCol
                        text:  qsTr("Run On Startup")
                    }

                    RowLayout {
                        spacing: 8

                        Layout.leftMargin: 16
                        Layout.fillWidth: true
                        Layout.maximumHeight: 30

                        Label {
                            Layout.fillHeight: true

                            Layout.maximumWidth: 120
                            Layout.preferredWidth: 120
                            Layout.minimumWidth: 120

                            text: qsTr("Download folder")
                            font.pointSize: 10
                            font.kerning: true

                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }

                        HoverableRadiusButton {
                            id: downloadButton
                            Layout.leftMargin: 16
                            Layout.maximumWidth: preferredColumnWidth
                            Layout.preferredWidth: preferredColumnWidth
                            Layout.minimumWidth: preferredColumnWidth

                            Layout.minimumHeight: 32
                            Layout.preferredHeight: 32
                            Layout.maximumHeight: 32

                            radius: height / 2

                            icon.source: "qrc:/images/icons/round-folder-24px.svg"
                            icon.height: 24
                            icon.width: 24

                            text: downloadPath
                            fontPointSize: 10

                            onClicked: {
                                openDownloadFolderSlot()
                            }
                        }
                    }
                }
            }

            // call recording setting panel
            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 16

                Label {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 32
                    Layout.preferredHeight: 32
                    Layout.maximumHeight: 32

                    text: qsTr("Call Recording")
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    ToggleSwitch {
                        id: alwaysRecordingCheckBox

                        labelText: alwaysRecordElidedText.elidedText
                        fontPointSize: 11

                        onSwitchToggled: {
                            slotAlwaysRecordingClicked(checked)
                        }
                    }

                    TextMetrics {
                        id: alwaysRecordElidedText
                        elide: Text.ElideRight
                        elideWidth: preferredWidthOneCol
                        text:  qsTr("Always record calls")
                    }


                    ToggleSwitch {
                        id: recordPreviewCheckBox
                        tooltipText: qsTr("toggle always record calls")

                        labelText: recordPreviewElidedText.elidedText
                        fontPointSize: 11

                        onSwitchToggled: {
                            slotRecordPreviewClicked(checked)
                        }
                    }

                    TextMetrics {
                        id: recordPreviewElidedText
                        elide: Text.ElideRight
                        elideWidth: preferredWidthOneCol
                        text:  qsTr("Record preview video for a call")
                    }

                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        Layout.maximumHeight: 32

                        Label {
                            Layout.fillHeight: true

                            //Layout.fillWidth: true
                            Layout.maximumWidth: 50
                            Layout.preferredWidth: 50
                            Layout.minimumWidth: 50

                            text: qsTr("Quality")
                            font.pointSize: 10
                            font.kerning: true

                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }

                        Label {
                            id: recordQualityValueLabel

                            Layout.minimumWidth: 50
                            Layout.preferredWidth: 50
                            Layout.maximumWidth: 50

                            Layout.minimumHeight: 32
                            Layout.preferredHeight: 32
                            Layout.maximumHeight: 32

                            text: qsTr("VALUE ")

                            font.pointSize: 10
                            font.kerning: true

                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }

                        Slider{
                            id: recordQualitySlider

                            Layout.fillHeight: true

                            Layout.maximumWidth: preferredColumnWidth+80
                            Layout.preferredWidth: preferredColumnWidth+80
                            Layout.minimumWidth: preferredColumnWidth+80

                            from: 0
                            to: 500
                            stepSize: 1

                            onMoved: {
                                slotRecordQualitySliderValueChanged(value)
                            }
                        }
                    }

                    RowLayout {
                        spacing: 8

                        Layout.leftMargin: 20
                        Layout.fillWidth: true
                        Layout.maximumHeight: 30

                        Label {
                            Layout.fillHeight: true

                            Layout.maximumWidth: 120
                            Layout.preferredWidth: 120
                            Layout.minimumWidth: 120

                            text: qsTr("Save in")
                            font.pointSize: 10
                            font.kerning: true

                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }

                        HoverableRadiusButton {
                            id: recordPathButton

                            Layout.leftMargin: 16
                            Layout.maximumWidth: preferredColumnWidth
                            Layout.preferredWidth: preferredColumnWidth
                            Layout.minimumWidth: preferredColumnWidth

                            Layout.minimumHeight: 32
                            Layout.preferredHeight: 32
                            Layout.maximumHeight: 32

                            radius: height / 2

                            icon.source: "qrc:/images/icons/round-folder-24px.svg"
                            icon.height: 24
                            icon.width: 24

                            text: recordPath
                            fontPointSize: 10

                            onClicked: {
                                openRecordFolderSlot()
                            }
                        }
                    }
                }
            }

            // update setting panel
            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 16
                visible: true // Qt.platform.os == "windows"? true : false

                Label {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 32
                    Layout.preferredHeight: 32
                    Layout.maximumHeight: 32

                    text: qsTr("Updates")
                    font.pointSize: JamiTheme.headerFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    ToggleSwitch {
                        id: autoUpdateCheckBox

                        labelText: qsTr("Check for updates automatically")
                        fontPointSize: 11

                        tooltipText: qsTr("toggle automatic updates")
                        onSwitchToggled: {
                            slotSetUpdateAutomatic(checked)
                        }
                    }

                    HoverableRadiusButton {
                        id: checkUpdateButton

                        Layout.maximumWidth: preferredWidthOneCol
                        Layout.preferredWidth: preferredWidthOneCol
                        Layout.minimumWidth: preferredWidthOneCol

                        Layout.minimumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.maximumHeight: 32

                        radius: height / 2

                        text: qsTr("Check for updates now")
                        toolTipText: qsTr("Check for updates now")
                        fontPointSize: 10

                        onClicked: {
                            checkForUpdateSlot()
                        }
                    }

                    HoverableRadiusButton {
                        id: installBetaButton

                        Layout.maximumWidth: preferredWidthOneCol
                        Layout.preferredWidth: preferredWidthOneCol
                        Layout.minimumWidth: preferredWidthOneCol

                        Layout.minimumHeight: 32
                        Layout.preferredHeight: 32
                        Layout.maximumHeight: 32

                        radius: height / 2

                        text: "Install the latest beta version"
                        fontPointSize: 10

                        toolTipText: qsTr("Install the newest beta version")
                        onClicked: {
                            installBetaSlot()
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
