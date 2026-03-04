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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import QtQuick.Controls
import QtQuick.Layouts
import "../../commoncomponents"

BaseModalDialog {
    id: root

    titleText: JamiStrings.encryptAccount

    closeButtonVisible: false

    signal accepted(string password)

    button1.text: JamiStrings.optionSave
    button1.enabled: false

    button2.text: JamiStrings.optionCancel
    button2.onClicked: close()

    popupContent: ColumnLayout {
        id: passwordColumnLayout

        width: 400

        spacing: 16

        Component.onCompleted: {
            root.button1.clicked.connect(function() {
                root.accepted(passwordConfirmEdit.modifiedTextFieldContent);
                root.close();
            });
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft

            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            text: JamiStrings.encryptDescription
            font.pixelSize: JamiTheme.headerFontSize
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }

        PasswordTextEdit {
            id: passwordEdit

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft

            firstEntry: true
            placeholderText: JamiStrings.enterPassword

            onModifiedTextFieldContentChanged: {
                button1.enabled = passwordEdit.modifiedTextFieldContent === passwordConfirmEdit.modifiedTextFieldContent && passwordEdit.modifiedTextFieldContent.length !== 0
            }

            KeyNavigation.up: passwordConfirmEdit
            KeyNavigation.down: KeyNavigation.up
        }

        PasswordTextEdit {
            id: passwordConfirmEdit

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft

            placeholderText: JamiStrings.confirmPassword

            onModifiedTextFieldContentChanged: {
                button1.enabled = passwordEdit.modifiedTextFieldContent === passwordConfirmEdit.modifiedTextFieldContent && passwordEdit.modifiedTextFieldContent.length !== 0
            }

            Accessible.description: JamiStrings.encryptDescription

            KeyNavigation.up: passwordEdit
            KeyNavigation.down: KeyNavigation.up
        }

        Control {
            Layout.fillWidth: true

            padding: 14

            contentItem: RowLayout {
                id: infoLayout
                anchors.centerIn: parent
                spacing: 10

                ResponsiveImage{
                    Layout.fillWidth: true
                    source: JamiResources.outline_info_24dp_svg
                    fillMode: Image.PreserveAspectFit
                    color: JamiTheme.darkTheme ? JamiTheme.editLineColor : JamiTheme.darkTintedBlue
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: 400 - 2 * popupMargins

                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                    text: JamiStrings.encryptWarning
                    font.pixelSize: JamiTheme.menuFontSize
                    lineHeight: 1.3
                }
            }

            background: Rectangle {
                radius: 5
                color: JamiTheme.infoRectangleColor
            }
        }
    }
}
