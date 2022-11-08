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
import net.jami.Constants 1.1

import "../../commoncomponents"

Rectangle {
    id: mapPopup

    x: xPos
    y: yPos
    width: isFullScreen ? root.width : windowSize
    height: isMinimised
            ? buttonOverlay.height + buttonsChoseSharing.height + 30
            : isFullScreen ? root.height - yPos : windowSize

    property bool isFullScreen: false
    property bool isMinimised: false
    property real windowSize: windowPreferedSize > JamiTheme.minimumMapWidth
                              ? windowPreferedSize
                              : JamiTheme.minimumMapWidth
    property real windowPreferedSize: root.width > root.height
                                      ? root.height / 3
                                      : root.width / 3
    property real xPos: 0
    property real yPos: JamiTheme.chatViewHeaderPreferredHeight

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
        property bool isSharing: (PositionManager.positionShareConvIds.length !== 0 )

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
                    var curLong = shareInfo.long
                    var curLat = shareInfo.lat
                    webView.runJavaScript("newPosition([" + curLong + "," + curLat  + "], '" + shareInfo.author + "', '" + shareInfo.avatar + "' )" );
                    webView.runJavaScript("zoomTolayersExtent()" );
                }

            }

            function onPositionShareUpdated(shareInfo) {
                if(webView.isLoaded) {
                    var curLong = shareInfo.long
                    var curLat = shareInfo.lat
                    webView.runJavaScript("updatePosition([" + curLong + "," + curLat  + "], '" + shareInfo.author + "' )" );
                }
            }

            function onPositionShareRemoved(author) {
                if(webView.isLoaded) {
                    webView.runJavaScript("removePosition( '" + author + "' )" );
                    webView.runJavaScript("zoomTolayersExtent()" );
                }
            }
        }

        Component.onCompleted: {
            loadHtml(UtilsAdapter.qStringFromFile(mapHtml), mapHtml)
            loadScripts()
        }

        onLoadingChanged: function (loadingInfo) {
            if (loadingInfo.status === WebEngineView.LoadSucceededStatus) {
                runJavaScript(UtilsAdapter.getStyleSheet("olcss",UtilsAdapter.qStringFromFile(olCss)))
                webView.isLoaded = true
                runJavaScript("setMapView([" + 0 + ","+ 0  + "], " + 1 + " );" );
                PositionManager.startPositioning()
            }
        }
    }

    ColumnLayout {
        id: buttonsChoseSharing

        anchors.horizontalCenter: mapPopup.horizontalCenter
        anchors.margins: 10
        anchors.bottom: mapPopup.bottom

        property bool shortSharing: true

        RowLayout {
            Layout.alignment: Qt.AlignHCenter

            MaterialButton {
                id: shortSharingButton

                preferredWidth: text.contentWidth
                visible: !webView.isSharing
                textLeftPadding: JamiTheme.buttontextPadding
                textRightPadding: JamiTheme.buttontextPadding
                primary: true
                text: JamiStrings.shortSharing
                color: buttonsChoseSharing.shortSharing ? JamiTheme.buttonTintedBluePressed : JamiTheme.buttonTintedBlue
                fontSize: JamiTheme.timerButtonsFontSize
                onClicked: {
                    buttonsChoseSharing.shortSharing = true
                }

            }

            MaterialButton {
                id: longSharingButton

                preferredWidth: text.contentWidth
                visible: !webView.isSharing
                textLeftPadding: JamiTheme.buttontextPadding
                textRightPadding: JamiTheme.buttontextPadding
                primary: true
                text: JamiStrings.longSharing
                color: !buttonsChoseSharing.shortSharing ? JamiTheme.buttonTintedBluePressed : JamiTheme.buttonTintedBlue
                fontSize: JamiTheme.timerButtonsFontSize
                onClicked: {
                    buttonsChoseSharing.shortSharing = false;
                }
            }

            Rectangle {

                radius: 10
                width: textTimer.width + 15
                height: textTimer.height + 15
                color: JamiTheme.mapButtonsOverlayColor
                visible: webView.isSharing && PositionManager.timeSharingRemaining

                Text {
                    id: textTimer

                    anchors.centerIn: parent
                    color: JamiTheme.mapButtonColor
                    text: remainingTimeMs <= 1
                          ? remainingTimeMs + " " + JamiStrings.minuteLeft
                          : remainingTimeMs + " " + JamiStrings.minutesLeft

                    Layout.alignment: Qt.AlignHCenter

                    property int remainingTimeMs: Math.ceil(PositionManager.timeSharingRemaining / 1000 / 60)
                }
            }
        }

        MaterialButton {
            id: sharePositionButton

            preferredWidth: text.contentWidth
            textLeftPadding: JamiTheme.buttontextPadding
            textRightPadding: JamiTheme.buttontextPadding
            primary: true
            text: webView.isSharing ?  JamiStrings.stopSharingPosition : JamiStrings.sharePosition
            color: isError
                   ? JamiTheme.buttonTintedGreyInactive
                   : webView.isSharing ? JamiTheme.buttonTintedRed : JamiTheme.buttonTintedBlue
            hoveredColor: isError
                          ? JamiTheme.buttonTintedGreyInactive
                          : webView.isSharing ? JamiTheme.buttonTintedRedHovered : JamiTheme.buttonTintedBlueHovered
            pressedColor: isError
                          ? JamiTheme.buttonTintedGreyInactive
                          : webView.isSharing ? JamiTheme.buttonTintedRedPressed: JamiTheme.buttonTintedBluePressed
            Layout.alignment: Qt.AlignHCenter

            property bool isHovered: false
            property string positioningError
            property bool isError: positioningError.length

            onClicked: {
                if (!isError) {
                    if(webView.isSharing) {
                        PositionManager.stopSharingPosition();
                    } else {
                        if( buttonsChoseSharing.shortSharing)
                            PositionManager.sharePosition(10 * 60 * 1000);
                        else
                            PositionManager.sharePosition(60 * 60 * 1000);
                    }
                }
            }

            onHoveredChanged: {
                isHovered = !isHovered
            }

            MaterialToolTip {
                visible: sharePositionButton.isHovered
                         && sharePositionButton.isError
                x: 0
                y: 0
                text: sharePositionButton.positioningError
            }

            Connections {
                target: PositionManager
                function onPositioningError (err) {
                    sharePositionButton.positioningError = err;
                }
            }
        }
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
                id: btnCenter

                imageColor: JamiTheme.mapButtonColor
                normalColor: JamiTheme.transparentColor
                source: JamiResources.share_location_svg
                onClicked: {
                    webView.runJavaScript("zoomTolayersExtent()" );
                }
            }

            PushButton {
                id: btnMove

                imageColor: JamiTheme.mapButtonColor
                normalColor: JamiTheme.transparentColor
                source: JamiResources.move_svg

                MouseArea {
                    anchors.fill: parent
                    drag.target: mapPopup
                    drag.minimumX: 0
                    drag.maximumX: root.width - mapPopup.width
                    drag.minimumY: 0
                    drag.maximumY: root.height - mapPopup.height
                }
            }

            PushButton {
                id: btnminimise

                imageColor: JamiTheme.mapButtonColor
                normalColor: JamiTheme.transparentColor
                source: isMinimised
                        ? JamiResources.close_fullscreen_24dp_svg
                        : JamiResources.minimize_svg
                onClicked: {
                    isMinimised = !isMinimised
                    isFullScreen = false;
                }
            }

            PushButton {
                id: btnmaximise

                imageColor: JamiTheme.mapButtonColor
                normalColor: JamiTheme.transparentColor
                source: isFullScreen? JamiResources.close_fullscreen_24dp_svg : JamiResources.open_in_full_24dp_svg
                onClicked: {
                    if (!isFullScreen && !isMinimised) {
                        mapPopup.x = mapPopup.xPos
                        mapPopup.y = mapPopup.yPos
                    }
                    isFullScreen = !isFullScreen
                    isMinimised = false;
                }
            }

            PushButton {
                id: btnClose

                imageColor: JamiTheme.mapButtonColor
                normalColor: JamiTheme.transparentColor
                source: JamiResources.round_close_24dp_svg

                onClicked: {
                    PositionManager.stopSharingPosition();
                    PositionManager.stopPositioning();
                    PositionManager.setMapActive(false);
                    PositionManager.mapAutoOpening = false;

                }
            }
        }
    }
}

