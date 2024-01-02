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
import QtQuick.Layouts
import net.jami.Constants 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    anchors.horizontalCenter: mapObject.horizontalCenter
    anchors.margins: 10
    anchors.bottom: mapObject.bottom

    RowLayout {
        Layout.alignment: Qt.AlignHCenter

        Rectangle {
            radius: 10
            Layout.preferredWidth: textTimer.width + 15
            Layout.preferredHeight: textTimer.height + 15
            color: JamiTheme.mapButtonsOverlayColor
            visible: textTimer.remainingTimeMs !== 0 && !isUnpin && webView.isLoaded && isSharingToCurrentConversation

            Text {
                id: textTimer

                anchors.centerIn: parent
                color: JamiTheme.mapButtonColor
                text: standartCountdown(Math.floor(remainingTimeMs / 1000))

                function standartCountdown(seconds) {
                    var minutes = Math.floor(seconds / 60);
                    var hour = Math.floor(minutes / 60);
                    minutes = minutes % 60;
                    var sec = seconds % 60;
                    if (hour) {
                        if (minutes)
                            return JamiStrings.xhourxmin.arg(hour).arg(minutes);
                        else
                            return JamiStrings.xhour.arg(hour);
                    }
                    if (minutes) {
                        if (sec)
                            return JamiStrings.xminxsec.arg(minutes).arg(sec);
                        else
                            return JamiStrings.xmin.arg(minutes);
                    }
                    return JamiStrings.xsec.arg(sec);
                }

                property int remainingTimeMs: 0
                Connections {
                    target: PositionManager
                    function onSendCountdownUpdate(key, remainingTime) {
                        if (key === attachedAccountId + "_" + currentConvId) {
                            textTimer.remainingTimeMs = remainingTime;
                        }
                    }
                }
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
            visible: !isSharingToCurrentConversation && !isUnpin && webView.isLoaded

            text: JamiStrings.shareLocation
            color: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBlue
            hoveredColor: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBlueHovered
            pressedColor: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBluePressed
            Layout.alignment: Qt.AlignHCenter
            property bool isHovered: false
            property string positioningError: "default"
            property bool isError: positioningError.length
            property int positionShareConvIdsCount: PositionManager.positionShareConvIdsCount
            property string currentConvId: CurrentConversation.id
            property bool isMapUnpin: isUnpin

            function errorString(posError) {
                if (posError === "locationServicesError")
                    return JamiStrings.locationServicesError;
                return JamiStrings.locationServicesClosedError;
            }

            onPositionShareConvIdsCountChanged: {
                isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId);
            }

            onCurrentConvIdChanged: {
                isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId);
            }

            onIsMapUnpinChanged: {
                isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId);
            }

            onClicked: {
                var sharingDuration = 60 * 1000 * UtilsAdapter.getAppValue(Settings.PositionShareDuration);
                if (!isError && !isUnpin) {
                    PositionManager.sharePosition(sharingDuration, attachedAccountId, currentConvId);
                }
                webView.runJavaScript("zoomTolayersExtent()");
            }

            MaterialToolTip {
                property bool isSharingPossible: !(sharePositionButton.isError && (sharePositionButton.positioningError !== "default"))

                visible: sharePositionButton.hovered
                text: isSharingPossible ? JamiStrings.shareLocationToolTip.arg(PositionManager.getmapTitle(attachedAccountId, currentConvId)) : sharePositionButton.errorString(sharePositionButton.positioningError)
            }
            Connections {
                target: PositionManager
                function onPositioningError(err) {
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
            text: stopAllSharing ? JamiStrings.shortStopAllSharings : JamiStrings.stopSharingLocation
            color: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedRed
            hoveredColor: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedRedHovered
            pressedColor: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedRedPressed
            Layout.alignment: Qt.AlignHCenter
            toolTipText: stopAllSharing ? isUnpin ? JamiStrings.unpinStopSharingTooltip : JamiStrings.stopAllSharings : JamiStrings.stopSharingSeveralConversationTooltip
            property bool isHovered: false
            property string positioningError
            property bool isError: positioningError.length
            property bool stopAllSharing: !(PositionManager.positionShareConvIdsCount >= 2 && !isUnpin && isSharingToCurrentConversation)
            onClicked: {
                if (!isError) {
                    if (stopAllSharing) {
                        PositionManager.stopSharingPosition();
                    } else {
                        stopSharingPositionPopup.open();
                    }
                }
            }
        }
    }
}
