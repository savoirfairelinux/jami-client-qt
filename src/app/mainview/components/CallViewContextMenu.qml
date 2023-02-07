/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../commoncomponents/contextmenu"
import "../js/screenrubberbandcreation.js" as ScreenRubberBandCreation

ContextMenuAutoLoader {
    id: root

    property bool windowSelection: false

    signal pluginItemClicked
    signal transferCallButtonClicked
    signal recordCallClicked
    signal openSelectionWindow
    signal screenshotTaken
    property bool screenshotButtonHovered: screenShot.itemHovered

    property string hoveredOverlayUri: ""
    property string hoveredOverlaySinkId: ""
    property bool hoveredOverVideoMuted: true

    property list<GeneralMenuItem> menuItems: [
        GeneralMenuItem {
            id: resumePauseCall

            canTrigger: CurrentCall.isSIP
            itemName: CurrentCall.isPaused ?
                          JamiStrings.resumeCall :
                          JamiStrings.pauseCall
            iconSource: CurrentCall.isPaused ?
                            JamiResources.play_circle_outline_24dp_svg :
                            JamiResources.pause_circle_outline_24dp_svg
            onClicked: {
                CallAdapter.holdThisCallToggle()
            }
        },
        GeneralMenuItem {
            id: inputPanelSIP

            canTrigger: CurrentCall.isSIP
            itemName: JamiStrings.sipInputPanel
            iconSource: JamiResources.ic_keypad_svg
            onClicked: {
                sipInputPanel.open()
            }
        },
        GeneralMenuItem {
            id: callTransfer

            canTrigger: CurrentCall.isSIP
            itemName: JamiStrings.transferCall
            iconSource: JamiResources.phone_forwarded_24dp_svg
            addMenuSeparatorAfter: CurrentCall.isSIP
            onClicked: {
                root.transferCallButtonClicked()
            }
        },
        GeneralMenuItem {
            id: localRecord

            itemName: CurrentCall.isRecordingLocally ?
                          JamiStrings.stopRec :
                          JamiStrings.startRec
            iconSource: JamiResources.fiber_manual_record_24dp_svg
            iconColor: JamiTheme.recordIconColor
            onClicked: {
                root.recordCallClicked()
            }
        },
        GeneralMenuItem {
            id: fullScreen

            itemName: layoutManager.isCallFullscreen ?
                          JamiStrings.exitFullScreen :
                          JamiStrings.viewFullScreen
            iconSource: layoutManager.isCallFullscreen ?
                            JamiResources.close_fullscreen_24dp_svg :
                            JamiResources.open_in_full_24dp_svg
            onClicked: {
                callStackView.toggleFullScreen()
            }
        },
        GeneralMenuItem {
            id: stopSharing

            canTrigger: CurrentCall.isSharing
                        && !CurrentCall.isSIP
                        && !CurrentCall.isVideoMuted
            itemName: JamiStrings.stopSharing
            iconSource: JamiResources.share_stop_black_24dp_svg
            iconColor: JamiTheme.redColor
            onClicked: AvAdapter.stopSharing(CurrentCall.sharingSource)
        },
        GeneralMenuItem {
            id: shareScreen

            canTrigger: CurrentAccount.videoEnabled_Video
                        && AvAdapter.currentRenderingDeviceType !== Video.DeviceType.DISPLAY
                        && !CurrentCall.isSIP
            itemName: JamiStrings.shareScreen
            iconSource: JamiResources.laptop_black_24dp_svg
            onClicked: {
                if (Qt.application.screens.length === 1) {
                    AvAdapter.shareEntireScreen(0)
                } else {
                    windowSelection = false
                    openSelectionWindow()
                }
            }
        },
        GeneralMenuItem {
            id: shareWindow

            canTrigger: CurrentAccount.videoEnabled_Video
                        && AvAdapter.currentRenderingDeviceType !== Video.DeviceType.DISPLAY
                        && !CurrentCall.isSIP
            itemName: JamiStrings.shareWindow
            iconSource: JamiResources.window_black_24dp_svg
            onClicked: {
                AvAdapter.getListWindows()
                if (AvAdapter.windowsNames.length >= 1) {
                    windowSelection = true
                    openSelectionWindow()
                }
            }
        },
        GeneralMenuItem {
            id: shareScreenArea

            canTrigger: CurrentAccount.videoEnabled_Video
                        && AvAdapter.currentRenderingDeviceType !== Video.DeviceType.DISPLAY
                        && !CurrentCall.isSIP
                        && Qt.platform.os.toString() !== "windows" // temporarily disable for windows
            itemName: JamiStrings.shareScreenArea
            iconSource: JamiResources.share_area_black_24dp_svg
            onClicked: {
                if (Qt.platform.os !== "windows") {
                    AvAdapter.shareScreenArea(0, 0, 0, 0)
                } else {
                    ScreenRubberBandCreation.createScreenRubberBandWindowObject()
                    ScreenRubberBandCreation.showScreenRubberBandWindow()
                }
            }
        },
        GeneralMenuItem {
            id: shareFile

            canTrigger: CurrentAccount.videoEnabled_Video
                        && !CurrentCall.isSIP
            itemName: JamiStrings.shareFile
            iconSource: JamiResources.file_black_24dp_svg
            onClicked: {
                jamiFileDialog.open()
            }
        },
        GeneralMenuItem {
            id: viewPlugin

            canTrigger: PluginAdapter.isEnabled &&
                        PluginAdapter.callMediaHandlersListCount
            itemName: JamiStrings.viewPlugin
            iconSource: JamiResources.extension_24dp_svg
            onClicked: {
                root.pluginItemClicked()
            }
        },
        GeneralMenuItem {
            id: advancedInformation

            canTrigger: true
            itemName: JamiStrings.advancedInformation
            iconSource: JamiResources.settings_24dp_svg

            onClicked: {
                CallAdapter.startTimerInformation();
                callInformationOverlay.open()
            }
        },
        GeneralMenuItem {
            id: screenShot

            canTrigger: hoveredOverlayUri !== "" && hoveredOverVideoMuted === false
            itemName: JamiStrings.tileScreenshot
            iconSource: JamiResources.baseline_camera_alt_24dp_svg

            MaterialToolTip {
                id: tooltip

                parent: screenShot
                visible: screenShot.itemHovered
                delay: Qt.styleHints.mousePressAndHoldInterval
                property bool isMe: CurrentAccount.uri === hoveredOverlayUri
                text: isMe ? JamiStrings.me
                           : UtilsAdapter.getBestNameForUri(CurrentAccount.id, hoveredOverlayUri)
            }

            onClicked: {
                if (CallAdapter.takeScreenshot(videoProvider.captureRawVideoFrame(hoveredOverlaySinkId),
                                               UtilsAdapter.getDirScreenshot())) {
                    screenshotTaken()
                }
            }
        }
    ]


    Component.onCompleted: menuItemsToLoad = menuItems
}
