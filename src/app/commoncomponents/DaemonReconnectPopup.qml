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
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Constants 1.1
import net.jami.Models 1.1

BaseModalDialog {
    id: root
    property bool connectionFailed: false
    property int preferredMargin: 15

    autoClose: false

    onPopupContentLoadStatusChanged: {
        if (popupContentLoadStatus === Loader.Ready) {
            root.height = Qt.binding(function () {
                    return popupContentLoader.item.implicitHeight + 50;
                });
            root.width = Qt.binding(function () {
                    return popupContentLoader.item.implicitWidth + 50;
                });
        }
    }

    Connections {
        ignoreUnknownSignals: true
        target: {
            if (Qt.platform.os.toString() !== "windows" && Qt.platform.os.toString() !== "osx")
                return DBusErrorHandler;
            return null;
        }

        function onDaemonReconnectFailed() {
            connectionFailed = true;
        }
        function onShowDaemonReconnectPopup(visible) {
            if (!visible) {
                viewCoordinator.dismiss(this);
            }
        }
    }

    popupContent: ColumnLayout {
        id: daemonReconnectPopupColumnLayout
        spacing: 0

        Text {
            id: daemonReconnectPopupTextLabel
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: preferredMargin
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.textFontSize + 2
            horizontalAlignment: Text.AlignHCenter
            text: connectionFailed ? JamiStrings.reconnectionFailed : JamiStrings.reconnectDaemon
            verticalAlignment: Text.AlignVCenter
        }
        AnimatedImage {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.bottomMargin: preferredMargin
            Layout.preferredHeight: 30
            Layout.preferredWidth: 30
            fillMode: Image.PreserveAspectFit
            mipmap: true
            paused: false
            playing: true
            smooth: true
            source: JamiResources.jami_rolling_spinner_gif
            visible: !connectionFailed
        }
        MaterialButton {
            id: btnOk
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            autoAccelerator: true
            color: JamiTheme.buttonTintedBlue
            hoveredColor: JamiTheme.buttonTintedBlueHovered
            preferredWidth: JamiTheme.preferredFieldWidth / 2
            pressedColor: JamiTheme.buttonTintedBluePressed
            secondary: true
            text: JamiStrings.optionOk
            visible: connectionFailed

            onClicked: Qt.quit()
        }
    }
}
