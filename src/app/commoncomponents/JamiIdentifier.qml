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
    id: jamiId
    property bool slimDisplay: true
    property color backgroundColor: JamiTheme.welcomeBlockColor
    height: getHeight()

    function getHeight() {
        return outerRow.height;
    }

    Connections {
        target: CurrentAccount
        function onIdChanged(id) {
            if (!usernameTextEdit.readOnly) {
                usernameTextEdit.readOnly = true;
            }
        }
    }

    Rectangle {
        id: mask
        anchors.fill: outerRow
        radius: 5
        visible: false
        Scaffold {
        }
    }

    RowLayout {
        id: outerRow
        width: parent.width

        RoundedBorderRectangle {
            id: leftRect
            fillColor: jamiId.backgroundColor
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            radius: {
                "tl": 5,
                "tr": 0,
                "br": 0,
                "bl": 5
            }

            layer {
                enabled: true
                effect: OpacityMask {
                    maskSource: mask
                }
            }

            RowLayout {
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter

                ResponsiveImage {
                    id: jamiIdLogoImage
                    Layout.preferredHeight: 40
                    containerHeight: 40
                    containerWidth: 40
                    Layout.leftMargin: JamiTheme.pushButtonMargins
                    source: JamiResources.jami_id_logo_svg
                    color: JamiTheme.tintedBlue
                }

                UsernameTextEdit {
                    id: usernameTextEdit
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    textColor: JamiTheme.tintedBlue
                    fontPixelSize: staticText.length > 16 ? JamiTheme.jamiIdSmallFontSize : JamiTheme.jamiIdFontSize
                    editMode: false
                    isPersistent: false
                    readOnly: true

                    onAccepted: {
                        usernameTextEdit.readOnly = true;
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
        }

        RoundedBorderRectangle {
            id: rightRect
            fillColor: jamiId.backgroundColor
            Layout.preferredWidth: childrenRect.width + 2 * JamiTheme.pushButtonMargins

            Layout.preferredHeight: leftRect.height
            radius: {
                "tl": 0,
                "tr": 5,
                "br": 5,
                "bl": 0
            }

            RowLayout {
                id: controlsLayout

                height: childrenRect.height
                width: childrenRect.width
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: JamiTheme.pushButtonMargins
                anchors.leftMargin: JamiTheme.pushButtonMargins
                anchors.horizontalCenter: parent.horizontalCenter

                JamiIdControlButton {
                    id: btnEdit
                    anchors.leftMargin: JamiTheme.pushButtonMargins
                    visible: CurrentAccount.registeredName === ""
                    border.color: enabled ? JamiTheme.buttonTintedBlue : JamiTheme.buttonTintedBlack
                    imageColor: enabled ? JamiTheme.buttonTintedBlue : JamiTheme.buttonTintedBlack
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
                    source: usernameTextEdit.editMode ? JamiResources.check_black_24dp_svg : JamiResources.round_edit_24dp_svg
                    toolTipText: JamiStrings.chooseUsername
                    onClicked: {
                        if (usernameTextEdit.readOnly) {
                            usernameTextEdit.startEditing();
                            usernameTextEdit.readOnly = false;
                        } else {
                            usernameTextEdit.accepted();
                        }
                    }
                }

                JamiIdControlButton {
                    id: btnCopy
                    anchors.leftMargin: JamiTheme.pushButtonMargins
                    source: JamiResources.content_copy_24dp_svg
                    border.color: "transparent"
                    toolTipText: JamiStrings.copy
                    onClicked: UtilsAdapter.setClipboardText(usernameTextEdit.staticText)
                }

                JamiIdControlButton {
                    id: btnShare
                    source: JamiResources.share_24dp_svg
                    border.color: "transparent"
                    toolTipText: JamiStrings.share
                    onClicked: viewCoordinator.presentDialog(appWindow, "mainview/components/WelcomePageQrDialog.qml")
                }

                JamiIdControlButton {
                    id: btnId
                    source: JamiResources.key_black_24dp_svg
                    visible: CurrentAccount.registeredName !== ""
                    border.color: "transparent"
                    toolTipText: JamiStrings.identifierURI
                    onClicked: {
                        if (clicked) {
                            usernameTextEdit.staticText = CurrentAccount.uri;
                            btnId.toolTipText = JamiStrings.identifierRegisterName;
                        } else {
                            usernameTextEdit.staticText = CurrentAccount.registeredName;
                            btnId.toolTipText = JamiStrings.identifierURI;
                        }
                        clicked = !clicked;
                    }
                }
            }
        }
    }

    component JamiIdControlButton: PushButton {
        property bool clicked: true
        preferredSize: 30
        radius: 5
        normalColor: JamiTheme.transparentColor
        //hoveredColor: JamiTheme.hoveredButtonColorWizard
        imageContainerWidth: JamiTheme.pushButtonSize
        imageContainerHeight: JamiTheme.pushButtonSize
        border.color: JamiTheme.tintedBlue
        imageColor: JamiTheme.buttonTintedBlue
    }
}
