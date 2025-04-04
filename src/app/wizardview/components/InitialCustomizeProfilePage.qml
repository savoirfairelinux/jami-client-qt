/*
 * Copyright (C) 2021-2025 Savoir-faire Linux Inc.
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
import QtQuick.Layouts
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import Qt5Compat.GraphicalEffects
import "../"
import "../../commoncomponents"
import "../../settingsview/components"
import "../../mainview/components"
import "../../commoncomponents/contextmenu"

Rectangle {
    id: root

    property bool isRendezVous: false
    property bool helpOpened: false
    property int preferredHeight: createAccountStack.implicitHeight
    property string alias: ""

    signal showThisPage

    function initializeOnShowUp(isRdv) {
        root.isRendezVous = isRdv;
        createAccountStack.currentIndex = 0;
        clearAllTextFields();
    }

    function clearAllTextFields() {
        finishStartupButton.enabled = true;
    }

    color: JamiTheme.secondaryBackgroundColor

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            var currentMainStep = WizardViewStepModel.mainStep;
            if (currentMainStep === WizardViewStepModel.MainSteps.ProfileCustomization) {
                createAccountStack.currentIndex = nameRegistrationPage.stackIndex;
                root.showThisPage();
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
            adviceBox.checked = false;
        }
    }

    StackLayout {
        id: createAccountStack
        Layout.minimumHeight: 1000
        objectName: "createAccountStack"
        anchors.fill: parent

        Rectangle {
            id: nameRegistrationPage

            objectName: "nameRegistrationPage"

            Layout.fillHeight: true
            Layout.fillWidth: true

            property int stackIndex: 0

            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {
                id: usernameColumnLayout

                spacing: JamiTheme.wizardViewPageLayoutSpacing

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(508, root.width - 100)

                Text {
                    id: joinJami

                    text: JamiStrings.customizeProfileOptional
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.preferredMarginSize
                    Layout.preferredWidth: Math.min(360, root.width - JamiTheme.preferredMarginSize * 2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    color: JamiTheme.textColor
                    font.pixelSize: JamiTheme.wizardViewTitleFontPixelSize
                    wrapMode: Text.WordWrap
                }

                ColumnLayout {
                    id: customColumnLayout
                    spacing: 20
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                    Layout.fillWidth: false
                    width: Math.max(508, root.width - 100)

                    Rectangle {
                        id: customRectangle
                        Layout.topMargin: 30
                        Layout.preferredHeight: customLayout.height
                        Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                        Layout.fillWidth: false
                        color: JamiTheme.customizeRectangleColor
                        radius: 5

                        RowLayout {
                            id: customLayout
                            anchors.centerIn: parent
                            width: parent.width

                            Rectangle {
                                Layout.alignment: Qt.AlignLeft | Qt.AlignCenter
                                Layout.margins: 10

                                color: "transparent"

                                width: accountAvatar.width
                                height: accountAvatar.height

                                PhotoboothView {
                                    id: accountAvatar

                                    anchors.centerIn: parent

                                    width: avatarSize
                                    height: avatarSize

                                    avatarSize: 56
                                    editButton.visible: false
                                    visible: UtilsAdapter.tempCreationImage(imageId).length !== 0
                                }

                                PushButton {
                                    id: editImage

                                    anchors.centerIn: parent

                                    width: 56
                                    height: 56

                                    anchors.fill: parent

                                    source: JamiResources.person_outline_black_24dp_svg
                                    background.opacity: {
                                        if (accountAvatar.visible) {
                                            if (hovered)
                                                return 0.3;
                                            else
                                                return 0;
                                        } else
                                            return 1;
                                    }

                                    preferredSize: 56

                                    normalColor: JamiTheme.customizePhotoColor
                                    imageColor: accountAvatar.visible ? JamiTheme.customizeRectangleColor : JamiTheme.whiteColor
                                    hoveredColor: JamiTheme.customizePhotoHoveredColor

                                    imageContainerWidth: 30

                                    onClicked: {
                                        var dlg = viewCoordinator.presentDialog(parent, "commoncomponents/PhotoboothPopup.qml", {
                                                "parent": editImage,
                                                "imageId": LRCInstance.currentAccountId,
                                                "newItem": false
                                            });
                                        dlg.onImageValidated.connect(function () {
                                                if (UtilsAdapter.tempCreationImage(LRCInstance.currentAccountId).length !== 0) {
                                                    accountAvatar.visible = true;
                                                }
                                            });
                                        dlg.onImageRemoved.connect(function () {
                                                if (UtilsAdapter.tempCreationImage(LRCInstance.currentAccountId).length !== 0) {
                                                    accountAvatar.visible = true;
                                                }
                                            });
                                    }
                                }
                            }

                            ModalTextEdit {
                                id: displayNameLineEdit

                                Layout.alignment: Qt.AlignLeft
                                Layout.rightMargin: 10
                                Layout.fillWidth: true

                                placeholderText: JamiStrings.displayName

                                onDynamicTextChanged: {
                                    root.alias = displayNameLineEdit.dynamicText;
                                }
                            }
                        }
                    }

                    Text {

                        Layout.fillWidth: false
                        Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                        Layout.alignment: Qt.AlignLeft
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: JamiTheme.textColor
                        text: JamiStrings.customizeProfileDescription
                        font.pixelSize: JamiTheme.headerFontSize
                        lineHeight: JamiTheme.wizardViewTextLineHeight
                    }
                }

                MaterialButton {
                    id: finishStartupButton
                    z: -1

                    TextMetrics {
                        id: textSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.capitalization: Font.AllUppercase
                        text: finishStartupButton.text
                    }

                    objectName: "finishStartupButton"

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: JamiTheme.wizardViewBlocMarginSize
                    primary: true
                    preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding

                    font.capitalization: Font.AllUppercase
                    color: enabled ? JamiTheme.buttonTintedBlue : JamiTheme.buttonTintedGrey
                    text: JamiStrings.finishStartup
                    enabled: true

                    KeyNavigation.tab: backButton
                    KeyNavigation.up: displayNameLineEdit
                    KeyNavigation.down: backButton

                    onClicked: {
                        AccountAdapter.setCurrAccDisplayName(root.alias)
                        WizardViewStepModel.nextStep();
                    }
                }
            }

        }
    }

    JamiPushButton {
        id: backButton
        QWKSetParentHitTestVisible {
        }

        objectName: "createAccountPageBackButton"

        preferredSize: 36
        imageContainerWidth: 20
        source: JamiResources.ic_arrow_back_24dp_svg

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        KeyNavigation.tab: adviceBox
        KeyNavigation.down: KeyNavigation.tab

        onClicked: {
            adviceBox.checked = false;
            if (createAccountStack.currentIndex > 0) {
                createAccountStack.currentIndex--;
            } else {
                WizardViewStepModel.previousStep();
                helpOpened = false;
            }
        }
    }

    JamiPushButton {
        id: adviceBox
        z: 1

        preferredSize: 36
        checkedImageColor: JamiTheme.chatviewButtonColor

        anchors.right: parent.right

        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        source: JamiResources._black_24dp_svg

        checkable: true

        onClicked: {
            if (!helpOpened) {
                checked = true;
                helpOpened = true;
                var dlg = viewCoordinator.presentDialog(appWindow, "wizardview/components/GoodToKnowPopup.qml");
                dlg.accepted.connect(function () {
                        checked = false;
                        helpOpened = false;
                    });
            }
        }

        KeyNavigation.tab: backButton
        KeyNavigation.up: backButton
        KeyNavigation.down: KeyNavigation.tab
    }
    //Component.onDestruction: UtilsAdapter.setTempCreationImageFromString("", "temp")
}
