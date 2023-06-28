/*
 * Copyright (C) 2022-2023 Savoir-faire Linux Inc.
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
import "../js/keyboardshortcuttablecreation.js" as KeyboardShortcutTableCreation

ListSelectionView {
    id: viewNode

    objectName: "WelcomePage"

    splitViewStateKey: "Main"
    hideRightPaneInSinglePaneMode: true

    color: JamiTheme.secondaryBackgroundColor

    onPresented: LRCInstance.deselectConversation()
    leftPaneItem: viewCoordinator.getView("SidePanel")

    property variant uiCustomization: CurrentAccount.uiCustomization

    onUiCustomizationChanged: {
        updateUiFlags();
    }

    Component.onCompleted: {
        updateUiFlags();
    }

    property bool hasCustomUi: false

    property bool hasTitle: true
    property bool hasDescription: true

    property bool hasCustomTitle: false
    property string customTitle: ""

    property bool hasCustomDescription: false
    property string customDescription: ""

    property bool hasLogo: true
    property bool hasTips: true

    property bool hasCustomBgImage: false
    property string customBgUrl: ""

    property bool hasCustomBgColor: false
    property string customBgColor: ""

    property bool hasCustomLogo: false
    property string customLogoUrl: ""

    property bool hasWelcomeInfo: true
    property bool hasBottomId: false
    property bool hasTopId: false

    function updateUiFlags() {
        hasCustomUi = Object.keys(uiCustomization).length > 0;
        hasTitle = hasCustomUi ? uiCustomization.title !== "" : true;
        hasDescription = hasCustomUi ? uiCustomization.description !== "" : true;
        hasCustomTitle = (hasCustomUi && hasTitle && uiCustomization.title !== undefined);
        customTitle = hasCustomTitle ? uiCustomization.title : "";
        hasCustomDescription = (hasCustomUi && hasDescription && uiCustomization.description !== undefined);
        customDescription = hasCustomDescription ? uiCustomization.description : "";
        hasLogo = hasCustomUi ? uiCustomization.logoUrl !== "" : true;
        hasTips = hasCustomUi ? uiCustomization.areTipsEnabled : true;
        hasCustomBgImage = (hasCustomUi && uiCustomization.backgroundType === "image");
        customBgUrl = hasCustomBgImage ? (CurrentAccount.managerUri + uiCustomization.backgroundColorOrUrl) : "";
        hasCustomBgColor = (hasCustomUi && uiCustomization.backgroundType === "color");
        customBgColor = hasCustomBgColor ? uiCustomization.backgroundColorOrUrl : "";
        hasCustomLogo = (hasCustomUi && hasLogo && uiCustomization.logoUrl !== undefined);
        customLogoUrl = hasCustomLogo ? CurrentAccount.managerUri + uiCustomization.logoUrl : "";
        hasWelcomeInfo = hasTitle || hasDescription;
        hasBottomId = !hasWelcomeInfo && !hasTips && hasLogo;
        hasTopId = !hasWelcomeInfo && (!hasLogo || hasTips);
    }

    rightPaneItem: JamiFlickable {
        id: root
        anchors.fill: parent
        property int thresholdSize: 800

        MouseArea {
            anchors.fill: parent
            enabled: visible
            onClicked: root.forceActiveFocus()
        }

        contentHeight: Math.max(root.height, welcomePageLayout.implicitHeight)
        contentWidth: Math.max(300, root.width)

        Rectangle {
            id: bgRect
            anchors.fill: parent
            color: hasCustomBgColor ? customBgColor : "transparent"
        }

        CachedImage {
            id: cachedImgLogo
            downloadUrl: hasCustomBgImage ? customBgUrl : ""
            visible: hasCustomBgImage
            anchors.fill: parent
            opacity: visible ? 1 : 0
            localPath: UtilsAdapter.getCachePath() + "/" + CurrentAccount.id + "/welcomeview/" + UtilsAdapter.base64Encode(downloadUrl) + fileExtension
            imageFillMode: Image.PreserveAspectCrop
        }

        Item {
            id: welcomePageLayout
            width: Math.max(300, root.width)
            height: parent.height

            Item {
                anchors.centerIn: parent
                height: 500
                width: 800
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: JamiTheme.welcomePageSpacing
                    RowLayout {
                        id: topRowLayout
                        Layout.preferredHeight: childrenRect.height
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0

                        Loader {
                            id: loader_welcomeLogo
                            objectName: "loader_welcomeLogo"
                            active: viewNode.hasLogo && ((root.width > root.thresholdSize) || (!loader_welcomeInfo.active && !loader_topJamiId.active))
                            source: "WelcomeLogo.qml"
                            Layout.preferredWidth: active ? item.getWidth() : 0
                            Layout.preferredHeight: active ? item.getHeight() : 0
                            Layout.rightMargin: active && (loader_welcomeInfo.active || loader_topJamiId.active) ? JamiTheme.welcomePageSpacing : 0
                        }

                        Loader {
                            id: loader_welcomeInfo
                            objectName: "loader_welcomeInfo"
                            active: viewNode.hasWelcomeInfo
                            source: "WelcomeInfo.qml"
                            Layout.preferredHeight: active ? item.getHeight() : 0
                            Layout.preferredWidth: {
                                if (!active) {
                                    return 0;
                                } else {
                                    if (root.width <= root.thresholdSize)
                                        return JamiTheme.welcomeShortGridWidth;
                                    else if (loader_welcomeInfo.item && loader_welcomeInfo.item.isLong) {
                                        return JamiTheme.welcomeGridWidth;
                                    } else {
                                        return JamiTheme.welcomeHalfGridWidth;
                                    }
                                }
                            }
                        }

                        Loader {
                            id: loader_topJamiId
                            objectName: "loader_topJamiId"
                            active: viewNode.hasTopId
                            source: "../../commoncomponents/JamiIdentifier.qml"
                            Layout.preferredHeight: active ? item.getHeight() : 0
                            Layout.preferredWidth: {
                                if (!active) {
                                    return 0;
                                } else {
                                    if (root.width <= root.thresholdSize)
                                        return JamiTheme.welcomeShortGridWidth;
                                    else if (loader_topJamiId.item && loader_topJamiId.item.isLong) {
                                        return JamiTheme.welcomeGridWidth;
                                    } else {
                                        return JamiTheme.welcomeHalfGridWidth;
                                    }
                                }
                            }
                        }

                        Binding {
                            target: loader_welcomeInfo.item
                            property: "isLong"
                            value: {
                                if (viewNode.hasLogo)
                                    return false;
                                else {
                                    return root.width > root.thresholdSize;
                                }
                            }
                            when: root.widthChanged
                        }

                        Binding {
                            target: loader_topJamiId.item
                            property: "isLong"
                            value: {
                                if (viewNode.hasLogo)
                                    return false;
                                else {
                                    return root.width > root.thresholdSize;
                                }
                            }
                            when: root.widthChanged
                        }

                        Binding {
                            target: loader_welcomeLogo.item
                            property: "alwaysVisible"
                            value: !loader_welcomeInfo.active && !loader_topJamiId.active
                        }

                        Binding {
                            target: loader_topJamiId.item
                            property: "backgroundColor"
                            value: JamiTheme.backgroundColor
                        }
                    }

                    RowLayout {
                        id: bottomRowLayout

                        Layout.preferredHeight: childrenRect.height
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0

                        Loader {
                            id: loader_bottomJamiIdentifier
                            objectName: "loader_bottomJamiIdentifier"
                            active: viewNode.hasBottomId
                            source: "../../commoncomponents/JamiIdentifier.qml"
                            Layout.preferredHeight: active ? item.getHeight() : 0
                            Layout.preferredWidth: {
                                if (!active) {
                                    return 0;
                                } else {
                                    if (loader_bottomJamiIdentifier.item && loader_bottomJamiIdentifier.item.isLong) {
                                        return JamiTheme.welcomeGridWidth;
                                    } else {
                                        return JamiTheme.welcomeShortGridWidth;
                                    }
                                }
                            }
                        }

                        Loader {
                            id: loader_tipsFlow
                            objectName: "loader_tipsFlow"
                            active: viewNode.hasTips
                            source: "TipsFlow.qml"
                            Layout.preferredHeight: active ? item.getHeight() : 0
                            Layout.preferredWidth: {
                                if (!active) {
                                    return 0;
                                } else {
                                    if (root.width > root.thresholdSize) {
                                        return JamiTheme.welcomeGridWidth;
                                    } else {
                                        return JamiTheme.welcomeShortGridWidth;
                                    }
                                }
                            }
                        }

                        Binding {
                            target: loader_bottomJamiIdentifier.item
                            property: "backgroundColor"
                            value: JamiTheme.rectColor
                            when: loader_bottomJamiIdentifier.item
                        }

                        Binding {
                            target: loader_bottomJamiIdentifier.item
                            property: "isLong"
                            value: {
                                if (loader_bottomJamiIdentifier.source == "../../commoncomponents/JamiIdentifier.qml") {
                                    if (root.width > root.thresholdSize)
                                        return true;
                                    else
                                        return false;
                                }
                            }
                            when: root.widthChanged
                        }
                    }
                }
            }

            Item {
                id: bottomRow
                width: Math.max(300, root.width)
                height: aboutJami.height + JamiTheme.preferredMarginSize
                anchors.bottom: parent.bottom

                MaterialButton {
                    id: aboutJami

                    TextMetrics {
                        id: textSize
                        font.weight: Font.Bold
                        font.pixelSize: JamiTheme.wizardViewButtonFontPixelSize
                        font.capitalization: Font.AllUppercase
                        text: aboutJami.text
                    }

                    tertiary: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    preferredWidth: textSize.width + 2 * JamiTheme.buttontextWizzardPadding
                    text: JamiStrings.aboutJami

                    onClicked: viewCoordinator.presentDialog(appWindow, "mainview/components/AboutPopUp.qml")
                }

                PushButton {
                    id: btnKeyboard

                    imageColor: JamiTheme.buttonTintedBlue
                    normalColor: JamiTheme.transparentColor
                    hoveredColor: JamiTheme.transparentColor
                    anchors.right: parent.right
                    anchors.rightMargin: JamiTheme.preferredMarginSize
                    preferredSize: 30
                    imageContainerWidth: JamiTheme.pushButtonSize
                    imageContainerHeight: JamiTheme.pushButtonSize

                    border.color: JamiTheme.buttonTintedBlue

                    source: JamiResources.keyboard_black_24dp_svg
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
