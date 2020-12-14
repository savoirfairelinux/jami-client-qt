/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Albert Babí Oller <albert.babi@savoirfairelinux.com>
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

import QtQuick 2.14
import QtQuick.Layouts 1.14
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"
import "../../mainview/components"
import "../../mainview/js/contactpickercreation.js" as ContactPickerCreation

ColumnLayout {
    id:root

    property bool isSIP

    function updateAndShowModeratorsSlot() {
        toggleLocalModerators.checked = SettingsAdapter.isLocalModeratorsEnabled(
                    AccountAdapter.currentAccountId)
        moderatorListWidget.model.reset()
        moderatorListWidget.visible =
                moderatorListWidget.model.rowCount() > 0
    }

    function removeModerator(uri) {
        SettingsAdapter.setDefaultModerator(AccountAdapter.currentAccountId, uri, false)
        updateAndShowModeratorsSlot()
    }

    function closePotentialContactPicker() {
        ContactPickerCreation.closeContactPicker()
    }

    Connections {
        target: ContactAdapter

        function onDefaultModeratorsUpdated() {
            updateAndShowModeratorsSlot()
        }
    }

    ElidedTextLabel {
        Layout.fillWidth: true

        eText: JamiStrings.conferenceModeration
        fontSize: JamiTheme.headerFontSize
        maxWidth: root.width - JamiTheme.preferredFieldHeight
                    - JamiTheme.preferredMarginSize * 4
    }


    ToggleSwitch {
        id: toggleLocalModerators
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        labelText: JamiStrings.enableLocalModerators
        fontPointSize: JamiTheme.settingsFontSize

        onSwitchToggled: SettingsAdapter.enableLocalModerators(
                             AccountAdapter.currentAccountId, checked)
    }

    ElidedTextLabel {
        Layout.fillWidth: true
        Layout.leftMargin: JamiTheme.preferredMarginSize

        eText: JamiStrings.defaultModerators
        fontSize: JamiTheme.settingsFontSize
        maxWidth: root.width - JamiTheme.preferredFieldHeight
                    - JamiTheme.preferredMarginSize * 4
    }

    ListViewJami {
        id: moderatorListWidget

        Layout.fillWidth: true
        Layout.preferredHeight: 160

        model: ModeratorListModel {}

        delegate: ModeratorItemDelegate {
            id: moderatorListDelegate

            width: moderatorListWidget.width
            height: 74

            contactName : ContactName
            contactID: ContactID

            onClicked: moderatorListWidget.currentIndex = index

            onBtnRemoveModeratorClicked: removeModerator(contactID)
        }
    }

    MaterialButton {
        id: addDefaultModeratorPushButton

        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: JamiTheme.preferredFieldWidth
        Layout.preferredHeight: JamiTheme.preferredFieldHeight

        color: JamiTheme.buttonTintedBlack
        hoveredColor: JamiTheme.buttonTintedBlackHovered
        pressedColor: JamiTheme.buttonTintedBlackPressed
        outlined: true
        toolTipText: JamiStrings.addDefaultModerator

        source: "qrc:/images/icons/round-add-24px.svg"

        text: JamiStrings.addDefaultModerator

        onClicked: {
            ContactPickerCreation.createContactPickerObjects(
                        ContactPicker.ContactPickerType.CONVERSATION,
                        root)
            ContactPickerCreation.calculateCurrentGeo(0, 0)
            ContactPickerCreation.openContactPicker()
        }
    }
}
