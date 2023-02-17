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
import "../../settingsview/components"

Item {
    id: root

    width: childrenRect.width
    height: controlsLayout.height + usernameTextEdit.height
            + 2 * JamiTheme.preferredMarginSize

    // Background rounded rectangle.
    Rectangle {
        id: outerRect
        anchors.fill: parent; radius: 20
        color: JamiTheme.secondaryBackgroundColor
    }

    // Logo masked by outerRect.
    Item {
        anchors.fill: outerRect
        layer.enabled: true; layer.effect: OpacityMask { maskSource: outerRect }

        Rectangle {
            id: logoRect
            width: 97 + radius
            height: 40
            color: JamiTheme.mainColor
            radius: 20
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: -radius

            ResponsiveImage {
                id: jamiIdLogo
                anchors.horizontalCenter: parent.horizontalCenter
                // Adjust offset for parent masking margin.
                anchors.horizontalCenterOffset: parent.radius / 2
                anchors.verticalCenter: parent.verticalCenter
                width: JamiTheme.jamiIdLogoWidth
                height: JamiTheme.jamiIdLogoHeight
                source: JamiResources.jamiid_svg
            }
        }
    }

    ColumnLayout {
        id: columnLayout

        spacing: JamiTheme.preferredMarginSize

        RowLayout {
            id: controlsLayout

            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Layout.topMargin: JamiTheme.pushButtonMargin
            Layout.rightMargin: JamiTheme.pushButtonMargin
            Layout.preferredHeight: childrenRect.height

            component JamiIdControlButton: PushButton {
                preferredSize : 30
                normalColor: JamiTheme.transparentColor
                hoveredColor: JamiTheme.transparentColor
                imageContainerWidth: JamiTheme.pushButtonSize
                imageContainerHeight: JamiTheme.pushButtonSize
                border.color: JamiTheme.tintedBlue
                imageColor: JamiTheme.buttonTintedBlue
            }

            JamiIdControlButton {
                id: btnEdit
                visible: CurrentAccount.registeredName === ""
                border.color: enabled ? JamiTheme.buttonTintedBlue :  JamiTheme.buttonTintedBlack
                imageColor: enabled ? JamiTheme.buttonTintedBlue :  JamiTheme.buttonTintedBlack
                enabled: {
                    if (!usernameTextEdit.editMode)
                        return true
                    switch(usernameTextEdit.nameRegistrationState) {
                    case UsernameLineEdit.NameRegistrationState.BLANK:
                    case UsernameLineEdit.NameRegistrationState.FREE:
                        return true
                    case UsernameLineEdit.NameRegistrationState.SEARCHING:
                    case UsernameLineEdit.NameRegistrationState.INVALID:
                    case UsernameLineEdit.NameRegistrationState.TAKEN:
                        return false
                    }
                }
                source: usernameTextEdit.editMode
                        ? JamiResources.check_black_24dp_svg
                        : JamiResources.round_edit_24dp_svg
                toolTipText: JamiStrings.chooseUsername
                onClicked: {
                    if (!usernameTextEdit.editMode) {
                        usernameTextEdit.startEditing()
                    } else {
                        usernameTextEdit.accepted()
                    }
                }
            }

            JamiIdControlButton {
                id: btnCopy
                source: JamiResources.content_copy_24dp_svg
                toolTipText: JamiStrings.copy
                onClicked: UtilsAdapter.setClipboardText(CurrentAccount.bestId)
            }

            JamiIdControlButton {
                id: btnShare
                source: JamiResources.share_24dp_svg
                toolTipText: JamiStrings.share
                onClicked: qrDialog.open()
            }
        }

        UsernameTextEdit {
            id: usernameTextEdit

            Layout.preferredWidth: 330
            Layout.preferredHeight: implicitHeight + JamiTheme.preferredMarginSize
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.rightMargin: JamiTheme.preferredMarginSize
            fontPointSize: JamiTheme.textFontSize + 1
            staticText: hasRegisteredName ? registeredName : infohash
            editMode: false
            isPersistent: false

            onAccepted: {
                if (dynamicText === '') {
                    return
                }
                var dlg = viewCoordinator.presentDialog(
                            appWindow,
                            "settingsview/components/NameRegistrationDialog.qml",
                            { registeredName: dynamicText })
                dlg.accepted.connect(function() {
                    currentRegisteredID.nameRegistrationState =
                            UsernameLineEdit.NameRegistrationState.BLANK
                })
            }
        }
    }
}
