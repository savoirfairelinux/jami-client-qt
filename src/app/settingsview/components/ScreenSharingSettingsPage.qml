

/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
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
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1

import "../../commoncomponents"

Rectangle {
    id: root

    property int contentWidth: currentAccountEnableColumnLayout.width
    property int preferredHeight: currentAccountEnableColumnLayout.implicitHeight
    property int preferredColumnWidth : Math.min(root.width / 2 - 50, 350)
    property int preferredWidth: Math.min(JamiTheme.maximumWidthSettingsView , root.width - JamiTheme.preferredMarginSize*4)

    property int itemWidth: 150

    signal navigateToMainView
    signal navigateToNewWizardView

    color: JamiTheme.secondaryBackgroundColor

    ColumnLayout {
        id: currentAccountEnableColumnLayout

        anchors.left: root.left
        anchors.top: root.top
        width: Math.min(JamiTheme.maximumWidthSettingsView, root.width)
        spacing: JamiTheme.wizardViewPageBackButtonMargins *2
        anchors.topMargin: JamiTheme.wizardViewPageBackButtonSize

        SettingsComboBox {
            id: screenSharingFPSComboBoxSetting

            visible: modelSize > 0

            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.bottomMargin: JamiTheme.preferredMarginSize

            widthOfComboBox: itemWidth
            fontPointSize: JamiTheme.settingsFontSize

            tipText: JamiStrings.selectScreenSharingFPS
            labelText: JamiStrings.fps
            currentSelectionText: VideoDevices.screenSharingDefaultFps.toString()
            placeholderText: VideoDevices.screenSharingDefaultFps.toString()
            comboModel: ListModel { id: screenSharingFpsModel }
            role: "FPS"
            Component.onCompleted: {
                var elements = VideoDevices.sharingFpsSourceModel
                for (var item in elements) {
                    screenSharingFpsModel.append({"FPS": elements[item]})
                }
            }

            onActivated: VideoDevices.setDisplayFPS(screenSharingFpsModel.get(modelIndex).FPS)
        }

    }

}
