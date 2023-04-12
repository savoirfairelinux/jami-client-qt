/*
 * Copyright (C) 2019-2023 Savoir-faire Linux Inc.
 * Author: Yang Wang   <yang.wang@savoirfairelinux.com>
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

    // signal to redirect the page to main view
    signal loaderSourceChangeRequested(int sourceToLoad)
    function slotDeleteButtonClicked() {
        stackedWidget.currentIndex = AccountMigrationView.AccountMigrationStep.Synching;
        CurrentAccountToMigrate.removeCurrentAccountToMigrate();
    }
    function slotMigrationButtonClicked() {
        stackedWidget.currentIndex = AccountMigrationView.AccountMigrationStep.Synching;
        AccountAdapter.setArchivePasswordAsync(CurrentAccountToMigrate.accountId, passwordInputLineEdit.text);
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

        function onCurrentAccountToMigrateRemoved() {
            successState = true;
            passwordInputLineEdit.clear();
            stackedWidget.currentIndex = AccountMigrationView.AccountMigrationStep.PasswordEnter;
        }
        function onMigrationEnded(ok) {
            successState = ok;
            if (ok) {
                passwordInputLineEdit.clear();
                stackedWidget.currentIndex = AccountMigrationView.AccountMigrationStep.PasswordEnter;
            } else {
                timerFailureReturn.restart();
            }
        }
    }
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        anchors.fill: parent

        StackLayout {
            id: stackedWidget
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.fillWidth: true

            // Index = 0
            Rectangle {
                id: accountMigrationPage
                ColumnLayout {
                    anchors.fill: accountMigrationPage
                    spacing: 8

                    Label {
                        id: accountMigrationLabel
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight
                        font.kerning: true
                        font.pointSize: JamiTheme.headerFontSize
                        horizontalAlignment: Text.AlignLeft
                        text: JamiStrings.authenticationRequired
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                    }
                    Label {
                        id: migrationReasonLabel
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: JamiTheme.preferredFieldHeight
                        font.kerning: true
                        font.pointSize: JamiTheme.textFontSize
                        horizontalAlignment: Text.AlignLeft
                        text: JamiStrings.migrationReason
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                    }
                    Avatar {
                        id: avatarLabel
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 200
                        Layout.preferredWidth: 200
                        imageId: CurrentAccountToMigrate.accountId
                        mode: Avatar.Mode.Account
                        showPresenceIndicator: false
                    }
                    GridLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.leftMargin: JamiTheme.preferredMarginSize
                        Layout.rightMargin: JamiTheme.preferredMarginSize
                        columnSpacing: 8
                        columns: 2
                        rowSpacing: 8
                        rows: 4

                        // 1st Row
                        Label {
                            id: aliasLabel
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            font.kerning: true
                            font.pointSize: JamiTheme.textFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: JamiStrings.alias
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            id: aliasInputLabel
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            font.kerning: true
                            font.pointSize: JamiTheme.textFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: {
                                if (CurrentAccountToMigrate.alias.length !== 0) {
                                    return CurrentAccountToMigrate.alias;
                                } else {
                                    return JamiStrings.notAvailable;
                                }
                            }
                            verticalAlignment: Text.AlignVCenter
                        }

                        // 2nd Row
                        Label {
                            id: usernameLabel
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            font.kerning: true
                            font.pointSize: JamiTheme.textFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: JamiStrings.username
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            id: usernameInputLabel
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            font.kerning: true
                            font.pointSize: JamiTheme.textFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: {
                                if (CurrentAccountToMigrate.username.length !== 0) {
                                    return CurrentAccountToMigrate.username;
                                } else if (CurrentAccountToMigrate.managerUsername.length !== 0) {
                                    return CurrentAccountToMigrate.managerUsername;
                                } else {
                                    return JamiStrings.notAvailable;
                                }
                            }
                            verticalAlignment: Text.AlignVCenter
                        }

                        // 3rd Row
                        Label {
                            id: managerUriLabel
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            font.kerning: true
                            font.pointSize: JamiTheme.textFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: JamiStrings.jamsServer
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            id: managerUriInputLabel
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            font.kerning: true
                            font.pointSize: JamiTheme.textFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: {
                                if (CurrentAccountToMigrate.managerUri.length !== 0) {
                                    return CurrentAccountToMigrate.managerUri;
                                } else {
                                    return JamiStrings.notAvailable;
                                }
                            }
                            verticalAlignment: Text.AlignVCenter
                        }

                        // 4th Row
                        Label {
                            id: passwordLabel
                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            font.kerning: true
                            font.pointSize: JamiTheme.textFontSize
                            horizontalAlignment: Text.AlignLeft
                            text: JamiStrings.password
                            verticalAlignment: Text.AlignVCenter
                        }
                        MaterialLineEdit {
                            id: passwordInputLineEdit
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: 48
                            Layout.preferredWidth: JamiTheme.preferredFieldWidth
                            echoMode: TextInput.Password
                            horizontalAlignment: Text.AlignLeft
                            placeholderText: JamiStrings.password
                            verticalAlignment: Text.AlignVCenter

                            onAccepted: slotMigrationButtonClicked()
                        }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: JamiTheme.preferredMarginSize
                        Layout.fillWidth: true
                        spacing: 80

                        MaterialButton {
                            id: migrationPushButton
                            Layout.alignment: Qt.AlignLeft
                            color: enabled ? JamiTheme.buttonTintedBlack : JamiTheme.buttonTintedGrey
                            enabled: passwordInputLineEdit.text.length > 0
                            hoveredColor: JamiTheme.buttonTintedBlackHovered
                            preferredWidth: JamiTheme.preferredFieldWidth / 2
                            pressedColor: JamiTheme.buttonTintedBlackPressed
                            secondary: true
                            text: JamiStrings.authenticate

                            onClicked: slotMigrationButtonClicked()
                        }
                        MaterialButton {
                            id: deleteAccountPushButton
                            Layout.alignment: Qt.AlignRight
                            color: JamiTheme.buttonTintedRed
                            hoveredColor: JamiTheme.buttonTintedRedHovered
                            preferredWidth: JamiTheme.preferredFieldWidth / 2
                            pressedColor: JamiTheme.buttonTintedRedPressed
                            secondary: true
                            text: JamiStrings.deleteAccount

                            onClicked: slotDeleteButtonClicked()
                        }
                    }
                }
            }

            // Index = 1
            Rectangle {
                id: migrationWaitingPage
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    height: stackedWidget.height
                    spacing: 8
                    width: stackedWidget.width

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        spacing: 8

                        ResponsiveImage {
                            id: errorLabel
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: 200
                            Layout.preferredWidth: 200
                            color: JamiTheme.redColor
                            containerHeight: Layout.preferredHeight
                            containerWidth: Layout.preferredWidth
                            source: JamiResources.round_remove_circle_24dp_svg
                            visible: !successState
                        }
                        AnimatedImage {
                            id: spinnerLabel
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: 200
                            Layout.preferredWidth: 200
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            playing: successState
                            source: JamiResources.jami_eclipse_spinner_gif
                            visible: successState
                        }
                    }
                    Label {
                        id: progressLabel
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 80
                        Layout.fillWidth: true
                        color: successState ? JamiTheme.textColor : JamiTheme.redColor
                        font.kerning: true
                        font.pointSize: JamiTheme.textFontSize + 5
                        horizontalAlignment: Text.AlignHCenter
                        text: successState ? JamiStrings.inProgress : JamiStrings.authenticationFailed
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Label.WordWrap
                    }
                }
            }
        }
    }
}
