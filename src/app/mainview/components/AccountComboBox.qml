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
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import SortFilterProxyModel 0.2
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"

/* Why is ComboBox not the root item?
 * To address accessibility, we separate the three main components:
 * account selection, QR code, and settings to allow focusability on
 * each individual element.
 */

Item {
    id: root

    width: parent.width
    height: JamiTheme.accountListItemHeight

    property bool inSettings: viewCoordinator.currentViewName === "SettingsView"

    Rectangle {
        id: contentRect

        anchors.fill: root
        color: JamiTheme.backgroundColor
        radius: JamiTheme.commonRadius
        layer.enabled: true
        layer.effect: MultiEffect {
            anchors.fill: root
            shadowEnabled: true
            shadowBlur: JamiTheme.shadowBlur
            shadowColor: JamiTheme.shadowColor
            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
            shadowOpacity: JamiTheme.shadowOpacity
        }

        RowLayout {
            anchors.fill: contentRect
            anchors.margins: JamiTheme.accountComboBoxPadding
            spacing: 0
            ComboBox {
                id: accountComboBox

                Layout.fillWidth: true
                Layout.fillHeight: true

                valueRole: "ID"

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

                    background: Rectangle {
                        anchors.fill: parent
                        anchors.margins: JamiTheme.itemMarginVertical
                        radius: JamiTheme.commonRadius + 4
                        color: (hovered || highlighted) ? JamiTheme.hoverColor : JamiTheme.backgroundColor

                        Behavior on color {
                            ColorAnimation {
                                duration: JamiTheme.shortFadeDuration
                            }
                        }
                    }

                    highlighted: accountComboBox.highlightedIndex === index

                    Accessible.role: Accessible.ListItem
                    Accessible.name: Alias || Username
                    Accessible.description: JamiStrings.switchToAccount
                }

                indicator: Item {}

                contentItem: RowLayout {
                    width: accountComboBox ? accountComboBox.width : undefined
                    height: JamiTheme.accountListItemHeight

                    spacing: 10

                    Avatar {
                        Layout.preferredWidth: JamiTheme.accountListAvatarSize
                        Layout.preferredHeight: JamiTheme.accountListAvatarSize
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 10
                        mode: Avatar.Mode.Account
                        imageId: CurrentAccount.id
                        presenceStatus: CurrentAccount.status
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            text: CurrentAccount.bestName
                            textFormat: TextEdit.PlainText
                            font.pointSize: JamiTheme.textFontSize
                            elide: Text.ElideRight
                            color: JamiTheme.textColor
                            horizontalAlignment: Text.AlignLeft
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            text: CurrentAccount.bestId
                            textFormat: TextEdit.PlainText
                            font.pointSize: JamiTheme.tinyFontSize
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            color: JamiTheme.faddedLastInteractionFontColor
                            visible: text.length && text !== CurrentAccount.bestName
                        }
                    }
                }

                popup: Popup {
                    id: accountComboBoxPopup

                    y: contentRect.height - 1
                    width: contentRect.width
                    height: Math.min(contentItem.implicitHeight, accountComboBox.Window.height - topMargin - bottomMargin)

                    padding: 0
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                    contentItem: ListView {
                        id: listView
                        clip: true
                        implicitHeight: contentHeight
                        currentIndex: accountComboBox.highlightedIndex
                        model: visible ? accountComboBox.delegateModel : null
                    }

                    background: Rectangle {
                        color: JamiTheme.backgroundColor
                        radius: JamiTheme.commonRadius
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            anchors.fill: accountComboBoxPopup
                            shadowEnabled: true
                            shadowBlur: JamiTheme.shadowBlur
                            shadowColor: JamiTheme.shadowColor
                            shadowHorizontalOffset: JamiTheme.shadowHorizontalOffset
                            shadowVerticalOffset: JamiTheme.shadowVerticalOffset
                            shadowOpacity: JamiTheme.shadowOpacity
                        }
                    }
                }

                background: Rectangle {
                    id: background

                    anchors.fill: accountComboBox
                    color: accountComboBox.hovered ? JamiTheme.hoverColor : JamiTheme.backgroundColor
                    radius: JamiTheme.commonRadius
                    Behavior on color {
                        ColorAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }

                onActivated: {
                    // This is a workaround for the synchronicity issue
                    // in AvatarRegistry::connectAccount()
                    AvatarRegistry.clearCache();
                    LRCInstance.currentAccountId = currentValue;
                }
            }

            NewIconButton {
                id: shareButton

                Layout.alignment: Qt.AlignVCenter

                iconSize: JamiTheme.iconButtonMedium
                iconSource: JamiResources.share_24dp_svg
                toolTipText: JamiStrings.displayQRCode

                visible: LRCInstance.currentAccountType === Profile.Type.JAMI

                onClicked: viewCoordinator.presentDialog(appWindow, "mainview/components/WelcomePageQrDialog.qml")
            }

            NewIconButton {
                id: settingsButton

                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 4

                iconSize: JamiTheme.iconButtonMedium
                iconSource: !inSettings ? JamiResources.settings_24dp_svg : JamiResources.round_close_24dp_svg
                toolTipText: !inSettings ? JamiStrings.openSettings : JamiStrings.closeSettings

                onClicked: {
                    !inSettings ? viewCoordinator.present("SettingsView") : viewCoordinator.dismiss("SettingsView");
                    background.state = "normal";
                }
            }
        }
    }
}
