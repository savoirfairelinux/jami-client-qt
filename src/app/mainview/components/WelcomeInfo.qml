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

Item {
    id: welcomeInfo

    property alias backgroundColor: bgRect.color
    property bool hasTitle: viewNode.hasTitle
    property bool hasDescription: viewNode.hasDescription

    property string title: viewNode.hasCustomTitle ? viewNode.customTitle : JamiStrings.welcomeToJami
    property string description: viewNode.hasCustomDescription ? viewNode.customDescription : JamiStrings.hereIsIdentifier

    property real contentWidth: isLong ? (width - 3 * JamiTheme.mainViewMargin) / 2 : width - 2 * JamiTheme.mainViewMargin

    property bool isLong: false

    function getHeight() {
        return bgRect.height;
    }

    Rectangle {
        id: bgRect
        radius: 30
        color: JamiTheme.backgroundColor
        height: childrenRect.height + 2 * JamiTheme.mainViewMargin
        width: welcomeInfo.width

        RowLayout {
            id: rowLayoutInfo
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: JamiTheme.mainViewMargin
            anchors.leftMargin: JamiTheme.mainViewMargin
            spacing: 0

            ColumnLayout {
                id: columnLayoutInfo
                Layout.rightMargin: isLong ? JamiTheme.mainViewMargin : 0
                spacing: 0

                Loader {
                    id: loader_welcomeTitle
                    Layout.preferredHeight: item ? item.contentHeight : 0
                    Layout.bottomMargin: loader_identifierDescription.item ? JamiTheme.mainViewMargin - 15 : 0
                    sourceComponent: welcomeInfo.hasTitle ? component_welcomeTitle : undefined
                }

                Loader {
                    id: loader_identifierDescription
                    Layout.preferredWidth: contentWidth
                    Layout.preferredHeight: item ? item.contentHeight : 0
                    Layout.bottomMargin: loader_bottomIdentifier.item ? JamiTheme.mainViewMargin - 10 : 0
                    sourceComponent: {
                        if (welcomeInfo.hasDescription) {
                            if (CurrentAccount.type !== Profile.Type.SIP) {
                                return component_identifierDescription;
                            } else {
                                return component_identifierDescriptionSIP;
                            }
                        } else {
                            return undefined;
                        }
                    }
                }

                Loader {
                    id: loader_bottomIdentifier
                    objectName: "loader_bottomIdentifier"
                    active: !welcomeInfo.isLong
                    source: "../../commoncomponents/JamiIdentifier.qml"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: active ? item.getHeight() : 0
                    Layout.preferredWidth: active ? contentWidth : 0
                }

                Binding {
                    target: loader_bottomIdentifier.item
                    property: "isLong"
                    value: false
                }
            }

            Loader {
                id: loader_sideIdentifier
                objectName: "loader_sideIdentifier"
                active: welcomeInfo.isLong
                source: "../../commoncomponents/JamiIdentifier.qml"
                Layout.preferredHeight: active ? item.getHeight() : 0
                Layout.preferredWidth: active ? contentWidth : 0
            }

            Binding {
                target: loader_sideIdentifier.item
                property: "isLong"
                value: false
            }
        }
    }

    Component {
        id: component_welcomeTitle
        Label {
            id: welcomeTitle

            width: welcomeInfo.contentWidth
            height: contentHeight

            font.pixelSize: JamiTheme.bigFontSize
            wrapMode: Text.WordWrap
            text: welcomeInfo.title
            color: JamiTheme.textColor
            textFormat: TextEdit.PlainText
        }
    }

    Component {
        id: component_identifierDescription
        Label {
            id: identifierDescription
            visible: CurrentAccount.type !== Profile.Type.SIP

            width: welcomeInfo.contentWidth
            height: contentHeight
            font.pixelSize: JamiTheme.headerFontSize

            wrapMode: Text.WordWrap

            text: welcomeInfo.description
            lineHeight: 1.25
            color: JamiTheme.textColor
            textFormat: TextEdit.PlainText
        }
    }

    Component {
        id: component_identifierDescriptionSIP
        Label {
            id: identifierDescriptionSIP

            width: welcomeInfo.contentWidth
            height: contentHeight
            font.pixelSize: JamiTheme.headerFontSize

            wrapMode: Text.WordWrap

            text: JamiStrings.description
            color: JamiTheme.textColor
            textFormat: TextEdit.PlainText
        }
    }
}
