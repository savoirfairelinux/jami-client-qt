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
import net.jami.Models 1.1
import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: donation

    property bool donationVisible: JamiQmlUtils.isDonationBannerVisible()

    width: parent.width - 30
    height: donationTextRect.height + 45 > donationIcon.height + 20 ? donationTextRect.height + 45 : donationIcon.height + 20
    radius: 5

    color: JamiTheme.donationBackgroundColor

    GridLayout {
        id: donationLayout

        anchors.fill: parent
        columns: 3
        rows: 2
        rowSpacing: 0
        columnSpacing: 10

        Rectangle {
            id: donationIcon

            Layout.row: 0
            Layout.column: 0
            Layout.rowSpan: 2
            Layout.preferredHeight: 53
            Layout.preferredWidth: 43
            Layout.leftMargin: 10
            Layout.topMargin: 10
            Layout.bottomMargin: 15

            color: JamiTheme.transparentColor

            Image {
                id: donationImage
                height: parent.height
                width: parent.width
                anchors.centerIn: parent
                source: JamiResources.icon_donate_svg
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.openUrlExternally(JamiTheme.donationUrl);
                }
            }
        }

        Rectangle {
            id: donationTextRect

            Layout.topMargin: 10
            Layout.row: 0
            Layout.column: 1
            Layout.columnSpan: 2
            Layout.preferredHeight: donationText.height
            Layout.preferredWidth: parent.width - 74
            Layout.bottomMargin: 5
            color: JamiTheme.transparentColor

            Text {
                id: donationText
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: parent.width
                height: contentHeight
                text: JamiStrings.donationText
                wrapMode: Text.WordWrap

                font.pointSize: JamiTheme.textFontSize
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.openUrlExternally(JamiTheme.donationUrl);
                }
            }
        }

        Rectangle {
            id: notNowRect

            Layout.row: 1
            Layout.column: 1
            Layout.preferredHeight: 30
            Layout.preferredWidth: (parent.width - 55) / 2

            color: JamiTheme.transparentColor

            PushButton {
                //Scaffold{}
                id: notNowButton
                anchors.top: parent.top
                anchors.left: parent.left
                height: 15
                width: 75
                preferredLeftMargin: 0
                preferredRightMargin: 0
                buttonText: JamiStrings.notNow
                buttonTextColor: JamiTheme.donationButtonTextColor
                buttonTextFontSize: JamiTheme.textFontSize + 4
                normalColor: "transparent"
                hoveredColor: "transparent"
                pressedColor: "transparent"
                onClicked: {
                    // When the user clicks on "Not now", we set the donation date to 7 days from now (1 for the test)
                    UtilsAdapter.setAppValue(Settings.Key.Donation2023VisibleDate, new Date(new Date().getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 16).replace("T", " "));
                    donation.donationVisible = Qt.binding(() => JamiQmlUtils.isDonationBannerVisible());
                }
                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: {
                        // When the user clicks on "Not now", we set the donation date to 7 days from now (1 for the test)
                        UtilsAdapter.setAppValue(Settings.Key.Donation2023VisibleDate, new Date(new Date().getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 16).replace("T", " "));
                        donation.donationVisible = Qt.binding(() => JamiQmlUtils.isDonationBannerVisible());
                    }
                }
            }
        }

        Rectangle {
            id: donateRect
            Layout.row: 1
            Layout.column: 2
            Layout.preferredHeight: 30
            Layout.preferredWidth: (parent.width - 50) / 2
            color: JamiTheme.transparentColor

            PushButton {
                //Scaffold{}
                id: donateButton
                anchors.top: parent.top
                anchors.left: parent.left
                height: 15
                width: 75
                preferredLeftMargin: 0
                preferredRightMargin: 0
                buttonText: JamiStrings.donation
                buttonTextColor: JamiTheme.donationButtonTextColor
                buttonTextFontSize: JamiTheme.textFontSize + 4
                normalColor: "transparent"
                hoveredColor: "transparent"
                pressedColor: "transparent"
                onClicked: {
                    Qt.openUrlExternally(JamiTheme.donationUrl);
                }
                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: {
                        Qt.openUrlExternally(JamiTheme.donationUrl);
                    }
                }
            }
        }
    }
}
