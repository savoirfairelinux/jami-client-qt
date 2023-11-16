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
import SortFilterProxyModel 0.2
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import "../../commoncomponents"

Popup {
    id: root

    y: parent.height
    implicitWidth: parent.width -10
    leftMargin: 7

    // limit the number of accounts shown at once
    implicitHeight: {
        return visible ? Math.min(JamiTheme.accountListItemHeight * Math.min(5, listView.model.count) + 95, appWindow.height - parent.height) : 0;
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
            //anchors.horizontalCenter: parent.horizontalCenter
            //anchors.top: parent.top
            height: 1.5
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
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
            Layout.leftMargin: 5

            background: Rectangle {
                color: addAccountItem.hovered ? JamiTheme.hoverColor : JamiTheme.backgroundColor
                radius: 5
                RowLayout{
                    anchors.centerIn: parent
                    anchors.fill: parent
                    ResponsiveImage {
                        id: addImage
                        Layout.alignment: Qt.AlignHCenter
                        Layout.leftMargin: 5
                        source: JamiResources.person_add_24dp_svg
                        color: addAccountItem.hovered ? JamiTheme.textColor : JamiTheme.buttonTintedGreyHovered
                    }
                    Text {
                        text: JamiStrings.addAccount
                        textFormat: TextEdit.PlainText
                        color: JamiTheme.textColor
                        font.pointSize: JamiTheme.textFontSize
                    }
                }
            }

            onClicked: {
                root.close();
                viewCoordinator.present("WizardView");
            }
        }

        ItemDelegate {
            id: manageAccountItem

            Layout.preferredHeight: 45
            Layout.preferredWidth: parent.width-10
            Layout.leftMargin: 5
            Layout.bottomMargin: 5

            background: Rectangle {
                color: manageAccountItem.hovered ? JamiTheme.hoverColor : JamiTheme.backgroundColor
                radius: 5

                RowLayout{
                    anchors.centerIn: parent
                    anchors.fill: parent

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
            }

            onClicked: {
                root.close();
                viewCoordinator.present("SettingsView")
            }
        }
    }

    background: Rectangle {
        color: JamiTheme.backgroundColor
        CustomBorder {
            commonBorder: true
            tBorderwidth: 1
            lBorderwidth: 2
            bBorderwidth: 2
            rBorderwidth: 1
            borderColor: JamiTheme.tabbarBorderColor
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
