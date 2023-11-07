/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
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

    title: JamiStrings.deleteAccount

    closeButtonVisible: false
    button1.text: JamiStrings.optionDelete

    button1Role: DialogButtonBox.DestructiveRole
    button1.onClicked: {
        button1.enabled = false;
        busyInd.running = true;
        AccountAdapter.deleteCurrentAccount();
        close();
        accepted();
    }
    
    button2.text: JamiStrings.optionCancel
    button2Role: DialogButtonBox.RejectRole
    button2.onClicked: close();
    button1.contentColorProvider: JamiTheme.deleteRedButton


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
        anchors.centerIn: parent
        spacing: 10

        Label {
            id: labelDeletion

            Layout.alignment: Qt.AlignLeft
            Layout.maximumWidth: root.width - 4*JamiTheme.preferredMarginSize
            Layout.bottomMargin: 5

            color: JamiTheme.textColor
            text: JamiStrings.confirmDeleteQuestion

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            wrapMode: Text.Wrap
        }

        Rectangle {
            id: accountRectangle

            color: JamiTheme.backgroundRectangleColor

            Layout.preferredWidth: parent.width
            Layout.preferredHeight: userProfileDialogLayout.height
            Layout.maximumWidth: root.width - 80

            radius: 5

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
                    Layout.fillWidth: true

                    radius: 5
                    color: root.backgroundColor

                    Layout.preferredHeight: accountId.height + 10
                    Layout.margins: 10
                    Layout.topMargin: 0
                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter

                        spacing: 20

                        Text {
                            id: identifierText

                            font.pointSize: JamiTheme.textFontSize
                            text: JamiStrings.identifier

                            color: JamiTheme.faddedFontColor
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            Layout.leftMargin: JamiTheme.preferredMarginSize
                        }
                        Label {
                            id: accountId

                            Layout.alignment: Qt.AlignLeft
                            Layout.preferredWidth: root.width - 250
                            Layout.rightMargin: JamiTheme.preferredMarginSize

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

            Layout.preferredWidth: parent.width
            Layout.preferredHeight: labelWarning.height + 20
            Layout.maximumWidth: root.width - 80

            radius: 5

            RowLayout{
                id: warningLayout

                anchors.centerIn: parent
                anchors.margins: 15
                width: accountRectangle.width

                Image{
                    id: warningIcon

                    Layout.fillWidth: true
                    Layout.leftMargin: 15

                    source: JamiResources.notification_important_24dp_svg
                    fillMode: Image.PreserveAspectFit
                }

                Label {
                    id: labelWarning

                    Layout.fillWidth: true
                    Layout.margins: 15

            visible: !isSIP


            text: JamiStrings.deleteAccountInfos

            font.pointSize: JamiTheme.textFontSize
            font.kerning: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap

            color: JamiTheme.redColor
        }
    }
}
