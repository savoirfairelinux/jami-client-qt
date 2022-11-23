/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import Qt5Compat.GraphicalEffects


Popup {
    id: root

    width: popupContent.width
    height: popupContent.height
    background.visible: false
    parent: Overlay.overlay

    property var emojiReaction

    // center in parent
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    modal: true
    padding: 0

    visible: false
    closePolicy:  Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Rectangle {
        id: container

        anchors.fill: parent
        radius: JamiTheme.modalPopupRadius
        color: JamiTheme.secondaryBackgroundColor

        ColumnLayout {
            id:  popupContent

            Layout.alignment: Qt.AlignCenter

            PushButton {
                id: btnClose

                Layout.alignment: Qt.AlignRight
                width: 30
                height: 30
                imageContainerWidth: 30
                imageContainerHeight : 30
                Layout.margins: 8
                radius : 5
                imageColor: "grey"
                normalColor: JamiTheme.transparentColor
                source: JamiResources.round_close_24dp_svg
                onClicked: { root.close() }
            }

            RowLayout {
                Layout.leftMargin: JamiTheme.popupButtonsMargin
                Layout.rightMargin: JamiTheme.popupButtonsMargin
                Layout.alignment: Qt.AlignCenter

                ListView {
                    id: listViewReaction

                    Layout.preferredWidth: 400
                    Layout.preferredHeight: modelCount < 5
                                            ? 50 + (JamiTheme.avatarSize * modelCount)
                                            : 300
                    model: Object.entries(emojiReaction)
                    clip: true
                    property int modelCount: Object.entries(emojiReaction).length
                    delegate: RowLayout {

                        width: parent.width
                        property string authorUri: modelData[0]
                        property var emojiArray: modelData[1]
                        property bool isMe: authorUri === CurrentAccount.uri

                        Avatar {
                            imageId: isMe ? CurrentAccount.id : authorUri
                            showPresenceIndicator: false
                            mode: isMe ? Avatar.Mode.Account : Avatar.Mode.Contact
                            width: JamiTheme.avatarSize
                            height: JamiTheme.avatarSize
                        }

                        Text {
                            id: authorName

                            Layout.maximumWidth: 180
                            elide: Text.ElideRight
                            font.pointSize: JamiTheme.namePopupFontsize
                            color: JamiTheme.chatviewTextColor
                            text: isMe
                                  ? " " + CurrentAccount.bestName
                                        + "   "
                                  : " " + UtilsAdapter.getBestNameForUri(CurrentAccount.id, authorUri)
                                        + "   "
                        }

                        Text {
                            Layout.fillWidth: true
                            text: {
                                var cur = "";
                                for (const emojiIndex in emojiArray) {
                                    cur = cur + emojiArray[emojiIndex]
                                }
                                return cur
                            }
                            horizontalAlignment: Text.AlignRight
                            font.pointSize: JamiTheme.emojiPopupFontsize
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Overlay.modal: Rectangle {
        color: JamiTheme.transparentColor
        // Color animation for overlay when pop up is shown.
        ColorAnimation on color {
            to: JamiTheme.popupOverlayColor
            duration: 500
        }
    }

    DropShadow {
        z: -1
        width: root.width
        height: root.height
        horizontalOffset: 3.0
        verticalOffset: 3.0
        radius: container.radius * 4
        color: JamiTheme.shadowColor
        source: container
        transparentBorder: true
    }

    enter: Transition {
        NumberAnimation {
            properties: "opacity"; from: 0.0; to: 1.0
            duration: JamiTheme.shortFadeDuration
        }
    }

    exit: Transition {
        NumberAnimation {
            properties: "opacity"; from: 1.0; to: 0.0
            duration: JamiTheme.shortFadeDuration
        }
    }
}
