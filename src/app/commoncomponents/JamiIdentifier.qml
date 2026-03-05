/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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

Control {
    id: jamiId

    property bool showFingerprint: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, implicitContentHeight + topPadding + bottomPadding)

    topPadding: JamiTheme.jamiIdVerticalPadding
    bottomPadding: JamiTheme.jamiIdVerticalPadding
    leftPadding: (implicitHeight / 2) - (jamiIDIcon.implicitWidth / 2)
    rightPadding: (implicitHeight / 2) - (shareButton.implicitHeight / 2)

    contentItem: RowLayout {
        spacing: JamiTheme.jamiIdContentItemSpacing

        NewIconButton {
            id: jamiIDIcon

            iconSource: JamiResources.jami_id_logo_new_24dp_svg
            iconSize: JamiTheme.iconButtonMedium
            icon.color: JamiTheme.buttonTintedGreyHovered

            background: null
            enabled: false
        }

        Text {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            text: CurrentAccount.registeredName !== "" && !showFingerprint ? CurrentAccount.registeredName : CurrentAccount.uri
            color: JamiTheme.tintedBlue
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            font.family: text === CurrentAccount.uri ? JamiTheme.ubuntuMonoFontFamily : JamiTheme.ubuntuFontFamily
            font.pixelSize: CurrentAccount.registeredName !== "" && !showFingerprint ? JamiTheme.bigFontSize : JamiTheme.mediumFontSize

            visible: !usernameTextEdit.visible

            opacity: visible ? 1.0 : 0.0

            FontMetrics {
                id: fontMetrics
                font: parent.font
            }

            // Optically center the x-height region of the text within the bounding box.
            // The visible center is at (ascent - xHeight/2), while the box center is at
            // (ascent + descent)/2. The correction aligns these two centers.
            transform: Translate {
                y: (fontMetrics.descent + fontMetrics.xHeight - fontMetrics.ascent) / 2
            }
        }

        UsernameTextEdit {
            id: usernameTextEdit

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: JamiTheme.jamiIdUsernameTextEditPreferredWidth
            Layout.maximumWidth: JamiTheme.jamiIdUsernameTextEditMaximumWidth

            opacity: visible ? 1.0 : 0.0

            visible: false

            onAccepted: {
                usernameTextEdit.visible = false;
                if (modifiedTextFieldContent === '') {
                    return;
                }
                var dlg = viewCoordinator.presentDialog(appWindow, "settingsview/components/NameRegistrationDialog.qml", {
                    "registeredName": modifiedTextFieldContent
                });
                dlg.accepted.connect(function () {
                    usernameTextEdit.nameRegistrationState = UsernameTextEdit.NameRegistrationState.BLANK;
                });
                modifiedTextFieldContent = '';
            }
        }

        RowLayout {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            NewIconButton {
                id: copyOrEditButton

                Layout.alignment: Qt.AlignVCenter

                iconSource: {
                    if (usernameTextEdit.visible) {
                        return JamiResources.close_black_24dp_svg;
                    } else {
                        if (CurrentAccount.registeredName !== "") {
                            return JamiResources.content_copy_24dp_svg;
                        } else {
                            return JamiResources.assignment_ind_black_24dp_svg;
                        }
                    }
                }
                iconSize: JamiTheme.iconButtonMedium
                toolTipText: {
                    if (usernameTextEdit.visible) {
                        return JamiStrings.cancel;
                    } else {
                        if (CurrentAccount.registeredName !== "") {
                            return JamiStrings.copy;
                        } else {
                            return JamiStrings.chooseAUsername;
                        }
                    }
                }

                onClicked: {
                    if (CurrentAccount.registeredName === "")
                        usernameTextEdit.visible = !usernameTextEdit.visible;
                    else
                        UtilsAdapter.setClipboardText(usernameTextEdit.textFieldContent);
                }

                Rectangle {
                    id: redDotIndicator

                    anchors.top: parent.top
                    anchors.topMargin: JamiTheme.redDotIndicatorMargin
                    anchors.right: parent.right
                    anchors.rightMargin: JamiTheme.redDotIndicatorMargin

                    width: JamiTheme.redDotIndicatorSize
                    height: JamiTheme.redDotIndicatorSize
                    radius: height / 2

                    z: parent.z + 2

                    color: JamiTheme.redDotIndicatorColor

                    visible: CurrentAccount.registeredName === "" && !usernameTextEdit.visible

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: redDotIndicator.visible
                        NumberAnimation {
                            from: 1.0
                            to: 1.2
                            duration: JamiTheme.recordBlinkDuration
                        }
                        NumberAnimation {
                            from: 1.2
                            to: 1.0
                            duration: JamiTheme.recordBlinkDuration
                        }
                    }
                }
            }

            NewIconButton {
                id: shareButton

                Layout.alignment: Qt.AlignVCenter

                iconSource: JamiResources.share_24dp_svg
                iconSize: JamiTheme.iconButtonMedium
                toolTipText: JamiStrings.share

                onClicked: viewCoordinator.presentDialog(appWindow, "mainview/components/WelcomePageQrDialog.qml")
            }

            NewIconButton {
                id: fingerprintButton

                Layout.alignment: Qt.AlignVCenter

                iconSource: showFingerprint ? JamiResources.fingerprint_off_24dp_svg : JamiResources.fingerprint_24dp_svg
                iconSize: JamiTheme.iconButtonMedium
                toolTipText: showFingerprint ? JamiStrings.hideFingerprint : JamiStrings.showFingerprint

                visible: CurrentAccount.registeredName !== ""

                onClicked: showFingerprint = !showFingerprint
            }
        }
    }

    background: Rectangle {
        color: JamiTheme.welcomeBlockColor
        radius: height / 2
    }

    Connections {
        target: CurrentAccount

        // Ensures that the text field is closed when changing accounts
        function onIdChanged() {
            usernameTextEdit.visible = false;
        }
    }
}
