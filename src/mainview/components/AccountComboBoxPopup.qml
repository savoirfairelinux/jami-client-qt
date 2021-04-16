/*
 * Copyright (C) 2020 by Savoir-faire Linux
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

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../../commoncomponents"

Popup {
    id: root

    y: parent.height
    implicitWidth: parent.width

    // limit the number of accounts shown at once
    implicitHeight: {
        root.visible
        return Math.min(JamiTheme.accountListItemHeight *
                        Math.min(5, accountListModel.rowCount() + 1),
                        mainViewSidePanelRect.height)
    }
    padding: 0

    contentItem: ListView {
        id: listView

        clip: true

        // TODO: this should use proxy model or custom filter out the
        // current account
        model: accountListModel
        delegate: AccountItemDelegate {
            height: JamiTheme.accountListItemHeight
            width: root.width
            onClicked: {
                //listView.currentIndex = index
                root.close()
                AccountAdapter.changeAccount(index)
            }
        }

        footer: ItemDelegate {
            id: footerItem

            implicitHeight: JamiTheme.accountListItemHeight
            implicitWidth: parent.width

            background: Rectangle {
                color: footerItem.hovered?
                           JamiTheme.hoverColor :
                           JamiTheme.backgroundColor

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Add Account") + "+"
                    color: JamiTheme.textColor
                    font.pointSize: JamiTheme.textFontSize
                }
            }

            onClicked: {
                root.close()
                mainView.startWizard()
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }

    background: Rectangle {
        color: JamiTheme.backgroundColor
        CustomBorder {
            commonBorder: false
            tBorderwidth: 1; lBorderwidth: 2
            bBorderwidth: 2; rBorderwidth: 1
            borderColor: JamiTheme.tabbarBorderColor
        }

        layer {
            enabled: true
            effect: DropShadow {
                horizontalOffset: 3.0
                verticalOffset: 3.0
                radius: 16.0
                samples: 16
                color: JamiTheme.shadowColor
            }
        }
    }
}
