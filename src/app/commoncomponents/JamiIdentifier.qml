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
    property bool isLong: true
    height: getHeight()

    function getHeight() {
        return usernameTextEdit.height + (isLong ? 0 : controlsLayout.height);
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
        id: outerRect
        radius: 20
        color: JamiTheme.secondaryBackgroundColor
        width: parent.width
        height: childrenRect.height

        JamiIdLogo {
            id: jamiIdLogo
            fillColor: JamiTheme.mainColor
            width: 97
            height: 40
            anchors.top: outerRect.top
            anchors.left: outerRect.left
            radius: {
                "tl": outerRect.radius,
                "tr": outerRect.radius,
                "br": outerRect.radius,
                "bl": isLong ? outerRect.radius : 0
            }
        }

        RowLayout {
            id: controlsLayout

            anchors.top: outerRect.top
            anchors.right: outerRect.right
            anchors.rightMargin: JamiTheme.pushButtonMargin
            anchors.topMargin: JamiTheme.pushButtonMargin / 2
            height: childrenRect.height
            width: childrenRect.width

            JamiIdControlButton {
                id: btnEdit
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

        UsernameTextEdit {
            id: usernameTextEdit

            //width: root.isLong ? 400 : 320
            width: root.width - ((isLong ? controlsLayout.width + jamiIdLogo.width : 0) + 2 * JamiTheme.preferredMarginSize);

            height: implicitHeight + 1 * JamiTheme.preferredMarginSize

            anchors.top: root.isLong ? parent.top : controlsLayout.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            anchors.leftMargin: JamiTheme.preferredMarginSize
            anchors.rightMargin: JamiTheme.preferredMarginSize
            fontPixelSize: JamiTheme.jamiIdFontSize
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

    component JamiIdControlButton: PushButton {
        property bool clicked: true
        preferredSize: 30
        normalColor: JamiTheme.transparentColor
        hoveredColor: JamiTheme.hoveredButtonColorWizard
        imageContainerWidth: JamiTheme.pushButtonSize
        imageContainerHeight: JamiTheme.pushButtonSize
        border.color: JamiTheme.tintedBlue
        imageColor: JamiTheme.buttonTintedBlue
    }

    component JamiIdLogo: Canvas {

        property var radius
        property string fillColor: Style.colorBGPrimary

        onRadiusChanged: requestPaint()
        onFillColorChanged: requestPaint()

        //Draw rounded rectangle.
        onPaint: {
            var ctx = getContext("2d");
            var r = {};
            Object.assign(r, radius);
            if (typeof r === 'undefined')
                r = 0;
            if (typeof r === 'number')
                r = {
                    "tl": r,
                    "tr": r,
                    "br": r,
                    "bl": r
                };
            else {
                var defaultRadius = {
                    "tl": 0,
                    "tr": 0,
                    "br": 0,
                    "bl": 0
                };
                for (var side in defaultRadius)
                    r[side] = r[side] || defaultRadius[side];
            }
            var x0 = 0;
            var y0 = x0;
            var x1 = width;
            var y1 = height;
            ctx.reset();
            ctx.beginPath();
            ctx.moveTo(x0 + r.tl, y0);
            ctx.lineTo(x1 - r.tr, y0);
            ctx.quadraticCurveTo(x1, y0, x1, y0 + r.tr);
            ctx.lineTo(x1, y1 - r.br);
            ctx.quadraticCurveTo(x1, y1, x1 - r.br, y1);
            ctx.lineTo(x0 + r.bl, y1);
            ctx.quadraticCurveTo(x0, y1, x0, y1 - r.bl);
            ctx.lineTo(x0, y0 + r.tl);
            ctx.quadraticCurveTo(x0, y0, x0 + r.tl, y0);
            ctx.closePath();
            ctx.fillStyle = fillColor;
            ctx.fill();
        }

        ResponsiveImage {
            id: jamiIdLogoImage
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: JamiTheme.jamiIdLogoWidth
            height: JamiTheme.jamiIdLogoHeight
            source: JamiResources.jamiid_svg
        }
    }
}
