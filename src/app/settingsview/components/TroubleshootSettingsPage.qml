/*
 * Copyright (C) 2021-2023 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh   <fadi.shehadeh@savoirfairelinux.com>
 * Author: Trevor Tabah <trevor.tabah@savoirfairelinux.com>
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/logviewwindowcreation.js" as LogViewWindowCreation

SettingsPageBase {
    id: root

    Layout.fillWidth: true

    property int type: ContactList.YOUR_NEW_TYPE

    readonly property string baseProviderPrefix: 'image://avatarImage'

    property string typePrefix: 'contact'
    property string divider: '_'

    property int itemWidth

    title: JamiStrings.troubleshootTitle

    flickableContent: Column {
        id: troubleshootSettingsColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        RowLayout {
            id: rawLayout
            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Layout.rightMargin: JamiTheme.preferredMarginSize

                text: JamiStrings.troubleshootText
                font.pointSize: JamiTheme.settingsFontSize
                font.kerning: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                color: JamiTheme.textColor
            }

            MaterialButton {
                id: enableTroubleshootingButton

                TextMetrics {
                    id: enableTroubleshootingButtonTextSize
                    font.weight: Font.Bold
                    font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                    font.capitalization: Font.AllUppercase
                    text: enableTroubleshootingButton.text
                }

                Layout.alignment: Qt.AlignRight

                preferredWidth: enableTroubleshootingButtonTextSize.width + 2 * JamiTheme.buttontextWizzardPadding
                buttontextHeightMargin: JamiTheme.buttontextHeightMargin

                primary: true

                text: JamiStrings.troubleshootButton
                toolTipText: JamiStrings.troubleshootButton

                onClicked: {
                    LogViewWindowCreation.createlogViewWindowObject();
                    LogViewWindowCreation.showLogViewWindow();
                }
            }
        }

        Rectangle {
            height: listview.childrenRect.height + 60
            width: contentFlickableWidth

            ListView {
                id: listview
                height: contentItem.childrenRect.height
                anchors.top: parent.top
                anchors.topMargin: 10

                spacing: 5
                cacheBuffer: 10

                property int rota: 0

                header: Rectangle {
                    height: 55
                    width: contentFlickableWidth
                    Rectangle {
                        color: "#d1d1d1"
                        anchors.top: parent.top
                        height: 50
                        width: contentFlickableWidth

                        RowLayout {
                            anchors.fill: parent
                            Rectangle {
                                //Scaffold{}
                                id: profile
                                height: 50
                                Layout.leftMargin: 5
                                Layout.fillWidth: true
                                color: JamiTheme.transparentColor
                                Text {
                                    id: textImage
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Account"
                                }
                            }

                            Rectangle {
                                //Scaffold{}
                                id: device
                                width: 90
                                height: 50
                                color: JamiTheme.transparentColor
                                Text {
                                    id: deviceText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Device"
                                }
                            }

                            Rectangle {
                                ////Scaffold{}
                                id: connection
                                width: 130
                                height: 50
                                radius: 5
                                color: JamiTheme.transparentColor
                                Text {
                                    id: connectionText
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 10
                                    text: "Connection"
                                }
                            }

                            Rectangle {
                                ////Scaffold{}
                                id: channel
                                height: 50
                                width: 70
                                color: JamiTheme.transparentColor
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Channels"
                                }
                            }
                        }
                    }
                }

                model: ConnectionInfoListModel
                Timer {
                    interval: 100 // L'intervalle est en millisecondes (1000 ms = 1 seconde)
                    running: root.visible // Démarrer le timer dès le chargement de la vue
                    repeat: true // Répéter le timer indéfiniment
                    onTriggered: {
                        ContactAdapter.updateConnectionInfo();
                        listview.rota = listview.rota + 5;
                    }
                }

                delegate: Rectangle {
                    id: delegate
                    height: 55 * Count
                    width: contentFlickableWidth
                    color: index % 2 === 0 ? "#f0efef" : "#f6f5f5"

                    ListView {
                        id: listView2
                        height: 55 * Count

                        anchors.top: delegate.top

                        spacing: 5

                        model: Count

                        delegate: RowLayout {
                            id: rowLayoutDelegate
                            height: 50
                            width: contentFlickableWidth

                            Rectangle {
                                //Scaffold{}
                                id: profile
                                height: 50
                                Layout.leftMargin: 5
                                Layout.fillWidth: true
                                color: delegate.color
                                Avatar {
                                    id: avatar
                                    visible: index == 0
                                    anchors.left: parent.left
                                    height: 40
                                    width: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                    imageId: PeerId
                                    mode: Avatar.Mode.Contact
                                }
                                Text {
                                    id: textImage
                                    visible: index == 0
                                    width: profile.width - 50
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: avatar.right
                                    text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, PeerId)
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                height: parent.height
                                Layout.preferredWidth: 90
                                color: delegate.color
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    text: DeviceId[index]
                                    elide: Text.ElideMiddle
                                    width: parent.width - 10
                                }
                            }
                            Rectangle {
                                id: connectionRectangle
                                color: delegate.color
                                height: parent.height
                                Layout.preferredWidth: 130
                                property var status: Status[index]
                                ResponsiveImage {
                                    id: connectionImage
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    rotation: connectionRectangle.status == 0 ? 0 : listview.rota
                                    source: {
                                        if (connectionRectangle.status == 0) {
                                            return JamiResources.connected_black_24dp_svg;
                                        } else {
                                            return JamiResources.connecting_black_24dp_svg;
                                        }
                                    }
                                    color: {
                                        if (connectionRectangle.status == 0) {
                                            return "green";
                                        } else {
                                            if (connectionRectangle.status == 4) {
                                                return "red";
                                            } else {
                                                return "orange";
                                            }
                                        }
                                    }
                                }
                                Text {
                                    anchors.left: connectionImage.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 5
                                    text: if (connectionRectangle.status == 0) {
                                        return "Connected";
                                    } else {
                                        if (connectionRectangle.status == 1) {
                                            return "Connecting TLS";
                                        } else {
                                            if (connectionRectangle.status == 2) {
                                                return "Connecting ICE";
                                            } else {
                                                if (connectionRectangle.status == 3) {
                                                    return "Connecting";
                                                } else {
                                                    return "Waiting";
                                                }
                                            }
                                        }
                                    }
                                    color: connectionImage.color
                                }
                            }
                            Rectangle {
                                height: parent.height
                                Layout.preferredWidth: 70
                                color: delegate.color
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 10
                                    anchors.left: parent.left
                                    text: Channels[index]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
