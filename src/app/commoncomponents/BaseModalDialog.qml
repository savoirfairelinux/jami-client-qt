/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import net.jami.Constants 1.1

Popup {
    id: root

    // convient access to closePolicy
    property bool autoClose: true
    property alias backgroundColor: container.color
    property alias popupContent: containerSubContentLoader.sourceComponent
    property alias popupContentLoadStatus: containerSubContentLoader.status
    property var popupContentLoader: containerSubContentLoader
    property int popupContentMargins: 0
    property int popupContentPreferredHeight: 0
    property int popupContentPreferredWidth: 0
    property alias title: titleText.text

    closePolicy: autoClose ? (Popup.CloseOnEscape | Popup.CloseOnPressOutside) : Popup.NoAutoClose
    modal: true
    padding: 0
    parent: Overlay.overlay

    // A popup is invisible until opened.
    visible: false

    // center in parent
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    Rectangle {
        id: container
        anchors.fill: parent
        color: JamiTheme.secondaryBackgroundColor
        radius: JamiTheme.modalPopupRadius

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Text {
                id: titleText
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                Layout.margins: text.length === 0 ? 0 : 10
                Layout.preferredHeight: text.length === 0 ? 0 : contentHeight
                color: JamiTheme.textColor
                font.pointSize: 12
            }
            Loader {
                id: containerSubContentLoader
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: popupContentMargins
                Layout.fillHeight: popupContentPreferredHeight === 0
                Layout.fillWidth: popupContentPreferredWidth === 0
                Layout.preferredHeight: popupContentPreferredHeight
                Layout.preferredWidth: popupContentPreferredWidth
                Layout.topMargin: popupContentMargins
            }
        }
    }
    DropShadow {
        color: JamiTheme.shadowColor
        height: root.height
        horizontalOffset: 3.0
        radius: container.radius * 4
        source: container
        transparentBorder: true
        verticalOffset: 3.0
        width: root.width
        z: -1
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor

        // Color animation for overlay when pop up is shown.
        ColorAnimation on color  {
            duration: 500
            to: JamiTheme.popupOverlayColor
        }
    }
    background: Rectangle {
        color: JamiTheme.transparentColor
    }
    enter: Transition {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            from: 0.0
            properties: "opacity"
            to: 1.0
        }
    }
    exit: Transition {
        NumberAnimation {
            duration: JamiTheme.shortFadeDuration
            from: 1.0
            properties: "opacity"
            to: 0.0
        }
    }
}
