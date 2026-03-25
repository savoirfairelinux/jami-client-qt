/*
 * Copyright (C) 2025 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

SettingsPageBase {
    id: root

    property bool apiEnabled: UtilsAdapter.getAppValue(Settings.Key.EnableApi)

    title: JamiStrings.apiSettingsTitle

    flickableContent: ColumnLayout {
        id: apiSettingsLayout

        width: contentFlickableWidth
        spacing: JamiTheme.settingsBlockSpacing
        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        Text {
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true

            text: JamiStrings.apiSettingsDescription
            color: JamiTheme.textColor
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
            font.pixelSize: JamiTheme.settingsDescriptionPixelSize
            font.kerning: true
            lineHeight: JamiTheme.wizardViewTextLineHeight
        }

        Rectangle {
            id: disabledServerCard

            visible: !root.apiEnabled
            Layout.fillWidth: true
            implicitHeight: disabledServerCardContent.implicitHeight + 32
            radius: 12
            color: JamiTheme.blockOrangeTransparency
            border.width: 1
            border.color: JamiTheme.blockOrange

            ColumnLayout {
                id: disabledServerCardContent

                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: JamiStrings.apiServerDisabledTitle
                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.settingsTitlePixelSize
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: JamiStrings.apiServerDisabledMessage
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                    font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                }

                NewMaterialButton {
                    Layout.alignment: Qt.AlignLeft
                    implicitHeight: JamiTheme.newMaterialButtonHeight
                    filledButton: true
                    color: JamiTheme.blockOrange
                    text: JamiStrings.apiEnableServerButton
                    onClicked: {
                        root.apiEnabled = true
                        UtilsAdapter.setAppValue(Settings.Key.EnableApi, true)
                        ApiServer.start(UtilsAdapter.getAppValue(Settings.Key.ApiPort))
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // ── Create Token ──

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: JamiTheme.settingsCategorySpacing
                spacing: 10

                NewMaterialTextField {
                    id: tokenLabelInput

                    Layout.fillWidth: true
                    textFieldContent: ""
                    placeholderText: JamiStrings.apiTokenLabelPlaceholder
                }

                NewMaterialButton {
                    id: createTokenBtn

                    implicitHeight: JamiTheme.newMaterialButtonHeight
                    filledButton: true
                    text: JamiStrings.apiCreateToken
                    enabled: (tokenLabelInput.modifiedTextFieldContent || "").trim().length > 0

                    onClicked: {
                        var tokenLabel = (tokenLabelInput.modifiedTextFieldContent || "").trim()
                        var rawToken = ApiTokenListModel.createToken(tokenLabel)
                        if (rawToken.length > 0) {
                            tokenLabelInput.modifiedTextFieldContent = ""
                            newTokenDialog.rawToken = rawToken
                            newTokenDialog.open()
                        }
                    }
                }
            }

            // ── Token List ──

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true

                text: JamiStrings.apiTokensListTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Text {
                visible: tokenListView.count === 0
                Layout.fillWidth: true

                text: JamiStrings.apiNoTokens
                color: JamiTheme.faddedLastInteractionFontColor
                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                font.italic: true
            }

            ListView {
                id: tokenListView

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(count, 5) * 72
                clip: true
                interactive: count > 5

                model: ApiTokenListModel

                delegate: Rectangle {
                    id: tokenDelegate

                    required property string tokenId
                    required property string tokenLabel
                    required property string tokenCreatedAt
                    required property string tokenExpiresAt
                    required property int index

                    width: tokenListView.width
                    height: 64
                    radius: 5
                    color: tokenHover.hovered ? JamiTheme.smartListSelectedColor
                                              : "transparent"

                    HoverHandler {
                        id: tokenHover
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: tokenDelegate.tokenLabel
                                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                                font.weight: Font.Medium
                                color: JamiTheme.textColor
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var s = JamiStrings.apiTokenCreatedAt.arg(tokenDelegate.tokenCreatedAt)
                                    if (tokenDelegate.tokenExpiresAt.length > 0)
                                        s += " · " + JamiStrings.apiTokenExpiresAt.arg(tokenDelegate.tokenExpiresAt)
                                    return s
                                }
                                font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 2
                                color: JamiTheme.faddedLastInteractionFontColor
                                elide: Text.ElideRight
                            }
                        }

                        NewMaterialButton {
                            id: revokeTokenButton

                            Layout.alignment: Qt.AlignVCenter
                            visible: tokenHover.hovered
                            outlinedButton: true
                            color: JamiTheme.buttonTintedRed
                            text: JamiStrings.optionDelete
                            onClicked: ApiTokenListModel.revokeToken(tokenDelegate.tokenId)
                        }
                    }
                }
            }
        }

        // ── "New token created" dialog ──

        BaseModalDialog {
            id: newTokenDialog

            property string rawToken: ""

            titleText: JamiStrings.apiTokenCreatedTitle

            popupContent: ColumnLayout {
                spacing: 16

                Text {
                    Layout.fillWidth: true
                    text: JamiStrings.apiTokenCreatedMessage
                    wrapMode: Text.WordWrap
                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: tokenContentLayout.implicitHeight + 20
                    radius: 5
                    color: JamiTheme.editBackgroundColor
                    border.color: JamiTheme.tintedBlue
                    border.width: 1

                    RowLayout {
                        id: tokenContentLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            id: tokenText
                            Layout.fillWidth: true
                            text: newTokenDialog.rawToken
                            font.family: JamiTheme.ubuntuMonoFontFamily
                            font.pixelSize: 13
                            wrapMode: Text.WrapAnywhere
                            color: JamiTheme.textColor
                        }

                        NewIconButton {
                            Layout.alignment: Qt.AlignTop
                            iconSource: JamiResources.content_copy_24dp_svg
                            iconSize: JamiTheme.iconButtonMedium
                            toolTipText: JamiStrings.copy
                            onClicked: {
                                UtilsAdapter.setClipboardText(newTokenDialog.rawToken)
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: JamiStrings.apiTokenCopyWarning
                    wrapMode: Text.WordWrap
                    color: JamiTheme.redColor
                    font.pixelSize: JamiTheme.settingsDescriptionPixelSize - 1
                    font.weight: Font.Medium
                }
            }

            button1.text: JamiStrings.optionOk
            button1.onClicked: {
                newTokenDialog.close()
                newTokenDialog.rawToken = ""
            }
        }
    }

    Component.onCompleted: {
        ApiTokenListModel.accountId = CurrentAccount.id
        root.apiEnabled = UtilsAdapter.getAppValue(Settings.Key.EnableApi)
    }

    Connections {
        target: CurrentAccount
        function onIdChanged() {
            ApiTokenListModel.accountId = CurrentAccount.id
        }
    }

    Connections {
        target: ApiServer

        function onStopped() {
            if (!UtilsAdapter.getAppValue(Settings.Key.EnableApi))
                root.apiEnabled = false
        }
    }
}
