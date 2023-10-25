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

        color: JamiTheme.jamiButtonBorderColor
        width: userProfileDialogLayout.width + 20
        height: userProfileDialogLayout.height + 20

        radius: 5


        ColumnLayout {
            id: userProfileDialogLayout
            anchors.centerIn: parent

            width: JamiTheme.secondaryDialogDimension
            height: childrenRect.height
            spacing: 10

            RowLayout {
                Layout.margins: 10
                Layout.fillWidth: true
                spacing: 10

                Avatar {
                    id: contactImage

                    //Layout.alignment: Qt.AlignRight
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

                        font.pointSize: JamiTheme.titleFontSize
                        font.kerning: true
                        color: JamiTheme.textColor
                        visible: aliasText ? (aliasText === idText ? false : true) : false

                        selectByMouse: true
                        readOnly: true

                        wrapMode: Text.NoWrap
                        text: textMetricsContactAliasText.elidedText

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        TextMetrics {
                            id: textMetricsContactAliasText
                            font: contactAlias.font
                            text: aliasText
                            elideWidth: root.width - 200
                            elide: Qt.ElideMiddle
                        }
                    }


                    // Visible when user name is not empty or equals to id.
                    TextEdit {
                        id: contactDisplayName

                        Layout.alignment: Qt.AlignLeft

                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true
                        color: JamiTheme.textColor
                        visible: registeredNameText ? (registeredNameText === idText ? false : true) : false

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

                Image {
                    id: contactQrImage

                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                    horizontalAlignment: Image.AlignRight

                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: preferredImgSize
                    sourceSize.height: preferredImgSize
                    mipmap: false
                    smooth: false

                    source: convId !== "" ? "image://qrImage/contact_" + convId : "image://qrImage/contact_" + idText
                }


            }

            Rectangle {
                Layout.fillWidth: true
                radius: 5
                color: root.backgroundColor
                width: userProfileDialogLayout.width - 10
                height: contactId.height + 10
                Layout.margins: 10


                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    height: childrenRect.height
                    spacing: 20

                    Text {
                        id: identifierText
                        font.pointSize: JamiTheme.textFontSize
                        text: JamiStrings.identifier
                        color: JamiTheme.faddedFontColor
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    TextEdit {
                        id: contactId

                        Layout.alignment: Qt.AlignLeft
                        Layout.preferredWidth: root.width - 250
                        Layout.rightMargin: JamiTheme.preferredMarginSize
                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true
                        color: JamiTheme.textColor

                        readOnly: true
                        selectByMouse: true

                        wrapMode: Text.Wrap
                        text: idText

                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            }
    }
    }

