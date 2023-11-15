/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Capucine Berthet <capucine.berthet@savoirfairelinux.com>
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

    title: JamiStrings.customizeProfile
    closeButtonVisible: false

    signal accepted(string displayName)

    property string alias: ""

    button1.text: JamiStrings.optionSave
    button1.enabled: false
    button1.onClicked: {
        accepted(alias);
        close();
    }

    button2.text: JamiStrings.optionCancel
    button2.onClicked: close()

    popupContent: ColumnLayout {
        id: customColumnLayout
        spacing: 20

        Rectangle {
            id: customRectangle

            Layout.preferredHeight: customLayout.height
            Layout.fillWidth: true
            color: JamiTheme.customizeRectangleColor
            radius: 5

            RowLayout {
                id: customLayout
                anchors.centerIn: parent
                width: parent.width

                PhotoboothView {
                    id: accountAvatar

                    width: avatarSize
                    height: avatarSize

                    Layout.alignment: Qt.AlignLeft | Qt.AlignCenter
                    Layout.margins: 10

                    newItem: true
                    imageId: "temp"
                    avatarSize: 56
                    editButton.visible: false
                    visible: false

                }

                PushButton {
                    id: editImage

                    width: 56
                    height: 56
                    Layout.margins: 10
                    Layout.alignment: Qt.AlignLeft| Qt.AlignCenter

                    source: JamiResources.person_outline_black_24dp_svg
                    visible: !accountAvatar.visible

                    preferredSize: 56

                    normalColor: JamiTheme.customizePhotoColor
                    imageColor: JamiTheme.whiteColor
                    hoveredColor: JamiTheme.customizePhotoHoveredColor

                    imageContainerWidth: 30

                    onClicked: {
                        var dlg = viewCoordinator.presentDialog(parent, "commoncomponents/PhotoboothPopup.qml", {
                            "parent": editImage,
                            "imageId": accountAvatar.imageId,
                            "newItem": true
                        })
                        dlg.onImageValidated.connect(function() {
                            accountAvatar.visible = true
                            root.button1.enabled = true
                        })
                    }
                }

                ModalTextEdit {
                    id: displayNameLineEdit

                    Layout.alignment: Qt.AlignLeft
                    Layout.rightMargin: 10
                    Layout.fillWidth: true

                    placeholderText: JamiStrings.displayName

                    onDynamicTextChanged: {
                        if (!button1.enabled)
                            button1.enabled = displayNameLineEdit.dynamicText.length !== 0
                        root.alias = displayNameLineEdit.dynamicText;
                    }
                }
            }
        }



        Text {

            Layout.fillWidth: true
            Layout.preferredWidth: 400 - 2 * popupMargins
            Layout.alignment: Qt.AlignLeft

            wrapMode: Text.WordWrap
            color: JamiTheme.textColor
            text: JamiStrings.customizeProfileDescription
            font.pixelSize: JamiTheme.headerFontSize
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }
    }
}
