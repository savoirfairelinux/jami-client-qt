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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Rectangle {
    id: root

    opacity: visible

    Connections {
        target: CurrentConversation
        enabled: true

        function onErrorsChanged() {
            if (CurrentConversation.errors.length > 0) {
                errorLabel.text = CurrentConversation.errors[0];
                backendErrorToolTip.text = JamiStrings.backendError.arg(CurrentConversation.backendErrors[0]);
            }
            errorRect.visible = CurrentConversation.errors.length > 0 && LRCInstance.debugMode();
        }
    }
    color: JamiTheme.filterBadgeColor

    RowLayout {
        anchors.fill: parent
        anchors.margins: JamiTheme.preferredMarginSize

        Text {
            id: errorLabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: CurrentConversation.errors.count > 0 ? CurrentConversation.errors[0][0] : ""
            color: JamiTheme.filterBadgeTextColor
            font.pixelSize: JamiTheme.headerFontSize
            elide: Text.ElideRight
        }

        ResponsiveImage {
            id: backEndError
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            width: 30
            height: 30

            source: JamiResources.outline_info_24dp_svg
            layer {
                enabled: true
                effect: ColorOverlay {
                    color: JamiTheme.filterBadgeTextColor
                }
            }

            MaterialToolTip {
                id: backendErrorToolTip
                text: ""
                visible: parent.hovered && text !== ""
                delay: Qt.styleHints.mousePressAndHoldInterval
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
            from: 0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
