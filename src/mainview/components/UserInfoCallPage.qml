
/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import QtQuick.Controls.Universal 2.12
import net.jami.Models 1.0

import "../../commoncomponents"

// Common element for IncomingCallPage and OutgoingCallPage
Rectangle {
    id: userInfoCallRect

    property int buttonPreferredSize: 48
    property string contactImgSource: ""
    property string bestName: "Best Name"
    property string bestId: "Best Id"

    function updateUI(accountId, convUid) {
        contactImgSource = "data:image/png;base64," + ClientWrapper.utilsAdaptor.getContactImageString(
                    accountId, convUid)
        bestName = ClientWrapper.utilsAdaptor.getBestName(accountId, convUid)
        var id = ClientWrapper.utilsAdaptor.getBestId(accountId, convUid)
        bestId = (bestName !== id) ? id : ""
    }

    color: "black"

    ColumnLayout {
        id: userInfoCallColumnLayout

        anchors.fill: parent

        Image {
            id: contactImg

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 48

            Layout.preferredWidth: 100
            Layout.preferredHeight: 100

            fillMode: Image.PreserveAspectFit
            source: contactImgSource
            asynchronous: true
        }

        Rectangle {
            id: userInfoCallPageTextRect

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 8

            Layout.preferredWidth: userInfoCallRect.width
            Layout.preferredHeight: jamiBestNameText.height + jamiBestIdText.height + 100

            color: "transparent"

            ColumnLayout {
                id: userInfoCallPageTextRectColumnLayout

                Text {
                    id: jamiBestNameText

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: userInfoCallPageTextRect.width
                    Layout.preferredHeight: 48

                    font.pointSize: JamiTheme.headerFontSize

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    text: textMetricsjamiBestNameText.elidedText
                    color: "white"

                    TextMetrics {
                        id: textMetricsjamiBestNameText
                        font: jamiBestNameText.font
                        text: bestName
                        elideWidth: userInfoCallPageTextRect.width - 48
                        elide: Qt.ElideMiddle
                    }
                }

                Text {
                    id: jamiBestIdText

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: userInfoCallPageTextRect.width
                    Layout.preferredHeight: 32

                    font.pointSize: JamiTheme.textFontSize

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    text: textMetricsjamiBestIdText.elidedText
                    color: Qt.lighter("white", 1.5)

                    TextMetrics {
                        id: textMetricsjamiBestIdText
                        font: jamiBestIdText.font
                        text: bestId
                        elideWidth: userInfoCallPageTextRect.width - 48
                        elide: Qt.ElideMiddle
                    }
                }
            }
        }
    }
}
