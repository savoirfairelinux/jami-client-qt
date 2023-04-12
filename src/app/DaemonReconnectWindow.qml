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
import Qt5Compat.GraphicalEffects
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "commoncomponents"

ApplicationWindow {
    id: root
    property bool connectionFailed: false
    property int preferredMargin: 15

    height: 500
    minimumHeight: 500
    minimumWidth: 600
    title: "Jami"
    visible: true
    width: 600

    function getTextBoundingRect(font, text) {
        textMetrics.font = font;
        textMetrics.text = text;
        return textMetrics.boundingRect;
    }

    Component.onCompleted: {
        DBusErrorHandler.setActive(true);
        x = Screen.width / 2 - width / 2;
        y = Screen.height / 2 - height / 2;
    }

    TextMetrics {
        id: textMetrics
    }
    ResponsiveImage {
        id: jamiLogoImage
        anchors.fill: parent
        source: JamiResources.logo_jami_standard_coul_svg
    }
    Popup {
        id: popup
        closePolicy: Popup.NoAutoClose
        modal: true
        visible: false

        // center in parent
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)

        contentItem: Rectangle {
            id: contentRect
            implicitHeight: daemonReconnectPopupColumnLayout.implicitHeight + 50

            ColumnLayout {
                id: daemonReconnectPopupColumnLayout
                anchors.fill: parent
                spacing: 0

                Text {
                    id: daemonReconnectPopupTextLabel
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    Layout.topMargin: preferredMargin
                    font.pointSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    text: connectionFailed ? JamiStrings.reconnectWarn : JamiStrings.reconnectTry
                    verticalAlignment: Text.AlignVCenter

                    Component.onCompleted: {
                        contentRect.implicitWidth = getTextBoundingRect(font, text).width + 100;
                    }
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
                Button {
                    id: btnOk
                    property color hoveredColor: "#0e81c5"
                    property color normalColor: "#00aaff"
                    property color pressedColor: "#273261"

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                    Layout.bottomMargin: preferredMargin
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: 128
                    visible: connectionFailed

                    onClicked: Qt.quit()

                    background: Rectangle {
                        id: backgroundRect
                        anchors.fill: parent
                        border.color: {
                            if (btnOk.hovered)
                                return btnOk.hoveredColor;
                            if (btnOk.checked)
                                return btnOk.pressedColor;
                            return btnOk.normalColor;
                        }
                        color: "transparent"
                        radius: 4
                    }
                    contentItem: Item {
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"

                            Text {
                                id: buttonText
                                anchors.centerIn: parent
                                color: {
                                    if (btnOk.hovered)
                                        return btnOk.hoveredColor;
                                    if (btnOk.checked)
                                        return btnOk.pressedColor;
                                    return btnOk.normalColor;
                                }
                                font: root.font
                                horizontalAlignment: Text.AlignHCenter
                                text: JamiString.optionOk
                                width: {
                                    return (parent.width / 2 - 18) * 2;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Connections {
        target: DBusErrorHandler

        function onDaemonReconnectFailed() {
            root.connectionFailed = true;
        }
        function onShowDaemonReconnectPopup(visible) {
            if (visible)
                popup.open();
            else {
                popup.close();
                Qt.quit();
            }
        }
    }
}
