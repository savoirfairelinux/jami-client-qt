/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
 * Author: Franck Laurent <nicolas.vengeon@savoirfairelinux.com>
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
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../mainview/components"

BaseModalDialog {
    id: root

    height: JamiTheme.chatViewFooterButtonSize
    x: -parent.width * 3
    y: -1.3 * height

    modal: false

    signal addStyle(string char1, string char2)
    signal addSpecificStyle(string headerPrefix)
    property int start: undefined
    property int end: undefined
    property string text: undefined

    popupContent: Item {

        ListView {
            id: listViewTypoSecond

            width: count * 36 + 10
            height: JamiTheme.chatViewFooterButtonSize
            orientation: ListView.Horizontal
            interactive: false
            leftMargin: 10
            spacing: 10

            Rectangle {
                anchors.fill: parent
                color: JamiTheme.showMoreTypoColor
                radius: 5
                z: -1
            }

            property list<Action> menuTypoActionsSecond: [
                Action {
                    id: linkAction
                    property var iconSrc: JamiResources.link_svg
                    property var toolTip: JamiStrings.link
                    onTriggered: function clickAction() {
                        addStyle("[", "](url)");
                    }
                },
                Action {
                    id: codeAction
                    property var iconSrc: JamiResources.code_svg
                    property var toolTip: JamiStrings.code
                    onTriggered: function clickAction() {
                        addStyle("```", "```");
                    }
                },
                Action {
                    id: quoteAction
                    property var iconSrc: JamiResources.quote_svg
                    property var toolTip: JamiStrings.quote
                    onTriggered: function clickAction() {
                        addSpecificStyle("> ");
                    }
                },
                Action {
                    id: bulletPointAction
                    property var iconSrc: JamiResources.bullet_point_svg
                    property var toolTip: JamiStrings.bulletPoint
                    onTriggered: function clickAction() {
                        addSpecificStyle("- ");
                    }
                },
                Action {
                    id: bulletNumberAction
                    property var iconSrc: JamiResources.bullet_number_svg
                    property var toolTip: JamiStrings.bulletNumber
                    onTriggered: function clickAction() {
                        addSpecificStyle("1. ");
                    }
                }
            ]

            model: menuTypoActionsSecond

            delegate: PushButton {
                anchors.verticalCenter: parent.verticalCenter

                preferredSize: JamiTheme.chatViewFooterRealButtonSize
                imageContainerWidth: 10
                imageContainerHeight: 10
                radius: 5

                toolTipText: modelData.toolTip
                source: modelData.iconSrc

                normalColor: JamiTheme.showMoreTypoColor
                imageColor: JamiTheme.chatViewFooterButtonImageColor
                hoveredColor: JamiTheme.chatViewFooterButtonColor
                pressedColor: JamiTheme.chatViewFooterButtonColor

                action: modelData
            }
        }
    }
}
