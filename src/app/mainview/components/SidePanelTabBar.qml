/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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
import QtQuick.Controls.impl
import QtQuick.Layouts

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ColumnLayout {
    id: root

    objectName: "conversationCategoryBar"
    spacing: 8

    function selectCategory(category) {
        ConversationsAdapter.category = category;
        ConversationsAdapter.invitationsOnly = false;
    }

    readonly property var categories: [
        {name: "all", label: JamiStrings.conversations,
            icon: JamiResources.chat_24dp_svg, selectedIcon: JamiResources.chat_filled_24dp_svg},
        {name: "oneToOne", label: JamiStrings.contacts,
            icon: JamiResources.person_24dp_svg, selectedIcon: JamiResources.person_filled_24dp_svg},
        {name: "groups", label: JamiStrings.groupConversations,
            icon: JamiResources.groups_24dp_svg, selectedIcon: JamiResources.groups_filled_24dp_svg},
        {name: "feeds", label: JamiStrings.feeds,
            icon: JamiResources.feed_24dp_svg, selectedIcon: JamiResources.feed_24dp_svg}
    ]

    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: root.categories

            delegate: NewIconButton {
                id: categoryButton

                required property var modelData
                required property int index
                readonly property int badgeCount: ConversationsAdapter.categoryBadgeCounts[index] || 0

                objectName: modelData.name + "CategoryButton"

                Layout.fillWidth: true

                iconSize: JamiTheme.iconButtonMedium
                iconSource: checked ? modelData.selectedIcon : modelData.icon
                iconColor: JamiTheme.buttonTintedBlue
                backgroundColor: Qt.rgba(iconColor.r, iconColor.g, iconColor.b, pressed ? 0.24 : 0.12)
                Behavior on backgroundColor {
                    ColorAnimation {
                        duration: JamiTheme.shortFadeDuration
                    }
                }

                toolTipText: modelData.label

                checkable: true
                autoExclusive: true
                checked: ConversationsAdapter.category === index
                onClicked: root.selectCategory(index)

                BadgeNotifier {
                    objectName: categoryButton.modelData.name + "CategoryBadge"

                    anchors.top: parent.top
                    anchors.right: parent.right

                    size: 20
                    count: categoryButton.badgeCount
                }

                Accessible.role: Accessible.RadioButton
                Accessible.checkable: true
                Accessible.checked: checked
                Accessible.description: JamiStrings.unreadItemsCount.arg(badgeCount)
            }
        }
    }


    RowLayout {
        Layout.fillWidth: true
        visible: ConversationsAdapter.category !== ConversationListProxyModel.All ||
                 ConversationsAdapter.invitationsOnly

        NewIconButton {
            objectName: "invitationsBackButton"

            Layout.alignment: Qt.AlignVCenter
            visible: ConversationsAdapter.invitationsOnly
            onClicked: ConversationsAdapter.invitationsOnly = false

            iconSize: JamiTheme.iconButtonSmall
            iconSource: JamiResources.bidirectional_arrow_back_24dp_svg
            toolTipText: JamiStrings.back
        }

        Text {
            id: sectionTitle

            objectName: "conversationSectionTitle"
            readonly property rect glyphBounds: titleFontMetrics.tightBoundingRect(text)

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: ConversationsAdapter.invitationsOnly ? JamiStrings.invitations :
                  root.categories[ConversationsAdapter.category].label
            color: JamiTheme.textColor
            font.pointSize: JamiTheme.largeFontSize
            font.weight: Font.Light
            elide: Text.ElideRight
            Accessible.role: Accessible.Heading

            FontMetrics {
                id: titleFontMetrics

                font: sectionTitle.font
            }

            transform: Translate {
                y: (sectionTitle.height - sectionTitle.glyphBounds.height) / 2 -
                   sectionTitle.baselineOffset - sectionTitle.glyphBounds.y
            }
        }
    }

    Control {
        objectName: "pendingInvitationsBanner"

        Layout.fillWidth: true

        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding)

        horizontalPadding: background.radius
        verticalPadding: 4

        visible: !ConversationsAdapter.invitationsOnly &&
                 ConversationsAdapter.categoryInvitationCounts[ConversationsAdapter.category] > 0

        contentItem: Row {
            spacing: 4

            IconImage {
                anchors.verticalCenter: parent.verticalCenter

                width: JamiTheme.iconButtonMedium
                height: JamiTheme.iconButtonMedium

                source: JamiResources.mail_24dp_svg
                sourceSize.width: JamiTheme.iconButtonMedium
                sourceSize.height: JamiTheme.iconButtonMedium

                color: JamiTheme.darkTintedBlue
            }

            Text {
                objectName: "pendingInvitationsText"

                anchors.verticalCenter: parent.verticalCenter

                text: JamiStrings.pendingInvitations.arg(ConversationsAdapter.categoryInvitationCounts[ConversationsAdapter.category] || 0)
                color: JamiTheme.textColor
                font.pointSize: JamiTheme.mediumFontSize
            }
        }

        background: Rectangle {
            color: JamiTheme.buttonTintedBlue
            opacity: parent.hovered ? 0.24 : 0.12

            Behavior on opacity {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }

            radius: height / 2
        }

        MouseArea {
            anchors.fill: parent

            onClicked: ConversationsAdapter.invitationsOnly = !ConversationsAdapter.invitationsOnly
        }
    }
}
