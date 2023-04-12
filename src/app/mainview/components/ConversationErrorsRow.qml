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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root
    color: JamiTheme.filterBadgeColor
    opacity: visible

    Connections {
        enabled: true
        target: CurrentConversation

        function onErrorsChanged() {
            if (CurrentConversation.errors.length > 0) {
                errorLabel.text = CurrentConversation.errors[0];
                backendErrorToolTip.text = JamiStrings.backendError.arg(CurrentConversation.backendErrors[0]);
            }
            errorRect.visible = CurrentConversation.errors.length > 0 && LRCInstance.debugMode();
        }
    }
    RowLayout {
        anchors.fill: parent
        anchors.margins: JamiTheme.preferredMarginSize

        Text {
            id: errorLabel
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            color: JamiTheme.filterBadgeTextColor
            elide: Text.ElideRight
            font.pixelSize: JamiTheme.headerFontSize
            text: CurrentConversation.errors.count > 0 ? CurrentConversation.errors[0][0] : ""
        }
        ResponsiveImage {
            id: backEndError
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            height: 30
            source: JamiResources.outline_info_24dp_svg
            width: 30

            layer {
                enabled: true

                effect: ColorOverlay {
                    color: JamiTheme.filterBadgeTextColor
                }
            }
            MaterialToolTip {
                id: backendErrorToolTip
                delay: Qt.styleHints.mousePressAndHoldInterval
                text: ""
                visible: parent.hovered && text !== ""
            }
        }
        PushButton {
            id: btnClose
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            imageColor: JamiTheme.filterBadgeTextColor
            normalColor: JamiTheme.transparentColor
            source: JamiResources.round_close_24dp_svg

            onClicked: ConversationsAdapter.popFrontError(CurrentConversation.id)
        }
    }

    Behavior on opacity  {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            from: 0
        }
    }
}
