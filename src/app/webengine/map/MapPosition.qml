/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
        root.destroy();
    }

    Connections {
        target: PositionManager

        function onPinMapSignal(key) {
            if (key === attachedAccountId) {
                isUnpin = false;
                mapObject.state = "pin";
                windowUnpin.close();
            }
        }

        function onCloseMap(key) {
            if (key === attachedAccountId)
                closeMapPosition();
        }

        function onUnPinMapSignal(key) {
            if (key === attachedAccountId) {
                isUnpin = true;
                mapObject.state = "unpin";
                windowUnpin.show();
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

            width: mapObject.width
            height: mapObject.height
        }

        onClosing: {
            if (isUnpin) {
                PositionManager.setMapInactive(attachedAccountId);
            }
        }
    }

    Item {
        id: parentPin

        width: mapObject.width
        height: mapObject.height

        Rectangle {
            id: mapObject

            x: xPos
            y: yPos
            width: root.isUnpin ? windowUnpin.width : isFullScreen ? root.maxWidth : windowSize
            height: root.isUnpin ? windowUnpin.height : isFullScreen ? root.maxHeight - yPos : windowSize

            property bool isFullScreen: false
            property real windowSize: windowPreferedSize > JamiTheme.minimumMapWidth ? windowPreferedSize : JamiTheme.minimumMapWidth
            property real windowPreferedSize: root.maxWidth > root.maxHeight ? root.maxHeight / 3 : root.maxWidth / 3
            property real xPos: 0
            property real yPos: root.isUnpin ? 0 : JamiTheme.qwkTitleBarHeight

            states: [
                State {
                    name: "unpin"
                    ParentChange {
                        target: mapObject
                        parent: parentUnPin
                        x: 0
                        y: 0
                    }
                },
                State {
                    name: "pin"
                    ParentChange {
                        target: mapObject
                        parent: parentPin
                        x: xPos
                        y: JamiTheme.qwkTitleBarHeight
                    }
                }
            ]
            property alias webView: webView

            WebEngineView {
                id: webView

                layer.enabled: !isFullScreen
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: webView.width
                        height: webView.height
                        radius: 10
                    }
                }

                width: parent.width
                height: parent.height

                property string mapHtml: ":/webengine/map/map.html"
                property string olCss: ":/webengine/map/ol.css"
                property string mapJs: "../../webengine/map/map.js"
                property string olJs: "../../webengine/map/ol.js"
                property bool isLoaded: false
                property var positionList: PositionManager.positionList
                property var avatarPositionList: PositionManager.avatarPositionList

                function loadScripts() {
                    var scriptMapJs = {
                        "sourceUrl": Qt.resolvedUrl(mapJs),
                        "injectionPoint": WebEngineScript.DocumentReady,
                        "worldId": WebEngineScript.MainWorld
                    };
                    var scriptOlJs = {
                        "sourceUrl": Qt.resolvedUrl(olJs),
                        "injectionPoint": WebEngineScript.DocumentReady,
                        "worldId": WebEngineScript.MainWorld
                    };
                    userScripts.collection = [scriptOlJs, scriptMapJs];
                }
                Connections {
                    target: PositionManager

                    function onPositionShareAdded(shareInfo) {
                        if (webView.isLoaded) {
                            if (shareInfo.account === attachedAccountId) {
                                var curLong = shareInfo.long;
                                var curLat = shareInfo.lat;
                                webView.runJavaScript("newPosition([" + curLong + "," + curLat + "], '" + shareInfo.author + "', '" + shareInfo.avatar + "', '" + shareInfo.authorName + "' )");
                                webView.runJavaScript("zoomTolayersExtent()");
                            }
                        }
                    }

                    function onPositionShareUpdated(shareInfo) {
                        if (webView.isLoaded) {
                            if (shareInfo.account === attachedAccountId) {
                                var curLong = shareInfo.long;
                                var curLat = shareInfo.lat;
                                webView.runJavaScript("updatePosition([" + curLong + "," + curLat + "], '" + shareInfo.author + "' )");
                            }
                        }
                    }

                    function onPositionShareRemoved(author, accountId) {
                        if (webView.isLoaded) {
                            if (accountId === attachedAccountId) {
                                webView.runJavaScript("removePosition( '" + author + "' )");
                                webView.runJavaScript("zoomTolayersExtent()");
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    loadHtml(UtilsAdapter.qStringFromFile(mapHtml), mapHtml);
                    loadScripts();
                }

                onLoadingChanged: function (loadingInfo) {
                    if (loadingInfo.status === WebEngineView.LoadSucceededStatus) {
                        attachedAccountId = CurrentAccount.id;
                        runJavaScript(UtilsAdapter.getStyleSheet("olcss", UtilsAdapter.qStringFromFile(olCss)));
                        webView.isLoaded = true;
                        webView.runJavaScript("setMapView([" + 0 + "," + 0 + "], " + 1 + " );");
                        PositionManager.startPositioning();
                        //load locations that were received before this conversation was opened
                        PositionManager.loadPreviousLocations(attachedAccountId);
                        isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId);
                    }
                }
            }

            MapPositionSharingControl {
            }

            MapPositionOverlay {
            }

            StopSharingPositionPopup {
                id: stopSharingPositionPopup
            }
        }
    }
}
