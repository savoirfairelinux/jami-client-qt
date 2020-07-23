
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
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.12
import net.jami.Models 1.0

import "../../commoncomponents"

import "../js/videodevicecontextmenuitemcreation.js" as VideoDeviceContextMenuItemCreation
import "../js/selectscreenwindowcreation.js" as SelectScreenWindowCreation

Menu {
    id: contextMenu
    property string responsibleAccountId: ""
    property string responsibleConvUid: ""

    property int generalMenuSeparatorCount: 0
    property int commonBorderWidth: 1
    font.pointSize: JamiTheme.textFontSize+3

    function activate() {
        var deviceContextMenuInfoMap = AvAdapter.populateVideoDeviceContextMenuItem()
        /*
         * Somehow, the map size is undefined, so use this instead.
         */
        var mapSize = deviceContextMenuInfoMap["size"]

        var count = 2
        for (var deviceName in deviceContextMenuInfoMap) {
            if (deviceName === "size")
                continue
            if (videoDeviceItem.itemName === "No video device") {
                videoDeviceItem.checkable = true
                videoDeviceItem.itemName = deviceName
                videoDeviceItem.checked = deviceContextMenuInfoMap[deviceName]
                if (count === mapSize)
                    contextMenu.open()
            } else {
                VideoDeviceContextMenuItemCreation.createVideoDeviceContextMenuItemObjects(
                            deviceName, deviceContextMenuInfoMap[deviceName],
                            count === mapSize)
            }
            count++
        }
        contextMenu.open()
    }

    Component.onCompleted: {
        VideoDeviceContextMenuItemCreation.setVideoContextMenuObject(contextMenu)
    }


    onClosed: {
        videoDeviceItem.itemName = "No video device"
        VideoDeviceContextMenuItemCreation.removeCreatedItems()
    }

    JamiFileDialog {
        id: jamiFileDialog

        mode: JamiFileDialog.Mode.OpenFile

        onAccepted: {
            var filePath = jamiFileDialog.file


            /*
             * No need to trim file:///.
             */
            AvAdapter.shareFile(filePath)
        }
    }

    /*
     * All GeneralMenuItems should remain the same width / height.
     */
    GeneralMenuItem {
        id: startRecordingItem

        itemName: qsTr("Start recording")
        iconSource: "qrc:/images/icons/ic_video_call_24px.svg"
        leftBorderWidth: commonBorderWidth
        rightBorderWidth: commonBorderWidth

        onClicked: {
            contextMenu.close()
            CallAdapter.recordThisCallToggle()
        }
    }

    GeneralMenuItem {
        id: fullScreenItem

        itemName: videoCallPage.isFullscreen ? qsTr("Exit full screen") : qsTr(
                                     "Full screen mode")
        iconSource: videoCallPage.isFullscreen ? "qrc:/images/icons/close_fullscreen-24px.svg" : "qrc:/images/icons/open_in_full-24px.svg"
        leftBorderWidth: commonBorderWidth
        rightBorderWidth: commonBorderWidth

        onClicked: {
            contextMenu.close()
            videoCallPageRect.needToShowInFullScreen()
        }
    }

    GeneralMenuSeparator {
        preferredWidth: startRecordingItem.preferredWidth
        preferredHeight: commonBorderWidth

        Component.onCompleted: {
            generalMenuSeparatorCount++
        }
    }

    VideoCallPageContextMenuDeviceItem {
        id: videoDeviceItem

        contextMenuPreferredWidth: contextMenu.implicitWidth
    }

    GeneralMenuSeparator {
        preferredWidth: startRecordingItem.preferredWidth
        preferredHeight: commonBorderWidth

        Component.onCompleted: {
            generalMenuSeparatorCount++
        }
    }

    GeneralMenuItem {
        id: shareEntireScreenItem

        itemName: qsTr("Share entire screen")
        iconSource: "qrc:/images/icons/screen_share-24px.svg"
        leftBorderWidth: commonBorderWidth
        rightBorderWidth: commonBorderWidth

        onClicked: {
            contextMenu.close()
            if (Qt.application.screens.length === 1) {
                AvAdapter.shareEntireScreen(0)
            } else {
                SelectScreenWindowCreation.createSelectScreenWindowObject()
                SelectScreenWindowCreation.showSelectScreenWindow()
            }
        }
    }

    GeneralMenuItem {
        id: shareScreenAreaItem

        itemName: qsTr("Share screen area")
        iconSource: "qrc:/images/icons/screen_share-24px.svg"
        leftBorderWidth: commonBorderWidth
        rightBorderWidth: commonBorderWidth

        onClicked: {
            contextMenu.close()
            if (Qt.application.screens.length === 1) {
                ScreenRubberBandCreation.createScreenRubberBandWindowObject(
                            null, 0)
                ScreenRubberBandCreation.showScreenRubberBandWindow()
            } else {
                SelectScreenWindowCreation.createSelectScreenWindowObject(true)
                SelectScreenWindowCreation.showSelectScreenWindow()
            }
        }
    }

    GeneralMenuItem {
        id: shareFileItem

        itemName: qsTr("Share file")
        iconSource: "qrc:/images/icons/insert_photo-24px.svg"
        leftBorderWidth: commonBorderWidth
        rightBorderWidth: commonBorderWidth

        onClicked: {
            contextMenu.close()
            jamiFileDialog.open()
        }
    }

    /* TODO
    GeneralMenuSeparator {
        preferredWidth: startRecordingItem.preferredWidth
        preferredHeight: commonBorderWidth

        Component.onCompleted: {
            generalMenuSeparatorCount++
        }
    }

    GeneralMenuItem {
        id: advancedInfosItem

        itemName: qsTr("Advanced informations")
        iconSource: "qrc:/images/icons/info-24px.svg"
        leftBorderWidth: commonBorderWidth
        rightBorderWidth: commonBorderWidth

        onClicked: {
            contextMenu.close()
        }
    }

    GeneralMenuItem {
        id: qualityItem

        itemName: qsTr("Manage video quality")
        iconSource: "qrc:/images/icons/ic_high_quality_24px.svg"
        leftBorderWidth: commonBorderWidth
        rightBorderWidth: commonBorderWidth

        onClicked: {
            contextMenu.close()
        }
    }

    GeneralMenuSeparator {
        preferredWidth: startRecordingItem.preferredWidth
        preferredHeight: commonBorderWidth

        Component.onCompleted: {
            generalMenuSeparatorCount++
        }
    }

    GeneralMenuItem {
        id: pluginItem

        itemName: qsTr("Toggle plugin")
        iconSource: "qrc:/images/icons/extension_24dp.svg"
        leftBorderWidth: commonBorderWidth
        rightBorderWidth: commonBorderWidth

        onClicked: {
            contextMenu.close()
        }
    }*/

    background: Rectangle {
        implicitWidth: startRecordingItem.preferredWidth
        implicitHeight: startRecordingItem.preferredHeight
                        * (contextMenu.count - generalMenuSeparatorCount)

        border.width: commonBorderWidth
        border.color: JamiTheme.tabbarBorderColor
    }
}

