/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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
import Qt5Compat.GraphicalEffects
import QtWebEngine

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"

Item {
    id: root

    property bool isUnpin: false
    property real maxWidth
    property real maxHeight
    property string attachedAccountId
    property string currentAccountId: CurrentAccount.id
    property string currentConvId: CurrentConversation.id
    property bool isSharing: (PositionManager.positionShareConvIdsCount !== 0)
    property bool isSharingToCurrentConversation

    function closeMapPosition() {
        root.destroy()
    }

    Connections {
        target: PositionManager

        function onPinMapSignal(key) {
            if (key === attachedAccountId) {
                isUnpin = false
                mapPopup.state = "pin"
                windowUnpin.close()
            }
        }

        function onCloseMapSignal(key) {
            if (key === attachedAccountId )
                closeMapPosition()
        }

        function onUnPinMapSignal(key) {
            if (key === attachedAccountId ) {
                isUnpin = true
                mapPopup.state = "unpin"
                windowUnpin.show()
            }
        }
    }

    Window {
        id: windowUnpin

        width: parentPin.width
        height: parentPin.height
        visible: false
        title: PositionManager.getmapTitle(attachedAccountId)

        Item {
            id: parentUnPin

            width: mapPopup.width
            height: mapPopup.height
        }

        onClosing: {
            if (isUnpin) {
                PositionManager.setMapInactive(attachedAccountId)
            }
        }
    }

    Item {
        id: parentPin

        width: mapPopup.width
        height: mapPopup.height

        Rectangle {
            id: mapPopup

            x: xPos
            y: yPos
            width: root.isUnpin
                   ? windowUnpin.width
                   : isFullScreen ? root.maxWidth : windowSize
            height: root.isUnpin
                    ? windowUnpin.height
                    : isFullScreen ? root.maxHeight - yPos : windowSize

            property bool isFullScreen: false
            property real windowSize: windowPreferedSize > JamiTheme.minimumMapWidth
                                      ? windowPreferedSize
                                      : JamiTheme.minimumMapWidth
            property real windowPreferedSize: root.maxWidth > root.maxHeight
                                              ? root.maxHeight / 3
                                              : root.maxWidth / 3
            property real xPos: 0
            property real yPos: root.isUnpin ? 0 : JamiTheme.chatViewHeaderPreferredHeight

            states: [ State {
                    name: "unpin"
                    ParentChange { target: mapPopup; parent: parentUnPin; x:0; y:0 }
                },
                State {
                    name: "pin"
                    ParentChange { target: mapPopup; parent: parentPin; x:xPos; y:JamiTheme.chatViewHeaderPreferredHeight }
                }
            ]

            WebEngineView {
                id: webView

                width: parent.width
                height: parent.height

                property string mapHtml: ":/webengine/map/map.html"
                property string olCss: ":/webengine/map/ol.css"
                property string mapJs: "../../webengine/map/map.js"
                property string olJs: "../../webengine/map/ol.js"
                property bool isLoaded: false
                property var positionList: PositionManager.positionList;
                property var avatarPositionList: PositionManager.avatarPositionList;

                function loadScripts () {
                    var scriptMapJs = {
                        sourceUrl: Qt.resolvedUrl(mapJs),
                        injectionPoint: WebEngineScript.DocumentReady,
                        worldId: WebEngineScript.MainWorld
                    }

                    var scriptOlJs = {
                        sourceUrl: Qt.resolvedUrl(olJs),
                        injectionPoint: WebEngineScript.DocumentReady,
                        worldId: WebEngineScript.MainWorld
                    }

                    userScripts.collection = [ scriptOlJs, scriptMapJs ]
                }
                Connections {
                    target: PositionManager

                    function onPositionShareAdded(shareInfo) {
                        if(webView.isLoaded) {
                            if (shareInfo.account === attachedAccountId) {
                                var curLong = shareInfo.long
                                var curLat = shareInfo.lat
                                webView.runJavaScript("newPosition([" + curLong + "," + curLat  + "], '" + shareInfo.author + "', '" + shareInfo.avatar + "' )" );
                                webView.runJavaScript("zoomTolayersExtent()" );
                            }
                        }
                    }

                    function onPositionShareUpdated(shareInfo) {
                        if(webView.isLoaded) {
                            if (shareInfo.account === attachedAccountId) {
                                var curLong = shareInfo.long
                                var curLat = shareInfo.lat
                                webView.runJavaScript("updatePosition([" + curLong + "," + curLat  + "], '" + shareInfo.author + "' )" );
                            }
                        }
                    }

                    function onPositionShareRemoved(author, accountId) {
                        if(webView.isLoaded) {
                            if (accountId === attachedAccountId) {
                                webView.runJavaScript("removePosition( '" + author + "' )" );
                                webView.runJavaScript("zoomTolayersExtent()" );
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    loadHtml(UtilsAdapter.qStringFromFile(mapHtml), mapHtml)
                    loadScripts()
                }

                onLoadingChanged: function (loadingInfo) {
                    if (loadingInfo.status === WebEngineView.LoadSucceededStatus) {
                        attachedAccountId = CurrentAccount.id
                        runJavaScript(UtilsAdapter.getStyleSheet("olcss",UtilsAdapter.qStringFromFile(olCss)))
                        webView.isLoaded = true
                        runJavaScript("setMapView([" + 0 + ","+ 0  + "], " + 1 + " );" );
                        PositionManager.startPositioning()
                        //load locations that were received before this conversation was opened
                        PositionManager.loadPreviousLocations(attachedAccountId);
                    }
                }
            }

            ColumnLayout {
                id: buttonsChoseSharing

                anchors.horizontalCenter: mapPopup.horizontalCenter
                anchors.margins: 10
                anchors.bottom: mapPopup.bottom

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        radius: 10
                        Layout.preferredWidth: textTimer.width + 15
                        Layout.preferredHeight: textTimer.height + 15
                        color: JamiTheme.mapButtonsOverlayColor
                        visible: textTimer.remainingTimeMs === 0
                                 ? false
                                 : isUnpin
                                   ? isSharing
                                   : root.isSharingToCurrentConversation

                        Text {
                            id: textTimer

                            anchors.centerIn: parent
                            color: JamiTheme.mapButtonColor
                            text: standartCountdown(Math.floor(remainingTimeMs / 1000))

                            function standartCountdown(seconds) {
                                var minutes = Math.floor(seconds / 60);
                                var hour = Math.floor(minutes / 60)
                                minutes = minutes % 60
                                var sec = seconds % 60
                                if (hour)
                                    return qsTr("%1h%2min").arg(hour).arg(minutes)
                                if (minutes && !(minutes === 1 && sec === 0))
                                    return qsTr("%1m%2sec").arg(minutes).arg(sec)
                                return qsTr("%1s").arg(seconds)
                            }

                            property int remainingTimeMs: PositionManager.timeSharingRemaining
                        }
                    }
                }

                RowLayout {
                    id: sharePositionLayout

                    Layout.alignment: Qt.AlignHCenter

                    MaterialButton {
                        id: sharePositionButton

                        preferredWidth: text.contentWidth
                        textLeftPadding: JamiTheme.buttontextPadding
                        textRightPadding: JamiTheme.buttontextPadding
                        primary: true
                        visible: !root.isSharingToCurrentConversation && !isUnpin
                        text: JamiStrings.shareLocation
                        color: isError
                               ? JamiTheme.buttonTintedGreyInactive
                               : JamiTheme.buttonTintedBlue
                        hoveredColor: isError
                                      ? JamiTheme.buttonTintedGreyInactive
                                      : JamiTheme.buttonTintedBlueHovered
                        pressedColor: isError
                                      ? JamiTheme.buttonTintedGreyInactive
                                      : JamiTheme.buttonTintedBluePressed
                        Layout.alignment: Qt.AlignHCenter
                        property bool isHovered: false
                        property string positioningError: "default"
                        property bool isError: positioningError.length
                        property int positionShareConvIdsCount: PositionManager.positionShareConvIdsCount
                        property string currentConvId: CurrentConversation.id
                        property bool isUnpin: root.isUnpin

                        function errorString(posError) {
                            if (posError === "locationServicesError")
                                return JamiStrings.locationServicesError
                            return JamiStrings.locationServicesClosedError
                        }

                        onPositionShareConvIdsCountChanged: {
                            root.isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId)
                        }

                        onCurrentConvIdChanged: {
                            root.isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId)
                        }

                        onIsUnpinChanged: {
                            root.isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId)
                        }

                        onClicked: {
                            var sharingDuration = 60 * 1000 * UtilsAdapter.getAppValue(Settings.PositionShareDuration)
                            if (!isError && !isUnpin) {
                                PositionManager.sharePosition(sharingDuration, attachedAccountId, currentConvId);
                            }
                            webView.runJavaScript("zoomTolayersExtent()" );
                        }

                        onHoveredChanged: {
                            isHovered = !isHovered
                        }

                        MaterialToolTip {
                            property bool isSharingPossible: !(sharePositionButton.isError && (sharePositionButton.positioningError !== "default"))

                            visible: sharePositionButton.isHovered
                            text: isSharingPossible
                                  ? JamiStrings.shareLocationToolTip.arg(PositionManager.getmapTitle(attachedAccountId, currentConvId))
                                  : sharePositionButton.errorString(sharePositionButton.positioningError)
                        }
                        Connections {
                            target: PositionManager
                            function onPositioningError (err) {
                                sharePositionButton.positioningError = err;
                            }
                        }
                    }
                    MaterialButton {
                        id: stopSharingPositionButton

                        preferredWidth: text.contentWidth
                        textLeftPadding: JamiTheme.buttontextPadding
                        textRightPadding: JamiTheme.buttontextPadding
                        primary: true
                        visible: isSharing
                        text: isUnpin
                              ? JamiStrings.stopAllSharings
                              : JamiStrings.stopSharingLocation
                        color: isError
                               ? JamiTheme.buttonTintedGreyInactive
                               : JamiTheme.buttonTintedRed
                        hoveredColor: isError
                                      ? JamiTheme.buttonTintedGreyInactive
                                      : JamiTheme.buttonTintedRedHovered
                        pressedColor: isError
                                      ? JamiTheme.buttonTintedGreyInactive
                                      :  JamiTheme.buttonTintedRedPressed
                        Layout.alignment: Qt.AlignHCenter
                        toolTipText: stopAllSharing
                                     ? isUnpin
                                       ? JamiStrings.unpinStopSharingTooltip
                                       : JamiStrings.stopAllSharings
                        : JamiStrings.stopSharingSeveralConversationTooltip
                        property bool isHovered: false
                        property string positioningError
                        property bool isError: positioningError.length
                        property bool stopAllSharing: !(PositionManager.positionShareConvIdsCount >= 2 && !isUnpin && isSharingToCurrentConversation)
                        onClicked: {
                            if (!isError) {
                                if (stopAllSharing) {
                                    PositionManager.stopSharingPosition();
                                } else {
                                    stopSharingPositionPopup.open()
                                }
                            }
                        }
                    }
                }
            }

            StopSharingPositionPopup {
                id: stopSharingPositionPopup

                property alias attachedAccountId: root.attachedAccountId
            }

            Rectangle {
                id: buttonOverlay

                anchors.right: webView.right
                anchors.top: webView.top
                anchors.margins: 10
                radius: 10
                width: lay.width + 10
                height: lay.height + 10
                color: JamiTheme.mapButtonsOverlayColor

                RowLayout {
                    id: lay

                    anchors.centerIn: parent

                    PushButton {
                        id: btnUnpin

                        toolTipText: !isUnpin ? JamiStrings.unpin : JamiStrings.pinWindow
                        imageColor: JamiTheme.mapButtonColor
                        normalColor: JamiTheme.transparentColor
                        source: JamiResources.unpin_svg
                        onClicked: {
                            if (!root.isUnpin) {
                                PositionManager.unPinMap(attachedAccountId)
                            } else {
                                PositionManager.pinMap(attachedAccountId)
                            }
                        }
                    }

                    PushButton {
                        id: btnCenter

                        toolTipText: JamiStrings.centerMapTooltip
                        imageColor: JamiTheme.mapButtonColor
                        normalColor: JamiTheme.transparentColor
                        source: JamiResources.share_location_svg
                        onClicked: {
                            webView.runJavaScript("zoomTolayersExtent()" );
                        }
                    }

                    PushButton {
                        id: btnMove

                        toolTipText: JamiStrings.dragMapTooltip
                        imageColor: JamiTheme.mapButtonColor
                        normalColor: JamiTheme.transparentColor
                        source: JamiResources.move_svg
                        visible: !isUnpin

                        MouseArea {
                            anchors.fill: parent
                            drag.target: mapPopup
                            drag.minimumX: 0
                            drag.maximumX: root.maxWidth - mapPopup.maxWidth
                            drag.minimumY: 0
                            drag.maximumY: root.maxHeight - mapPopup.maxHeight
                        }
                    }

                    PushButton {
                        id: btnmaximise

                        visible: !isUnpin
                        toolTipText: isFullScreen
                                     ? JamiStrings.reduceMapTooltip
                                     : JamiStrings.maximizeMapTooltip
                        imageColor: JamiTheme.mapButtonColor
                        normalColor: JamiTheme.transparentColor
                        source: isFullScreen? JamiResources.close_fullscreen_24dp_svg : JamiResources.open_in_full_24dp_svg
                        onClicked: {
                            if (!isFullScreen) {
                                mapPopup.x = mapPopup.xPos
                                mapPopup.y = mapPopup.yPos
                            }

                            isFullScreen = !isFullScreen
                        }
                        property alias isFullScreen: mapPopup.isFullScreen

                    }

                    PushButton {
                        id: btnClose

                        toolTipText: JamiStrings.closeMapTooltip
                        imageColor: JamiTheme.mapButtonColor
                        normalColor: JamiTheme.transparentColor
                        source: JamiResources.round_close_24dp_svg
                        visible: !isUnpin

                        onClicked: {
                            PositionManager.setMapInactive(root.attachedAccountId)
                            PositionManager.mapAutoOpening = false
                        }
                    }
                }
            }
        }
    }
}

