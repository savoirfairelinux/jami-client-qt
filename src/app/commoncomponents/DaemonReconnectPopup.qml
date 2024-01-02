/*
 * Copyright (C) 2020-2024 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1
import net.jami.Models 1.1

BaseModalDialog {
    id: root

    property bool connectionFailed: false
    property int preferredMargin: 15

    autoClose: false

    button1.text: JamiStrings.optionOk
    button1Role: DialogButtonBox.AcceptRole
    button1.visible: connectionFailed
    button1.onClicked: Qt.quit()

    Connections {
        target: {
            if (Qt.platform.os.toString() !== "windows" && Qt.platform.os.toString() !== "osx")
                return DBusErrorHandler;
            return null;
        }
        ignoreUnknownSignals: true

        function onShowDaemonReconnectPopup(visible) {
            if (!visible) {
                viewCoordinator.dismiss(this);
            }
        }

        function onDaemonReconnectFailed() {
            connectionFailed = true;
        }
    }

    onPopupContentLoadStatusChanged: {
        if (popupContentLoadStatus === Loader.Ready) {
            root.height = Qt.binding(function () {
                    return popupContent.implicitHeight + 50;
                });
            root.width = Qt.binding(function () {
                    return popupContent.implicitWidth + 50;
                });
        }
    }

    popupContent: ColumnLayout {
        id: daemonReconnectPopupColumnLayout

        spacing: 0

        Text {
            id: daemonReconnectPopupTextLabel

            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.maximumWidth: root.parent.width - 4 * JamiTheme.preferredMarginSize
            wrapMode: Text.Wrap

            text: connectionFailed ? JamiStrings.reconnectionFailed : JamiStrings.reconnectDaemon
            font.pointSize: JamiTheme.textFontSize + 2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor
        }

        AnimatedImage {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.preferredHeight: 30
            Layout.preferredWidth: 30
            Layout.bottomMargin: preferredMargin

            visible: !connectionFailed

            source: JamiResources.jami_rolling_spinner_gif

            playing: true
            paused: false
            mipmap: true
            smooth: true
            fillMode: Image.PreserveAspectFit
        }
    }
}
