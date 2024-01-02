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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root
    margins: JamiTheme.preferredMarginSize
    title: JamiStrings.aboutJami

    button1.text: JamiStrings.contribute
    button2.text: JamiStrings.feedback

    button1.onClicked: { Qt.openUrlExternally("https://jami.net/contribute/")}
    button2.onClicked: { Qt.openUrlExternally("mailto:jami@gnu.org")}

    popupContent: JamiFlickable {
            id: aboutPopUpScrollView

            width: aboutPopUpContentRectColumnLayout.implicitWidth
            height: Math.min(root.implicitHeight, aboutPopUpContentRectColumnLayout.implicitHeight)

            contentHeight: aboutPopUpContentRectColumnLayout.implicitHeight

            ColumnLayout {
                id: aboutPopUpContentRectColumnLayout
                anchors.centerIn: parent

                RowLayout{
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    spacing: 10

                    ResponsiveImage {
                        id: aboutPopUPJamiLogoImage

                        Layout.alignment: Qt.AlignCenter
                        Layout.margins: 10
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 50

                        source: JamiTheme.darkTheme ? JamiResources.logo_jami_standard_coul_white_svg : JamiResources.logo_jami_standard_coul_svg
                    }

                    Rectangle {
                        color: JamiTheme.backgroundRectangleColor
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        radius: 5

                        ColumnLayout {
                            id: sloganLayout

                            anchors.verticalCenter: parent.verticalCenter

                            TextEdit {
                                id: jamiSlogansText

                                Layout.alignment: Qt.AlignLeft
                                Layout.margins: 10
                                Layout.bottomMargin: 0

                                wrapMode: Text.WordWrap
                                font.pixelSize: JamiTheme.menuFontSize
                                font.bold: true

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                text: textMetricsjamiSlogansText.text
                                selectByMouse: true
                                readOnly: true
                                color: JamiTheme.textColor

                                TextMetrics {
                                    id: textMetricsjamiSlogansText
                                    font: jamiSlogansText.font
                                    text: JamiStrings.slogan
                                }
                            }
                            TextEdit {
                                id: jamiVersionText

                                Layout.alignment: Qt.AlignLeft
                                Layout.margins: 10
                                Layout.topMargin: 0
                                Layout.maximumWidth: JamiTheme.preferredDialogWidth - 2*JamiTheme.preferredMarginSize

                                font.pixelSize: JamiTheme.textFontSize
                                padding: 0
                                text: JamiStrings.version + ": " + UtilsAdapter.getVersionStr()

                                selectByMouse: true
                                readOnly: true

                                color: JamiTheme.faddedFontColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                TextEdit {
                    id: jamiDeclarationHyperText

                    Layout.alignment: Qt.AlignLeft
                    Layout.fillWidth: true

                    // Strangely, hoveredLink works badly when width grows too large
                    Layout.maximumWidth: JamiTheme.preferredDialogWidth - 2*JamiTheme.preferredMarginSize
                    Layout.topMargin: 15

                    color: JamiTheme.textColor

                    font.pixelSize: JamiTheme.menuFontSize
                    verticalAlignment: Text.AlignVCenter

                    text: textMetricsjamiDeclarationHyperText.text
                    textFormat: TextEdit.RichText
                    wrapMode: TextEdit.WordWrap
                    selectByMouse: true
                    readOnly: true
                    onLinkActivated: Qt.openUrlExternally(link)

                    TextMetrics {
                        id: textMetricsjamiDeclarationHyperText
                        font: jamiDeclarationHyperText.font
                        text: JamiStrings.declaration
                    }

                    MouseArea {
                        anchors.fill: parent

                        // We don't want to eat clicks on the Text.
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }

                TextEdit {
                    id: jamiNoneWarrantyHyperText

                    Layout.alignment: Qt.AlignLeft
                    Layout.maximumWidth: JamiTheme.preferredDialogWidth - 2*JamiTheme.preferredMarginSize
                    Layout.topMargin: 15
                    wrapMode: Text.WordWrap
                    font.pixelSize: JamiTheme.menuFontSize

                    verticalAlignment: Text.AlignTop
                    color: JamiTheme.textColor

                    text: textMetricsjamiNoneWarrantyHyperText.text
                    textFormat: TextEdit.RichText
                    selectByMouse: true
                    readOnly: true
                    onLinkActivated: Qt.openUrlExternally(link)

                    TextMetrics {
                        id: textMetricsjamiNoneWarrantyHyperText
                        font: jamiDeclarationHyperText.font
                        text: JamiStrings.noWarranty
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }

                TextEdit {
                    id: jamiYears

                    Layout.alignment: Qt.AlignLeft
                    Layout.maximumWidth: JamiTheme.preferredDialogWidth - 2*JamiTheme.preferredMarginSize
                    Layout.topMargin: 15

                    wrapMode: Text.WordWrap
                    font.pixelSize: JamiTheme.menuFontSize
                    verticalAlignment: Text.AlignTop

                    color: JamiTheme.textColor

                    text: textMetricsYears.text
                    textFormat: TextEdit.RichText
                    selectByMouse: true
                    readOnly: true

                    onLinkActivated: Qt.openUrlExternally(link)

                    TextMetrics {
                        id: textMetricsYears
                        font: jamiDeclarationHyperText.font
                        text: JamiStrings.declarationYear + " " + '<a href="https://savoirfairelinux.com" style="color: ' + JamiTheme.buttonTintedBlue + '">Savoir-faire Linux</a><br>'
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }

                Rectangle {
                    width: projectCreditsScrollView.width + 20
                    height: projectCreditsScrollView.height + 20

                    color: JamiTheme.backgroundRectangleColor
                    radius: 5

                    ProjectCreditsScrollView {
                        id: projectCreditsScrollView

                        anchors.centerIn: parent
                        width: JamiTheme.preferredDialogWidth - 2*JamiTheme.preferredMarginSize
                        height: 140
                        anchors.margins: 10
                    }
                }

        }
    }
}
