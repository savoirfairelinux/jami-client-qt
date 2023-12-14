/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

Label {
    id: root

    property alias popup: comboBoxPopup

    width: parent ? parent.width : o
    height: JamiTheme.accountListItemHeight

    property bool inSettings: viewCoordinator.currentViewName === "SettingsView"

    // TODO: remove these refresh hacks use QAbstractItemModels correctly
    Connections {
        target: AccountAdapter

        function onAccountStatusChanged(accountId) {
            AccountListModel.reset();
        }
    }

    Connections {
        target: LRCInstance

        function onAccountListChanged() {
            root.update();
            AccountListModel.reset();
        }
    }

    function togglePopup() {
        if (root.popup.opened) {
            root.popup.close();
        } else {
            root.popup.open();
        }
    }

    background: Rectangle {
        id: background
        anchors.fill: parent

        color: JamiTheme.backgroundColor
        Behavior on color  {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }

    AccountComboBoxPopup {
        id: comboBoxPopup
    }

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 15
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.popup.opened ? Qt.lighter(JamiTheme.hoverColor, 1.0) : mouseArea.containsMouse ? Qt.lighter(JamiTheme.hoverColor, 1.0) : JamiTheme.backgroundColor
            radius: 5
            Layout.topMargin: 5

            MouseArea {
                id: mouseArea
                enabled: visible
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.forceActiveFocus();
                    togglePopup();
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 15

                spacing: 10


                Avatar {
                    id: avatar

                    Layout.preferredWidth: JamiTheme.accountListAvatarSize
                    Layout.preferredHeight: JamiTheme.accountListAvatarSize
                    Layout.alignment: Qt.AlignVCenter

                    mode: Avatar.Mode.Account
                    imageId: CurrentAccount.id
                    presenceStatus: CurrentAccount.status
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    Text {
                        id: bestNameText

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                        text: CurrentAccount.bestName
                        textFormat: TextEdit.PlainText

                        font.pointSize: JamiTheme.textFontSize
                        color: JamiTheme.textColor
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                    }

                    Text {
                        id: bestIdText

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                        visible: text.length && text !== bestNameText.text

                        text: CurrentAccount.bestId
                        textFormat: TextEdit.PlainText

                        font.pointSize: JamiTheme.tinyFontSize
                        color: JamiTheme.faddedLastInteractionFontColor
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }
        }

        Row {
            id: controlRow

            spacing: 10

            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: parent.height

            JamiPushButton {
                id: shareButton

                width: visible ? preferredSize : 0
                height: visible ? preferredSize : 0
                anchors.verticalCenter: parent.verticalCenter

                visible: LRCInstance.currentAccountType === Profile.Type.JAMI
                toolTipText: JamiStrings.displayQRCode

                source: JamiResources.share_24dp_svg

                normalColor: JamiTheme.backgroundColor
                imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered

                onClicked: viewCoordinator.presentDialog(appWindow, "mainview/components/WelcomePageQrDialog.qml")
            }

            JamiPushButton {
                id: settingsButton

                anchors.verticalCenter: parent.verticalCenter
                source: !inSettings ? JamiResources.settings_24dp_svg : JamiResources.round_close_24dp_svg

                imageContainerWidth: inSettings ? 30 : 24

                normalColor: JamiTheme.backgroundColor
                imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
                toolTipText: !inSettings ? JamiStrings.openSettings : JamiStrings.closeSettings

                onClicked: {
                    !inSettings ? viewCoordinator.present("SettingsView") : viewCoordinator.dismiss("SettingsView");
                    background.state = "normal";
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+,"
        context: Qt.ApplicationShortcut
        onActivated: settingBtnClicked()
    }
}
