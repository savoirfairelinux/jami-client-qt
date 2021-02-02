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
import QtGraphicalEffects 1.14
import QtQuick.Layouts 1.14
import net.jami.Models 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

// Overlay menu for conference moderation
Rectangle {
    id: root

    property bool hasMinimumSize: true
    property int buttonPreferredSize: 24
    property int iconButtonPreferredSize: 16

    property int minimumWidth: 260 //Math.max(114), visibleButtons * 37 + 21 * 2)

    property int minimumHeight: 114
    property int visibleButtons: toggleModerator.visible
                                 + toggleMute.visible
                                 + maximizeParticipant.visible
                                 + minimizeParticipant.visible
                                 + hangupParticipant.visible

    property int buttonsSize: visibleButtons * 24 + 8 * 2

    property bool isBarLayout: hasMinimumSize
    property int participantWidth: 10

    property string uri: ""
    property string bestName: ""
    property bool isLocalMuted: false
    property bool showSetModerator: false
    property bool showUnsetModerator: false
    property bool showModeratorMute: false
    property bool showModeratorUnmute: false
    property bool showMaximize: false
    property bool showMinimize: false
    property bool showHangup: false

    signal mouseAreaExited
    signal mouseChanged

    //width: hasMinimumSize? (bestNameLabel.width + buttonsSize) : 114 // minimumWidth
    width: bestNameLabel.contentWidth + buttonsSize + 32

    height: hasMinimumSize? 30 : 114 // minimumHeight

    anchors.bottom: hasMinimumSize? parent.bottom : undefined

    color: JamiTheme.darkGreyColorOpacity
    radius: hasMinimumSize? 0 : 10

    MouseArea {
        id: mouseAreaHover

        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton

        onExited: {
            mouseAreaExited()
        }

        onMouseXChanged: {
            mouseChanged()
            console.error(root.width)
        }

//        Rectangle {
//            id: rectBarLayout
//            height: 30
//            width: bestNameLabel.width + buttonsSize
//            anchors.bottom: parent.bottom
//            color: JamiTheme.darkGreyColorOpacity
//            visible: isBarLayout
//        }

        Text {
            id: bestNameLabel
            anchors {
                left: isBarLayout? parent.left : undefined
                leftMargin: isBarLayout? 8 : 0
                bottom: isBarLayout? parent.bottom : undefined
                bottomMargin: isBarLayout? 8 : 0
                horizontalCenter: isBarLayout? undefined : parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            TextMetrics {
                id: participantMetricsColumn
                text: bestName
                elide: Text.ElideRight
                elideWidth: Math.max(participantWidth - buttonsSize, 80)
            }

            text: participantMetricsColumn.elidedText
            color: JamiTheme.whiteColor
            font.pointSize: JamiTheme.participantFontSize
            horizontalAlignment: isBarLayout? Text.AlignLeft : Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        RowLayout {
            id: rowLayoutButtons

            anchors {
                right: isBarLayout? parent.right : undefined
                rightMargin: isBarLayout? 12 : 0
//                bottom: isBarLayout? parent.bottom : undefined
//                top: isBarLayout? undefined : bestNameLabel.bottom
//                topMargin: isBarLayout? 0 : 8
                ///horizontalCenter: isBarLayout? undefined : parent.horizontalCenter
                //verticalCenter: isBarLayout? rectBarLayout.verticalCenter : undefined
                verticalCenter: parent.verticalCenter
            }

            implicitWidth: buttonsSize

            //spacing: 4

            PushButton {
                id: toggleModerator

                visible: (showSetModerator || showUnsetModerator)
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize
                preferredSize: iconButtonPreferredSize
                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: "qrc:/images/icons/moderator.svg"
                imageColor: JamiTheme.whiteColor

                onClicked: CallAdapter.setModerator(uri, showSetModerator)
                onHoveredChanged: toggleModeratorToolTip.visible = hovered

                Text {
                    id: toggleModeratorToolTip

                    visible: false
                    width: parent.width
                    text: showSetModerator? JamiStrings.setModerator
                                          : JamiStrings.unsetModerator
                    horizontalAlignment: Text.AlignHCenter
                    anchors {
                        bottom: isBarLayout? parent.top : undefined
                        bottomMargin: isBarLayout? 6 : undefined
                        top: isBarLayout? undefined : parent.bottom
                        topMargin: isBarLayout? undefined : 6
                    }
                    color: JamiTheme.whiteColor
                    font.pointSize: JamiTheme.tinyFontSize
                }
            }

            PushButton {
                id: toggleMute

                visible: showModeratorMute || showModeratorUnmute
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize
                Layout.alignment: Qt.AlignVCenter
                preferredSize: iconButtonPreferredSize

                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: showModeratorMute? "qrc:/images/icons/mic-24px.svg"
                                         : "qrc:/images/icons/mic_off-24px.svg"
                imageColor: JamiTheme.whiteColor

                onClicked: CallAdapter.muteParticipant(uri, showModeratorMute)
                onHoveredChanged: {
                    toggleParticipantToolTip.visible = hovered
                    localMutedText.visible = hovered && isLocalMuted
                }

                Text {
                    id: toggleParticipantToolTip

                    visible: false
                    width: parent.width
                    text: showModeratorMute? JamiStrings.muteParticipant
                                           : JamiStrings.unmuteParticipant
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    anchors {
                        bottom: isBarLayout? parent.top : undefined
                        bottomMargin: isBarLayout? (localMutedText.visible? 20 : 6) : undefined
                        top: isBarLayout? undefined : parent.bottom
                        topMargin: isBarLayout? undefined : 6
                    }
                    color: JamiTheme.whiteColor
                    font.pointSize: JamiTheme.tinyFontSize
                }

                Text {
                    id: localMutedText

                    visible: false
                    width: parent.width
                    text: "(" + JamiStrings.localMuted + ")"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    anchors {
                        top: toggleParticipantToolTip.bottom
                    }
                    color: JamiTheme.whiteColor
                    font.pointSize: JamiTheme.tinyFontSize
                }
            }

            PushButton {
                id: maximizeParticipant

                visible: showMaximize
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize
                preferredSize: iconButtonPreferredSize

                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: "qrc:/images/icons/open_in_full-24px.svg"
                imageColor: JamiTheme.whiteColor

                onClicked: CallAdapter.maximizeParticipant(uri)
                onHoveredChanged: maximizeParticipantToolTip.visible = hovered

                Text {
                    id: maximizeParticipantToolTip

                    visible: false
                    width: parent.width
                    text: JamiStrings.maximizeParticipant
                    horizontalAlignment: Text.AlignHCenter
                    anchors {
                        bottom: isBarLayout? parent.top : undefined
                        bottomMargin: isBarLayout? 6 : undefined
                        top: isBarLayout? undefined : parent.bottom
                        topMargin: isBarLayout? undefined : 6
                    }
                    color: JamiTheme.whiteColor
                    font.pointSize: JamiTheme.tinyFontSize
                }
            }

            PushButton {
                id: minimizeParticipant

                visible: showMinimize
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize
                preferredSize: iconButtonPreferredSize

                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: "qrc:/images/icons/close_fullscreen-24px.svg"
                imageColor: JamiTheme.whiteColor
                onClicked: CallAdapter.minimizeParticipant(uri)
                onHoveredChanged: minimizeParticipantToolTip.visible = hovered

                Text {
                    id: minimizeParticipantToolTip

                    visible: false
                    width: parent.width
                    text: JamiStrings.minimizeParticipant
                    horizontalAlignment: Text.AlignHCenter
                    anchors {
                        bottom: isBarLayout? parent.top : undefined
                        bottomMargin: isBarLayout? 6 : undefined
                        top: isBarLayout? undefined : parent.bottom
                        topMargin: isBarLayout? undefined : 6
                    }
                    color: JamiTheme.whiteColor
                    font.pointSize: JamiTheme.tinyFontSize
                }
            }

            PushButton {
                id: hangupParticipant

                visible: showHangup
                Layout.preferredWidth: buttonPreferredSize
                Layout.preferredHeight: buttonPreferredSize
                preferredSize: iconButtonPreferredSize

                normalColor: JamiTheme.buttonConference
                hoveredColor: JamiTheme.buttonConferenceHovered
                pressedColor: JamiTheme.buttonConferencePressed

                source: "qrc:/images/icons/ic_block_24px.svg"
                imageColor: JamiTheme.whiteColor
                onClicked: CallAdapter.hangupParticipant(uri)
                onHoveredChanged: hangupParticipantToolTip.visible = hovered

                Text {
                    id: hangupParticipantToolTip

                    visible: false
                    width: parent.width
                    text: JamiStrings.hangupParticipant
                    horizontalAlignment: Text.AlignHCenter
                    anchors {
                        bottom: isBarLayout? parent.top : undefined
                        bottomMargin: isBarLayout? 6 : undefined
                        top: isBarLayout? undefined : parent.bottom
                        topMargin: isBarLayout? undefined : 6
                    }
                    color: JamiTheme.whiteColor
                    font.pointSize: JamiTheme.tinyFontSize
                }
            }
        }
    }
}
