/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import Jami as JamiStyle

import net.jami.Constants 1.1
import "../mainview/components"

JamiStyle.Dialog {
    id: root

    // Header
    property alias titleText: root.title
    property bool autoClose: true

    // Popup content
    property alias popupContent: containerSubContentLoader.sourceComponent

    // Footer
    property alias button1: leftButton
    property alias button2: centerButton
    property alias button3: rightButton
    property int button1Role
    property int button2Role
    property int button3Role

    property int popupMargins: 30

    // ADDRESS THIS
    property int maximumPopupWidth: 560

    anchors.centerIn: parent

    modal: true

    focus: true
    closePolicy: autoClose ? (Popup.CloseOnEscape | Popup.CloseOnPressOutside) : Popup.NoAutoClose

    contentItem: JamiFlickable {
        implicitWidth: containerSubContentLoader.width + ScrollBar.vertical.width
        implicitHeight: containerSubContentLoader.height

        Loader {
            id: containerSubContentLoader
        }
    }

    footer: RowLayout {

        spacing: 8
        visible: button1.text.length > 0 || button2.text.length > 0 || button3.text.length > 0

        NewMaterialButton {
            id: leftButton

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.leftMargin: root.dialogPadding
            Layout.rightMargin: centerButton.visible || rightButton.visible ? 0 : root.dialogPadding
            Layout.bottomMargin: root.dialogPadding

            visible: text.length > 0
            textButton: true

            DialogButtonBox.buttonRole: root.button1Role
        }

        NewMaterialButton {
            id: centerButton

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.leftMargin: leftButton.visible ? 0 : root.dialogPadding
            Layout.rightMargin: rightButton.visible ? 0 : root.dialogPadding
            Layout.bottomMargin: root.dialogPadding

            visible: text.length > 0
            textButton: true

            DialogButtonBox.buttonRole: root.button2Role
        }

        NewMaterialButton {
            id: rightButton

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.rightMargin: root.dialogPadding
            Layout.bottomMargin: root.dialogPadding

            visible: text.length > 0
            textButton: true

            DialogButtonBox.buttonRole: root.button3Role
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
