/*
 * Copyright (C) 2022-2024 Savoir-faire Linux Inc.
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
    id: tipsRow
    clip: false

    property color tipsColor: JamiTheme.welcomeBlockColor
    property color tipsTextColor: JamiTheme.textColor
    property color iconColor: JamiTheme.tintedBlue
    property alias visibleTipBoxCount: tipsRepeater.visibleTipBoxCount

    width: JamiTheme.welcomeGridWidth
    height: getHeight()
    function getHeight() {
        return row.height;
    }

    Row {
        id: row
        clip: false
        spacing: JamiTheme.welcomePageSpacing
        height: 150

        width: JamiTheme.welcomeGridWidth
        property real openedTipCount: 0

        Repeater {
            id: tipsRepeater
            model: TipsModel
            anchors.bottom: row.bottom
            delegate: TipBox {
                backgroundColor: tipsRow.tipsColor
                tipId: TipId
                title: Title
                description: Description
                type: Type
                property bool hideTipBox: false
                anchors.bottom: row.bottom
                textColor: tipsTextColor
                iconColor: tipsRow.iconColor

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

                enabled: {
                    if (x > tipsRow.width || x < tipsRow.x )
                        return false;
                    else
                        return true;
                }

                opacity: {
                    if (x > tipsRow.width || x < tipsRow.x )
                        return 0;
                    else
                        return 1;
                }

                onIgnoreClicked: {
                    hideTipBox = true;
                }

                onHideTipBoxChanged: {
                    tipsRepeater.updateVisibleTipBoxCount()
                }

                onOpenedChanged: {
                    if (opened)
                        row.openedTipCount++;
                    else
                        row.openedTipCount--;
                }
            }

            property int visibleTipBoxCount: 0

            Component.onCompleted: {
                updateVisibleTipBoxCount()
            }

            function updateVisibleTipBoxCount() {
                var count = 0
                for (var i = 0; i < tipsRepeater.count; i++) {
                    var item = tipsRepeater.itemAt(i)
                    if (item.type === "backup" || item.type === "customize"){
                        if (item.visible)
                            count ++
                    }
                    else if (!item.hideTipBox) {
                        count++
                    }
                }
                visibleTipBoxCount = count
            }
        }
    }
}
