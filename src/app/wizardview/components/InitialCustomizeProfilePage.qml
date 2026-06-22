/*
* Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
import net.jami.UI as JUI
import net.jami.SettingsView as JSV
import net.jami.MainView as JMV
import net.jami.UI as JUI

Rectangle {
    id: root

    property bool helpOpened: false
    property string alias: ""
    property bool customProfilePicture: false
    property int preferredHeight: customizeProfilePage.implicitHeight

    signal showThisPage

    color: JamiTheme.secondaryBackgroundColor
    Accessible.role: Accessible.Pane
    Accessible.name: joinJami.text
    Accessible.description: JamiStrings.customizeAccountDescription

    Connections {
        target: WizardViewStepModel

        function onMainStepChanged() {
            var currentMainStep = WizardViewStepModel.mainStep;
            if (currentMainStep === WizardViewStepModel.MainSteps.ProfileCustomization) {
                root.showThisPage();
                displayNameLineEdit.forceActiveFocus();
            }
        }
    }

    Rectangle {
        id: customizeProfilePage
        objectName: "customizeProfilePage"

        Layout.fillHeight: true
        Layout.fillWidth: true
        anchors.fill: parent

        color: JamiTheme.secondaryBackgroundColor

        ColumnLayout {
            id: displayNameColumnLayout

            spacing: JamiTheme.wizardViewPageLayoutSpacing
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
            Layout.fillWidth: true

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

            Rectangle {
                id: customRectangle
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 30
                Layout.preferredHeight: customLayout.height
                Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                Layout.fillWidth: false
                color: JamiTheme.customizeRectangleColor
                radius: 32

                RowLayout {
                    id: customLayout
                    anchors.centerIn: parent
                    width: parent.width

                    Rectangle {
                        Layout.alignment: Qt.AlignCenter
                        Layout.margins: 10

                        color: "transparent"

                        width: accountAvatar.width
                        height: accountAvatar.height

                        JUI.PhotoboothView {
                            id: accountAvatar

                            anchors.centerIn: parent

                            width: avatarSize
                            height: avatarSize
                            imageId: LRCInstance.currentAccountId

                            avatarSize: 56
                            editButton.visible: true
                            visible: customProfilePicture
                        }

                        JUI.PushButton {
                            id: editImage

                            Accessible.role: Accessible.Button
                            Accessible.name: JamiStrings.selectImage
                            Accessible.description: JamiStrings.customizeOptional

                            anchors.centerIn: parent

                            width: 56
                            height: 56

                            anchors.fill: parent

                            source: JamiResources.person_outline_black_24dp_svg
                            background.opacity: {
                                if (customProfilePicture) {
                                    if (hovered)
                                        return 0.3;
                                    else
                                        return 0;
                                } else
                                    return 1;
                            }

                            preferredSize: 56

                            normalColor: JamiTheme.customizePhotoColor
                            imageColor: accountAvatar.visible ? JamiTheme.customizeRectangleColor :
                                                                JamiTheme.whiteColor
                            hoveredColor: JamiTheme.customizePhotoHoveredColor

                            imageContainerWidth: 30

                            onClicked: {
                                var dlg = viewCoordinator.presentDialog(parent,
                                                                        "commoncomponents/JUI.PhotoboothPopup.qml",
                                                                        {
                                                                            "parent": editImage,
                                                                            "imageId":
                                                                            LRCInstance.currentAccountId,
                                                                            "newItem": false
                                                                        });
                                dlg.onImageTemporaryValidated.connect(function () {
                                    accountAvatar.visible = true;
                                    customProfilePicture = true;
                                });
                                dlg.onImageTemporaryRemoved.connect(function () {
                                    customProfilePicture = false;
                                    accountAvatar.visible = false;
                                });
                            }
                        }
                    }

                    JUI.NewMaterialTextField {
                        id: displayNameLineEdit

                        Layout.alignment: Qt.AlignLeft
                        Layout.rightMargin: 20
                        Layout.fillWidth: true

                        leadingIconSource: JamiResources.account_24dp_svg
                        placeholderText: JamiStrings.displayName

                        onModifiedTextFieldContentChanged: {
                            root.alias = displayNameLineEdit.modifiedTextFieldContent;
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: false
                Layout.topMargin: JamiTheme.preferredMarginSize
                Layout.preferredWidth: Math.min(440, root.width - JamiTheme.preferredMarginSize * 2)
                Layout.alignment: Qt.AlignCenter

                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: JamiTheme.textColor
                text: JamiStrings.customizeAccountDescription
                font.pixelSize: JamiTheme.headerFontSize
                lineHeight: JamiTheme.wizardViewTextLineHeight
            }

            JUI.NewMaterialButton {
                id: saveProfileButton

                objectName: "saveProfileButton"

                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: JamiTheme.wizardViewBlocMarginSize

                z: -1

                filledButton: true
                text: JamiStrings.saveProfile

                onClicked: {
                    AccountAdapter.setCurrAccDisplayName(root.alias);
                    WizardViewStepModel.nextStep();
                }
            }

            RowLayout {
                id: advancedButtons

                Layout.alignment: Qt.AlignCenter

                spacing: 5

                JUI.NewMaterialButton {
                    id: skipButton

                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 0.5 * JamiTheme.wizardViewBlocMarginSize

                    textButton: true
                    text: JamiStrings.skip
                    toolTipText: JamiStrings.skipProfile

                    onClicked: {
                        WizardViewStepModel.nextStep();
                    }
                }
            }
        }
    }

    JUI.NewIconButton {
        id: backButton
        JUI.QWKSetParentHitTestVisible {}

        objectName: "createAccountPageBackButton"

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: JamiTheme.wizardViewPageBackButtonMargins

        iconSize: JamiTheme.iconButtonMedium
        iconSource: JamiResources.bidirectional_arrow_back_24dp_svg
        toolTipText: JamiStrings.back
        onClicked: {
            helpOpened = false;
            WizardViewStepModel.nextStep();
        }

        Accessible.role: Accessible.Button
        Accessible.name: JamiStrings.backButton
        Accessible.description: JamiStrings.backButtonExplanation
    }

    Component.onDestruction: UtilsAdapter.setTempCreationImageFromString("", "temp")
}
