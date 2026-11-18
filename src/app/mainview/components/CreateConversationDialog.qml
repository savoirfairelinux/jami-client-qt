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
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

BaseModalDialog {
    id: root
    objectName: "CreateConversationDialog"

    required property var viewCoordinator
    property bool isFeed: false
    property bool detailsStep: false
    property bool creating: false
    property bool creationFailed: false
    property bool created: false
    property string creationAccountId: ""
    readonly property int participantCount: ConversationsAdapter.participantCountFromConversations(picker.selectedIds)

    signal canceled

    implicitWidth: {
        const preferred = Math.max(400, implicitFooterWidth);
        return parent ? Math.min(preferred, Math.max(0, parent.width - 64)) : preferred;
    }
    height: Math.min(detailsStep ? detailsLayout.implicitHeight + topPadding + bottomPadding
                                   + implicitHeaderHeight + implicitFooterHeight + 2 * spacing : parent.height * 0.7,
                     Math.max(0, parent.height - 64))

    titleText: isFeed ? JamiStrings.createNewFeed : JamiStrings.newGroup
    title: titleText
    headerLeadingButton: !detailsStep && !creating ? picker.helpButton : null
    autoClose: !creating

    closeButtonVisible: !creating

    function createConversation() {
        if (creating || creationAccountId !== CurrentAccount.id)
            return;
        creating = true;
        const id = ConversationsAdapter.createConversationFromConversations(title.modifiedTextFieldContent,
                                                                            description.modifiedTextFieldContent,
                                                                            UtilsAdapter.tempCreationImage(),
                                                                            picker.selectedIds,
                                                                            isFeed);
        if (!id) {
            creating = false;
            creationFailed = true;
            return;
        }
        created = true;
        close();
        LRCInstance.selectConversation(id);
    }

    onAboutToShow: {
        creationAccountId = CurrentAccount.id;
        UtilsAdapter.setTempCreationImageFromString();
    }
    onOpened: picker.focusSearch()
    onClosed: {
        UtilsAdapter.setTempCreationImageFromString();
        if (!created && creationAccountId === CurrentAccount.id)
            canceled();
    }

    Connections {
        target: LRCInstance

        function onCurrentAccountIdChanged() {
            root.close();
        }
        function onCurrentAccountRemoved() {
            root.close();
        }
    }

    button1.text: detailsStep ? JamiStrings.back : ""
    button1.textButton: false
    button1.outlinedButton: true
    button1.enabled: !creating
    button1.onClicked: {
        detailsStep = false;
        creationFailed = false;
        picker.focusSearch();
    }
    button3.text: detailsStep ? titleText : (participantCount > 0 ? JamiStrings.nextWithCount.arg(participantCount) : JamiStrings.next)
    button3.iconSource: detailsStep ? JamiResources.add_24dp_svg : ""
    button3.textButton: false
    button3.filledButton: true
    button3.enabled: !creating
    button3.onClicked: {
        if (detailsStep) {
            createConversation();
        } else {
            detailsStep = true;
            title.forceTextFieldActiveFocus();
        }
    }

    contentItem: StackLayout {
        id: pages
        currentIndex: root.detailsStep ? 1 : 0

        ConversationPicker {
            id: picker
            viewCoordinator: root.viewCoordinator
            isFeed: root.isFeed
        }

        JamiFlickable {
            id: details
            contentWidth: width
            contentHeight: detailsLayout.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            enabled: !root.creating

            ColumnLayout {
                id: detailsLayout
                width: details.width
                spacing: JamiTheme.preferredMarginSize

                Label {
                    Layout.fillWidth: true
                    visible: root.creationFailed
                    text: root.isFeed ? JamiStrings.feedCreationFailed : JamiStrings.groupCreationFailed
                    color: JamiTheme.textColor
                    wrapMode: Text.WordWrap
                }

                PhotoboothView {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: avatarSize
                    Layout.preferredHeight: avatarSize
                    newItem: true
                    fallbackKind: root.isFeed ? Avatar.FallbackKind.Feed : Avatar.FallbackKind.Default
                    imageId: "temp"
                    avatarSize: 140
                }

                NewMaterialTextField {
                    id: title
                    objectName: "titleLineEdit"
                    leadingIconSource: root.isFeed ? JamiResources.feed_24dp_svg : JamiResources.groups_3_24dp_svg
                    maxCharacters: JamiTheme.maximumCharacters
                    placeholderText: root.isFeed ? JamiStrings.feedName : JamiStrings.groupName
                    onAccepted: description.forceTextFieldActiveFocus()
                }

                NewMaterialTextField {
                    id: description
                    objectName: "descriptionLineEdit"
                    leadingIconSource: JamiResources.swarm_details_panel_24dp_svg
                    maxCharacters: JamiTheme.maximumCharacters
                    placeholderText: JamiStrings.addDescription
                    onAccepted: root.button3.forceActiveFocus()
                }
            }
        }
    }
}
