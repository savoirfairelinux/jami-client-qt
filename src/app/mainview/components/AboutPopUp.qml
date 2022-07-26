/*
 * Copyright (C) 2020-2022 Savoir-faire Linux Inc.
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1


import "../../commoncomponents"

BaseModalDialog {
    id: root


    popupContentMargins: 14

    PushButton {
        id: btnClose

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: JamiTheme.preferredMarginSize
        anchors.rightMargin: JamiTheme.preferredMarginSize
        imageColor: "grey"
        normalColor: JamiTheme.transparentColor

        source: JamiResources.round_close_24dp_svg

        onClicked: { close();}
    }

    popupContent: JamiFlickable {
        id: aboutPopUpScrollView

        width: root.width
        contentHeight: aboutPopUpContentRectColumnLayout.implicitHeight

        ColumnLayout {
            id: aboutPopUpContentRectColumnLayout

            width: root.width

            ResponsiveImage {
                id: aboutPopUPJamiLogoImage

                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.preferredWidth: JamiTheme.aboutLogoPreferredWidth
                Layout.preferredHeight: JamiTheme.aboutLogoPreferredHeight

                source: JamiTheme.darkTheme ?
                            JamiResources.logo_jami_standard_coul_white_svg :
                            JamiResources.logo_jami_standard_coul_svg
            }

            Label {
                id: jamiSlogansText

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: aboutPopUpScrollView.width
                Layout.topMargin: 26

                wrapMode: Text.WordWrap
                font.pixelSize: JamiTheme.bigFontSize

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                text: textMetricsjamiSlogansText.text
                color: JamiTheme.tintedBlue

                TextMetrics {
                    id: textMetricsjamiSlogansText
                    font: jamiSlogansText.font
                    text: JamiStrings.slogan
                }
            }

            Label {
                id: jamiVersionText

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: aboutPopUpScrollView.width

                font.pixelSize: JamiTheme.tinyCreditsTextSize

                padding: 0

                text: JamiStrings.version + ": " + UtilsAdapter.getVersionStr()
                color: JamiTheme.textColor

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Label {
                id: jamiDeclarationText

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: aboutPopUpScrollView.width - JamiTheme.preferredMarginSize * 2
                Layout.topMargin: 15

                wrapMode: Text.WordWrap
                font.pixelSize: JamiTheme.creditsTextSize
                color: JamiTheme.textColor

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                // TextMetrics does not work for multi-line.
                text: JamiStrings.declaration
            }

            Label {
                id: jamiDeclarationHyperText

                Layout.alignment: Qt.AlignCenter

                // Strangely, hoveredLink works badly when width grows too large
                Layout.preferredWidth: 50
                Layout.topMargin: 15

                color: JamiTheme.textColor

                font.pixelSize: JamiTheme.creditsTextSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                text: textMetricsjamiDeclarationHyperText.text
                onLinkActivated: Qt.openUrlExternally(link)

                TextMetrics {
                    id: textMetricsjamiDeclarationHyperText
                    font: jamiDeclarationHyperText.font
                    text: '<html><style type="text/css"></style><a href="https://jami.net">jami.net</a></html>'
                }

                MouseArea {
                    anchors.fill: parent

                    // We don't want to eat clicks on the Text.
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }

            Label {
                id: jamiNoneWarrantyHyperText

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: Math.min(390, root.width)
                Layout.topMargin: 15
                lineHeight: 1.2
                wrapMode: Text.WordWrap
                font.pixelSize: JamiTheme.tinyCreditsTextSize

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                color: JamiTheme.textColor

                text: textMetricsjamiNoneWarrantyHyperText.text
                onLinkActivated: Qt.openUrlExternally(link)

                TextMetrics {
                    id: textMetricsjamiNoneWarrantyHyperText
                    font: jamiDeclarationHyperText.font
                    text: JamiStrings.declarationYear + " " + '<html><style type="text/css"></style><a href="https://savoirfairelinux.com">Savoir-faire Linux Inc.<br></a></html>'
                          + '<html><style type="text/css"></style>This program comes with absolutely no warranty. See the <a href="http://www.gnu.org/licenses/gpl-3.0.html">GNU General Public License</a>, version 3 or later for details.</html>'
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }

            ProjectCreditsScrollView {
                id: projectCreditsScrollView
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: aboutPopUpScrollView.width - JamiTheme.preferredMarginSize * 2
                Layout.preferredHeight: 100
                Layout.topMargin: 25
                Layout.margins: JamiTheme.preferredMarginSize
            }

        }
    }
}
