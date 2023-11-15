/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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
import QtQuick.Layouts
import "../../commoncomponents"

BaseModalDialog {
    id: root

    title: JamiStrings.encryptAccount

    closeButtonVisible: false

    signal accepted(string password)

    button1.text: JamiStrings.optionSave
    button1.enabled: false

    button2.text: JamiStrings.optionCancel
    button2.onClicked: close()

    popupContent: ColumnLayout {

        id: passwordColumnLayout
        anchors.bottomMargin: 30

        Component.onCompleted: {
            root.button1.clicked.connect(function() {
                root.accepted(passwordConfirmEdit.dynamicText);
            });
        }

        Text {
            Layout.preferredWidth: 400 - 2 * popupMargins
            Layout.alignment: Qt.AlignLeft

            color: JamiTheme.textColor
            wrapMode: Text.WordWrap
            text: JamiStrings.encryptDescription
            font.pixelSize: JamiTheme.headerFontSize
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }

        PasswordTextEdit {
            id: passwordEdit

            firstEntry: true
            placeholderText: JamiStrings.password

            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: 20
            Layout.preferredWidth: 400 - 2 * popupMargins

            KeyNavigation.up: passwordConfirmEdit
            KeyNavigation.down: KeyNavigation.up

            onDynamicTextChanged: {
                button1.enabled = passwordEdit.dynamicText === passwordConfirmEdit.dynamicText && passwordEdit.dynamicText.length !== 0
            }
        }

        PasswordTextEdit {
            id: passwordConfirmEdit
            placeholderText: JamiStrings.confirmPassword

            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 400 - 2 * popupMargins
            Layout.topMargin: 20
            KeyNavigation.up: passwordEdit
            KeyNavigation.down: KeyNavigation.up

            onDynamicTextChanged: {
                button1.enabled = passwordEdit.dynamicText === passwordConfirmEdit.dynamicText && passwordEdit.dynamicText.length !== 0
            }
        }

        Rectangle {
            radius: 5
            color: JamiTheme.infoRectangleColor
            Layout.fillWidth: true
            Layout.minimumHeight: infoLayout.height + 35
            Layout.topMargin: 20

            RowLayout {
                id: infoLayout
                anchors.centerIn: parent
                width: parent.width - 35
                anchors.margins: 14
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
                    font.pixelSize: JamiTheme.headerFontSize
                }
            }
        }
    }
}
