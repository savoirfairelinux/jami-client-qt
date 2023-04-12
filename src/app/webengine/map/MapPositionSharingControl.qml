/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
    anchors.bottom: mapObject.bottom
    anchors.horizontalCenter: mapObject.horizontalCenter
    anchors.margins: 10

    RowLayout {
        Layout.alignment: Qt.AlignHCenter

        Rectangle {
            Layout.preferredHeight: textTimer.height + 15
            Layout.preferredWidth: textTimer.width + 15
            color: JamiTheme.mapButtonsOverlayColor
            radius: 10
            visible: textTimer.remainingTimeMs !== 0 && !isUnpin && webView.isLoaded && isSharingToCurrentConversation

            Text {
                id: textTimer
                property int remainingTimeMs: 0

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
                            return qsTr("%1h%2min").arg(hour).arg(minutes);
                        else
                            return qsTr("%1h").arg(hour);
                    }
                    if (minutes) {
                        if (sec)
                            return qsTr("%1m%2sec").arg(minutes).arg(sec);
                        else
                            return qsTr("%1m").arg(minutes);
                    }
                    return qsTr("%1sec").arg(sec);
                }

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
            property string currentConvId: CurrentConversation.id
            property bool isError: positioningError.length
            property bool isHovered: false
            property bool isMapUnpin: isUnpin
            property int positionShareConvIdsCount: PositionManager.positionShareConvIdsCount
            property string positioningError: "default"

            Layout.alignment: Qt.AlignHCenter
            color: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBlue
            hoveredColor: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBlueHovered
            preferredWidth: text.contentWidth
            pressedColor: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedBluePressed
            primary: true
            text: JamiStrings.shareLocation
            textLeftPadding: JamiTheme.buttontextPadding
            textRightPadding: JamiTheme.buttontextPadding
            visible: !isSharingToCurrentConversation && !isUnpin && webView.isLoaded

            function errorString(posError) {
                if (posError === "locationServicesError")
                    return JamiStrings.locationServicesError;
                return JamiStrings.locationServicesClosedError;
            }

            onClicked: {
                var sharingDuration = 60 * 1000 * UtilsAdapter.getAppValue(Settings.PositionShareDuration);
                if (!isError && !isUnpin) {
                    PositionManager.sharePosition(sharingDuration, attachedAccountId, currentConvId);
                }
                webView.runJavaScript("zoomTolayersExtent()");
            }
            onCurrentConvIdChanged: {
                isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId);
            }
            onIsMapUnpinChanged: {
                isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId);
            }
            onPositionShareConvIdsCountChanged: {
                isSharingToCurrentConversation = PositionManager.isPositionSharedToConv(attachedAccountId, currentConvId);
            }

            MaterialToolTip {
                property bool isSharingPossible: !(sharePositionButton.isError && (sharePositionButton.positioningError !== "default"))

                text: isSharingPossible ? JamiStrings.shareLocationToolTip.arg(PositionManager.getmapTitle(attachedAccountId, currentConvId)) : sharePositionButton.errorString(sharePositionButton.positioningError)
                visible: sharePositionButton.hovered
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
            property bool isError: positioningError.length
            property bool isHovered: false
            property string positioningError
            property bool stopAllSharing: !(PositionManager.positionShareConvIdsCount >= 2 && !isUnpin && isSharingToCurrentConversation)

            Layout.alignment: Qt.AlignHCenter
            color: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedRed
            hoveredColor: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedRedHovered
            preferredWidth: text.contentWidth
            pressedColor: isError ? JamiTheme.buttonTintedGreyInactive : JamiTheme.buttonTintedRedPressed
            primary: true
            text: stopAllSharing ? JamiStrings.shortStopAllSharings : JamiStrings.stopSharingLocation
            textLeftPadding: JamiTheme.buttontextPadding
            textRightPadding: JamiTheme.buttontextPadding
            toolTipText: stopAllSharing ? isUnpin ? JamiStrings.unpinStopSharingTooltip : JamiStrings.stopAllSharings : JamiStrings.stopSharingSeveralConversationTooltip
            visible: isSharing

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
