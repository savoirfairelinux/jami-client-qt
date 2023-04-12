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
    property string aliasText
    property string convId
    property string idText
    property int preferredImgSize: 80
    property string registeredNameText

    height: Math.min(appWindow.height - 2 * JamiTheme.preferredMarginSize, JamiTheme.secondaryDialogDimension)
    width: Math.min(appWindow.width - 2 * JamiTheme.preferredMarginSize, JamiTheme.secondaryDialogDimension)

    popupContent: Rectangle {
        id: userProfileContentRect
        anchors.fill: parent
        color: JamiTheme.backgroundColor
        radius: JamiTheme.modalPopupRadius

        GridLayout {
            id: userProfileDialogLayout
            anchors.centerIn: parent
            anchors.fill: parent
            anchors.margins: JamiTheme.preferredMarginSize
            columnSpacing: 24
            columns: 2
            rowSpacing: 16
            rows: 6

            ConversationAvatar {
                id: contactImage
                Layout.alignment: Qt.AlignRight
                Layout.preferredHeight: preferredImgSize
                Layout.preferredWidth: preferredImgSize
                imageId: convId
                showPresenceIndicator: false
            }

            // Visible when user alias is not empty and not equal to id.
            TextEdit {
                id: contactAlias
                Layout.alignment: Qt.AlignLeft
                color: JamiTheme.textColor
                font.kerning: true
                font.pointSize: JamiTheme.titleFontSize
                horizontalAlignment: Text.AlignLeft
                selectByMouse: true
                text: textMetricsContactAliasText.elidedText
                verticalAlignment: Text.AlignVCenter
                visible: aliasText ? (aliasText === idText ? false : true) : false
                wrapMode: Text.NoWrap

                TextMetrics {
                    id: textMetricsContactAliasText
                    elide: Qt.ElideMiddle
                    elideWidth: userProfileContentRect.width - 200
                    font: contactAlias.font
                    text: aliasText
                }
            }
            Item {
                Layout.columnSpan: 2
                height: 8
            }
            Text {
                Layout.alignment: Qt.AlignRight
                color: JamiTheme.textColor
                font.pointSize: JamiTheme.menuFontSize
                text: JamiStrings.information
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                Layout.alignment: Qt.AlignRight
                color: JamiTheme.faddedFontColor
                font.pointSize: JamiTheme.textFontSize
                text: JamiStrings.username
                visible: contactDisplayName.visible
            }

            // Visible when user name is not empty or equals to id.
            TextEdit {
                id: contactDisplayName
                Layout.alignment: Qt.AlignLeft
                color: JamiTheme.textColor
                font.kerning: true
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignLeft
                readOnly: true
                selectByMouse: true
                text: textMetricsContactDisplayNameText.elidedText
                verticalAlignment: Text.AlignVCenter
                visible: registeredNameText ? (registeredNameText === idText ? false : true) : false
                wrapMode: Text.NoWrap

                TextMetrics {
                    id: textMetricsContactDisplayNameText
                    elide: Qt.ElideMiddle
                    elideWidth: userProfileContentRect.width - 200
                    font: contactDisplayName.font
                    text: registeredNameText
                }
            }
            Text {
                Layout.alignment: Qt.AlignRight
                color: JamiTheme.faddedFontColor
                font.pointSize: JamiTheme.textFontSize
                text: JamiStrings.identifier
            }
            TextEdit {
                id: contactId
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: userProfileContentRect.width - 200
                color: JamiTheme.textColor
                font.kerning: true
                font.pointSize: JamiTheme.textFontSize
                horizontalAlignment: Text.AlignLeft
                readOnly: true
                selectByMouse: true
                text: idText
                verticalAlignment: Text.AlignVCenter
                wrapMode: TextEdit.WrapAnywhere
            }
            Text {
                Layout.alignment: Qt.AlignRight
                color: JamiTheme.faddedFontColor
                font.pointSize: JamiTheme.textFontSize
                text: JamiStrings.qrCode
            }
            Image {
                id: contactQrImage
                Layout.alignment: Qt.AlignLeft
                fillMode: Image.PreserveAspectFit
                mipmap: false
                smooth: false
                source: convId !== "" ? "image://qrImage/contact_" + convId : ""
                sourceSize.height: preferredImgSize
                sourceSize.width: preferredImgSize
            }
            MaterialButton {
                id: btnClose
                Layout.alignment: Qt.AlignHCenter
                Layout.columnSpan: 2
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin
                color: JamiTheme.buttonTintedBlack
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                preferredWidth: JamiTheme.preferredFieldWidth / 2
                pressedColor: JamiTheme.buttonTintedBlackPressed
                secondary: true
                text: JamiStrings.close

                onClicked: close()
            }
        }
    }
}
