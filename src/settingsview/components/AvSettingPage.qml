/*
 * Copyright (C) 2019-2020 by Savoir-faire Linux
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

import QtQuick 2.15
import QtQuick.Window 2.14
import QtQuick.Controls 2.15
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.14
import QtQuick.Controls.Styles 1.4
import net.jami.Models 1.0
import net.jami.Adapters 1.0

import "../../commoncomponents"

Rectangle {
    id: root

    property int preferredColumnWidth: Math.min(root.width / 2 - 50, 275)

    signal backArrowClicked

    onVisibleChanged: {
        if (!visible) {
            videoSettings.stopPreviewing()
            audioSettings.stopAudioMeter()
        }
    }

    function populateAVSettings() {
        audioSettings.populateAudioSettings()
        videoSettings.populateVideoSettings()
    }

    SettingsHeader {
        id: avSettingsHeader

        anchors.left: root.left
        anchors.leftMargin: (root.width - avSettingsColumnLayout.width) / 2
                            + JamiTheme.preferredMarginSize
        anchors.top: root.top

        title: JamiStrings.avSettingsTitle

        onBackArrowClicked: root.backArrowClicked()
    }

    ScrollView {
        id: scrollView

        property ScrollBar vScrollBar: ScrollBar.vertical
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        anchors.top: avSettingsHeader.bottom
        anchors.topMargin: JamiTheme.preferredMarginSize
        anchors.horizontalCenter: root.horizontalCenter

        height: root.height - JamiTheme.preferredMarginSize - avSettingsHeader.height
        width: root.width

        focus: true
        clip: true

        ColumnLayout {
            height: Math.min(scrollView.height, JamiTheme.preferredAvSettingsHeight)
            width: scrollView.width

            spacing: 0

            ColumnLayout {
                id: avSettingsColumnLayout

                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: JamiTheme.maximumWidthSettingsView

                // Audio
                AudioSettings {
                    id: audioSettings

                    Layout.fillWidth: true
                    Layout.leftMargin: JamiTheme.preferredMarginSize
                    Layout.rightMargin: JamiTheme.preferredMarginSize

                    itemWidth: preferredColumnWidth
                }

                // Video
                VideoSettings {
                    id: videoSettings

                    Layout.fillWidth: true
                    Layout.leftMargin: JamiTheme.preferredMarginSize
                    Layout.rightMargin: JamiTheme.preferredMarginSize

                    itemWidth: preferredColumnWidth
                }
            }
        }
    }
}
