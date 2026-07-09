/*
 * Copyright (C) 2019-2026 Savoir-faire Linux Inc.
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
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "commoncomponents"

// Account Migration Dialog for migrating account
BaseView {
    id: root

    enum AccountMigrationStep {
        PasswordEnter,
        Synching
    }

    property bool successState: true

    function slotMigrationButtonClicked() {
        stackedWidget.currentIndex = AccountMigrationView.AccountMigrationStep.Synching;
        AccountAdapter.setArchivePasswordAsync(CurrentAccountToMigrate.accountId, passwordInputLineEdit.modifiedTextFieldContent);
    }

    function slotDeleteButtonClicked() {
        stackedWidget.currentIndex = AccountMigrationView.AccountMigrationStep.Synching;
        CurrentAccountToMigrate.removeCurrentAccountToMigrate();
    }

    Timer {
        id: timerFailureReturn

        interval: 1000
        repeat: false

        onTriggered: {
            stackedWidget.currentIndex = AccountMigrationView.AccountMigrationStep.PasswordEnter;
            successState = true;
        }
    }

    Connections {
        id: connectionMigrationEnded

        target: CurrentAccountToMigrate

        function onMigrationEnded(ok) {
            successState = ok;
            if (ok) {
                passwordInputLineEdit.modifiedTextFieldContent = "";
                stackedWidget.currentIndex = AccountMigrationView.AccountMigrationStep.PasswordEnter;
            } else {
                timerFailureReturn.restart();
            }
        }

        function onCurrentAccountToMigrateRemoved() {
            successState = true;
            passwordInputLineEdit.modifiedTextFieldContent = "";
            stackedWidget.currentIndex = AccountMigrationView.AccountMigrationStep.PasswordEnter;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Layout.alignment: Qt.AlignHCenter

        StackLayout {
            id: stackedWidget

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter

            // Index = 0
            Rectangle {
                id: accountMigrationPage

                color: JamiTheme.globalBackgroundColor

                ColumnLayout {
                    anchors.fill: accountMigrationPage

                    spacing: 8

                    Label {
                        id: accountMigrationLabel

                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight

                        text: JamiStrings.authenticationRequired
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        color: JamiTheme.textColor

                        font.pointSize: JamiTheme.headerFontSize
                        font.kerning: true

                        wrapMode: Text.Wrap
                    }

                    Label {
                        id: migrationReasonLabel

                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight

                        text: JamiStrings.migrationReason
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        color: JamiTheme.textColor

                        wrapMode: Text.Wrap

                        font.pointSize: JamiTheme.textFontSize
                        font.kerning: true
                    }

                    Avatar {
                        id: avatarLabel

                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 200

                        Layout.alignment: Qt.AlignHCenter

                        showPresenceIndicator: false
                        mode: Avatar.Mode.Account
                        imageId: CurrentAccountToMigrate.accountId
                    }

                    GridLayout {
                        rows: 4
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        Layout.rightMargin: JamiTheme.preferredMarginSize

                        // 1st Row
                        Label {
                            id: aliasLabel

                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight

                            text: JamiStrings.alias
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true

                            visible: aliasInputLabel.visible
                        }

                        Label {
                            id: aliasInputLabel

                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight

                            text: CurrentAccountToMigrate.alias.length !== 0 ? CurrentAccountToMigrate.alias : ""
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true

                            visible: text.length > 0
                        }

                        // 2nd Row
                        Label {
                            id: usernameLabel

                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight

                            text: JamiStrings.username
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true

                            visible: usernameInputLabel.visible
                        }

                        Label {
                            id: usernameInputLabel

                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight

                            text: {
                                if (CurrentAccountToMigrate.username.length !== 0) {
                                    return CurrentAccountToMigrate.username;
                                } else if (CurrentAccountToMigrate.managerUsername.length !== 0) {
                                    return CurrentAccountToMigrate.managerUsername;
                                } else {
                                    return "";
                                }
                            }
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true

                            visible: text.length > 0
                        }

                        // 3rd Row
                        Label {
                            id: managerUriLabel

                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight

                            text: JamiStrings.jamsServer
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true

                            visible: managerUriInputLabel.visible
                        }

                        Label {
                            id: managerUriInputLabel

                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight

                            text: CurrentAccountToMigrate.managerUri.length !== 0 ? CurrentAccountToMigrate.managerUri : ""
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true

                            visible: text.length > 0
                        }

                        // 4th Row
                        Label {
                            id: passwordLabel

                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight

                            text: JamiStrings.password
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor

                            font.pointSize: JamiTheme.textFontSize
                            font.kerning: true
                        }

                        NewMaterialTextField {
                            id: passwordInputLineEdit

                            Layout.fillWidth: false
                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            Layout.alignment: Qt.AlignHCenter

                            placeholderText: JamiStrings.password
                            echoMode: TextInput.Password
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: JamiTheme.preferredMarginSize

                        spacing: 80

                        NewMaterialButton {
                            id: migrationPushButton

                            Layout.alignment: Qt.AlignLeft

                            outlinedButton: true
                            iconSource: JamiResources.key_black_24dp_svg

                            text: JamiStrings.authenticate

                            enabled: passwordInputLineEdit.modifiedTextFieldContent.length > 0

                            onClicked: slotMigrationButtonClicked()
                        }

                        NewMaterialButton {
                            id: deleteAccountPushButton

                            Layout.alignment: Qt.AlignRight

                            outlinedButton: true
                            color: JamiTheme.buttonTintedRed
                            iconSource: JamiResources.delete_forever_24dp_svg

                            text: JamiStrings.deleteAccount

                            onClicked: {
                                var dlg = viewCoordinator.presentDialog(appWindow, "../../commoncomponents/ConfirmDialog.qml", {
                                                                            "titleText": JamiStrings.confirmAction,
                                                                            "textLabel": JamiStrings.confirmDeleteAccount,
                                                                            "confirmLabel": JamiStrings.deleteAccount
                                                                        });
                                dlg.accepted.connect(function() {
                                    slotDeleteButtonClicked()
                                });
                            }
                        }
                    }
                }
            }

            // Index = 1
            Rectangle {
                id: migrationWaitingPage

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter

                    width: stackedWidget.width
                    height: stackedWidget.height

                    spacing: 8

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true

                        spacing: 8

                        ResponsiveImage {
                            id: errorLabel

                            Layout.preferredWidth: 200
                            Layout.preferredHeight: 200
                            Layout.alignment: Qt.AlignHCenter

                            containerHeight: Layout.preferredHeight
                            containerWidth: Layout.preferredWidth

                            visible: !successState

                            source: JamiResources.round_remove_circle_24dp_svg
                            color: JamiTheme.redColor
                        }

                        Item {
                            id: spinnerLabel
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 194
                            Layout.preferredHeight: 194

                            visible: successState

                            SpinningAnimation {
                                id: animation

                                anchors.fill: parent
                                mode: SpinningAnimation.Mode.Radial
                                color: JamiTheme.tintedBlue
                                spinningAnimationWidth: 6
                            }
                        }
                    }

                    Label {
                        id: progressLabel

                        Layout.fillWidth: true
                        Layout.bottomMargin: 80
                        Layout.alignment: Qt.AlignHCenter

                        text: successState ? JamiStrings.inProgress : JamiStrings.authenticationFailed
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        color: successState ? JamiTheme.textColor : JamiTheme.redColor

                        font.pointSize: JamiTheme.textFontSize + 5
                        font.kerning: true

                        wrapMode: Label.WordWrap
                    }
                }
            }
        }
    }
}
