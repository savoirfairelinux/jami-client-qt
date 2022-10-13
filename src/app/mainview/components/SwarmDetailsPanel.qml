/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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
import Qt.labs.platform
import Qt5Compat.GraphicalEffects
import QtWebEngine

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

import "../../commoncomponents"
import "../../settingsview/components"

Rectangle {
    id: root

    color: CurrentConversation.color
    property var isAdmin: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri) === Member.Role.ADMIN
    property int spacingFlow: JamiTheme.swarmDetailsPageDocumentsMargins
    property int spacingLength: spacingFlow * (numberElementsPerRow - 1)
    property int numberElementsPerRow: {
        var sizeW = flow.width
        var breakSize = JamiTheme.swarmDetailsPageDocumentsMediaSize
        return Math.floor(sizeW / breakSize)
    }

    ColumnLayout {
        id: swarmProfileDetails
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: 0

        ColumnLayout {
            id: header
            Layout.topMargin: JamiTheme.swarmDetailsPageTopMargin
            Layout.fillWidth: true
            spacing: JamiTheme.preferredMarginSize

            PhotoboothView {
                id: currentAccountAvatar
                darkTheme: UtilsAdapter.luma(root.color)
                readOnly: !root.isAdmin

                Layout.alignment: Qt.AlignHCenter

                newItem: true
                imageId: LRCInstance.selectedConvUid
                avatarSize: JamiTheme.smartListAvatarSize
            }

            EditableLineEdit {
                id: titleLine

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: JamiTheme.preferredFieldWidth

                font.pointSize: JamiTheme.titleFontSize

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                firstIco:  JamiResources.round_edit_24dp_svg
                secondIco: editable ? JamiResources.close_black_24dp_svg : ""

                fontSize: 20
                borderColor: "transparent"

                text: CurrentConversation.title
                readOnly: !root.isAdmin
                placeholderText: JamiStrings.swarmName
                placeholderTextColor: {
                    if (editable) {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.placeholderTextColorWhite
                        } else {
                            return JamiTheme.placeholderTextColor
                        }
                    } else {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.chatviewTextColorLight
                        } else {
                            return JamiTheme.chatviewTextColorDark
                        }
                    }
                }
                tooltipText: JamiStrings.swarmName
                backgroundColor: root.color
                color: UtilsAdapter.luma(backgroundColor) ?
                           JamiTheme.chatviewTextColorLight :
                           JamiTheme.chatviewTextColorDark

                onEditingFinished: {
                    if (text !== CurrentConversation.title)
                        ConversationsAdapter.updateConversationTitle(LRCInstance.selectedConvUid, text)
                }
                onSecondIcoClicked: {editable = !editable}

            }

            EditableLineEdit {
                id: descriptionLine

                Layout.alignment: Qt.AlignHCenter

                font.pointSize: JamiTheme.menuFontSize

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Layout.preferredWidth: JamiTheme.preferredFieldWidth
                fontSize: 16

                firstIco:  JamiResources.round_edit_24dp_svg
                secondIco: editable ? JamiResources.close_black_24dp_svg : ""
                borderColor: "transparent"

                text: CurrentConversation.description
                readOnly: !root.isAdmin
                placeholderText: JamiStrings.addADescription
                placeholderTextColor: {
                    if (editable) {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.placeholderTextColorWhite
                        } else {
                            return JamiTheme.placeholderTextColor
                        }
                    } else {
                        if (UtilsAdapter.luma(root.color)) {
                            return JamiTheme.chatviewTextColorLight
                        } else {
                            return JamiTheme.chatviewTextColorDark
                        }
                    }
                }
                tooltipText: JamiStrings.addADescription
                backgroundColor: root.color
                color: UtilsAdapter.luma(backgroundColor) ?
                           JamiTheme.chatviewTextColorLight :
                           JamiTheme.chatviewTextColorDark

                onEditingFinished: {
                    if (text !== CurrentConversation.description)
                        ConversationsAdapter.updateConversationDescription(LRCInstance.selectedConvUid, text)
                }

                onSecondIcoClicked: {editable = !editable}
            }

            TabBar {
                id: tabBar

                currentIndex: 1

                Layout.preferredWidth: root.width
                Layout.preferredHeight: membersTabButton.height

                FilterTabButton {
                    id: aboutTabButton
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                                   JamiTheme.chatviewTextColorLight :
                                   JamiTheme.chatviewTextColorDark

                    down: tabBar.currentIndex === 0
                    labelText: JamiStrings.about
                }

                FilterTabButton {
                    id: membersTabButton
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                                   JamiTheme.chatviewTextColorLight :
                                   JamiTheme.chatviewTextColorDark

                    down: tabBar.currentIndex === 1
                    labelText: {
                        var membersNb = CurrentConversation.uris.length;
                        if (membersNb > 1)
                            return JamiStrings.members.arg(membersNb)
                        return JamiStrings.member
                    }
                }

                FilterTabButton {
                    id: documentsTabButton
                    backgroundColor: CurrentConversation.color
                    hoverColor: CurrentConversation.color
                    borderWidth: 4
                    bottomMargin: JamiTheme.settingsMarginSize
                    fontSize: JamiTheme.menuFontSize
                    underlineContentOnly: true

                    textColorHovered: UtilsAdapter.luma(root.color) ? JamiTheme.placeholderTextColorWhite : JamiTheme.placeholderTextColor
                    textColor: UtilsAdapter.luma(root.color) ?
                                   JamiTheme.chatviewTextColorLight :
                                   JamiTheme.chatviewTextColorDark

                    down: tabBar.currentIndex === 2
                    labelText: JamiStrings.documents
                }
            }
        }

        ColorDialog {
            id: colorDialog
            title: JamiStrings.chooseAColor
            onAccepted: {
                CurrentConversation.setPreference("color", colorDialog.color)
            }
        }

        Rectangle {
            id: details
            Layout.fillWidth: true
            Layout.preferredHeight: root.height - header.height - JamiTheme.preferredMarginSize
            color: JamiTheme.secondaryBackgroundColor

            ColumnLayout {
                id: aboutSwarm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: JamiTheme.settingsMarginSize
                visible: tabBar.currentIndex === 0
                Layout.alignment: Qt.AlignTop

                SwarmDetailsItem {
                    Layout.fillWidth: true
                    Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                    ToggleSwitch {
                        id: ignoreSwarm

                        anchors.fill: parent
                        anchors.leftMargin: JamiTheme.preferredMarginSize

                        checked: CurrentConversation.ignoreNotifications

                        labelText: JamiStrings.ignoreTheSwarm
                        fontPointSize: JamiTheme.settingsFontSize

                        tooltipText: JamiStrings.ignoreTheSwarmTooltip

                        onSwitchToggled: {
                            CurrentConversation.setPreference("ignoreNotifications", checked ? "true" : "false")
                        }
                    }
                }

                SwarmDetailsItem {
                    Layout.fillWidth: true
                    Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                    Text {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: JamiTheme.preferredMarginSize
                        text: JamiStrings.leaveTheSwarm
                        font.pointSize: JamiTheme.settingsFontSize
                        font.kerning: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        color: JamiTheme.textColor
                    }

                    TapHandler {
                        target: parent
                        enabled: parent.visible
                        onTapped: function onTapped(eventPoint) {
                            MessagesAdapter.removeConversation(LRCInstance.selectedConvUid)
                        }
                    }
                }

                SwarmDetailsItem {
                    Layout.fillWidth: true
                    Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: JamiTheme.preferredMarginSize

                        Text {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            Layout.rightMargin: JamiTheme.preferredMarginSize

                            text: JamiStrings.chooseAColor
                            font.pointSize: JamiTheme.settingsFontSize
                            font.kerning: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: JamiTheme.textColor
                        }

                        Rectangle {
                            id: chooseAColorBtn

                            Layout.alignment: Qt.AlignRight

                            width: JamiTheme.aboutBtnSize
                            height: JamiTheme.aboutBtnSize
                            radius: JamiTheme.aboutBtnSize / 2

                            color: CurrentConversation.color
                        }
                    }

                    TapHandler {
                        target: parent
                        enabled: parent.visible
                        onTapped: function onTapped(eventPoint) {
                            colorDialog.open()
                        }
                    }
                }

                RowLayout {
                    Layout.leftMargin: JamiTheme.preferredMarginSize
                    Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        Layout.rightMargin: JamiTheme.preferredMarginSize

                        text: JamiStrings.typeOfSwarm
                        font.pointSize: JamiTheme.settingsFontSize
                        font.kerning: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        color: JamiTheme.textColor
                    }

                    Label {
                        id: typeOfSwarmLabel

                        Layout.alignment: Qt.AlignRight

                        color: JamiTheme.textColor

                        text: CurrentConversation.modeString
                    }
                }

                RowLayout {
                    Layout.leftMargin: JamiTheme.preferredMarginSize
                    Layout.preferredHeight: JamiTheme.settingsFontSize + 2 * JamiTheme.preferredMarginSize + 4
                    Layout.maximumWidth: parent.width

                    Text {
                        id: idLabel
                        Layout.preferredHeight: 30
                        Layout.rightMargin: JamiTheme.preferredMarginSize
                        Layout.maximumWidth: parent.width / 2

                        text: JamiStrings.identifier
                        font.pointSize: JamiTheme.settingsFontSize
                        font.kerning: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        color: JamiTheme.textColor
                    }

                    Text {
                        Layout.alignment: Qt.AlignRight
                        Layout.maximumWidth: parent.width / 2

                        color: JamiTheme.textColor


                        text: CurrentConversation.id
                        elide: Text.ElideRight

                    }
                }
            }

            JamiListView {
                id: members
                anchors.topMargin: JamiTheme.preferredMarginSize
                anchors.bottomMargin: JamiTheme.preferredMarginSize
                anchors.fill: parent

                visible: tabBar.currentIndex === 1

                SwarmParticipantContextMenu {
                    id: contextMenu
                    role: UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, CurrentAccount.uri)

                    function openMenuAt(x, y, participantUri) {
                        contextMenu.x = x
                        contextMenu.y = y
                        contextMenu.conversationId = CurrentConversation.id
                        contextMenu.participantUri = participantUri

                        openMenu()
                    }
                }

                model: CurrentConversation.uris
                delegate: ItemDelegate {
                    id: member
                    width: members.width
                    height: JamiTheme.smartListItemHeight

                    background: Rectangle {
                        anchors.fill: parent
                        color: {
                            if (member.hovered)
                                return Qt.darker(JamiTheme.selectedColor, 1.05)
                            else
                                return "transparent"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: modelData != CurrentAccount.uri
                        acceptedButtons: Qt.RightButton
                        onClicked: function (mouse) {
                            contextMenu.openMenuAt(x + mouse.x, y + mouse.y, modelData)
                        }
                    }

                    RowLayout {
                        spacing: 10

                        Avatar {
                            width: JamiTheme.smartListAvatarSize
                            height: JamiTheme.smartListAvatarSize
                            Layout.leftMargin: JamiTheme.preferredMarginSize
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2
                            z: -index
                            opacity: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                return role === Member.Role.INVITED ? 0.5 : 1
                            }

                            imageId: CurrentAccount.uri == modelData ? CurrentAccount.id : modelData
                            showPresenceIndicator: UtilsAdapter.getContactPresence(CurrentAccount.id, modelData)
                            mode: CurrentAccount.uri == modelData ? Avatar.Mode.Account : Avatar.Mode.Contact
                        }

                        ElidedTextLabel {
                            id: bestName

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2

                            eText: UtilsAdapter.getContactBestName(CurrentAccount.id, modelData)
                            maxWidth: JamiTheme.preferredFieldWidth

                            font.pointSize: JamiTheme.participantFontSize
                            color: JamiTheme.primaryForegroundColor
                            opacity: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                return role === Member.Role.INVITED ? 0.5 : 1
                            }
                            font.kerning: true

                            verticalAlignment: Text.AlignVCenter
                        }

                        ElidedTextLabel {
                            id: role

                            Layout.preferredHeight: JamiTheme.preferredFieldHeight
                            Layout.topMargin: JamiTheme.preferredMarginSize / 2

                            eText: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                if (role === Member.Role.ADMIN)
                                    return JamiStrings.administrator
                                if (role === Member.Role.INVITED)
                                    return JamiStrings.invited
                                return ""
                            }
                            maxWidth: JamiTheme.preferredFieldWidth

                            font.pointSize: JamiTheme.participantFontSize
                            color: JamiTheme.textColorHovered
                            opacity: {
                                var role = UtilsAdapter.getParticipantRole(CurrentAccount.id, CurrentConversation.id, modelData)
                                return role === Member.Role.INVITED ? 0.5 : 1
                            }
                            font.kerning: true

                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
            Flickable {
                id: documents

                visible: tabBar.currentIndex === 2
                clip: true
                anchors.fill: parent
                contentWidth: width
                contentHeight: flow.implicitHeight
                onVisibleChanged: {
                    if (visible) {
                        MessagesAdapter.getConvMedias()
                    } else {
                        MessagesAdapter.mediaMessageListModel = null
                    }
                }
                Flow {
                    id: flow

                    width: parent.width
                    spacing: spacingFlow
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: MessagesAdapter.mediaMessageListModel

                        delegate: Loader {
                            id: loaderRoot

                            sourceComponent: {
                                if(Status === Interaction.Status.TRANSFER_FINISHED || Status === Interaction.Status.SUCCESS ){
                                    if (Object.keys(MessagesAdapter.getMediaInfo(Body)).length !== 0 && WITH_WEBENGINE)
                                        return localMediaMsgComp

                                    return dataTransferMsgComp
                                }
                            }

                            Component {
                                id: dataTransferMsgComp

                                Rectangle {
                                    id: dataTransferRect

                                    clip: true
                                    width: (documents.width - spacingLength ) / numberElementsPerRow
                                    height: width
                                    color: "transparent"

                                    ColumnLayout{
                                        anchors.fill: parent
                                        anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins

                                        Text {
                                            id: myText

                                            text: TransferName
                                            color: JamiTheme.textColor
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        Rectangle {
                                            Layout.preferredHeight: parent.height - myText.height - JamiTheme.swarmDetailsPageDocumentsMargins
                                            Layout.preferredWidth: parent.width
                                            Layout.rightMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                                            Layout.bottomMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                                            color: "transparent"

                                            Rectangle {
                                                id: rectContent

                                                anchors.fill: parent
                                                anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins
                                                color: "transparent"
                                                border.color: CurrentConversation.color
                                                border.width: 2
                                                radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                                                layer.enabled: true

                                                ResponsiveImage {
                                                    id: paperClipImage

                                                    source: JamiResources.link_black_24dp_svg
                                                    width: parent.width / 2
                                                    height: parent.height / 2
                                                    anchors.centerIn: parent
                                                    color: JamiTheme.textColor

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                        onEntered: {
                                                            cursorShape = Qt.PointingHandCursor
                                                        }

                                                        onClicked: function (mouse) {
                                                            if (mouse.button === Qt.RightButton) {
                                                                ctxMenu.x = mouse.x
                                                                ctxMenu.y = mouse.y
                                                                ctxMenu.openMenu()
                                                            } else {
                                                                Qt.openUrlExternally("file://" + Body)
                                                            }
                                                        }
                                                    }
                                                    SBSContextMenu {
                                                        id: ctxMenu

                                                        msgId: Id
                                                        location: Body
                                                        transferId: Id
                                                        transferName: TransferName
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Component {
                                id: localMediaMsgComp

                                Rectangle {
                                    id: localMediaRect

                                    width: (documents.width - spacingLength) /  numberElementsPerRow
                                    height: width
                                    color: "transparent"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins

                                        Text {
                                            id: myText

                                            text: TransferName
                                            color: JamiTheme.textColor
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        Rectangle {
                                            Layout.preferredHeight: parent.height - myText.height - JamiTheme.swarmDetailsPageDocumentsMargins
                                            Layout.preferredWidth: parent.width
                                            Layout.rightMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                                            Layout.bottomMargin: JamiTheme.swarmDetailsPageDocumentsMargins
                                            color: "transparent"

                                            Rectangle {
                                                id: rectContent

                                                anchors.fill: parent
                                                anchors.margins: JamiTheme.swarmDetailsPageDocumentsMargins
                                                color: CurrentConversation.color
                                                layer.enabled: true
                                                layer.effect: OpacityMask {
                                                    maskSource: Item {
                                                        width: localMediaCompLoader.width
                                                        height: localMediaCompLoader.height
                                                        Rectangle {
                                                            anchors.centerIn: parent
                                                            width:  localMediaCompLoader.width
                                                            height: localMediaCompLoader.height
                                                            radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                                                        }
                                                    }
                                                }

                                                Loader {
                                                    id: localMediaCompLoader

                                                    property var mediaInfo: MessagesAdapter.getMediaInfo(Body)
                                                    anchors.fill: parent
                                                    anchors.margins: 2
                                                    sourceComponent: {
                                                        if (mediaInfo.isImage || mediaInfo.isAnimatedImage )
                                                            return simpleImage
                                                        else if (WITH_WEBENGINE)
                                                            return avComp
                                                    }
                                                    Component {
                                                        id: avComp

                                                        Loader {
                                                            id:loadVideo

                                                            property real msgRadius: 20

                                                            Rectangle {
                                                                id: videoAudioRect
                                                                color: JamiTheme.secondaryBackgroundColor
                                                                anchors.fill: parent

                                                                WebEngineView {
                                                                    id: wev

                                                                    property bool isVideo: mediaInfo.isVideo
                                                                    property string html: mediaInfo.html

                                                                    anchors.fill: parent
                                                                    anchors.verticalCenter: videoAudioRect.verticalCenter
                                                                    backgroundColor: JamiTheme.secondaryBackgroundColor
                                                                    anchors.topMargin: isVideo? 0 :  wev.implicitHeight / 2
                                                                    settings.fullScreenSupportEnabled: isVideo
                                                                    settings.javascriptCanOpenWindows: false
                                                                    Component.onCompleted: loadHtml(html, 'file://')
                                                                    onFullScreenRequested: function(request) {
                                                                        if (request.toggleOn) {
                                                                            layoutManager.pushFullScreenItem(
                                                                                        this,
                                                                                        videoAudioRect,
                                                                                        null,
                                                                                        function() { wev.fullScreenCancelled() })
                                                                        } else if (!request.toggleOn) {
                                                                            layoutManager.removeFullScreenItem(this)
                                                                        }
                                                                        request.accept()
                                                                    }
                                                                }

                                                                layer.enabled: true
                                                                layer.effect: OpacityMask {
                                                                    maskSource: Item {
                                                                        width: videoAudioRect.width
                                                                        height: videoAudioRect.height
                                                                        Rectangle {
                                                                            anchors.centerIn: parent
                                                                            width:  videoAudioRect.width
                                                                            height: videoAudioRect.height
                                                                            radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Component {
                                                        id: simpleImage

                                                        Image {
                                                            id: fileImage

                                                            anchors.fill: parent
                                                            fillMode: Image.PreserveAspectCrop
                                                            source: "file:///" + Body
                                                            layer.enabled: true
                                                            layer.effect: OpacityMask {
                                                                maskSource: Item {
                                                                    width: fileImage.width
                                                                    height: fileImage.height
                                                                    Rectangle {
                                                                        anchors.centerIn: parent
                                                                        width:  fileImage.width
                                                                        height: fileImage.height
                                                                        radius: JamiTheme.swarmDetailsPageDocumentsMediaRadius
                                                                    }
                                                                }
                                                            }
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                                                onEntered: {
                                                                    cursorShape = Qt.PointingHandCursor
                                                                }

                                                                onClicked: function(mouse)  {
                                                                    if (mouse.button === Qt.RightButton) {
                                                                        ctxMenu.x = mouse.x
                                                                        ctxMenu.y = mouse.y
                                                                        ctxMenu.openMenu()
                                                                    } else {
                                                                        MessagesAdapter.openUrl(fileImage.source)
                                                                    }
                                                                }
                                                            }

                                                            SBSContextMenu {
                                                                id: ctxMenu

                                                                msgId: Id
                                                                location: Body
                                                                transferId: Id
                                                                transferName: TransferName
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
