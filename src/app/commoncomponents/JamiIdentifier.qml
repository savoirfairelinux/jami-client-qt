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
    property bool validated: false
    property bool outsideClic: false
    property bool justChanged: false
    property bool clic : false
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

    RowLayout {
        id: outerRow
        anchors.horizontalCenter: jamiId.centered ? parent.horizontalCenter : undefined
        anchors.left: jamiId.centered ? undefined : parent.left
        spacing: 2

        RoundedBorderRectangle {
            id: leftRect
            fillColor: JamiTheme.jamiIdBackgroundColor
            Layout.preferredWidth: usernameTextEdit.visible ? childrenRect.width + JamiTheme.pushButtonMargins : childrenRect.width
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
                    Layout.fillHeight: true
                    Layout.leftMargin: JamiTheme.pushButtonMargins
                    source: JamiResources.jami_id_logo_svg
                    color: JamiTheme.tintedBlue
                }

                UsernameTextEdit {
                    id: usernameTextEdit
                    visible: !readOnly
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 300
                    Layout.alignment: Qt.AlignVCenter
                    textColor: JamiTheme.tintedBlue
                    fontPixelSize: JamiTheme.jamiIdSmallFontSize
                    editMode: false
                    isPersistent: false
                    readOnly: true

                    onAccepted: {
                        usernameTextEdit.readOnly = true;
                        if (dynamicText === '' /*|| outsideClic*/) {
                            print(dynamicText)
                            outsideClic = false;
                            print("return");
                            return;
                        }
                        var dlg = viewCoordinator.presentDialog(appWindow, "settingsview/components/NameRegistrationDialog.qml", {
                                "registeredName": dynamicText
                            });
                        dlg.accepted.connect(function () {
                                usernameTextEdit.nameRegistrationState = UsernameTextEdit.NameRegistrationState.BLANK;
                            });
                    }

                    onIsActiveChanged: {
                        print("isActiveChanged: " + isActive);
                        if (!isActive && !readOnly) {
                            print("ds if");
                            readOnly = true;
                            justChanged = true;
                            //dynamicText = ''
                            outsideClic = true;
                            print("outsideClic: " + outsideClic);
                        }
                    }
                }
                Label{
                    id: usernameLabel
                    visible: usernameTextEdit.readOnly

                    verticalAlignment: Text.AlignVCenter

                    Layout.rightMargin: JamiTheme.pushButtonMargins
                    Layout.bottomMargin: text === registeredName ? 5 : 0
                    Layout.maximumWidth: leftRect.width - 50
                    Layout.fillHeight: true
                    elide: Text.ElideRight
                    color: JamiTheme.tintedBlue
                    font.pixelSize : text.length > 16 ? JamiTheme.jamiIdSmallFontSize : JamiTheme.bigFontSize
                    property string registeredName: CurrentAccount.registeredName
                    property string infohash: CurrentAccount.uri
                    text: registeredName ? registeredName : infohash
                    onRegisteredNameChanged: {
                        text = registeredName ? registeredName : infohash
                    }
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
                        case UsernameTextEdit.NameRegistrationState.FREE:
                            return true;
                        case UsernameTextEdit.NameRegistrationState.SEARCHING:
                        case UsernameTextEdit.NameRegistrationState.INVALID:
                        case UsernameTextEdit.NameRegistrationState.TAKEN:
                        case UsernameTextEdit.NameRegistrationState.BLANK:
                            return false;
                        }
                    }
                    hoverEnabled: enabled
                    source: usernameTextEdit.editMode ? JamiResources.check_black_24dp_svg : JamiResources.assignment_ind_black_24dp_svg
                    toolTipText: JamiStrings.chooseUsername
                    onClicked: {
                        clic = true;
                        outsideClic = false;
                        if (!justChanged /*|| !usernameTextEdit.isActive*/ /*&& !outsideClic*/) {
                            print("v1");
                            justChanged = false;
                            usernameTextEdit.startEditing();
                            usernameTextEdit.readOnly = false;
                            print("start editing");
                        } else {
                            print("v2");
                            usernameTextEdit.accepted();
                            print("accepted");
                            justChanged = false;
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
