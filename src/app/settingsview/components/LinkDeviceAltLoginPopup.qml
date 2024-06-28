
/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
 * Author: Fadi Shehadeh <fadi.shehadeh@savoirfairelinux.com>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import SortFilterProxyModel 0.2
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Enums 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"
import "../../mainview/components"

BaseModalDialog {
    id: root

    property string authUri: props.authUri

    property int itemWidth: 266 * 1.5
    property real aspectRatio: 0.75
    property string mostRecentUri: ""

    width: itemWidth
    height: itemWidth

    function copyUriToClipboard() {
        UtilsAdapter.setClipboardText(root.authUri)
    }

    ColumnLayout {
        id: body
        spacing: JamiTheme.wizardViewPageLayoutSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        // title
        Text {
            text: JamiStrings.ldQrPageTitleAlt
            Layout.alignment: Qt.AlignCenters
            Layout.topMargin: JamiTheme.preferredMarginSize
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: JamiTheme.textColor

            font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
            wrapMode: Text.WordWrap
        }

        // desc
        Text {
            text: JamiStrings.ldLoginInstructionsInfoAlt + "\n" + JamiStrings.ldNoQr
            Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.topMargin: JamiTheme.wizardViewDescriptionMarginSize
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: JamiTheme.wizardViewDescriptionFontPixelSize
            font.weight: Font.Medium
            color: JamiTheme.textColor
            wrapMode: Text.WrapAnywhere
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            lineHeight: JamiTheme.wizardViewTextLineHeight

            // onClick: {
            //     root.copyUriToClipboard()
            // }
            // TODO KESS make this clickable to copy to clipboard + add a button to share via email, text (spacebar or that grome app on postmarketos support?), etc.
        }

        // code box
        InfoBox {
            id: copyCodeBox

            spacing: 30
            Layout.alignment: Qt.AlignHCenter
            title: root.authUri

            // source: JamiResources.content_copy_24dp_svg

            onClick: {
               /* 207                      id: btnCopy
                208                      anchors.leftMargin: JamiTheme.pushButtonMargins
                209                      source: JamiResources.content_copy_24dp_svg
                210                      border.color: "transparent"
                211                      toolTipText: JamiStrings.copy
                212                      onClicked:*/
               root.copyUriToClipboard()
            }

            opacity: visible ? 1.0 : 0.5
            scale: visible ? 1.0 : 0.8  // Scale based on opacity

            Behavior on opacity {
                NumberAnimation {
                    from: 0.5
                    duration: 150  // Duration for the fade animation
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 150  // Duration for the scale animation
                }
            }
        }
    }

    // Label {
    //     id: errorLabel
    //
    //     Layout.alignment: Qt.AlignCenter
    //     Layout.bottomMargin: JamiTheme.wizardViewPageBackButtonMargins
    //
    //     visible: errorText.length !== 0
    //
    //     text: errorText
    //
    //     font.pixelSize: JamiTheme.textEditError
    //     color: JamiTheme.redColor
    // }

}
