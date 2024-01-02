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
import Qt5Compat.GraphicalEffects
import SortFilterProxyModel 0.2
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"

Popup {
    id: root

    implicitWidth: parent.width - 10
    leftMargin: 5
    topMargin: 5

    // limit the number of accounts shown at once
    implicitHeight: {
        return visible ? Math.min(JamiTheme.accountListItemHeight * Math.min(6, listView.model.count + 1) + 96, appWindow.height - parent.height) : 0;
    }
    padding: 0
    modal: true
    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
    }

    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    contentItem: ColumnLayout {
        spacing: 0
        anchors.leftMargin: 20

        Rectangle {
            id: comboBox

            height: JamiTheme.accountListItemHeight - 5
            Layout.fillWidth: true
            radius: 5
            color: JamiTheme.accountComboBoxBackgroundColor

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
                    AccountListModel.reset();
                }
            }

            RowLayout {
                id: mainLayout
                anchors.fill: parent
                spacing: 10

                Rectangle {
                    id: accountInfoRect
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: mouseArea.containsMouse ? JamiTheme.hoverColor : JamiTheme.accountComboBoxBackgroundColor
                    radius: 5

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.close()
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
                    Layout.rightMargin: 10
                    Layout.topMargin: -7

                    JamiPushButton {
                        id: shareButton

                        width: visible ? preferredSize : 0
                        height: visible ? preferredSize : 0
                        anchors.verticalCenter: parent.verticalCenter

                        visible: LRCInstance.currentAccountType === Profile.Type.JAMI
                        toolTipText: JamiStrings.displayQRCode

                        source: JamiResources.share_24dp_svg

                        normalColor: JamiTheme.accountComboBoxBackgroundColor
                        imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
                        hoveredColor: JamiTheme.hoverColor

                        onClicked: {
                            viewCoordinator.presentDialog(appWindow, "mainview/components/WelcomePageQrDialog.qml");
                            root.close();
                        }
                    }

                    JamiPushButton {
                        id: settingsButton

                        anchors.verticalCenter: parent.verticalCenter
                        source: !inSettings ? JamiResources.settings_24dp_svg : JamiResources.round_close_24dp_svg

                        imageContainerWidth: inSettings ? 30 : 24

                        normalColor: JamiTheme.accountComboBoxBackgroundColor
                        imageColor: hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
                        hoveredColor: JamiTheme.hoverColor

                        toolTipText: !inSettings ? JamiStrings.openSettings : JamiStrings.closeSettings

                        onClicked: {
                            !inSettings ? viewCoordinator.present("SettingsView") : viewCoordinator.dismiss("SettingsView");
                            root.close();
                        }

                        KeyNavigation.tab: addAccountItem
                    }
                }
            }
        }

        Rectangle{
            Layout.alignment: Qt.AlignHCenter
            height: 1
            Layout.fillWidth: true
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            color: JamiTheme.smartListHoveredColor
        }


        JamiListView {
            id: listView

            Layout.fillHeight: true
            Layout.preferredWidth: parent.width

            model: SortFilterProxyModel {
                sourceModel: AccountListModel
                filters: ValueFilter {
                    roleName: "ID"
                    value: LRCInstance.currentAccountId
                    inverted: true
                }
            }

            delegate: AccountItemDelegate {
                height: JamiTheme.accountListItemHeight
                width: root.width
                onClicked: {
                    root.close();
                    LRCInstance.currentAccountId = ID;
                }
            }
        }

        Rectangle{
            Layout.alignment: Qt.AlignHCenter
            height: 1
            Layout.fillWidth: true
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            color: JamiTheme.smartListHoveredColor
        }

        // fake footer item as workaround for Qt 5.15 bug
        // https://bugreports.qt.io/browse/QTBUG-85302
        // don't use the clip trick and footer item overlay
        // explained here https://stackoverflow.com/a/64625149
        // as it causes other complexities in handling the drop shadow
        ItemDelegate {
            id: addAccountItem

            Layout.preferredHeight: 45
            Layout.preferredWidth: parent.width -10
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 5

            Accessible.name: JamiStrings.addAccount
            Accessible.role: Accessible.Button

            background: Rectangle {
                color: addAccountItem.hovered ? JamiTheme.hoverColor : JamiTheme.accountComboBoxBackgroundColor
                radius: 5
            }

            RowLayout{
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18

                ResponsiveImage {
                    id: addImage
                    Layout.alignment: Qt.AlignHCenter
                    source: JamiResources.person_add_24dp_svg
                    color: addAccountItem.hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
                }

                Text {
                    Layout.alignment: Qt.AlignLeft
                    text: JamiStrings.addAccount
                    textFormat: TextEdit.PlainText
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                }
            }
            onClicked: {
                root.close();
                viewCoordinator.present("WizardView");
            }

            KeyNavigation.tab: manageAccountItem
        }

        ItemDelegate {
            id: manageAccountItem

            Accessible.role: Accessible.Button
            Accessible.name: JamiStrings.manageAccount

            Layout.preferredHeight: 45
            Layout.preferredWidth: parent.width-10
            Layout.leftMargin: 5
            Layout.bottomMargin: 5

            background: Rectangle {
                color: manageAccountItem.hovered ? JamiTheme.hoverColor : JamiTheme.accountComboBoxBackgroundColor
                radius: 5
            }

            RowLayout{
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18

                ResponsiveImage {
                    id: manageImage

                    Layout.alignment: Qt.AlignHCenter
                    source: JamiResources.manage_accounts_24dp_svg
                    color: manageAccountItem.hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
                }
                Text {
                    text: JamiStrings.manageAccount

                    textFormat: TextEdit.PlainText
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                }
            }
            onClicked: {
                root.close();
                viewCoordinator.present("SettingsView")
            }
        }
    }

    background: Rectangle {
        id: bgRect
        color: JamiTheme.accountComboBoxBackgroundColor
        radius: 5

        layer {
            enabled: true
            effect: DropShadow {
                horizontalOffset: 3.0
                verticalOffset: 3.0
                radius: bgRect.radius * 4
                color: JamiTheme.shadowColor
                source: bgRect
                transparentBorder: true
                samples: radius + 1
            }
        }

        layer {
            enabled: true
            effect: DropShadow {
                horizontalOffset: 3.0
                verticalOffset: 3.0
                radius: 6
                color: JamiTheme.shadowColor
                transparentBorder: true
                samples: radius + 1
            }
        }
    }
}
