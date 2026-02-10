/*
 * Copyright (C) 2022-2026 Savoir-faire Linux Inc.
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
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Enums 1.1
import net.jami.Models 1.1
import "../../commoncomponents"
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

ListSelectionView {
    id: viewNode

    objectName: "WelcomePage"

    splitViewStateKey: "Main"
    hideMajorPaneInSinglePaneMode: true

    color: JamiTheme.transparentColor

    onPresented: LRCInstance.deselectConversation()

    // Stub when view coordinator does not create views (e.g. test harness).
    property Item _leftPaneStub: Item {
        function deselect() {}
        function select(_index) {}
    }
    leftPaneItem: viewCoordinator.getView("SidePanel", !viewCoordinator.isTestContext) || _leftPaneStub

    Accessible.role: Accessible.Pane
    Accessible.name: title
    Accessible.description: JamiStrings.description

    property variant uiCustomization: CurrentAccount.uiCustomization

    onUiCustomizationChanged: {
        updateUiFlags();
    }

    Component.onCompleted: {
        updateUiFlags();
    }

    property bool hasCustomUi: false

    property bool hasTitle: false
    property bool hasDescription: true

    property bool hasCustomTitle: false
    property string title: JamiStrings.welcomeToJami

    property bool hasCustomDescription: false
    property string description: JamiStrings.hereIsIdentifier

    property bool hasLogo: true
    property bool hasTips: true

    property bool hasOverridenBgImage: false
    property string overridenImageUrl: ""

    //logoSize has to be between 0 and 1
    property real logoSize: 1

    property bool hasCustomLogo: false
    property string customLogoUrl: ""

    property bool hasWelcomeInfo: true
    property bool hasBottomId: false
    property bool hasTopId: false

    property color tipBoxAndIdColor: JamiTheme.welcomeBlockColor

    property color mainBoxColor: "transparent"

    property color tipsTextColor: JamiTheme.textColor
    property color mainBoxTextColor: JamiTheme.textColor
    property color contentTipAndIdColor: JamiTheme.tintedBlue

    Connections {
        target: UtilsAdapter
        function onChangeLanguage() {
            title = hasCustomUi && uiCustomization.title !== undefined ? uiCustomization.title : JamiStrings.welcomeToJami;
            description = hasCustomUi && uiCustomization.description !== undefined ? uiCustomization.description : JamiStrings.hereIsIdentifier;
        }
    }

    Connections {
        target: JamiTheme
        function onDarkThemeChanged() {
            tipBoxAndIdColor = (hasCustomUi && uiCustomization.tipBoxAndIdColor !== undefined) ? uiCustomization.tipBoxAndIdColor : JamiTheme.welcomeBlockColor;
            tipsTextColor = (hasCustomUi && uiCustomization.tipBoxAndIdColor !== undefined) ? (UtilsAdapter.luma(tipBoxAndIdColor) ? JamiTheme.whiteColor : JamiTheme.blackColor) : JamiTheme.textColor;
            mainBoxTextColor = (hasCustomUi && uiCustomization.mainBoxColor !== undefined) ? (UtilsAdapter.luma(mainBoxColor) ? JamiTheme.whiteColor : JamiTheme.blackColor) : JamiTheme.textColor;
            contentTipAndIdColor = (hasCustomUi && uiCustomization.tipBoxAndIdColor !== undefined) ? (UtilsAdapter.luma(tipBoxAndIdColor) ? JamiTheme.lightTintedBlue : JamiTheme.darkTintedBlue) : JamiTheme.tintedBlue;
        }
    }

    function updateUiFlags() {
        hasCustomUi = Object.keys(uiCustomization).length > 0;
        hasTitle = hasCustomUi ? uiCustomization.title !== "" : false;
        hasDescription = hasCustomUi ? uiCustomization.description !== "" : true;
        title = hasCustomUi && uiCustomization.title !== undefined ? uiCustomization.title : JamiStrings.welcomeToJami;
        description = hasCustomUi && uiCustomization.description !== undefined ? uiCustomization.description : JamiStrings.hereIsIdentifier;
        hasLogo = hasCustomUi ? uiCustomization.logoUrl !== "" : true;
        hasTips = hasCustomUi ? uiCustomization.areTipsEnabled : true;
        const bgOverride = AccountSettingsManager.accountSettingsPropertyMap.backgroundUri;
        overridenImageUrl = bgOverride === undefined ? "" : bgOverride;
        hasOverridenBgImage = bgOverride !== undefined && bgOverride !== "";
        hasCustomLogo = (hasCustomUi && hasLogo && uiCustomization.logoUrl !== undefined);
        customLogoUrl = hasCustomLogo ? CurrentAccount.managerUri + uiCustomization.logoUrl : "";
        hasWelcomeInfo = hasTitle || hasDescription;
        hasBottomId = !hasWelcomeInfo && !hasTips && hasLogo;
        hasTopId = !hasWelcomeInfo && (!hasLogo || hasTips);
        logoSize = (hasCustomUi && uiCustomization.logoSize !== undefined) ? uiCustomization.logoSize / 100 : 1;
        tipBoxAndIdColor = (hasCustomUi && uiCustomization.tipBoxAndIdColor !== undefined) ? uiCustomization.tipBoxAndIdColor : JamiTheme.welcomeBlockColor;
        mainBoxColor = (hasCustomUi && uiCustomization.mainBoxColor !== undefined) ? uiCustomization.mainBoxColor : "transparent";
        tipsTextColor = (hasCustomUi && uiCustomization.tipBoxAndIdColor !== undefined) ? (UtilsAdapter.luma(tipBoxAndIdColor) ? JamiTheme.whiteColor : JamiTheme.blackColor) : JamiTheme.textColor;
        mainBoxTextColor = (hasCustomUi && uiCustomization.mainBoxColor !== undefined) ? (UtilsAdapter.luma(mainBoxColor) ? JamiTheme.whiteColor : JamiTheme.blackColor) : JamiTheme.textColor;
        contentTipAndIdColor = (hasCustomUi && uiCustomization.tipBoxAndIdColor !== undefined) ? (UtilsAdapter.luma(tipBoxAndIdColor) ? JamiTheme.lightTintedBlue : JamiTheme.darkTintedBlue) : JamiTheme.tintedBlue;
    }

    rightPaneItem: JamiFlickable {
        id: root
        objectName: "WelcomeLayout"

        anchors.fill: parent
        property int thresholdSize: 700
        property int thresholdHeight: 570

        MouseArea {
            anchors.fill: parent
            enabled: visible
            onClicked: root.forceActiveFocus()
        }

        contentHeight: Math.max(root.height, welcomePageLayout.implicitHeight)
        contentWidth: Math.max(300, root.width)

        ColumnLayout {
            id: welcomePageLayout
            width: Math.max(300, root.width)
            height: parent.height

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter

                ColumnLayout {
                    anchors.centerIn: parent

                    Loader {
                        id: loader_welcomeLogo
                        objectName: "loader_welcomeLogo"
                        active: viewNode.hasLogo
                        sourceComponent: WelcomeLogo {
                            logoSize: viewNode.logoSize
                        }
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: active ? item.getWidth() : 0
                        Layout.preferredHeight: active ? item.getHeight() : 0
                        Layout.topMargin: 20
                    }

                    Loader {
                        id: loader_welcomeInfo
                        objectName: "loader_welcomeInfo"
                        sourceComponent: WelcomeInfo {
                            backgroundColor: viewNode.mainBoxColor
                            hasTitle: viewNode.hasTitle
                            hasDescription: viewNode.hasDescription
                            title: viewNode.title
                            description: viewNode.description
                            idColor: viewNode.tipBoxAndIdColor
                            textColor: mainBoxTextColor
                            contentIdColor: viewNode.contentTipAndIdColor
                        }
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: item.getHeight()
                        Layout.preferredWidth: 500
                    }
                }
            }

            Loader {
                id: loader_tipsRow
                objectName: "loader_tipsRow"
                active: viewNode.hasTips && root.height > root.thresholdHeight
                sourceComponent: TipsRow {
                    tipsColor: viewNode.tipBoxAndIdColor
                    tipsTextColor: viewNode.tipsTextColor
                    iconColor: viewNode.contentTipAndIdColor
                }
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: active ? item.getHeight() : 0
                Layout.preferredWidth: {
                    if (!active) {
                        return 0;
                    } else {
                        if (item.visibleTipBoxCount <= 2) {
                            if (item.visibleTipBoxCount <= 1)
                                return JamiTheme.tipBoxWidth;
                            return JamiTheme.welcomeShortGridWidth;
                        } else {
                            if (root.width > root.thresholdSize) {
                                return JamiTheme.welcomeGridWidth;
                            } else {
                                return JamiTheme.welcomeShortGridWidth;
                            }
                        }
                    }
                }
                focus: true
            }

            Connections {
                target: CurrentAccount
                function onIdChanged() {
                    //Making sure the tips are refreshed when changing user
                    loader_tipsRow.active = false;
                    loader_tipsRow.active = Qt.binding(function () {
                        return viewNode.hasTips && root.height > root.thresholdHeight;
                    });
                }
            }

            Item {
                id: bottomRow
                Layout.preferredWidth: Math.max(300, root.width)
                Layout.preferredHeight: aboutJami.height
                Layout.margins: JamiTheme.welcomePageSpacing / 2
                Layout.alignment: Qt.AlignHCenter

                NewMaterialButton {
                    id: aboutJami

                    objectName: "aboutJami"

                    anchors.horizontalCenter: parent.horizontalCenter

                    textButton: true
                    text: JamiStrings.aboutJami

                    onClicked: viewCoordinator.presentDialog(appWindow, "mainview/components/AboutPopUp.qml")
                }

                NewIconButton {
                    id: btnKeyboard

                    anchors.right: parent.right
                    anchors.rightMargin: JamiTheme.preferredMarginSize

                    iconSize: JamiTheme.iconButtonMedium
                    iconSource: JamiResources.keyboard_black_24dp_svg
                    icon.color: JamiTheme.buttonTintedBlue
                    toolTipText: JamiStrings.keyboardShortcuts

                    onClicked: {
                        KeyboardShortcutTableCreation.createKeyboardShortcutTableWindowObject(appWindow);
                        KeyboardShortcutTableCreation.showKeyboardShortcutTableWindow();
                    }
                }
            }
        }
    }
}
