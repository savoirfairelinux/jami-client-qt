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
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Helpers 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root

    // We want this particular dialog to only be as wide as the buttons,
    // otherwise it is too large
    implicitWidth: footer.implicitWidth

    margins: JamiTheme.preferredMarginSize

    titleText: JamiStrings.aboutJami

    button1.iconSource: JamiResources.favorite_border_24dp_svg
    button1.text: JamiStrings.donation
    button2.iconSource: JamiResources.volunteer_activism_24dp_svg
    button2.text: JamiStrings.contribute
    button3.iconSource: JamiResources.feedback_24dp_svg
    button3.text: JamiStrings.feedback

    button1.onClicked: {
        Qt.openUrlExternally("https://jami.net/donate/");
    }
    button2.onClicked: {
        Qt.openUrlExternally("https://jami.net/contribute/");
    }
    button3.onClicked: {
        Qt.openUrlExternally("mailto:jami@gnu.org");
    }

    contentItem: JamiFlickable {
        id: aboutPopUpScrollView

        implicitWidth: aboutPopUpContentRectColumnLayout.implicitWidth
        implicitHeight: aboutPopUpContentRectColumnLayout.implicitHeight

        ColumnLayout {
            id: aboutPopUpContentRectColumnLayout

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            width: aboutPopUpScrollView.width

            RowLayout {
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

                Control {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    padding: 10

                    contentItem: ColumnLayout {
                        spacing: 4

                        TextEdit {
                            id: jamiSlogansText

                            Layout.alignment: Qt.AlignLeft

                            text: textMetricsjamiSlogansText.text
                            color: JamiTheme.textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            font.pixelSize: JamiTheme.menuFontSize
                            font.bold: true

                            wrapMode: Text.WordWrap
                            selectByMouse: true
                            readOnly: true

                            TextMetrics {
                                id: textMetricsjamiSlogansText
                                font: jamiSlogansText.font
                                text: JamiStrings.slogan
                            }
                        }
                        RowLayout {
                            TextEdit {
                                id: versionAndBuildInfo
                                readonly property bool isBeta: AppVersionManager.isCurrentVersionBeta()

                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft

                                font.pixelSize: JamiTheme.textFontSize
                                padding: 0
                                text: {
                                    // HACK: Only display the version string if it has been constructed properly.
                                    // This is a workaround for an issue that occurs due to the way Linux
                                    // packaging is done, where the git repository is not available in the
                                    // build source at configure time, which is when the version files are
                                    // generated, so we prevent a "." from being displayed if the version
                                    // string is not available.
                                    var contentStr = JamiStrings.buildID + ": " + UtilsAdapter.getBuildIDStr();
                                    const versionStr = UtilsAdapter.getVersionStr();
                                    if (versionStr.length > 1) {
                                        contentStr += "\n" + JamiStrings.version + ": " + (isBeta ? "(Beta) " : "") + versionStr;
                                    }
                                    return contentStr;
                                }

                                selectByMouse: true
                                readOnly: true

                                color: JamiTheme.faddedFontColor
                            }
                            NewIconButton {
                                id: copyBuildAndVersionInfoButton

                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                iconSource: JamiResources.content_copy_24dp_svg
                                iconSize: JamiTheme.iconButtonSmall
                                toolTipText: JamiStrings.copy

                                onClicked: {
                                    versionAndBuildInfo.selectAll();
                                    versionAndBuildInfo.copy();
                                    versionAndBuildInfo.deselect();
                                    toolTipText = JamiStrings.logsViewCopied;
                                }
                            }
                        }
                    }

                    background: Rectangle {
                        color: JamiTheme.backgroundRectangleColor
                        radius: 5
                    }
                }
            }

            TextEdit {
                id: jamiDeclarationHyperText

                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                Layout.topMargin: 15

                text: textMetricsjamiDeclarationHyperText.text
                color: JamiTheme.textColor
                verticalAlignment: Text.AlignVCenter

                font.pixelSize: JamiTheme.menuFontSize

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

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
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
                Layout.fillWidth: true
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
                    text: JamiStrings.declarationYear + " " + '<a href="https://savoirfairelinux.com/" style="color: ' + JamiTheme.buttonTintedBlue + '">Savoir-faire Linux Inc.</a><br>'
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 160

                color: JamiTheme.backgroundRectangleColor
                radius: 5

                ProjectCreditsScrollView {
                    id: projectCreditsScrollView

                    anchors.fill: parent
                }
            }
        }
    }
}
