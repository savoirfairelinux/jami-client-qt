/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
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
import QtQuick.Controls.Universal 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14

import net.jami.Models 1.0
import net.jami.Adapters 1.0
import net.jami.Constants 1.0

import "../"
import "../commoncomponents"
import "components"

Rectangle {
    id: root
    property var inputParaObject: ({})

    // signal to redirect the page to main view
    signal loaderSourceChangeRequested(int sourceToLoad)

    color: JamiTheme.backgroundColor

    ScrollView {
        id: wizardViewScrollView

        property ScrollBar vScrollBar: ScrollBar.vertical

        anchors.fill: parent

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        clip: true
        contentHeight: controlPanelStackView.height

        StackLayout {
            id: controlPanelStackView

            anchors.centerIn: parent

            width: wizardViewScrollView.width

            currentIndex: WizardView.WizardViewPageIndex.WELCOMEPAGE

            /*Component.onCompleted: {
                // avoid binding loop
                height = Qt.binding(function (){
                    var index = currentIndex
                            === WizardView.WizardViewPageIndex.CREATERENDEZVOUS ?
                                WizardView.WizardViewPageIndex.CREATEACCOUNTPAGE : currentIndex
                    return Math.max(
                                controlPanelStackView.itemAt(index).preferredHeight,
                                wizardViewScrollView.height)
                })
            }*/

            WelcomePage {
                id: welcomePage

                Layout.alignment: Qt.AlignCenter

                onWelcomePageRedirectPage: {
                    changePageQML(toPageIndex)
                }

                onLeavePage: {
                    wizardViewIsClosed()
                }

                onScrollToBottom: {
                    if (welcomePage.preferredHeight > root.height)
                        wizardViewScrollView.vScrollBar.position = 1
                }
            }
        }
    }
}
