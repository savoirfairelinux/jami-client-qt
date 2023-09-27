/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

    function isDonationBannerVisible() {
        // The banner is visible if the current date is after the date set in the settings and before the end date
        // And if the donation toggle is checked
        var isDonationVisible = UtilsAdapter.getAppValue(Settings.Key.IsDonationVisible);
        var endDonationDate = new Date(Date.parse(UtilsAdapter.getAppValue(Settings.Key.DonationEndDate)));
        var donationVisibleDate = new Date(Date.parse(UtilsAdapter.getAppValue(Settings.Key.DonationVisibleDate)));
        return new Date() < endDonationDate && new Date() > donationVisibleDate && isDonationVisible;
    }

    function isDonationToggleChecked() {
        var isDonationVisible = UtilsAdapter.getAppValue(Settings.Key.IsDonationVisible);
        return isDonationVisible;
    }

    function setDonationToggleChecked() {
        var isDonationVisible = UtilsAdapter.getAppValue(Settings.Key.IsDonationVisible);
        if (isDonationVisible) {
            UtilsAdapter.setAppValue(Settings.Key.IsDonationVisible, false);
        } else {
            UtilsAdapter.setAppValue(Settings.Key.IsDonationVisible, true);
        }
    }

    function isDonationToggleChecked() {
        // Desactivate the donation = set the date to 2999-01-01
        // If the date is after 2998-01-01, the donation is desactivated
        var date2998 = new Date(Date.parse(new Date(2998, 1, 1, 0, 0, 0, 0).toISOString().slice(0, 16).replace("T", " ")));
        var donationVisibleDate = new Date(Date.parse(UtilsAdapter.getAppValue(Settings.Key.DonateVisibleDate)));
        return date2998 >= donationVisibleDate;
    }

    function setDonationToggleChecked(checked) {
        if (checked) {
            // Activate the donation = set the date to yesterday
            var yesterday = new Date(new Date().getTime() - 24 * 60 * 60 * 1000).toISOString().slice(0, 16).replace("T", " ");
            return UtilsAdapter.setAppValue(Settings.Key.DonateVisibleDate, yesterday);
        } else {
            // Desactivate the donation = set the date to 2999-01-01
            var date2999 = new Date(2999, 1, 1, 0, 0, 0, 0).toISOString().slice(0, 16).replace("T", " ");
            return UtilsAdapter.setAppValue(Settings.Key.DonateVisibleDate, date2999);
        }
    }
}
