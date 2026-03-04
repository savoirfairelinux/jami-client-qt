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
import QtQuick.Effects
import QtQuick.Layouts

import net.jami.Constants 1.1
import "../mainview/components"

Dialog {
    id: root

    // Header
    property alias titleText: titleText.text
    property bool autoClose: true
    property bool closeButtonVisible: true

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

    property real dialogPadding: 12

    anchors.centerIn: parent

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding,
                            implicitHeaderWidth,
                            implicitFooterWidth)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    modal: true

    focus: true
    closePolicy: autoClose ? (Popup.CloseOnEscape | Popup.CloseOnPressOutside) : Popup.NoAutoClose

    padding: 30

    header: RowLayout {
        Label {
            id: titleText

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            Layout.leftMargin: root.dialogPadding
            Layout.topMargin: root.dialogPadding

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor
            font.bold: true
            font.pointSize: JamiTheme.menuFontSize

            visible: text.length > 0
        }

        NewIconButton {
            id: closeButton
            QWKSetParentHitTestVisible {}

            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.rightMargin: root.dialogPadding
            Layout.topMargin: root.dialogPadding

            iconSize: JamiTheme.iconButtonMedium
            iconSource: JamiResources.round_close_24dp_svg
            toolTipText: JamiStrings.close

            visible: closeButtonVisible

            onClicked: close()
        }
    }

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

    background: Rectangle {
        topLeftRadius: closeButton.background.radius + root.dialogPadding
        topRightRadius: closeButton.background.radius + root.dialogPadding
        bottomRightRadius: JamiTheme.newMaterialButtonHeight / 2 + root.dialogPadding
        bottomLeftRadius: JamiTheme.newMaterialButtonHeight / 2 + root.dialogPadding

        color: JamiTheme.globalIslandColor

        layer.enabled: true
        layer.effect: MultiEffect {
            anchors.fill: parent
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: 3.0
            shadowVerticalOffset: 3.0
        }
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor

        // Color animation for overlay when pop up is shown.
        ColorAnimation on color {
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
