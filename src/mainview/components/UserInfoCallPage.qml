/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
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
import QtQuick.Layouts 1.14
import QtQuick.Controls.Universal 2.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

// Common element for IncomingCallPage and OutgoingCallPage
Rectangle {
    id: userInfoCallRect

    property int buttonPreferredSize: 48
    property bool isAudioOnly: false
    property bool isIncoming: false
    property string bestName: "Best Name"

    function updateUI(accountId, convUid, audioCall, incomingCall) {
        contactImg.updateImage(convUid)
        userInfoCallRect.bestName = UtilsAdapter.getBestName(accountId, convUid)
        userInfoCallRect.isAudioOnly = audioCall
        userInfoCallRect.isIncoming = incomingCall
    }

    color: "transparent"

    ColumnLayout {
        id: userInfoCallColumnLayout

        anchors.fill: parent

        PushButton {
            id: backButton

            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.rightMargin: JamiTheme.preferredMarginSize
            Layout.topMargin: JamiTheme.preferredMarginSize
            Layout.leftMargin: JamiTheme.preferredMarginSize

            source: "qrc:/images/icons/ic_arrow_back_24px.svg"

            pressedColor: JamiTheme.invertedPressedButtonColor
            hoveredColor: JamiTheme.invertedHoveredButtonColor
            normalColor: JamiTheme.invertedNormalButtonColor

            imageColor: JamiTheme.whiteColor

            toolTipText: qsTr("Toggle to display side panel")

            visible: mainView.sidePanelOnly

            onClicked: mainView.showWelcomeView()
        }

        AvatarImage {
            id: contactImg

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 60

            Layout.preferredWidth: 100
            Layout.preferredHeight: 100

            mode: AvatarImage.Mode.FromConvUid
            showPresenceIndicator: false
        }

        Rectangle {
            id: userInfoCallPageTextRect

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 8

            Layout.preferredWidth: userInfoCallRect.width
            Layout.preferredHeight: jamiBestNameText.height + jamiComplementarText.height + 50

            color: "transparent"

            ColumnLayout {
                id: userInfoCallPageTextRectColumnLayout

                Text {
                    id: jamiBestNameText

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: userInfoCallPageTextRect.width
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight

                    font.pointSize: JamiTheme.headerFontSize

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    text: textMetricsjamiBestNameText.elidedText
                    color: "white"

                    TextMetrics {
                        id: textMetricsjamiBestNameText
                        font: jamiBestNameText.font
                        text: {
                            if (isIncoming) {
                                if (isAudioOnly)
                                    return JamiStrings.audioCallFrom + " " + bestName
                                else
                                    return JamiStrings.videoCallFrom + " " + bestName
                            }
                            return bestName
                        }
                        elideWidth: userInfoCallPageTextRect.width - 48
                        elide: Qt.ElideMiddle
                    }
                }

                Text {
                    id: jamiComplementarText

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: userInfoCallPageTextRect.width
                    Layout.preferredHeight: JamiTheme.preferredFieldHeight

                    font.pointSize: JamiTheme.textFontSize

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    text: textMetricsjamiComplementarText.elidedText
                    color: Qt.lighter("white", 1.5)

                    TextMetrics {
                        id: textMetricsjamiComplementarText
                        font: jamiComplementarText.font
                        text: {
                            if (isIncoming && !isAudioOnly)
                                return "Your camera is active. Click on the camera\nto deactivate it and answer in audio."
                            return ""
                        }
                    }
                }
            }
        }
    }
}
