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
    ////Scaffold{}
    id: root

    Layout.fillWidth: true

    property int type: ContactList.YOUR_NEW_TYPE

    readonly property string baseProviderPrefix: 'image://avatarImage'

    property string typePrefix: 'contact'
    property string divider: '_'

    property int itemWidth

    title: JamiStrings.troubleshootTitle

    flickableContent: ColumnLayout {
        id: troubleshootSettingsColumnLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        RowLayout {
            id: rawLayout
            Layout.alignment: Qt.AlignTop
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
            //color: "lightblue"
            height: listview.childrenRect.height
            Layout.fillWidth: true

            ListView {
                id: listview
                height: contentItem.childrenRect.height

                spacing: 5

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
                                width: 80
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
                                width: 120
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

                //model: ConversationListModel
                model: ContactAdapter.getContactSelectableModel(type)

                delegate: Rectangle {
                    width: contentFlickableWidth
                    height: 50
                    color: index % 2 === 0 ? "#f0efef" : "#f6f5f5"

                    RowLayout {
                        anchors.fill: parent
                        Rectangle {
                            //Scaffold{}
                            id: profile
                            height: 50
                            Layout.leftMargin: 5
                            Layout.fillWidth: true
                            color: JamiTheme.transparentColor
                            Avatar {
                                id: avatar
                                anchors.left: parent.left
                                height: 40
                                width: 40
                                anchors.verticalCenter: parent.verticalCenter
                                imageId: UID
                                mode: Avatar.Mode.Conversation
                            }
                            Text {
                                id: textImage
                                width: profile.width - 50
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: avatar.right
                                text: Title === undefined ? "" : Title
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            //Scaffold{}
                            id: device
                            width: 80
                            height: 50
                            color: JamiTheme.transparentColor
                            Text {
                                id: deviceText
                                width: 80
                                elide: Text.ElideMiddle
                                anchors.verticalCenter: parent.verticalCenter
                                text: URI
                            }
                        }

                        Rectangle {
                            ////Scaffold{}
                            id: connection
                            width: 120
                            height: 50
                            radius: 5
                            color: JamiTheme.transparentColor
                            ResponsiveImage {
                                id: connectionImage
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                source: connected ? JamiResources.connected_black_24dp_svg : JamiResources.connecting_black_24dp_svg
                                color: elementColor
                            }
                            Text {
                                id: connectionText
                                width: parent.width - 30
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: connectionImage.right
                                anchors.leftMargin: 5
                                text: status
                                elide: Text.ElideRight
                                color: elementColor
                            }
                        }

                        Rectangle {
                            ////Scaffold{}
                            id: channel
                            height: 50
                            color: JamiTheme.transparentColor
                            width: 70
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "4" + deviceID
                            }
                        }
                    }
                }
            }
        }
    }
}
