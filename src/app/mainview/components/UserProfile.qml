/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
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
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    property string convId
    property string aliasText
    property string registeredNameText
    property string idText

    property int preferredImgSize: 80

    title: JamiStrings.contactDetails

    popupContent: Rectangle {
        color: JamiTheme.backgroundRectangleColor
        width: idRectangle.width + 20
        height: userProfileDialogLayout.height + 10
        radius: 5

        Rectangle{
            id: qrImageBackground
            radius: 5
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 10
            anchors.topMargin: 10
            width: 90
            height: 90

            Image {
                id: contactQrImage

                anchors.centerIn: parent
                horizontalAlignment: Image.AlignRight
                fillMode: Image.PreserveAspectFit

                sourceSize.width: preferredImgSize
                sourceSize.height: preferredImgSize

                mipmap: false
                smooth: false

                source: convId !== "" ? "image://qrImage/contact_" + convId : "image://qrImage/contact_" + idText
            }
        }

        ColumnLayout {
            id: userProfileDialogLayout
            spacing: 10

            RowLayout {
                Layout.margins: 10
                Layout.preferredWidth: childrenRect.width

                spacing: 10

                Avatar {
                    id: contactImage

                    Layout.preferredWidth: preferredImgSize
                    Layout.preferredHeight: preferredImgSize

                    imageId: convId !== "" ? convId : idText
                    showPresenceIndicator: false
                    mode: convId !== "" ? Avatar.Mode.Conversation : Avatar.Mode.Contact
                }

                ColumnLayout {
                    spacing: 10
                    Layout.alignment: Qt.AlignLeft

                    // Visible when user alias is not empty and not equal to id.
                    TextEdit {
                        id: contactAlias

                        Layout.alignment: Qt.AlignLeft
                        font.pointSize: JamiTheme.settingsFontSize
                        font.kerning: true

                        color: JamiTheme.textColor
                        visible: aliasText ? (aliasText === idText ? false : true) : false

                        selectByMouse: true
                        readOnly: true

                        text: textMetricsContactAliasText.elidedText
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        TextMetrics {
                            id: textMetricsContactAliasText
                            font: contactAlias.font
                            text: aliasText
                            elideWidth: userProfileDialogLayout.width - qrImageBackground.width - 100
                            elide: Qt.ElideRight
                        }
                    }

                    // Visible when user name is not empty or equals to id.
                    TextEdit {
                        id: contactDisplayName

                        Layout.alignment: Qt.AlignLeft
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true

                        color: JamiTheme.faddedFontColor
                        visible: registeredNameText ? (registeredNameText === aliasText ? false : true) : false
                        readOnly: true

                        selectByMouse: true
                        wrapMode: Text.NoWrap
                        text: textMetricsContactDisplayNameText.elidedText
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        TextMetrics {
                            id: textMetricsContactDisplayNameText
                            font: contactDisplayName.font
                            text: registeredNameText
                            elideWidth: root.width - 200
                            elide: Qt.ElideMiddle
                        }
                    }
                }
            }



            Rectangle {
                id: idRectangle

                Layout.alignment: Qt.AlignHCenter

                Layout.preferredWidth: idLayout.width + 20
                radius: 5

                color: root.backgroundColor

                Layout.preferredHeight: contactId.height + 20
                Layout.leftMargin: 10

                RowLayout {
                    id: idLayout
                    anchors.centerIn: parent
                    spacing: 15

                    Text {
                        id: identifierText

                        font.pointSize: JamiTheme.textFontSize
                        text: JamiStrings.identifier
                        color: JamiTheme.faddedFontColor

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        Layout.leftMargin: 10
                    }

                    TextEdit {
                        id: contactId
                        Layout.alignment: Qt.AlignLeft
                        Layout.minimumWidth: 400 - identifierText.width - 2 * root.popupMargins - 35

                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true
                        color: JamiTheme.textColor

                        selectByMouse: true
                        readOnly: true
                        text: textMetricsContacIdText.elidedText

                        TextMetrics {
                            id: textMetricsContacIdText
                            font: contactDisplayName.font
                            text: idText
                            elideWidth: root.width - identifierText.width - 2 * root.popupMargins - 60
                            elide: Qt.ElideMiddle
                        }

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}

