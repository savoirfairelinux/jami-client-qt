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
    property color contentColor: JamiTheme.tintedBlue
    property bool centered: true
    height: getHeight()

    function getHeight() {
        return outerRow.height;
    }

    Connections {
        target: CurrentAccount
        function onIdChanged(id) {
            if (usernameTextEdit.editMode) {
                usernameTextEdit.editMode = false;
            }

        }
    }

    RowLayout {
        id: outerRow
        anchors.horizontalCenter: jamiId.centered ? parent.horizontalCenter : undefined
        anchors.left: jamiId.centered ? undefined : parent.left
        spacing: 2

        RoundedBorderRectangle {
            id: leftRect
            fillColor: JamiTheme.jamiIdBackgroundColor
            Layout.preferredWidth: childrenRect.width
            Layout.maximumWidth: jamiId.width - rightRect.width
            Layout.preferredHeight: childrenRect.height
            radius: {
                "tl": 5,
                "tr": 0,
                "br": 0,
                "bl": 5
            }

            RowLayout {
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

                IdentifierUsernameTextEdit {
                    id: usernameTextEdit
                    visible: editMode
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true

                    editMode: false

                    onAccepted: {
                        usernameTextEdit.editMode = false;
                        if (dynamicText === '') {
                            return;
                        }
                        var dlg = viewCoordinator.presentDialog(appWindow, "settingsview/components/NameRegistrationDialog.qml", {
                                "registeredName": dynamicText
                            });
                        dlg.accepted.connect(function () {
                                usernameTextEdit.nameRegistrationState = IdentifierUsernameTextEdit.NameRegistrationState.BLANK;
                            });
                        dynamicText = '';
                    }
                }
                Label{
                    id: usernameLabel

                    visible: !usernameTextEdit.editMode

                    verticalAlignment: Text.AlignVCenter

                    Layout.rightMargin: JamiTheme.pushButtonMargins
                    Layout.maximumWidth: leftRect.width - 50
                    elide: Text.ElideRight
                    color: JamiTheme.tintedBlue
                    font.pixelSize : text.length > 16 ? JamiTheme.jamiIdSmallFontSize : JamiTheme.bigFontSize
                    property string registeredName: CurrentAccount.registeredName
                    property string infohash: CurrentAccount.uri
                    text: registeredName ? registeredName : infohash
                }
            }
        }

        RoundedBorderRectangle {
            id: rightRect
            fillColor: JamiTheme.jamiIdBackgroundColor
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
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: JamiTheme.pushButtonMargins
                anchors.leftMargin: JamiTheme.pushButtonMargins
                anchors.horizontalCenter: parent.horizontalCenter

                JamiIdControlButton {
                    id: btnEdit
                    anchors.leftMargin: JamiTheme.pushButtonMargins
                    visible: CurrentAccount.registeredName === ""
                    imageColor: enabled ? JamiTheme.tintedBlue : JamiTheme.buttonTintedBlack
                    border.color: usernameTextEdit.editMode ? jamiId.contentColor : "transparent"
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
                    hoverEnabled: enabled

                    onHoveredChanged: {
                        if (hovered) {
                            usernameTextEdit.btnHovered = true;
                        } else {
                            usernameTextEdit.btnHovered = false;
                        }
                    }

                    source: usernameTextEdit.editMode ? JamiResources.check_black_24dp_svg : JamiResources.assignment_ind_black_24dp_svg
                    toolTipText: JamiStrings.chooseUsername
                    onClicked: {
                        usernameTextEdit.forceActiveFocus();
                        if (!usernameTextEdit.editMode) {
                            usernameTextEdit.startEditing();
                            usernameTextEdit.editMode = true;
                        } else {
                            usernameTextEdit.accepted();
                        }
                    }

                    Rectangle {
                        width: 10
                        height: 10
                        visible: !usernameTextEdit.editMode

                        anchors.top: parent.top
                        anchors.right: parent.right
                        radius: width / 2
                        color: JamiTheme.redDotColor
                        border.color: JamiTheme.jamiIdBackgroundColor
                        border.width: 2
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
                    source: JamiResources.outline_info_24dp_svg
                    visible: CurrentAccount.registeredName !== ""
                    border.color: "transparent"
                    toolTipText: JamiStrings.identifierURI
                    onClicked: {
                        if (clicked) {
                            usernameLabel.text = Qt.binding(function() {return CurrentAccount.uri} );
                            usernameTextEdit.staticText = Qt.binding(function() {return CurrentAccount.uri} );
                            btnId.toolTipText = JamiStrings.identifierRegisterName;
                        } else {
                            usernameLabel.text = Qt.binding(function() {return CurrentAccount.registeredName} );
                            usernameTextEdit.staticText = Qt.binding(function() {return CurrentAccount.registeredName} );
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
        imageContainerWidth: JamiTheme.pushButtonSize
        imageContainerHeight: JamiTheme.pushButtonSize
        border.color: jamiId.contentColor
        imageColor: JamiTheme.tintedBlue
        duration: 0
    }
}
