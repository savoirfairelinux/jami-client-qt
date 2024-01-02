/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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

// JamiQmlUtils as a singleton is to provide global property entry
pragma Singleton
import QtQuick
import net.jami.Adapters 1.1
import net.jami.Enums 1.1

Item {
    property string qmlFilePrefix: "file:/"

    readonly property string mainViewLoadPath: "qrc:/mainview/MainView.qml"
    readonly property string wizardViewLoadPath: "qrc:/wizardview/WizardView.qml"
    readonly property string base64StringTitle: "data:image/png;base64,"

    property var accountCreationInputParaObject: ({})

    function setUpAccountCreationInputPara(inputPara) {
        JamiQmlUtils.accountCreationInputParaObject = {};
        Object.assign(JamiQmlUtils.accountCreationInputParaObject, inputPara);
        return accountCreationInputParaObject;
    }

    // MessageBar buttons in mainview points
    property var mainViewRectObj
    property var messageBarButtonsRowObj
    property var audioRecordMessageButtonObj
    property var videoRecordMessageButtonObj
    property var emojiPickerButtonObj
    property point audioRecordMessageButtonInMainViewPoint
    property point videoRecordMessageButtonInMainViewPoint
    property var emojiPickerButtonInMainViewPoint

    signal settingsPageRequested(int index)

    function updateMessageBarButtonsPoints() {
        if (messageBarButtonsRowObj && audioRecordMessageButtonObj && videoRecordMessageButtonObj) {
            audioRecordMessageButtonInMainViewPoint = messageBarButtonsRowObj.mapToItem(mainViewRectObj, audioRecordMessageButtonObj.x, audioRecordMessageButtonObj.y);
            videoRecordMessageButtonInMainViewPoint = messageBarButtonsRowObj.mapToItem(mainViewRectObj, videoRecordMessageButtonObj.x, videoRecordMessageButtonObj.y);
            emojiPickerButtonInMainViewPoint = messageBarButtonsRowObj.mapToItem(mainViewRectObj, emojiPickerButtonObj.x, emojiPickerButtonObj.y);
        }
    }

    Text {
        id: globalTextMetrics
    }

    function getTextBoundingRect(font, text) {
        globalTextMetrics.font = font;
        globalTextMetrics.text = text;
        return Qt.size(globalTextMetrics.contentWidth, globalTextMetrics.contentHeight);
    }

    function clamp(val, min, max) {
        return Math.min(Math.max(val, min), max);
    }

    property bool isDonationBannerVisible: getIsDonationBannerVisible()
    Connections {
        target: UtilsAdapter
        function onDonationCampaignSettingsChanged() {
            // Changing any of the donation campaign settings will trigger a recompute
            // of the banner visibility.
            updateIsDonationBannerVisible();
        }
    }

    function updateIsDonationBannerVisible() {
        isDonationBannerVisible = getIsDonationBannerVisible();
    }

    function getIsDonationBannerVisible() {
        // The banner is visible if the current date is after the date set in the settings and before the end date
        // And if the donation toggle is checked
        const isVisible = UtilsAdapter.getAppValue(Settings.Key.IsDonationVisible);
        const endDate = Date.parse(UtilsAdapter.getAppValue(Settings.Key.Donation2023EndDate));
        const startDate = Date.parse(UtilsAdapter.getAppValue(Settings.Key.Donation2023VisibleDate));
        const now = new Date();
        return isVisible && now < endDate && now >= startDate;
    }
}
