/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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
import QtQuick.Controls 2.14
import net.jami.Models 1.0

//
// A dialog that presents a QR code corresponding to the current account's
// info hash.
//
Dialog {
    id: root

    // TODO(atraczyk): this should be based on a Q_PROPERTY and notified when
    // the current account changes.
    property string accountInfoHash: ClientWrapper.utilsAdaptor.getCurrentAccountInfoHash()

    function updateQrDialog() {
        accountInfoHash = ClientWrapper.utilsAdaptor.getCurrentAccountInfoHash()
    }

    // When dialog the is opened, trigger mainViewWindow overlay which is defined
    // in overlay.model. (model : true is necessary)
    modal: true

    // TODO(atraczyk): this margin and the dimensions of 'image' are good examples
    // of values that should respond to screen scaling updates.
    contentHeight: image.height + 30

    Image {
        id: image

        anchors.centerIn: parent

        width: 256
        height: 256
        smooth: false
        fillMode: Image.PreserveAspectFit
        source: "data:image/png;base64," +
                ClientWrapper.utilsAdaptor.getBase64QRCodeImage(accountInfoHash)
    }

    background: Rectangle {
        radius: 10
    }
}
