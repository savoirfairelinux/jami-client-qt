
/*
 * Copyright (C) 2020 by Savoir-faire Linux
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
import QtQuick 2.14
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.14
import QtQuick.Dialogs 1.2
import net.jami.Models 1.0
import net.jami.Adapters 1.0

import "../../constant"
import "../../commoncomponents"

Dialog {
    id: userQrImageDialog

    visible: false
    title: qsTr("Account Qr")

    width: content.width
    height: content.height

    contentItem: Rectangle {
        id: content

        implicitWidth: userQrImage.width + JamiTheme.preferredMarginSize * 2
        implicitHeight: userQrImage.height + btnClose.height +
                        JamiTheme.preferredMarginSize * 4

        ColumnLayout {

            anchors.centerIn: parent
            anchors.fill: parent

            Image {
                id: userQrImage

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 256
                Layout.preferredHeight: 256

                smooth: false

                fillMode: Image.PreserveAspectFit
                source: "image://qrImage/account_" + AccountAdapter.currentAccountId
            }

            MaterialButton {
                id: btnClose

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth / 2 - 8
                Layout.preferredHeight: JamiTheme.preferredFieldHeight
                Layout.bottomMargin: JamiTheme.preferredMarginSize

                text: qsTr("Close")
                color: enabled? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                hoveredColor: JamiTheme.buttonTintedBlackHovered
                pressedColor: JamiTheme.buttonTintedBlackPressed
                outlined: true

                onClicked: {
                    close()
                }
            }
        }
    }
}
