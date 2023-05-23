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
import QtQuick.Controls
import QtMultimedia
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"
import "../../mainview/components"
import "../../mainview/js/contactpickercreation.js" as ContactPickerCreation

SettingsPageBase {
    id: root

    property bool isSIP
    property int itemWidth: 132
    title: JamiStrings.callSettingsTitle

    function updateAndShowModeratorsSlot() {
        moderatorListWidget.model.reset();
        moderatorListWidget.visible = moderatorListWidget.model.rowCount() > 0;
    }

    Connections {
        target: ContactAdapter

        function onDefaultModeratorsUpdated() {
            updateAndShowModeratorsSlot();
        }
    }

    flickableContent: ColumnLayout {
        id: callSettingsColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        ColumnLayout {
            id: generalSettings

            Layout.fillWidth: true
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: enableAccountTitle

                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true

                text: JamiStrings.generalSettingsTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: checkBoxUntrusted
                visible: !root.isSIP

                labelText: JamiStrings.allowCallsUnknownContacs
                checked: CurrentAccount.PublicInCalls_DHT
                onSwitchToggled: CurrentAccount.PublicInCalls_DHT = checked
            }

            ToggleSwitch {
                id: checkBoxAutoAnswer

                labelText: JamiStrings.autoAnswerCalls
                checked: CurrentAccount.autoAnswer
                onSwitchToggled: CurrentAccount.autoAnswer = checked
            }
        }

        ColumnLayout {
            id: ringtoneSettings

            Layout.fillWidth: true
            spacing: 9

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true

                text: JamiStrings.ringtone
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: checkBoxCustomRingtone

                labelText: JamiStrings.enableCustomRingtone
                checked: CurrentAccount.ringtoneEnabled_Ringtone
                onSwitchToggled: CurrentAccount.ringtoneEnabled_Ringtone = checked
            }

            SettingMaterialButton {
                id: btnRingtone

                Layout.fillWidth: true

                enabled: checkBoxCustomRingtone.checked

                textField: UtilsAdapter.toFileInfoName(CurrentAccount.ringtonePath_Ringtone)

                titleField: JamiStrings.selectCustomRingtone
                itemWidth: root.itemWidth

                onClick: {
                    var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/JamiFileDialog.qml", {
                            "title": JamiStrings.selectNewRingtone,
                            "fileMode": JamiFileDialog.OpenFile,
                            "folder": JamiQmlUtils.qmlFilePrefix + UtilsAdapter.toFileAbsolutepath(CurrentAccount.ringtonePath_Ringtone),
                            "nameFilters": [JamiStrings.audioFile, JamiStrings.allFiles]
                        });
                    dlg.fileAccepted.connect(function (file) {
                            var url = UtilsAdapter.getAbsPath(file.toString());
                            if (url.length !== 0) {
                                CurrentAccount.ringtonePath_Ringtone = url;
                            }
                        });
                }
            }
        }

        ColumnLayout {
            id: rendezVousSettings

            Layout.fillWidth: true
            spacing: JamiTheme.settingsCategorySpacing

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                text: JamiStrings.rendezVousPoint
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: checkBoxRdv

                visible: !isSIP

                labelText: JamiStrings.rendezVous
                checked: CurrentAccount.isRendezVous
                onSwitchToggled: CurrentAccount.isRendezVous = checked
            }
        }

        ColumnLayout {
            id: moderationSettings

            Layout.fillWidth: true
            spacing: 9

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true

                text: JamiStrings.moderation
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            ToggleSwitch {
                id: toggleLocalModerators

                labelText: JamiStrings.enableLocalModerators
                checked: CurrentAccount.isLocalModeratorsEnabled
                onSwitchToggled: CurrentAccount.isLocalModeratorsEnabled = checked
            }

            ToggleSwitch {
                id: checkboxAllModerators

                labelText: JamiStrings.enableAllModerators
                checked: CurrentAccount.isAllModeratorsEnabled
                onSwitchToggled: CurrentAccount.isAllModeratorsEnabled = checked
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize

                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                    text: JamiStrings.defaultModerators
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialButton {
                    id: addDefaultModeratorPushButton

                    Layout.alignment: Qt.AlignCenter

                    preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                    primary: true
                    toolTipText: JamiStrings.addDefaultModerator

                    text: JamiStrings.addModerator

                    onClicked: {
                        ContactPickerCreation.presentContactPickerPopup(ContactList.CONVERSATION, appWindow);
                    }

                    TextMetrics {
                        id: textSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.capitalization: Font.AllUppercase
                        text: addDefaultModeratorPushButton.text
                    }
                }
            }

            JamiListView {
                id: moderatorListWidget

                Layout.fillWidth: true
                Layout.preferredHeight: 160
                spacing: JamiTheme.settingsListViewsSpacing

                visible: model.rowCount() > 0

                model: ModeratorListModel {
                    lrcInstance: LRCInstance
                }

                delegate: ContactItemDelegate {
                    id: moderatorListDelegate

                    width: moderatorListWidget.width
                    height: 74

                    contactName: ContactName
                    contactID: ContactID

                    btnImgSource: JamiStrings.optionRemove
                    btnToolTip: JamiStrings.removeDefaultModerator

                    onClicked: moderatorListWidget.currentIndex = index
                    onBtnContactClicked: {
                        AccountAdapter.setDefaultModerator(LRCInstance.currentAccountId, contactID, false);
                        updateAndShowModeratorsSlot();
                    }
                }
            }
        }

        ColumnLayout {
            id: chatViewSettings

            width: parent.width
            spacing: 9

            function isComplete() {
                var horizontalView = UtilsAdapter.getAppValue(Settings.Key.ShowChatviewHorizontally) ? 1 : 0;
                verticalRadio.checked = horizontalView === 0;
                horizontalRadio.checked = horizontalView === 1;
            }

            Component.onCompleted: chatViewSettings.isComplete()

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true

                text: JamiStrings.chatSettingsTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Flow {

                Layout.fillWidth: true
                spacing: 5

                ButtonGroup {
                    id: optionsB
                }

                MaterialRadioButton {
                    id: verticalRadio

                    TextMetrics {
                        id: verticalRadioTextSize
                        font.weight: Font.Normal
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        text: verticalRadio.text
                    }

                    width: verticalRadioTextSize.width + 2 * JamiTheme.buttontextWizzardPadding + JamiTheme.verticalChatViewIcon
                    text: JamiStrings.verticalViewOpt
                    ButtonGroup.group: optionsB
                    iconSource: JamiResources.vertical_view_svg

                    onCheckedChanged: {
                        if (checked) {
                            UtilsAdapter.setAppValue(Settings.Key.ShowChatviewHorizontally, false);
                        }
                    }
                }

                MaterialRadioButton {
                    id: horizontalRadio

                    TextMetrics {
                        id: horizontalRadioTextSize
                        font.weight: Font.Normal
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        text: verticalRadio.text
                    }

                    width: horizontalRadioTextSize.width + 2 * JamiTheme.buttontextWizzardPadding + JamiTheme.horizontalChatViewIcon
                    text: JamiStrings.horizontalViewOpt
                    ButtonGroup.group: optionsB
                    //color: JamiTheme.blackColor
                    iconSource: JamiResources.horizontal_view_svg

                    onCheckedChanged: {
                        if (checked) {
                            UtilsAdapter.setAppValue(Settings.Key.ShowChatviewHorizontally, true);
                        }
                    }
                }
            }
        }
    }
}
