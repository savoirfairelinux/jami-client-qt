/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

JamiFlickable {
    id: tipsFlow
    property bool isLong: true
    clip: true

    width: getWidth()
    height: getHeight()

    function getWidth() {
        return 2*JamiTheme.tipBoxWidth + JamiTheme.welcomPageSpacing +  (tipsFlow.isLong ? JamiTheme.tipBoxWidth + JamiTheme.welcomPageSpacing : 0);
    }
    function getHeight() {
        return flow.height + JamiTheme.preferredMarginSize * 2;
    }

    Flow {
        id: flow
        spacing: JamiTheme.welcomPageSpacing
        layoutDirection: UtilsAdapter.isRTL ? Qt.RightToLeft : Qt.LeftToRight

        Repeater {
            id: tipsRepeater
            model: TipsModel
            Layout.alignment: Qt.AlignCenter

            delegate: TipBox {
                tipId: TipId
                title: Title
                description: Description
                type: Type
                property bool hideTipBox: false

                visible: {
                    if (hideTipBox)
                        return false;
                    if (type === "backup") {
                        return LRCInstance.currentAccountType !== Profile.Type.SIP && CurrentAccount.managerUri.length === 0;
                    } else if (type === "customize") {
                        return CurrentAccount.alias.length === 0;
                    }
                    return true;
                }

                onIgnoreClicked: {
                    hideTipBox = true;
                }
            }
        }
    }
}
