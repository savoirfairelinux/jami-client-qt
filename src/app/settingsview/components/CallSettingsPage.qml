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
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize
        spacing: JamiTheme.settingsBlockSpacing
        width: contentFlickableWidth

        ColumnLayout {
            id: generalSettings
            spacing: JamiTheme.settingsCategorySpacing
            width: parent.width

            Text {
                id: enableAccountTitle
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.generalSettingsTitle
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            ToggleSwitch {
                id: checkBoxUntrusted
                checked: CurrentAccount.PublicInCalls_DHT
                labelText: JamiStrings.allowCallsUnknownContacs
                visible: !root.isSIP

                onSwitchToggled: CurrentAccount.PublicInCalls_DHT = checked
            }
            ToggleSwitch {
                id: checkBoxAutoAnswer
                checked: CurrentAccount.autoAnswer
                labelText: JamiStrings.autoAnswerCalls

                onSwitchToggled: CurrentAccount.autoAnswer = checked
            }
        }
        ColumnLayout {
            id: ringtoneSettings
            spacing: 9
            width: parent.width

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.ringtone
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            ToggleSwitch {
                id: checkBoxCustomRingtone
                checked: CurrentAccount.ringtoneEnabled_Ringtone
                labelText: JamiStrings.enableCustomRingtone

                onSwitchToggled: CurrentAccount.ringtoneEnabled_Ringtone = checked
            }
            SettingMaterialButton {
                id: btnRingtone
                Layout.fillWidth: true
                enabled: checkBoxCustomRingtone.checked
                itemWidth: root.itemWidth
                textField: UtilsAdapter.toFileInfoName(CurrentAccount.ringtonePath_Ringtone)
                titleField: JamiStrings.selectCustomRingtone

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
            spacing: JamiTheme.settingsCategorySpacing
            width: parent.width

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.rendezVousPoint
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            ToggleSwitch {
                id: checkBoxRdv
                checked: CurrentAccount.isRendezVous
                labelText: JamiStrings.rendezVous
                visible: !isSIP

                onSwitchToggled: CurrentAccount.isRendezVous = checked
            }
        }
        ColumnLayout {
            id: moderationSettings
            spacing: 9
            width: parent.width

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width
                color: JamiTheme.textColor
                font.kerning: true
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                horizontalAlignment: Text.AlignLeft
                text: JamiStrings.moderation
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            ToggleSwitch {
                id: toggleLocalModerators
                checked: CurrentAccount.isLocalModeratorsEnabled
                labelText: JamiStrings.enableLocalModerators

                onSwitchToggled: CurrentAccount.isLocalModeratorsEnabled = checked
            }
            ToggleSwitch {
                id: checkboxAllModerators
                checked: CurrentAccount.isAllModeratorsEnabled
                labelText: JamiStrings.enableAllModerators

                onSwitchToggled: CurrentAccount.isAllModeratorsEnabled = checked
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize
                    color: JamiTheme.textColor
                    font.kerning: true
                    font.pointSize: JamiTheme.settingsFontSize
                    horizontalAlignment: Text.AlignLeft
                    text: JamiStrings.defaultModerators
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
                MaterialButton {
                    id: addDefaultModeratorPushButton
                    Layout.alignment: Qt.AlignCenter
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
                    primary: true
                    text: JamiStrings.addModerator
                    toolTipText: JamiStrings.addDefaultModerator

                    onClicked: {
                        ContactPickerCreation.presentContactPickerPopup(ContactList.CONVERSATION, appWindow);
                    }

                    TextMetrics {
                        id: textSize
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.weight: Font.Bold
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

                delegate: ContactItemDelegate {
                    id: moderatorListDelegate
                    btnImgSource: JamiStrings.optionRemove
                    btnToolTip: JamiStrings.removeDefaultModerator
                    contactID: ContactID
                    contactName: ContactName
                    height: 74
                    width: moderatorListWidget.width

                    onBtnContactClicked: {
                        AccountAdapter.setDefaultModerator(LRCInstance.currentAccountId, contactID, false);
                        updateAndShowModeratorsSlot();
                    }
                    onClicked: moderatorListWidget.currentIndex = index
                }
                model: ModeratorListModel {
                    lrcInstance: LRCInstance
                }
            }
        }
    }
}
