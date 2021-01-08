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
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls.Universal 2.14
import QtGraphicalEffects 1.14
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

// Import qml component files.
import "components"
import "../"
import "../wizardview"
import "../settingsview"
import "../settingsview/components"
import "../commoncomponents"

Item {
    id: mainView

    VideoRenderingItemBase {
        id: previewWidget

        anchors.centerIn: mainView

        width: 150
        height: 150
    }

    MaterialButton {
        id: downloadButton

        anchors.bottom: mainView.bottom
        anchors.horizontalCenter: mainView.horizontalCenter

        width: 150
        height: JamiTheme.preferredFieldHeight

        toolTipText: JamiStrings.tipChooseDownloadFolder
        text: "sssssssssssss"
        source: "qrc:/images/icons/round-folder-24px.svg"
        color: JamiTheme.buttonTintedGrey
        hoveredColor: JamiTheme.buttonTintedGreyHovered
        pressedColor: JamiTheme.buttonTintedGreyPressed
    }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: AccountAdapter.startPreviewing(false)
    }
}
