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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

BaseModalDialog {
    id: root

    property bool isSIP: false

    signal accepted

    titleText: JamiStrings.deleteAccount

    closeButtonVisible: false

    button1.text: JamiStrings.optionDelete
    button1.color: JamiTheme.deleteRedButton
    button1.onClicked: {
        button1.enabled = false;
        busyInd.running = true;
        AccountAdapter.deleteCurrentAccount();
        close();
        accepted();
    }
    button1Role: DialogButtonBox.DestructiveRole

    button2.text: JamiStrings.optionCancel
    button2.onClicked: close()
    button2Role: DialogButtonBox.RejectRole

    BusyIndicator {
        id: busyInd
        running: false
        Connections {
            target: root
            function onClosed() {
                busyInd.running = false;
            }
        }
    }

    popupContent: ColumnLayout {
        id: deleteAccountContentColumnLayout

        spacing: 10

        Label {
            id: labelDeletion

            Layout.fillWidth: true
            Layout.maximumWidth: root.width - 4 * JamiTheme.preferredMarginSize
            Layout.alignment: Qt.AlignLeft

            text: JamiStrings.confirmDeleteAccount
            color: JamiTheme.textColor
            wrapMode: Text.Wrap

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true
        }

        Rectangle {
            id: accountRectangle

            color: JamiTheme.backgroundRectangleColor

            Layout.fillWidth: true

            Layout.preferredHeight: userProfileDialogLayout.height

            topRightRadius: JamiTheme.avatarBasedRadius
            topLeftRadius: JamiTheme.avatarBasedRadius
            bottomLeftRadius: identifier.radius + 10
            bottomRightRadius: identifier.radius + 10

            ColumnLayout {
                id: userProfileDialogLayout

                anchors.centerIn: parent
                width: parent.width

                RowLayout {
                    Layout.margins: 10
                    Layout.fillWidth: true

                    spacing: 10

                    Avatar {
                        id: currentAccountImage

                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56

                        imageId: CurrentAccount.id
                        showPresenceIndicator: false
                        mode: Avatar.Mode.Account
                    }

                    ColumnLayout {

                        spacing: 10
                        Layout.alignment: Qt.AlignLeft

                        // Visible when user alias is not empty and not equal to id.
                        TextEdit {
                            id: accountAlias

                            Layout.alignment: Qt.AlignLeft

                            font.pointSize: JamiTheme.settingsFontSize
                            font.kerning: true

                            color: JamiTheme.textColor
                            visible: accountDisplayName.text ? (CurrentAccount.alias === CurrentAccount.bestId ? false : true) : false
                            selectByMouse: true
                            readOnly: true

                            wrapMode: Text.NoWrap
                            text: textMetricsAccountAliasText.elidedText
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            TextMetrics {
                                id: textMetricsAccountAliasText

                                font: accountAlias.font
                                text: CurrentAccount.alias
                                elideWidth: root.width - 200
                                elide: Qt.ElideMiddle
                            }
                        }

                        // Visible when user name is not empty or equals to id.
                        TextEdit {
                            id: accountDisplayName

                            Layout.alignment: Qt.AlignLeft

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true
                            color: JamiTheme.faddedFontColor

                            visible: text.length && text !== CurrentAccount.alias
                            readOnly: true
                            selectByMouse: true

                            wrapMode: Text.NoWrap
                            text: textMetricsAccountDisplayNameText.elidedText
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            TextMetrics {
                                id: textMetricsAccountDisplayNameText

                                font: accountDisplayName.font
                                text: CurrentAccount.bestId
                                elideWidth: root.width - 200
                                elide: Qt.ElideMiddle
                            }
                        }
                    }
                }
                Rectangle {
                    id: identifier

                    Layout.fillWidth: true
                    Layout.preferredHeight: accountId.height + 10
                    Layout.margins: 12
                    Layout.topMargin: 0

                    visible: !isSIP

                    radius: height / 2
                    color: JamiTheme.globalBackgroundColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4

                        spacing: 10

                        Text {
                            id: identifierText

                            Layout.leftMargin: identifier.radius

                            text: JamiStrings.identifier
                            color: JamiTheme.faddedFontColor
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            font.pointSize: JamiTheme.textFontSize
                        }
                        Label {
                            id: accountId

                            Layout.alignment: Qt.AlignLeft
                            Layout.fillWidth: true
                            Layout.rightMargin: 4

                            font.family: JamiTheme.ubuntuMonoFontFamily
                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true
                            color: JamiTheme.textColor

                            elide: Text.ElideRight
                            text: CurrentAccount.uri
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
        Rectangle {
            id: warningRectangle

            color: JamiTheme.warningRedRectangle

            Layout.fillWidth: true
            Layout.preferredHeight: labelWarning.height + 20

            radius: 8

            RowLayout {
                id: warningLayout

                anchors.centerIn: parent
                anchors.margins: 15
                width: parent.width

                Button {
                    id: warningIcon

                    Layout.fillWidth: true
                    Layout.leftMargin: 15

                    padding: 0
                    horizontalPadding: 0

                    icon.source: JamiResources.notification_important_24dp_svg
                    icon.width: JamiTheme.iconButtonMedium
                    icon.height: JamiTheme.iconButtonMedium
                    icon.color: JamiTheme.redColor

                    background: null
                }

                Label {
                    id: labelWarning

                    Layout.fillWidth: true
                    Layout.margins: 15

                    text: JamiStrings.deleteAccountInfo
                    color: JamiTheme.redColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap

                    font.pointSize: JamiTheme.textFontSize
                    font.kerning: true
                }
            }
        }
    }
}
