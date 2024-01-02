/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

    property bool isSIP: CurrentAccount.type === Profile.Type.SIP
    property int itemWidth: 132
    property string key: PttListener.keyToString(PttListener.getCurrentKey())
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

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: enableAccountTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

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

            width: parent.width
            spacing: 9

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

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

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing
            visible: !isSIP

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

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

                labelText: JamiStrings.rendezVous
                checked: CurrentAccount.isRendezVous
                onSwitchToggled: CurrentAccount.isRendezVous = checked
            }
        }

        ColumnLayout {
            id: moderationSettings

            width: parent.width
            spacing: 9
            visible: !isSIP

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

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

                visible: count > 0
                model: ModeratorListModel

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
                Layout.preferredWidth: parent.width

                text: JamiStrings.chatSettingsTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Flow {

                Layout.preferredWidth: parent.width
                Layout.preferredHeight: childrenRect.height
                spacing: 5

                ButtonGroup {
                    id: optionsB
                }

                MaterialRadioButton {
                    id: horizontalRadio
                    width: 255
                    height: 60

                    text: JamiStrings.horizontalViewOpt
                    ButtonGroup.group: optionsB
                    iconSource: JamiResources.horizontal_view_svg

                    onCheckedChanged: {
                        if (checked) {
                            UtilsAdapter.setAppValue(Settings.Key.ShowChatviewHorizontally, true);
                        }
                    }
                }

                MaterialRadioButton {
                    id: verticalRadio

                    width: 255
                    height: 60

                    text: JamiStrings.verticalViewOpt
                    ButtonGroup.group: optionsB
                    //color: JamiTheme.blackColor
                    iconSource: JamiResources.vertical_view_svg

                    onCheckedChanged: {
                        if (checked) {
                            UtilsAdapter.setAppValue(Settings.Key.ShowChatviewHorizontally, false);
                        }
                    }
                }
            }
        }
        ColumnLayout{
            width: parent.width
            spacing: 9
            Text {
                text: JamiStrings.pushToTalk
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }
            ToggleSwitch {
                id: pttToggle
                labelText: JamiStrings.enablePTT
                checked: UtilsAdapter.getAppValue(Settings.EnablePtt)
                onSwitchToggled: {
                    UtilsAdapter.setAppValue(Settings.Key.EnablePtt, checked)
                }
            }
            RowLayout {
                visible: pttToggle.checked
                Layout.preferredWidth: parent.width

                Label {
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                    text: JamiStrings.keyboardShortcut
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
                Label {
                    id: keyLabel
                    color: JamiTheme.blackColor
                    wrapMode: Text.WordWrap
                    text: key
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    background: Rectangle {
                         id: backgroundRect
                         anchors.centerIn: parent
                         width: keyLabel.width + 2 * JamiTheme.preferredMarginSize
                         height: keyLabel.height + JamiTheme.preferredMarginSize
                         color: JamiTheme.lightGrey_
                         border.color: JamiTheme.darkGreyColor
                         radius: 4
                    }
                }
                MaterialButton {
                    Layout.alignment: Qt.AlignRight
                    buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                    primary: true
                    toolTipText: JamiStrings.changeKeyboardShortcut
                    text: JamiStrings.change
                    onClicked: {
                        var dlg = viewCoordinator.presentDialog(appWindow, "commoncomponents/ChangePttKeyPopup.qml");
                        dlg.choiceMade.connect(function (chosenKey) {
                             keyLabel.text = PttListener.keyToString(chosenKey);
                        });
                    }
                }
            }
        }
    }
}
