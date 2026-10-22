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

// Picks who a function is used with: a contact, a group, a Circle or a Board.
// The caller acts on the choice, made through one of the *Picked signals.
BaseModalDialog {
    id: root
    objectName: "functionTargetPicker"

    property int fn: FunctionsPanel.Messages
    property string accentColor: "#0EA5E9"
    property var conversations: ConversationsAdapter.targetsListProxyModel
    property var circleService: CircleAdapter
    property var feedService: FeedAdapter

    signal conversationPicked(string convId, bool withVideo)
    signal circlePicked(string circleId)
    signal boardPicked(string feedId)

    readonly property bool calling: fn === FunctionsPanel.Calls
    // Circles and Boards have no calls nor location, and a document lives in one conversation.
    readonly property var filters: calling || fn === FunctionsPanel.Location || fn === FunctionsPanel.Documents
                                   ? ["all", "contacts", "groups"]
                                   : ["all", "contacts", "groups", "circles", "boards"]
    property string filter: calling || fn === FunctionsPanel.Messages ? "contacts" : "all"
    property string query: ""

    // Circles with members, and Boards the account publishes or follows.
    readonly property var circles: filters.includes("circles") && (filter === "all" || filter === "circles")
                                   ? (circleService.circles || []).filter(c => c.count > 0 && matches(c.name))
                                   : []
    readonly property var boards: filters.includes("boards") && (filter === "all" || filter === "boards")
                                  ? (feedService.feeds || []).filter(f => (f.owned ? !f.feedClosed : f.subscribed)
                                                                     && matches(f.title))
                                  : []

    function matches(name) {
        return query === "" || (name || "").toLowerCase().includes(query.toLowerCase());
    }

    function applyFilter() {
        conversations.showContacts = filter === "all" || filter === "contacts";
        conversations.showGroups = filter === "all" || filter === "groups";
        conversations.setFilter(query);
    }

    function filterName(filter) {
        switch (filter) {
        case "contacts":
            return JamiStrings.targetContacts;
        case "groups":
            return JamiStrings.targetGroups;
        case "circles":
            return JamiStrings.targetCircles;
        case "boards":
            return JamiStrings.targetBoards;
        default:
            return JamiStrings.targetAll;
        }
    }

    function actionIcon() {
        switch (fn) {
        case FunctionsPanel.Documents:
            return JamiResources.article_24dp_svg;
        case FunctionsPanel.Location:
            return JamiResources.my_location_24dp_svg;
        default:
            return JamiResources.chat_24dp_svg;
        }
    }

    function actionName(name) {
        switch (fn) {
        case FunctionsPanel.Documents:
            return JamiStrings.newDocumentWith.arg(name);
        case FunctionsPanel.Location:
            return JamiStrings.shareLocationWith.arg(name);
        default:
            return JamiStrings.writeTo.arg(name);
        }
    }

    function pickConversation(convId, withVideo) {
        conversationPicked(convId, withVideo);
        close();
    }

    onFilterChanged: applyFilter()
    onQueryChanged: applyFilter()
    Component.onCompleted: applyFilter()

    popupContent: ColumnLayout {
        width: 440
        height: 480
        spacing: 10

        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.filters

                delegate: AbstractButton {
                    id: chip

                    required property string modelData

                    objectName: "targetFilter-" + modelData
                    checkable: true
                    checked: root.filter === modelData
                    focusPolicy: Qt.TabFocus
                    hoverEnabled: true
                    padding: 6
                    leftPadding: 14
                    rightPadding: 14
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: root.filterName(modelData)

                    contentItem: Text {
                        text: root.filterName(chip.modelData)
                        color: chip.checked ? root.accentColor : JamiTheme.textColor
                        font.pointSize: JamiTheme.textFontSize
                        font.bold: chip.checked
                    }
                    background: Rectangle {
                        radius: height / 2
                        color: chip.checked ? "#26" + root.accentColor.substring(1)
                                            : chip.hovered ? JamiTheme.hoveredButtonColor : JamiTheme.transparentColor
                        border.width: chip.visualFocus ? 2 : 1
                        border.color: chip.checked ? root.accentColor : JamiTheme.greyBorderColor
                    }
                    onClicked: root.filter = modelData
                }
            }
        }

        Searchbar {
            objectName: "targetSearch"

            Layout.fillWidth: true
            Layout.preferredHeight: 40
            placeHolderText: JamiStrings.search
            onSearchBarTextChanged: function (text) {
                root.query = text.trim();
            }
        }

        ListView {
            id: list
            objectName: "targetList"

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.conversations
            ScrollBar.vertical: JamiScrollBar {}

            // The conversation roles (UID, Title...) are the delegate's context.
            delegate: TargetRow {
                objectName: "targetConversation-" + UID
                name: Title
                typeName: IsCoreDialog ? JamiStrings.contact : JamiStrings.targetGroup
                typeIcon: IsCoreDialog ? JamiResources.person_24dp_svg : JamiResources.group_24dp_svg
                avatar: ConversationAvatar {
                    anchors.fill: parent
                    imageId: UID
                    presenceStatus: Presence
                    showPresenceIndicator: Presence !== undefined ? Presence : false
                }
                onPicked: withVideo => root.pickConversation(UID, withVideo)
            }

            footer: Column {
                width: list.width

                Repeater {
                    model: root.circles

                    delegate: TargetRow {
                        id: circleRow

                        required property var modelData

                        objectName: "targetCircle-" + modelData.id
                        width: list.width
                        name: modelData.name
                        typeName: JamiStrings.targetCircle
                        typeIcon: JamiResources.circles_24dp_svg
                        avatar: Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "#266366F1"
                            border.color: "#6366F1"
                            Text {
                                anchors.centerIn: parent
                                text: circleRow.modelData.name.charAt(0).toUpperCase()
                                color: "#6366F1"
                                font.bold: true
                            }
                        }
                        onPicked: {
                            root.circlePicked(modelData.id);
                            root.close();
                        }
                    }
                }

                Repeater {
                    model: root.boards

                    delegate: TargetRow {
                        id: boardRow

                        required property var modelData

                        objectName: "targetBoard-" + modelData.id
                        width: list.width
                        name: modelData.title
                        typeName: JamiStrings.targetBoard
                        typeIcon: JamiResources.campaign_24dp_svg
                        avatar: Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: JamiTheme.secondaryBackgroundColor
                            Image {
                                anchors.fill: parent
                                sourceSize: Qt.size(128, 128)
                                fillMode: Image.PreserveAspectFit
                                source: boardRow.modelData.avatar ? "data:image/png;base64," + boardRow.modelData.avatar : ""
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !boardRow.modelData.avatar
                                text: (boardRow.modelData.title || "B").charAt(0).toUpperCase()
                                color: JamiTheme.textColor
                            }
                        }
                        onPicked: {
                            root.boardPicked(modelData.id);
                            root.close();
                        }
                    }
                }
            }
        }

        Text {
            objectName: "targetEmpty"

            Layout.fillWidth: true
            visible: list.count === 0 && root.circles.length === 0 && root.boards.length === 0
            text: JamiStrings.targetEmpty
            color: JamiTheme.faddedLastInteractionFontColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    // One recipient: avatar, kind, name, then the function's own actions.
    component TargetRow: ItemDelegate {
        id: row

        property string name
        property string typeName
        property url typeIcon
        property alias avatar: avatarHolder.data

        signal picked(bool withVideo)

        width: ListView.view ? ListView.view.width : implicitWidth
        height: JamiTheme.smartListItemHeight
        Accessible.name: row.name + ", " + row.typeName

        contentItem: RowLayout {
            spacing: 10

            Item {
                id: avatarHolder

                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
            }

            ResponsiveImage {
                containerWidth: 18
                containerHeight: 18
                source: row.typeIcon
                color: JamiTheme.faddedLastInteractionFontColor
            }

            Text {
                Layout.fillWidth: true
                text: row.name
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: JamiTheme.textColor
                font.pointSize: JamiTheme.textFontSize
            }

            NewIconButton {
                objectName: "videoCall"
                visible: root.calling
                iconSource: JamiResources.videocam_24dp_svg
                iconSize: JamiTheme.iconButtonMedium
                toolTipText: JamiStrings.startVideoCall
                onClicked: row.picked(true)
            }

            NewIconButton {
                objectName: "audioCall"
                visible: root.calling
                iconSource: JamiResources.call_24dp_svg
                iconSize: JamiTheme.iconButtonMedium
                toolTipText: JamiStrings.startAudioCall
                onClicked: row.picked(false)
            }

            NewIconButton {
                objectName: "pickTarget"
                visible: !root.calling
                iconSource: root.actionIcon()
                iconSize: JamiTheme.iconButtonMedium
                toolTipText: root.actionName(row.name)
                onClicked: row.picked(false)
            }
        }

        // As on Android, a row starts an audio call when calling.
        onClicked: row.picked(false)
    }
}
