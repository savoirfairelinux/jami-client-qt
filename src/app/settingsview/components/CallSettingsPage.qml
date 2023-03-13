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

    signal navigateToMainView
    signal navigateToNewWizardView
    title: JamiStrings.callSettingsTitle

    function updateAndShowModeratorsSlot() {
        moderatorListWidget.model.reset()
        moderatorListWidget.visible = moderatorListWidget.model.rowCount() > 0
    }

    Connections {
        target: ContactAdapter

        function onDefaultModeratorsUpdated() {
            updateAndShowModeratorsSlot()
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
            Layout.topMargin: JamiTheme.preferredSettingsContentMarginSize
            spacing: JamiTheme.settingsCategorySpacing

            Text {
                id: enableAccountTitle

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.generalSettingsTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true

            }


            ToggleSwitch {
                id: checkBoxUntrusted
                visible: !root.isSIP

                labelText: JamiStrings.allowCallsUnknownContacs
                fontPointSize: JamiTheme.settingsFontSize

                checked: CurrentAccount.PublicInCalls_DHT

                onSwitchToggled: CurrentAccount.PublicInCalls_DHT = checked
            }

            ToggleSwitch {
                id: checkBoxAutoAnswer

                labelText: JamiStrings.autoAnswerCalls
                fontPointSize: JamiTheme.settingsFontSize

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
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true

            }

            ToggleSwitch {
                id: checkBoxCustomRingtone

                labelText: JamiStrings.enableCustomRingtone
                fontPointSize: JamiTheme.settingsFontSize

                checked: CurrentAccount.ringtoneEnabled_Ringtone

                onSwitchToggled: CurrentAccount.ringtoneEnabled_Ringtone = checked
            }

            SettingMaterialButton {
                id: btnRingtone

                Layout.fillWidth: true
                Layout.minimumHeight: JamiTheme.preferredFieldHeight

                enabled: checkBoxCustomRingtone.checked

                textField: UtilsAdapter.toFileInfoName(CurrentAccount.ringtonePath_Ringtone) !== "" ? UtilsAdapter.toFileInfoName(CurrentAccount.ringtonePath_Ringtone) : JamiStrings.ringtoneDefaultDevice

                titleField: JamiStrings.selectCustomRingtone
                itemWidth: root.itemWidth

                onClick: {
                    var dlg = viewCoordinator.presentDialog(
                                appWindow,
                                "commoncomponents/JamiFileDialog.qml",
                                {
                                    title: JamiStrings.selectNewRingtone,
                                    fileMode: JamiFileDialog.OpenFile,
                                    folder: JamiQmlUtils.qmlFilePrefix +
                                            UtilsAdapter.toFileAbsolutepath(
                                                CurrentAccount.ringtonePath_Ringtone),
                                    nameFilters: [JamiStrings.audioFile, JamiStrings.allFiles]
                                })
                    dlg.fileAccepted.connect(function (file) {
                        var url = UtilsAdapter.getAbsPath(file.toString())
                        if(url.length !== 0) {
                            CurrentAccount.ringtonePath_Ringtone = url
                        }
                    })
                }
            }
        }

        ColumnLayout {
            id: rendezVousSettings

            width: parent.width
            spacing: JamiTheme.settingsCategorySpacing

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.rendezVousPoint
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true

            }

            ToggleSwitch {
                id: checkBoxRdv

                visible: !isSIP

                labelText: JamiStrings.rendezVous
                fontPointSize: JamiTheme.settingsFontSize

                checked: CurrentAccount.isRendezVous

                onSwitchToggled: CurrentAccount.isRendezVous = checked
            }
        }

        ColumnLayout {
            id: moderationSettings

            width: parent.width
            spacing: 9

            Text {

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width

                text: JamiStrings.moderation
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode : Text.WordWrap

                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true

            }

            ToggleSwitch {
                id: toggleLocalModerators

                labelText: JamiStrings.enableLocalModerators
                fontPointSize: JamiTheme.settingsFontSize

                checked: CurrentAccount.isLocalModeratorsEnabled

                onSwitchToggled: CurrentAccount.isLocalModeratorsEnabled = checked
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: JamiTheme.preferredFieldHeight

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.rightMargin: JamiTheme.preferredMarginSize

                    color: JamiTheme.textColor
                    wrapMode : Text.WordWrap
                    text: JamiStrings.defaultModerators
                    font.pointSize: JamiTheme.settingsFontSize
                    font.kerning: true

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MaterialButton {
                    id: addDefaultModeratorPushButton

                    Layout.alignment: Qt.AlignCenter

                    preferredWidth: textSize.width + 2*JamiTheme.buttontextWizzardPadding
                    preferredHeight: JamiTheme.preferredFieldHeight

                    primary: true
                    toolTipText: JamiStrings.addDefaultModerator

                    text: JamiStrings.addModerator

                    onClicked: {
                        ContactPickerCreation.presentContactPickerPopup(
                                    ContactList.CONVERSATION,
                                    appWindow)
                    }

                    TextMetrics{
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

                    btnImgSource: JamiResources.round_remove_circle_24dp_svg
                    btnToolTip: JamiStrings.removeDefaultModerator

                    onClicked: moderatorListWidget.currentIndex = index
                    onBtnContactClicked: {
                        AccountAdapter.setDefaultModerator(
                                    LRCInstance.currentAccountId, contactID, false)
                        updateAndShowModeratorsSlot()
                    }
                }
            }

            ToggleSwitch {
                id: checkboxAllModerators

                labelText: JamiStrings.enableAllModerators
                fontPointSize: JamiTheme.settingsFontSize

                checked: CurrentAccount.isAllModeratorsEnabled

                onSwitchToggled: CurrentAccount.isAllModeratorsEnabled = checked
            }
        }

        /* TO DO
        MaterialButton {
            id: defaultSettings

            TextMetrics{
                id: defaultSettingsTextSize
                font.weight: Font.Bold
                font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                font.capitalization: Font.AllUppercase
                text: defaultSettings.text
            }

            secondary: true

            text: JamiStrings.defaultSettings
            preferredWidth: defaultSettingsTextSize.width + 2*JamiTheme.buttontextWizzardPadding
            preferredHeight: JamiTheme.preferredButtonSettingsHeight
            Layout.bottomMargin: JamiTheme.settingsMenuChildrenButtonHeight

            onClicked: {

            }

        }*/

    }
}
