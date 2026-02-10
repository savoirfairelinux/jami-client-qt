/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

Item {
    id: root

    property bool uniqueActiveCall: CurrentConversation.activeCalls.length === 1
    property bool activeCalls: CurrentConversation.activeCalls.length > 1

    implicitWidth: dropDownButton.visible ? joinCallButton.implicitWidth + dropDownButton.implicitWidth : joinCallButton.implicitWidth
    implicitHeight: joinCallButton.implicitHeight

    Button {
        id: joinCallButton

        implicitWidth: background.width
        implicitHeight: background.height

        icon.width: JamiTheme.iconButtonMedium
        icon.height: JamiTheme.iconButtonMedium
        icon.source: JamiResources.start_audiocall_24dp_svg
        icon.color: hovered ? JamiTheme.buttonCallLightGreen : JamiTheme.blackColor

        visible: uniqueActiveCall || activeCalls

        Behavior on icon.color {
            ColorAnimation {
                duration: 200
            }
        }

        background: Rectangle {
            id: callButtonBackground

            width: joinCallButton.icon.width + (joinCallButton.icon.width/ 2)
            height: joinCallButton.icon.height + (joinCallButton.icon.height / 2)

            radius: height / 2
            color: parent.hovered ? JamiTheme.buttonCallDarkGreen : JamiTheme.buttonCallLightGreen

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }

            SpinningAnimation {
                id: animation
                anchors.fill: parent
                mode: SpinningAnimation.Mode.Radial
                color: parent.hovered ? JamiTheme.buttonCallLightGreen : JamiTheme.buttonCallDarkGreen
                spinningAnimationWidth: 2
            }
        }

        onClicked: {
            if (root.uniqueActiveCall && CurrentConversation.activeCalls.length > 0) {
                var call = CurrentConversation.activeCalls[0];
                MessagesAdapter.joinCall(call.uri, call.device, call.id, true);
            } else {
                CallAdapter.startAudioOnlyCall();
            }
        }
    }

    ComboBox {
        id: dropDownButton

        implicitWidth: background.width - background.radius
        implicitHeight: JamiTheme.iconButtonSmall
        z: joinCallButton.z - 1

        anchors.verticalCenter: root.verticalCenter
        anchors.left: joinCallButton.right
        anchors.leftMargin: -background.radius

        model: CurrentConversation.activeCalls

        visible: activeCalls

        delegate: ItemDelegate {
            width: ListView.view.width
            height: 50

            topInset: 4
            leftInset: 4
            rightInset: 4
            bottomInset: 4

            topPadding: topInset * 2
            leftPadding: topInset * 2
            rightPadding: rightInset * 2
            bottomPadding: bottomInset * 2

            contentItem: RowLayout {
                spacing: 10

                Button {
                    Layout.preferredWidth: background.width
                    Layout.preferredHeight: background.height
                    Layout.leftMargin: 2
                    Layout.alignment: Qt.AlignVCenter

                    icon.width: JamiTheme.iconButtonMedium
                    icon.height: JamiTheme.iconButtonMedium
                    icon.color: JamiTheme.textColor
                    icon.source: JamiResources.start_audiocall_24dp_svg

                    background: Rectangle {
                        width: icon.width + (icon.width / 2)
                        height: icon.height + (icon.height / 2)
                        radius: height / 2
                        color: dropDownButton.delegate.hovered ? JamiTheme.buttonCallDarkGreen : JamiTheme.buttonCallLightGreen

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: UtilsAdapter.getBestNameForUri(CurrentAccount.id, modelData.uri) + "'s call"
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.headerFontSize
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.uri
                        color: JamiTheme.textColor
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }

            background: Rectangle {
                radius: height / 2
                color:  parent.hovered ? JamiTheme.smartListHoveredColor : JamiTheme.globalIslandColor

                Behavior on color {
                    ColorAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }
            }

            highlighted: dropDownButton.highlightedIndex === index

            onClicked: {
                MessagesAdapter.joinCall(modelData.uri, modelData.device, modelData.id, true); //CurrentCall.isAudioOnly
                dropdownPopup.close();
            }
        }

        indicator: Button {
            anchors.verticalCenter: parent.verticalCenter

            icon.width: JamiTheme.iconButtonSmall
            icon.height: JamiTheme.iconButtonSmall
            icon.color: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
            icon.source: dropdownPopup.opened ? JamiResources.arrow_drop_up_24dp_svg : JamiResources.arrow_drop_down_24dp_svg

            Behavior on icon.color {
                ColorAnimation {
                    duration: 200
                }
            }

            background: null

            onClicked: if (dropdownPopup.opened) dropdownPopup.close(); else dropdownPopup.open();
        }

        contentItem: null

        background: Rectangle {
            width: JamiTheme.iconButtonSmall + radius
            height: JamiTheme.iconButtonSmall
            radius: height / 2

            color: JamiTheme.globalBackgroundColor
        }

        popup: Popup {
            id: dropdownPopup

            x: parent.width - width / 2
            y: parent.height + JamiTheme.qwkTitleBarHeight / 2
            width: 250
            padding: 1

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: dropDownButton.visible ? dropDownButton.delegateModel : null
                currentIndex: dropDownButton.highlightedIndex
            }

            background: Rectangle {
                radius: 25
                color: JamiTheme.globalIslandColor
            }
        }
    }
}
