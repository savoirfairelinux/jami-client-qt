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
    property bool inSettings: viewCoordinator.currentViewName === "SettingsView"
    property alias popup: comboBoxPopup

    height: JamiTheme.accountListItemHeight
    width: parent ? parent.width : o

    function togglePopup() {
        if (root.popup.opened) {
            root.popup.close();
        } else {
            root.popup.open();
        }
    }

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
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: visible
        hoverEnabled: true

        onClicked: {
            root.forceActiveFocus();
            togglePopup();
        }
    }
    AccountComboBoxPopup {
        id: comboBoxPopup
        Shortcut {
            context: Qt.ApplicationShortcut
            sequence: "Ctrl+J"

            onActivated: togglePopup()
        }
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 10

        Avatar {
            id: avatar
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: JamiTheme.accountListAvatarSize
            Layout.preferredWidth: JamiTheme.accountListAvatarSize
            imageId: CurrentAccount.id
            mode: Avatar.Mode.Account
            presenceStatus: CurrentAccount.status
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 2

            Text {
                id: bestNameText
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.fillWidth: true
                color: JamiTheme.textColor
                elide: Text.ElideRight
                font.pointSize: JamiTheme.textFontSize
                text: CurrentAccount.bestName
                textFormat: TextEdit.PlainText
            }
            Text {
                id: bestIdText
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.fillWidth: true
                color: JamiTheme.faddedLastInteractionFontColor
                elide: Text.ElideRight
                font.pointSize: JamiTheme.textFontSize
                text: CurrentAccount.bestId
                textFormat: TextEdit.PlainText
                visible: text.length && text !== bestNameText.text
            }
        }
        Row {
            id: controlRow
            Layout.preferredHeight: parent.height
            Layout.preferredWidth: childrenRect.width
            spacing: 10

            ResponsiveImage {
                id: arrowDropDown
                anchors.verticalCenter: parent.verticalCenter
                color: JamiTheme.textColor
                height: 24
                source: !root.popup.opened ? JamiResources.expand_more_24dp_svg : JamiResources.expand_less_24dp_svg
                width: 24
            }
            PushButton {
                id: shareButton
                anchors.verticalCenter: parent.verticalCenter
                height: visible ? preferredSize : 0
                imageColor: JamiTheme.textColor
                normalColor: JamiTheme.backgroundColor
                source: JamiResources.share_24dp_svg
                toolTipText: JamiStrings.displayQRCode
                visible: LRCInstance.currentAccountType === Profile.Type.JAMI
                width: visible ? preferredSize : 0

                onClicked: viewCoordinator.presentDialog(appWindow, "mainview/components/WelcomePageQrDialog.qml")
            }
            PushButton {
                id: settingsButton
                anchors.verticalCenter: parent.verticalCenter
                imageColor: JamiTheme.textColor
                normalColor: JamiTheme.backgroundColor
                source: !inSettings ? JamiResources.settings_24dp_svg : JamiResources.round_close_24dp_svg
                toolTipText: !inSettings ? JamiStrings.openSettings : JamiStrings.closeSettings

                onClicked: {
                    !inSettings ? viewCoordinator.present("SettingsView") : viewCoordinator.dismiss("SettingsView");
                    background.state = "normal";
                }
            }
        }
    }
    Shortcut {
        context: Qt.ApplicationShortcut
        sequence: "Ctrl+,"

        onActivated: settingBtnClicked()
    }

    background: Rectangle {
        id: background
        anchors.fill: parent
        color: root.popup.opened ? Qt.lighter(JamiTheme.hoverColor, 1.0) : mouseArea.containsMouse ? Qt.lighter(JamiTheme.hoverColor, 1.05) : JamiTheme.backgroundColor

        // TODO: this can be removed when frameless window is implemented
        Rectangle {
            color: JamiTheme.tabbarBorderColor
            height: 1

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
        }

        Behavior on color  {
            ColorAnimation {
                duration: JamiTheme.shortFadeDuration
            }
        }
    }
}
