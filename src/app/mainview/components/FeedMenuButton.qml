/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Controls
import net.jami.Adapters 1.1
import net.jami.Models 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

NewIconButton {
    id: root
    property var coordinator
    property var dialogParent
    property string feedId: ""
    iconSize: JamiTheme.iconButtonMedium
    iconSource: JamiResources.more_vert_24dp_svg
    toolTipText: qsTr("Feed options")
    onClicked: menu.popup()
    Menu {
        id: menu
        MenuItem {
            text: qsTr("Available Feeds")
            onTriggered: root.coordinator.presentDialog(root.dialogParent, "commoncomponents/FeedCatalogueDialog.qml",
                                                        {"accountId": CurrentAccount.id})
        }
        MenuItem {
            text: qsTr("Create a Feed")
            onTriggered: root.coordinator.presentDialog(root.dialogParent, "commoncomponents/FeedSettingsDialog.qml",
                                                        {"accountId": CurrentAccount.id})
        }
        MenuItem {
            text: qsTr("Manage Feed")
            visible: root.feedId !== "" && CurrentConversation.isFeedOwner
            onTriggered: root.coordinator.presentDialog(root.dialogParent, "commoncomponents/FeedSettingsDialog.qml",
                                                        {"accountId": CurrentAccount.id, "feedId": root.feedId})
        }
        MenuItem {
            text: qsTr("Unsubscribe")
            visible: root.feedId !== "" && !CurrentConversation.isFeedOwner
            onTriggered: FeedAdapter.subscribe(CurrentAccount.id, root.feedId, false)
        }
    }
}
