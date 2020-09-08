/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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
import QtQuick.Layouts 1.15
import QtQuick.Window 2.14
import QtQuick.Controls 2.15
import QtQuick.Controls.Universal 2.12
import QtGraphicalEffects 1.14
import QtQuick.Controls.Styles 1.4
import net.jami.Models 1.0
import net.jami.Adapters 1.0
import Qt.labs.platform 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    property int itemWidth
    property bool isSIP

    signal scrolled

    function updateAccountInfo() {
        if (advanceSettingsView.visible) {
            advanceSettingsView.updateAccountInfoDisplayedAdvance()
        }

        if (advanceSIPSettingsView.visible) {
            advanceSIPSettingsView.updateAccountInfoDisplayedAdvanceSIP()
        }
    }

    // Advanced Settigs Button
    RowLayout {
        id: rowAdvancedSettingsBtn
        Layout.fillWidth: true
        Layout.bottomMargin: 8

        ElidedTextLabel {
            Layout.fillWidth: true
            Layout.preferredHeight: JamiTheme.preferredFieldHeight

            eText: qsTr("Advanced Account Settings")
            fontSize: JamiTheme.headerFontSize
            maxWidth: root.width - JamiTheme.preferredFieldHeight
                        - JamiTheme.preferredMarginSize * 6
        }

        HoverableButtonTextItem {
            Layout.preferredWidth: JamiTheme.preferredFieldHeight
            Layout.preferredHeight: JamiTheme.preferredFieldHeight
            Layout.alignment: Qt.AlignHCenter

            radius: height / 2

            toolTipText: qsTr("Press to display or hide advance settings")

            source: {
                if (advanceSIPSettingsView.visible) {
                    return "qrc:/images/icons/round-arrow_drop_up-24px.svg"
                } else {
                    return "qrc:/images/icons/round-arrow_drop_down-24px.svg"
                }
            }

            onClicked: {
                if (isSIP) {
                    advanceSIPSettingsView.visible = !advanceSIPSettingsView.visible
                    if(advanceSIPSettingsView.visible)
                        advanceSIPSettingsView.updateAccountInfoDisplayedAdvanceSIP()
                } else {
                    advanceSettingsView.visible = !advanceSettingsView.visible
                    if(advanceSettingsView.visible)
                        advanceSettingsView.updateAccountInfoDisplayedAdvance()
                }
                scrolled()
            }
        }
    }

    // Advanced Settings
    AdvancedSettingsView {
        id: advanceSettingsView
        visible: false
        Layout.fillWidth: true
        Layout.bottomMargin: JamiTheme.preferredMarginSize
        itemWidth: root.itemWidth
    }

    // SIP Advanced Settings
    AdvancedSIPSettingsView {
        id: advanceSIPSettingsView
        Layout.fillWidth: true
        Layout.bottomMargin: JamiTheme.preferredMarginSize
        visible: false
        itemWidth: root.itemWidth
    }
}