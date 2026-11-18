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
    width: parent ? Math.min(JamiTheme.secondaryDialogDimension,
                             Math.max(0, parent.width - 2 * JamiTheme.preferredMarginSize))
                  : JamiTheme.secondaryDialogDimension

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

        width: root.availableWidth
        spacing: 10

        Label {
            id: labelDeletion

            Layout.fillWidth: true
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
            bottomLeftRadius: root.isSIP ? JamiTheme.avatarBasedRadius : identifier.radius + 10
            bottomRightRadius: root.isSIP ? JamiTheme.avatarBasedRadius : identifier.radius + 10

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
                        Layout.fillWidth: true
                        spacing: 10

                        TextEdit {
                            id: accountAlias

                            Layout.fillWidth: true

                            font.pointSize: JamiTheme.settingsFontSize
                            font.kerning: true

                            color: JamiTheme.textColor
                            visible: text.length > 0
                            selectByMouse: true
                            readOnly: true

                            wrapMode: TextEdit.Wrap
                            text: CurrentAccount.alias
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }

                        TextEdit {
                            id: accountDisplayName

                            Layout.fillWidth: true

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true
                            color: JamiTheme.faddedFontColor

                            visible: text.length > 0 && text !== CurrentAccount.alias
                            readOnly: true
                            selectByMouse: true

                            wrapMode: TextEdit.Wrap
                            text: CurrentAccount.bestId
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
                Rectangle {
                    id: identifier

                    Layout.fillWidth: true
                    Layout.preferredHeight: identifierLayout.implicitHeight + 10
                    Layout.margins: 12
                    Layout.topMargin: 0

                    visible: !isSIP

                    radius: height / 2
                    color: JamiTheme.globalBackgroundColor

                    RowLayout {
                        id: identifierLayout

                        anchors.fill: parent
                        anchors.leftMargin: JamiTheme.preferredMarginSize
                        anchors.rightMargin: JamiTheme.preferredMarginSize

                        spacing: 10

                        Text {
                            id: identifierText

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

                            font.family: JamiTheme.ubuntuMonoFontFamily
                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true
                            color: JamiTheme.textColor

                            wrapMode: Text.WrapAnywhere
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
            Layout.preferredHeight: warningLayout.implicitHeight + 20

            radius: 8

            RowLayout {
                id: warningLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: JamiTheme.preferredMarginSize
                anchors.rightMargin: JamiTheme.preferredMarginSize

                Button {
                    id: warningIcon

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
