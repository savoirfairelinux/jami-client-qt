/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1

import "../../commoncomponents"

Control {
    id: control

    function bumpDonationReminderVisibility() {
        // Calculate the time 7 days from now
        var futureDate = new Date(new Date().getTime() + 7 * 24 * 60 * 60 * 1000);
        var formattedDate = Qt.formatDateTime(futureDate, "yyyy-MM-dd hh:mm");
        UtilsAdapter.setAppValue(Settings.Key.Donation2023VisibleDate, formattedDate);
    }

    MouseArea {
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
        onClicked: Qt.openUrlExternally(JamiTheme.donationUrl)
    }

    padding: 10
    background: Rectangle {
        color: JamiTheme.donationBackgroundColor
        radius: 5
    }
    contentItem: RowLayout {
        spacing: 16
        Image {
            // The image fades to the top, so align it to the bottom.
            Layout.alignment: Qt.AlignVCenter
            source: JamiResources.icon_donate_svg
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 8

            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignTop

                text: JamiStrings.donationText
                wrapMode: Text.WordWrap
                font.pointSize: JamiTheme.textFontSize
            }

            RowLayout {
                spacing: 32
                Layout.alignment: Qt.AlignBaseline
                component BannerButton : PushButton {
                    id: bannerButton
                    contentItem: Text {
                        text: bannerButton.text
                        color: JamiTheme.donationButtonTextColor
                        font.pointSize: JamiTheme.textFontSize
                        MouseArea {
                            cursorShape: Qt.PointingHandCursor
                            anchors.fill: parent
                            onClicked: bannerButton.clicked()
                        }
                    }
                    background: null
                }
                // Clicking "Not now" sets the donation date to 7 days from now.
                BannerButton {
                    text: JamiStrings.notNow
                    onClicked: bumpDonationReminderVisibility()
                }
                BannerButton {
                    text: JamiStrings.donation
                    onClicked: Qt.openUrlExternally(JamiTheme.donationUrl)
                }
            }
        }
    }
}
