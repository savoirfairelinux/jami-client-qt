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
    color: JamiTheme.secondaryBackgroundColor
    hideRightPaneInSinglePaneMode: true
    leftPaneItem: viewCoordinator.getView("SidePanel")
    objectName: "WelcomePage"
    splitViewStateKey: "Main"

    onPresented: LRCInstance.deselectConversation()

    CustomBorder {
        bBorderwidth: 0
        borderColor: JamiTheme.tabbarBorderColor
        commonBorder: false
        lBorderwidth: 1
        rBorderwidth: 0
        tBorderwidth: 0
    }

    rightPaneItem: JamiFlickable {
        id: root
        anchors.fill: parent
        contentHeight: Math.max(root.height, welcomePageLayout.implicitHeight)
        contentWidth: Math.max(300, root.width)

        MouseArea {
            anchors.fill: parent
            enabled: visible

            onClicked: root.forceActiveFocus()
        }
        Item {
            id: welcomePageLayout
            height: parent.height
            width: Math.max(300, root.width)

            Item {
                anchors.centerIn: parent
                height: childrenRect.height

                Rectangle {
                    id: welcomeInfo
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 25
                    color: JamiTheme.rectColor
                    height: childrenRect.height + 10
                    opacity: 1
                    radius: 30
                    width: identifier.width + 2 * JamiTheme.mainViewMargin + (welcomeLogo.visible ? welcomeLogo.width : 0)

                    Label {
                        id: welcome
                        anchors.left: parent.left
                        anchors.leftMargin: JamiTheme.mainViewMargin
                        anchors.top: parent.top
                        anchors.topMargin: JamiTheme.mainViewMargin
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.bigFontSize
                        horizontalAlignment: Text.AlignLeft
                        text: JamiStrings.welcomeToJami
                        verticalAlignment: Text.AlignVCenter
                        width: 300
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        id: descriptionLabel
                        anchors.left: parent.left
                        anchors.leftMargin: JamiTheme.mainViewMargin
                        anchors.top: welcome.bottom
                        anchors.topMargin: JamiTheme.preferredMarginSize * 2
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.headerFontSize
                        text: JamiStrings.description
                        visible: CurrentAccount.type === Profile.Type.SIP
                        width: 300
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        id: identifierDescription
                        anchors.left: parent.left
                        anchors.leftMargin: JamiTheme.mainViewMargin
                        anchors.top: welcome.bottom
                        anchors.topMargin: JamiTheme.preferredMarginSize
                        color: JamiTheme.textColor
                        font.pixelSize: JamiTheme.headerFontSize
                        lineHeight: 1.25
                        text: JamiStrings.hereIsIdentifier
                        visible: CurrentAccount.type !== Profile.Type.SIP
                        width: 330
                        wrapMode: Text.WordWrap
                    }
                    JamiIdentifier {
                        id: identifier
                        anchors.left: parent.left
                        anchors.leftMargin: JamiTheme.mainViewMargin
                        anchors.rightMargin: JamiTheme.preferredMarginSize
                        anchors.top: identifierDescription.bottom
                        anchors.topMargin: JamiTheme.preferredMarginSize
                        visible: CurrentAccount.type !== Profile.Type.SIP
                    }
                    Image {
                        id: welcomeLogo
                        anchors.margins: JamiTheme.preferredMarginSize
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: -20
                        height: 244
                        opacity: visible
                        source: JamiResources.welcome_illustration_2_svg
                        visible: root.width > 630
                        width: 212

                        Behavior on opacity  {
                            NumberAnimation {
                                duration: JamiTheme.shortFadeDuration
                            }
                        }
                    }

                    Behavior on width  {
                        NumberAnimation {
                            duration: JamiTheme.shortFadeDuration
                        }
                    }
                }
                JamiFlickable {
                    id: tipsFlow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: welcomeInfo.bottom
                    anchors.topMargin: JamiTheme.preferredMarginSize * 2
                    clip: true
                    height: flow.height + JamiTheme.preferredMarginSize * 2
                    width: welcomeInfo.width

                    Flow {
                        id: flow
                        spacing: 13

                        Repeater {
                            id: tipsRepeater
                            Layout.alignment: Qt.AlignCenter
                            model: TipsModel

                            delegate: TipBox {
                                property bool hideTipBox: false

                                description: Description
                                tipId: TipId
                                title: Title
                                type: Type
                                visible: {
                                    if (hideTipBox)
                                        return false;
                                    if (type === "backup") {
                                        return LRCInstance.currentAccountType !== Profile.Type.SIP && CurrentAccount.managerUri.length === 0;
                                    } else if (type === "customize") {
                                        return CurrentAccount.alias.length === 0;
                                    }
                                    return true;
                                }

                                onIgnoreClicked: {
                                    hideTipBox = true;
                                }
                            }
                        }
                    }
                }
            }
            Item {
                id: bottomRow
                anchors.bottom: parent.bottom
                height: aboutJami.height + JamiTheme.preferredMarginSize
                width: Math.max(300, root.width)

                MaterialButton {
                    id: aboutJami
                    anchors.horizontalCenter: parent.horizontalCenter
                    preferredWidth: JamiTheme.aboutButtonPreferredWidth
                    tertiary: true
                    text: JamiStrings.aboutJami

                    onClicked: viewCoordinator.presentDialog(appWindow, "mainview/components/AboutPopUp.qml")
                }
                PushButton {
                    id: btnKeyboard
                    anchors.right: parent.right
                    anchors.rightMargin: JamiTheme.preferredMarginSize
                    border.color: JamiTheme.buttonTintedBlue
                    hoveredColor: JamiTheme.transparentColor
                    imageColor: JamiTheme.buttonTintedBlue
                    imageContainerHeight: JamiTheme.pushButtonSize
                    imageContainerWidth: JamiTheme.pushButtonSize
                    normalColor: JamiTheme.transparentColor
                    preferredSize: 30
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
