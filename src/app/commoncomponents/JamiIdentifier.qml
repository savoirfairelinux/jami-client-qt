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

Item {
    id: root
    property alias backgroundColor: outerRect.color

    height: controlsLayout.height + usernameTextEdit.height + 2 * JamiTheme.preferredMarginSize
    width: childrenRect.width

    // Background rounded rectangle.
    Rectangle {
        id: outerRect
        anchors.fill: parent
        color: JamiTheme.secondaryBackgroundColor
        radius: 20
    }

    // Logo masked by outerRect.
    Item {
        anchors.fill: outerRect
        layer.enabled: true

        Rectangle {
            id: logoRect
            anchors.left: parent.left
            anchors.leftMargin: -radius
            anchors.top: parent.top
            color: JamiTheme.mainColor
            height: 40
            radius: 20
            width: 97 + radius

            ResponsiveImage {
                id: jamiIdLogo
                anchors.horizontalCenter: parent.horizontalCenter
                // Adjust offset for parent masking margin.
                anchors.horizontalCenterOffset: parent.radius / 2
                anchors.verticalCenter: parent.verticalCenter
                height: JamiTheme.jamiIdLogoHeight
                source: JamiResources.jamiid_svg
                width: JamiTheme.jamiIdLogoWidth
            }
        }

        layer.effect: OpacityMask {
            maskSource: outerRect
        }
    }
    ColumnLayout {
        id: columnLayout
        spacing: JamiTheme.preferredMarginSize

        RowLayout {
            id: controlsLayout
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            Layout.preferredHeight: childrenRect.height
            Layout.rightMargin: JamiTheme.pushButtonMargin
            Layout.topMargin: JamiTheme.pushButtonMargin / 2

            JamiIdControlButton {
                id: btnEdit
                border.color: enabled ? JamiTheme.buttonTintedBlue : JamiTheme.buttonTintedBlack
                enabled: {
                    if (!usernameTextEdit.editMode)
                        return true;
                    switch (usernameTextEdit.nameRegistrationState) {
                    case UsernameTextEdit.NameRegistrationState.BLANK:
                    case UsernameTextEdit.NameRegistrationState.FREE:
                        return true;
                    case UsernameTextEdit.NameRegistrationState.SEARCHING:
                    case UsernameTextEdit.NameRegistrationState.INVALID:
                    case UsernameTextEdit.NameRegistrationState.TAKEN:
                        return false;
                    }
                }
                imageColor: enabled ? JamiTheme.buttonTintedBlue : JamiTheme.buttonTintedBlack
                source: usernameTextEdit.editMode ? JamiResources.check_black_24dp_svg : JamiResources.round_edit_24dp_svg
                toolTipText: JamiStrings.chooseUsername
                visible: CurrentAccount.registeredName === ""

                onClicked: {
                    if (!usernameTextEdit.editMode) {
                        usernameTextEdit.startEditing();
                    } else {
                        usernameTextEdit.accepted();
                    }
                }
            }
            JamiIdControlButton {
                id: btnCopy
                source: JamiResources.content_copy_24dp_svg
                toolTipText: JamiStrings.copy

                onClicked: UtilsAdapter.setClipboardText(usernameTextEdit.staticText)
            }
            JamiIdControlButton {
                id: btnShare
                source: JamiResources.share_24dp_svg
                toolTipText: JamiStrings.share

                onClicked: viewCoordinator.presentDialog(appWindow, "mainview/components/WelcomePageQrDialog.qml")
            }
            JamiIdControlButton {
                id: btnId
                source: JamiResources.key_black_24dp_svg
                visible: CurrentAccount.registeredName !== ""

                onClicked: {
                    if (clicked) {
                        usernameTextEdit.staticText = CurrentAccount.uri;
                    } else {
                        usernameTextEdit.staticText = CurrentAccount.registeredName;
                    }
                    clicked = !clicked;
                }
            }
        }
        UsernameTextEdit {
            id: usernameTextEdit
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.leftMargin: JamiTheme.preferredMarginSize
            Layout.preferredHeight: implicitHeight + JamiTheme.preferredMarginSize
            Layout.preferredWidth: 330
            Layout.rightMargin: JamiTheme.preferredMarginSize
            editMode: false
            fontPixelSize: JamiTheme.jamiIdFontSize
            isPersistent: false

            onAccepted: {
                if (dynamicText === '') {
                    return;
                }
                var dlg = viewCoordinator.presentDialog(appWindow, "settingsview/components/NameRegistrationDialog.qml", {
                        "registeredName": dynamicText
                    });
                dlg.accepted.connect(function () {
                        usernameTextEdit.nameRegistrationState = UsernameTextEdit.NameRegistrationState.BLANK;
                    });
            }
        }
    }

    component JamiIdControlButton: PushButton {
        property bool clicked: true

        border.color: JamiTheme.tintedBlue
        hoveredColor: JamiTheme.hoveredButtonColorWizard
        imageColor: JamiTheme.buttonTintedBlue
        imageContainerHeight: JamiTheme.pushButtonSize
        imageContainerWidth: JamiTheme.pushButtonSize
        normalColor: JamiTheme.transparentColor
        preferredSize: 30
    }
}
