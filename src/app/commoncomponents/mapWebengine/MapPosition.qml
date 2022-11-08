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


Component {
    id: mapComp

    Rectangle
    {
        id: mapPopup

        x: 10
        y: 10
        width: isFullScreen ? root.width : windowSize
        height: isMinimised
                ? buttonOverlay.height + buttonsChoseSharing.height + 30
                : isFullScreen ? root.height : windowSize

        property bool isFullScreen: false
        property bool isMinimised: false
        property real windowSize: windowPreferedSize > JamiTheme.minimumMapWidth
                                  ? windowPreferedSize
                                  : JamiTheme.minimumMapWidth
        property real windowPreferedSize: root.width > root.height
                                          ? root.height / 3
                                          : root.width / 3
        WebEngineView {
            id: webView

            width: parent.width
            height: parent.height

            property string mapHtml: ":/commoncomponents/mapWebengine/map.html"
            property string olCss: ":/commoncomponents/mapWebengine/ol.css"
            property string mapJs: "../../commoncomponents/mapWebengine/map.js"
            property string olJs: "../../commoncomponents/mapWebengine/ol.js"
            property bool isLoaded: false
            property var positionList: MessagesAdapter.positionList;
            property var avatarPositionList: MessagesAdapter.avatarPositionList;
            property bool couldSendAvatar: false
            property bool setZoom: false
            property bool isSharing: (MessagesAdapter.positionShareConvIds.length !== 0 )

            function dynamicZoom() {

                var minPosLat = 181;
                var maxPosLat = -181;
                var minPosLong = 91;
                var maxPosLong = -91;

                if (webView.isLoaded) {
                    for(var i = 0; i < positionList.length; i++) {
                        if(positionList[i].lat > maxPosLat )
                            maxPosLat = positionList[i].lat;
                        if(positionList[i].lat < minPosLat )
                            minPosLat = positionList[i].lat
                        if(positionList[i].long > maxPosLong )
                            maxPosLong = positionList[i].long;
                        if(positionList[i].long < minPosLong )
                            minPosLong = positionList[i].long
                    }
                    runJavaScript("dynamicZoom( " +minPosLong + ","
                                  +minPosLat + ","
                                  +maxPosLong +","
                                  + maxPosLat+ ");");
                }
            }

            function sendAvatarListToJs () {
                for(var i = 0; i < avatarPositionList.length; i++) {
                    runJavaScript("setAvatarList ( '" + avatarPositionList[i].author + "','" +avatarPositionList[i].avatar + "' );");
                }
                setZoom = true
            }

            Component.onCompleted: {

                loadHtml(UtilsAdapter.qStringFromFile(mapHtml), mapHtml);
                var scriptMapJs = {
                    sourceUrl: Qt.resolvedUrl(mapJs),
                    injectionPoint: WebEngineScript.DocumentReady,
                    worldId: WebEngineScript.MainWorld
                }

                var scriptOlJs = { name: "olJs",
                    sourceUrl: Qt.resolvedUrl(olJs),
                    injectionPoint: WebEngineScript.DocumentReady,worldId: WebEngineScript.MainWorld }

                userScripts.collection = [ scriptOlJs, scriptMapJs ];
                couldSendAvatar = false;
            }

            onVisibleChanged: {
                couldSendAvatar = false;
            }

            onLoadingChanged: function (loadingInfo) {
                if (loadingInfo.status === WebEngineView.LoadSucceededStatus) {
                    webView.isLoaded = true
                    runJavaScript(UtilsAdapter.getStyleSheet("olcss",UtilsAdapter.qStringFromFile(olCss)))
                    runJavaScript("setMapView([" + 0 + ","+ 0  + "], " + 1 + " );" );
                    MessagesAdapter.startPositioning()
                }
            }

            onAvatarPositionListChanged : {
                if(webView.isLoaded) {
                    couldSendAvatar = true;
                    sendAvatarListToJs();
                }
            }

            onPositionListChanged: {
                if(webView.isLoaded) {
                    if (!couldSendAvatar) {
                        couldSendAvatar = true;
                        sendAvatarListToJs();
                    }
                    runJavaScript("resetPoints();" );
                    for(var i = 0; i < positionList.length; i++) {
                        runJavaScript("printIcon([" + positionList[i].long + ","+ positionList[i].lat  + "], '" + positionList[i].author+ "' );" );
                    }
                    if(setZoom) {
                        dynamicZoom()
                        setZoom = false
                    }
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
                    visible: webView.isSharing && MessagesAdapter.timeSharingRemaining

                    Text {
                        id: textTimer

                        anchors.centerIn: parent
                        color: JamiTheme.mapButtonColor
                        text: remainingTimeMs <= 1
                              ? remainingTimeMs + " " + JamiStrings.minuteLeft
                              : remainingTimeMs + " " + JamiStrings.minutesLeft

                        Layout.alignment: Qt.AlignHCenter

                        property int remainingTimeMs: Math.ceil(MessagesAdapter.timeSharingRemaining / 1000 / 60)
                    }
                }
            }

            MaterialButton {
                id: sharePositionButton

                preferredWidth: text.contentWidth
                textLeftPadding: JamiTheme.buttontextPadding
                textRightPadding: JamiTheme.buttontextPadding
                primary:true
                text: webView.isSharing ?  JamiStrings.stopSharingPosition : JamiStrings.sharePosition
                color: webView.isSharing ? JamiTheme.buttonTintedRed : JamiTheme.buttonTintedBlue
                hoveredColor:webView.isSharing ? JamiTheme.buttonTintedRedHovered : JamiTheme.buttonTintedBlueHovered
                pressedColor: webView.isSharing ? JamiTheme.buttonTintedRedPressed: JamiTheme.buttonTintedBluePressed
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    if(webView.isSharing) {
                        MessagesAdapter.stopSharingPosition();
                    } else {
                        if( buttonsChoseSharing.shortSharing)
                            MessagesAdapter.sharePosition(10 * 60 * 1000);
                        else
                            MessagesAdapter.sharePosition(60 * 60 * 1000);
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
                        webView.dynamicZoom()
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
                            mapPopup.x = 0
                            mapPopup.y = 0
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
                        MessagesAdapter.setMapActive(false);
                        MessagesAdapter.stopSharingPosition();
                    }
                }
            }
        }
    }
}
