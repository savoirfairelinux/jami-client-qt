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
import QtQuick.Controls.impl

import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

SettingsPageBase {
    id: root

    property bool apiEnabled: UtilsAdapter.getAppValue(Settings.Key.EnableApi)

    title: JamiStrings.appAccessSettingsTitle

    flickableContent: ColumnLayout {
        id: apiSettingsLayout

        anchors.left: parent.left
        anchors.leftMargin: JamiTheme.preferredSettingsMarginSize

        width: contentFlickableWidth

        spacing: JamiTheme.settingsBlockSpacing

        Text {
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true

            text: JamiStrings.appAccessSettingsDescription
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
                    text: JamiStrings.appAccessServerDisabledTitle
                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.settingsTitlePixelSize
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: JamiStrings.appAccessServerDisabledMessage
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                    font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                }

                NewMaterialButton {
                    Layout.alignment: Qt.AlignLeft
                    implicitHeight: JamiTheme.newMaterialButtonHeight
                    filledButton: true
                    color: JamiTheme.blockOrange
                    text: JamiStrings.appAccessEnableServerButton
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
            spacing: 12

            // ── Create Token ──

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: JamiTheme.settingsCategorySpacing
                spacing: 10

                NewMaterialTextField {
                    id: tokenLabelInput

                    Layout.fillWidth: true
                    textFieldContent: ""
                    placeholderText: JamiStrings.appAccessTokenLabelPlaceholder
                }

                NewMaterialButton {
                    id: createTokenBtn

                    implicitHeight: JamiTheme.newMaterialButtonHeight
                    filledButton: true
                    iconSource: JamiResources.token_24dp_svg
                    text: JamiStrings.appAccessCreateToken
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

                text: JamiStrings.appAccessTokensListTitle
                color: JamiTheme.textColor
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: JamiTheme.settingsTitlePixelSize
                font.kerning: true
            }

            Text {
                visible: tokenListView.count === 0
                Layout.fillWidth: true

                text: JamiStrings.appAccessNoTokens
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

                delegate: ItemDelegate {
                    id: tokenDelegate

                    required property string tokenId
                    required property string tokenLabel
                    required property string tokenCreatedAt
                    required property string tokenExpiresAt
                    required property int index

                    width: tokenListView.width
                    height: 64

                    activeFocusOnTab: true

                    contentItem: RowLayout {
                        IconImage {
                            source: JamiResources.token_24dp_svg

                            sourceSize.width: JamiTheme.iconButtonMedium
                            sourceSize.height: JamiTheme.iconButtonMedium

                            color: JamiTheme.textColor
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true

                                text: tokenDelegate.tokenLabel
                                color: JamiTheme.textColor
                                elide: Text.ElideRight

                                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                                font.weight: Font.Medium
                            }

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var s = JamiStrings.appAccessTokenCreatedAt.arg(tokenDelegate.tokenCreatedAt)
                                    if (tokenDelegate.tokenExpiresAt.length > 0)
                                        s += " · " + JamiStrings.appAccessTokenExpiresAt.arg(tokenDelegate.tokenExpiresAt)
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

                            outlinedButton: true
                            text: JamiStrings.optionDelete
                            color: JamiTheme.buttonTintedRed
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: JamiTheme.shortFadeDuration
                                }
                            }

                            visible: tokenDelegate.hovered || tokenDelegate.highlighted || tokenDelegate.activeFocus

                            onClicked: ApiTokenListModel.revokeToken(tokenDelegate.tokenId)
                        }
                    }

                    background: Rectangle {
                        color: JamiTheme.transparentColor
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Row {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true

                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: JamiStrings.appAccessBotAccounts
                        color: JamiTheme.textColor
                        horizontalAlignment: Text.AlignLeft

                        font.pixelSize: JamiTheme.settingsTitlePixelSize
                        font.kerning: true
                    }

                    NewIconButton {
                        anchors.verticalCenter: parent.verticalCenter

                        iconSource: JamiResources.bidirectional_help_outline_24dp_svg
                        iconSize: JamiTheme.iconButtonMedium
                        toolTipText: JamiStrings.appAccessBotHelp

                        onClicked: viewCoordinator.presentDialog(appWindow, "settingsview/components/AboutBotAccountsPopup.qml");
                    }
                }


                NewMaterialButton {
                    id: createBot

                    implicitHeight: JamiTheme.newMaterialButtonHeight
                    filledButton: true
                    iconSource: JamiResources.robot_2_24dp_svg
                    text: JamiStrings.appAccessCreateBotAccount

                    onClicked: {
                        viewCoordinator.presentDialog(appWindow, "settingsview/components/CreateBotDialog.qml");
                    }
                }
            }
            Text {
                Layout.fillWidth: true

                text: JamiStrings.appAccessNoBotsConfigured
                color: JamiTheme.faddedLastInteractionFontColor
                font.pixelSize: JamiTheme.settingsDescriptionPixelSize
                font.italic: true

                visible: botListView.count === 0
            }

            ListView {
                id: botListView

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(count, 5) * 72
                clip: true
                interactive: count > 5

                model: SortFilterProxyModel {
                    model: AccountListModel
                    filters: ValueFilter {
                        roleName: "BotOwner"
                        value: CurrentAccount.uri
                    }
                }

                delegate: ItemDelegate {
                    id: botItemDelegate

                    width: botListView.width

                    contentItem: RowLayout {
                        spacing: 8

                        Avatar {
                            Layout.alignment: Qt.AlignVCenter

                            width: JamiTheme.accountListAvatarSize
                            height: JamiTheme.accountListAvatarSize

                            imageId: ID
                            mode: Avatar.Mode.Account

                            showPresenceIndicator: false
                        }

                        ColumnLayout {
                            RowLayout {
                                Layout.fillWidth: true
                                IconImage {
                                    Layout.alignment: Qt.AlignVCenter

                                    source: JamiResources.robot_2_24dp_svg
                                    sourceSize.width: JamiTheme.iconButtonSmall
                                    sourceSize.height: JamiTheme.iconButtonSmall

                                    color: JamiTheme.textColor
                                }

                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true

                                    text: Alias
                                    color: JamiTheme.textColor

                                    elide: Text.ElideRight

                                    font.pointSize: JamiTheme.mediumFontSize
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Row {
                                spacing: 4

                                Rectangle {
                                    color: Enabled ? JamiTheme.presenceGreen : JamiTheme.notificationRed

                                    width: statusText.height
                                    height: statusText.height
                                    radius: height / 2

                                    SequentialAnimation on scale {
                                        loops: Animation.Infinite
                                        running: Enabled
                                        NumberAnimation {
                                            from: 0.8
                                            to: 1.0
                                            duration: JamiTheme.recordBlinkDuration
                                        }
                                        NumberAnimation {
                                            from: 1.0
                                            to: 0.8
                                            duration: JamiTheme.recordBlinkDuration
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: JamiTheme.shortFadeDuration
                                        }
                                    }
                                }

                                Text {
                                    id: statusText
                                    text: Enabled ? JamiStrings.appAccessBotOnline : JamiStrings.appAccessBotOffline
                                    color: Enabled ? JamiTheme.presenceGreen : JamiTheme.notificationRed

                                    font.family: JamiTheme.ubuntuMonoFontFamily
                                    font.pointSize: JamiTheme.smallFontSize

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: JamiTheme.shortFadeDuration
                                        }
                                    }
                                }
                            }
                        }

                        NewIconButton {
                            id: copyBotUriButton

                            Layout.alignment: Qt.AlignLeft

                            iconSource: JamiResources.content_copy_24dp_svg
                            iconSize: JamiTheme.iconButtonMedium
                            toolTipText: JamiStrings.appAccessCopyBotUri

                            // To avoid conflict with delegate background
                            background.visible: false

                            onClicked: {
                                UtilsAdapter.setClipboardText(Uri)
                            }

                        }

                        NewIconButton {
                            id: shareBotButton

                            Layout.alignment: Qt.AlignLeft

                            iconSource: JamiResources.share_24dp_svg
                            iconSize: JamiTheme.iconButtonMedium
                            toolTipText: JamiStrings.appAccessShareBot

                            // To avoid conflict with delegate background
                            background.visible: false

                            onClicked: {
                                var dlg = viewCoordinator.presentDialog(appWindow, "../../mainview/components/ContactPicker.qml", {
                                                                            "type": ContactList.ONE_TO_ONE,
                                                                            "titleText": JamiStrings.appAccessShareBotDialogTitle
                                                                        });


                                dlg.contactSelected.connect(function(uri) {
                                    const convId = UtilsAdapter.getConvIdForUri(CurrentAccount.id, uri);
                                    MessagesAdapter.sendMessageToUid(JamiStrings.appAccessShareBotMessage.arg(Alias).arg(Uri), convId);
                                });
                            }
                        }

                        JamiSwitch {
                            Layout.alignment: Qt.AlignVCenter
                            checked: Enabled
                            onClicked: AccountAdapter.model.setAccountEnabled(ID, checked)
                        }
                    }

                    background: Rectangle {
                        radius: height / 2
                        color: botItemDelegate.hovered ? JamiTheme.smartListHoveredColor : JamiTheme.globalBackgroundColor

                        Behavior on color {
                            ColorAnimation {
                                duration: JamiTheme.shortFadeDuration
                            }
                        }
                    }
                }
            }
        }

    }

    // ── "New token created" dialog ──

    BaseModalDialog {
        id: newTokenDialog

        property string rawToken: ""

        titleText: JamiStrings.appAccessTokenCreatedTitle

        popupContent: ColumnLayout {
            spacing: 16

            Text {
                Layout.fillWidth: true
                text: JamiStrings.appAccessTokenCreatedMessage
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
                text: JamiStrings.appAccessTokenCopyWarning
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
