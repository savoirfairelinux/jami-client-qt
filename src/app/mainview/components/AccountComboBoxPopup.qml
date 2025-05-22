/*
 * Copyright (C) 2020-2025 Savoir-faire Linux Inc.
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
import net.jami.Helpers 1.1
import "../../commoncomponents"

Popup {
    id: root

    implicitWidth: parent.width - 10
    leftMargin: 5
    topMargin: 5

    // limit the number of accounts shown at once
    implicitHeight: {
        return visible ? Math.min(JamiTheme.accountListItemHeight * Math.min(6, listView.model.count + 1) + 91, appWindow.height - parent.height) : 0;
    }
    padding: 0
    modal: true
    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
    }

    onOpened: {
        // Reset the current index when the popup is closed
        Qt.callLater(() => listView.currentIndex = -1);
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
                            objectName: "accountComboBoxPopupAvatar"

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

                        Accessible.role: Accessible.Button
                        Accessible.name: toolTipText
                        Accessible.description: JamiStrings.qrCodeExplanation

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

                        Accessible.role: Accessible.Button
                        Accessible.name: toolTipText
                        KeyNavigation.backtab: shareButton

                        onClicked: {
                            !inSettings ? viewCoordinator.present("SettingsView") : viewCoordinator.dismiss("SettingsView");
                            root.close();
                        }
                    }
                }
            }
        }

        ListView {
            id: listView
            objectName: "accountList"
            Accessible.name: JamiStrings.accountList
            Accessible.role: Accessible.List
            Accessible.description: JamiStrings.accountListDescription

            layer.mipmap: false
            clip: true
            maximumFlickVelocity: 1024

            // HACK: remove after migration to Qt 6.7+
            boundsBehavior: Flickable.StopAtBounds

            Layout.fillHeight: true
            Layout.preferredWidth: parent.width

            activeFocusOnTab: true
            focus: true
            currentIndex: -1 // Set to -1 to avoid initial highlighting

            model: SortFilterProxyModel {
                sourceModel: AccountListModel
                filters: ValueFilter {
                    roleName: "ID"
                    value: LRCInstance.currentAccountId
                    inverted: true
                }
            }

            highlight: Rectangle {
                color: "transparent"
                border.color: JamiTheme.primaryBackgroundColor
                border.width: 2
                radius: 5

                Rectangle {
                    anchors.fill: parent
                    color: JamiTheme.hoverColor
                    radius: 5
                    opacity: 0.3
                }
            }

            delegate: AccountItemDelegate {
                height: JamiTheme.accountListItemHeight
                width: root.width

                Accessible.role: Accessible.ListItem
                Accessible.name: Alias || Username
                Accessible.description: JamiStrings.switchToAccount

                // Update the background to show focus state
                background: Rectangle {
                    color: parent.activeFocus || parent.hovered ? JamiTheme.hoverColor : "transparent"
                    opacity: parent.activeFocus ? 0.3 : 1
                    radius: 5
                }

                onClicked: {
                    root.close();
                    // This is a workaround for the synchronicity issue
                    // in AvatarRegistry::connectAccount()
                    AvatarRegistry.clearCache();
                    LRCInstance.currentAccountId = ID;
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            height: 1
            Layout.fillWidth: true
            Layout.leftMargin: 15
            Layout.rightMargin: 15
            color: JamiTheme.smartListHoveredColor
        }

        ItemDelegate {
            id: addAccountItem

            Layout.preferredHeight: 45
            Layout.preferredWidth: parent.width - 10
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 5

            focusPolicy: Qt.StrongFocus
            Accessible.name: addAccountText.text
            Accessible.role: Accessible.Button

            KeyNavigation.tab: manageAccountItem
            KeyNavigation.up: listView
            KeyNavigation.down: manageAccountItem

            background: Rectangle {
                color: addAccountItem.hovered ? JamiTheme.hoverColor : JamiTheme.accountComboBoxBackgroundColor
                radius: 5
            }

            RowLayout {
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
                    id: addAccountText
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
        }

        ItemDelegate {
            id: manageAccountItem

            focusPolicy: Qt.StrongFocus
            Accessible.role: Accessible.Button
            Accessible.name: manageAccountText.text

            KeyNavigation.backtab: addAccountItem
            KeyNavigation.tab: shareButton
            KeyNavigation.up: addAccountItem

            Layout.preferredHeight: 45
            Layout.preferredWidth: parent.width - 10
            Layout.leftMargin: 5
            Layout.bottomMargin: 5

            background: Rectangle {
                color: manageAccountItem.hovered ? JamiTheme.hoverColor : JamiTheme.accountComboBoxBackgroundColor
                radius: 5
            }

            RowLayout {
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
                    id: manageAccountText
                    text: JamiStrings.manageAccount
                    textFormat: TextEdit.PlainText
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                }
            }
            onClicked: {
                root.close();
                viewCoordinator.present("SettingsView");
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
