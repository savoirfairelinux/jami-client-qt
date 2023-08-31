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
    id: popup

    // convient access to closePolicy
    property bool autoClose: true
    property alias backgroundColor: container.color
    property alias title: titleText.text
    property var popupcontainerSubContentLoader: containerSubContentLoader
    property alias popupContentLoadStatus: containerSubContentLoader.status
    property alias popupContent: containerSubContentLoader.sourceComponent
    property int popupContentMargins: JamiTheme.preferredMarginSize

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: JamiTheme.preferredDialogWidth


    modal: true
    padding: 0
    focus: true
    closePolicy: autoClose ? (Popup.CloseOnEscape | Popup.CloseOnPressOutside) : Popup.NoAutoClose


    contentItem: Rectangle {
        id: container

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 3.0
            verticalOffset: 3.0
            radius: container.radius * 4
            color: JamiTheme.shadowColor
            source: container
            transparentBorder: true
            samples: radius + 1
        }

        anchors.fill: parent

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent

            spacing: 0

            Label {
                Component.onCompleted: print(this, width, height)
                id: titleText

                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                font.pointSize: JamiTheme.menuFontSize
                color: JamiTheme.textColor

                //if there is no title, no space should be allocated for it
                Layout.preferredWidth: text.lenght === 0 ? 0 : contentLayout.width - JamiTheme.preferredMarginSize * 2
                Layout.margins: text.lenght === 0 ? 0 : JamiTheme.preferredMarginSize
                visible: text.length > 0
            }

            Loader{
                id: containerSubContentLoader

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: contentLayout.width - JamiTheme.preferredMarginSize * 2
                Layout.bottomMargin: popupContentMargins
        
            }
        }
        radius: JamiTheme.modalPopupRadius
        color: JamiTheme.secondaryBackgroundColor
    }

    background: Rectangle {
        color: JamiTheme.transparentColor
    }

     Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor

        // Color animation for overlay when pop up is shown.
        ColorAnimation on color  {
            to: JamiTheme.popupOverlayColor
            duration: 500
        }
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 0.0
            to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }
    exit: Transition {
        NumberAnimation {
            properties: "opacity"
            from: 1.0
            to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
