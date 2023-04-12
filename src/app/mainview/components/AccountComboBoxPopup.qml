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
import "../../commoncomponents"

Popup {
    id: root
    // limit the number of accounts shown at once
    implicitHeight: {
        return visible ? Math.min(JamiTheme.accountListItemHeight * Math.min(5, listView.model.count + 1), appWindow.height - parent.height) : 0;
    }
    implicitWidth: parent.width
    modal: true
    padding: 0
    y: parent.height

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
    }
    background: Rectangle {
        color: JamiTheme.backgroundColor

        CustomBorder {
            bBorderwidth: 2
            borderColor: JamiTheme.tabbarBorderColor
            commonBorder: false
            lBorderwidth: 2
            rBorderwidth: 1
            tBorderwidth: 1
        }
        layer {
            enabled: true

            effect: DropShadow {
                color: JamiTheme.shadowColor
                horizontalOffset: 3.0
                radius: 16.0
                transparentBorder: true
                verticalOffset: 3.0
            }
        }
    }
    contentItem: ColumnLayout {
        spacing: 0

        JamiListView {
            id: listView
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width

            delegate: AccountItemDelegate {
                height: JamiTheme.accountListItemHeight
                width: root.width

                onClicked: {
                    root.close();
                    LRCInstance.currentAccountId = ID;
                }
            }
            model: SortFilterProxyModel {
                sourceModel: AccountListModel

                filters: ValueFilter {
                    inverted: true
                    roleName: "ID"
                    value: LRCInstance.currentAccountId
                }
            }
        }

        // fake footer item as workaround for Qt 5.15 bug
        // https://bugreports.qt.io/browse/QTBUG-85302
        // don't use the clip trick and footer item overlay
        // explained here https://stackoverflow.com/a/64625149
        // as it causes other complexities in handling the drop shadow
        ItemDelegate {
            id: footerItem
            Layout.preferredHeight: JamiTheme.accountListItemHeight
            Layout.preferredWidth: parent.width

            onClicked: {
                root.close();
                viewCoordinator.present("WizardView");
            }

            background: Rectangle {
                color: footerItem.hovered ? JamiTheme.hoverColor : JamiTheme.backgroundColor

                Text {
                    anchors.centerIn: parent
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                    text: JamiStrings.addAccount + "+"
                    textFormat: TextEdit.PlainText
                }
            }
        }
    }
}
