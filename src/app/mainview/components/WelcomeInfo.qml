/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

    property color backgroundColor: "transparent"
    property color textColor: JamiTheme.textColor
    property color idColor: JamiTheme.welcomeBlockColor
    property color contentIdColor: JamiTheme.tintedBlue
    property bool hasTitle: false
    property bool hasDescription: true

    property string title: JamiStrings.welcomeToJami
    property string description: JamiStrings.hereIsIdentifier

    property real contentWidth: welcomeInfo.width - 2 * JamiTheme.mainViewMargin

    function getHeight() {
        return bgRect.height;
    }

    Rectangle {
        id: bgRect
        radius: 5
        color: welcomeInfo.backgroundColor
        height: childrenRect.height + JamiTheme.mainViewMargin / 2
        width: welcomeInfo.width

        ColumnLayout {
            id: columnLayoutInfo
            anchors.horizontalCenter: bgRect.horizontalCenter

            spacing: 0

            Loader {
                id: loader_welcomeTitle
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: item ? item.contentHeight : 0
                Layout.topMargin: JamiTheme.mainViewMargin / 2
                Layout.bottomMargin: loader_identifierDescription.item ? JamiTheme.mainViewMargin - 15 : 0
                sourceComponent: welcomeInfo.hasTitle ? component_welcomeTitle : undefined
            }

            Loader {
                id: loader_identifierDescription
                Layout.alignment: Qt.AlignHCenter
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
                active: CurrentAccount.type !== Profile.Type.SIP
                objectName: "loader_bottomIdentifier"
                sourceComponent: JamiIdentifier {
                    backgroundColor: welcomeInfo.idColor
                    contentColor: contentIdColor
                }
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: active ? item.getHeight() : 0
                Layout.preferredWidth: active ? contentWidth : 0
            }

            Binding {
                target: loader_bottomIdentifier.item
                property: "slimDisplay"
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
            color: welcomeInfo.textColor
            textFormat: TextEdit.PlainText
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Component {
        id: component_identifierDescription
        Label {
            id: identifierDescription
            visible: CurrentAccount.type !== Profile.Type.SIP

            width: welcomeInfo.contentWidth
            height: contentHeight
            font.pixelSize: JamiTheme.tipBoxContentFontSize

            wrapMode: Text.WordWrap

            text: welcomeInfo.description
            lineHeight: 1.25
            color: welcomeInfo.textColor
            textFormat: TextEdit.PlainText
            horizontalAlignment: Text.AlignHCenter
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
            color: welcomeInfo.textColor
            textFormat: TextEdit.PlainText
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
