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

    width: Math.min(appWindow.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.secondaryDialogDimension)

    property string convId
    property string aliasText
    property string registeredNameText
    property string idText

    property int preferredImgSize: 80

    popupContent:

        GridLayout {
            id: userProfileDialogLayout

            anchors.centerIn: parent
            anchors.fill: parent
            anchors.margins: JamiTheme.preferredMarginSize

            columns: 2
            rows: 6
            rowSpacing: 16
            columnSpacing: 24

            Avatar {
                id: contactImage

                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: preferredImgSize
                Layout.preferredHeight: preferredImgSize

                imageId: convId !== "" ? convId : idText
                showPresenceIndicator: false
                mode: convId !== "" ? Avatar.Mode.Conversation : Avatar.Mode.Contact
            }

            // Visible when user alias is not empty and not equal to id.
            TextEdit {
                id: contactAlias

                Layout.alignment: Qt.AlignLeft

                font.pointSize: JamiTheme.titleFontSize
                font.kerning: true
                color: JamiTheme.textColor
                visible: aliasText ? (aliasText === idText ? false : true) : false

                selectByMouse: true

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

            Item {
                Layout.columnSpan: 2
                height: 8
            }

            Text {
                Layout.alignment: Qt.AlignRight
                font.pointSize: JamiTheme.menuFontSize
                text: JamiStrings.information
                color: JamiTheme.textColor
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                Layout.alignment: Qt.AlignRight
                font.pointSize: JamiTheme.textFontSize
                text: JamiStrings.username
                visible: contactDisplayName.visible
                color: JamiTheme.faddedFontColor
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

            Text {
                id: identifierText
                Layout.alignment: Qt.AlignRight
                font.pointSize: JamiTheme.textFontSize
                text: JamiStrings.identifier
                color: JamiTheme.faddedFontColor
            }

            TextEdit {
                id: contactId

                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: root.width - 240
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

            Text {
                Layout.alignment: Qt.AlignRight
                font.pointSize: JamiTheme.textFontSize
                text: JamiStrings.qrCode
                color: JamiTheme.faddedFontColor
            }

            Image {
                id: contactQrImage

                Layout.alignment: Qt.AlignLeft

                fillMode: Image.PreserveAspectFit
                sourceSize.width: preferredImgSize
                sourceSize.height: preferredImgSize
                mipmap: false
                smooth: false

                source: convId !== "" ? "image://qrImage/contact_" + convId : "image://qrImage/contact_" + idText
            }

            MaterialButton {
                id: btnClose

                Layout.columnSpan: 2
                Layout.alignment: Qt.AlignHCenter
                Layout.margins: JamiTheme.preferredMarginSize

                preferredWidth: JamiTheme.preferredFieldWidth / 2
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true

                text: JamiStrings.close

                onClicked: close()
            }
        }
    }

