/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import net.jami.Models 1.1
import "../../commoncomponents"

// The groups of the account: open one, leave one, or create a new one.
BaseModalDialog {
    id: root
    objectName: "groupsDialog"

    property var conversations: ConversationsAdapter.targetsListProxyModel

    signal groupPicked(string convId)
    signal createGroupRequested
    signal leaveGroupRequested(string convId)

    titleText: JamiStrings.functionGroups

    Component.onCompleted: {
        conversations.showContacts = false;
        conversations.showGroups = true;
        conversations.setFilter("");
    }

    popupContent: ColumnLayout {
        width: 440
        height: 480
        spacing: 10

        NewMaterialButton {
            objectName: "createGroupButton"

            Layout.alignment: Qt.AlignHCenter
            filledButton: true
            color: "#EC4899"
            iconSource: JamiResources.add_people_24dp_svg
            text: JamiStrings.newGroup
            onClicked: {
                root.createGroupRequested();
                root.close();
            }
        }

        ListView {
            id: list
            objectName: "groupList"

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.conversations
            ScrollBar.vertical: JamiScrollBar {}

            // The conversation roles (UID, Title...) are the delegate's context.
            delegate: ItemDelegate {
                id: group

                objectName: "group-" + UID
                width: list.width
                height: JamiTheme.smartListItemHeight
                Accessible.name: Title

                contentItem: RowLayout {
                    spacing: 10

                    ConversationAvatar {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        imageId: UID
                        presenceStatus: Presence
                        showPresenceIndicator: Presence !== undefined ? Presence : false
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: Title
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: JamiTheme.textColor
                            font.bold: true
                            font.pointSize: JamiTheme.textFontSize
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: LastInteraction
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: JamiTheme.faddedLastInteractionFontColor
                            font.pointSize: JamiTheme.textFontSize
                        }
                    }

                    NewIconButton {
                        objectName: "groupOptions"
                        iconSource: JamiResources.more_vert_24dp_svg
                        iconSize: JamiTheme.iconButtonMedium
                        toolTipText: JamiStrings.leaveGroup
                        onClicked: menu.popup()

                        Menu {
                            id: menu

                            MenuItem {
                                text: JamiStrings.leaveGroup
                                onTriggered: root.leaveGroupRequested(UID)
                            }
                        }
                    }
                }

                onClicked: {
                    root.groupPicked(UID);
                    root.close();
                }
            }
        }

        Text {
            objectName: "noGroups"

            Layout.fillWidth: true
            visible: list.count === 0
            text: JamiStrings.noGroups
            color: JamiTheme.faddedLastInteractionFontColor
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
