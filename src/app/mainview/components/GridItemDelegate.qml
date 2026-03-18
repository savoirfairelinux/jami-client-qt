import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl

import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1
import "../../commoncomponents"

ItemDelegate {
    id: root

    leftPadding: 4
    rightPadding: 4
    topPadding: 4
    bottomPadding: 4

    spacing: 0

    activeFocusOnTab: true

    contentItem: Column {
        spacing: 4
        Avatar {
            id: avatar

            anchors.horizontalCenter: parent.horizontalCenter

            width: JamiTheme.smartListAvatarSize
            height: JamiTheme.smartListAvatarSize

            scale: mouseArea.containsMouse ? 1.05 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: JamiTheme.shortFadeDuration
                }
            }

            opacity: (MemberRole === Member.Role.INVITED || MemberRole === Member.Role.BANNED) ? 0.5 : 1

            imageId: CurrentAccount.uri === MemberUri ? CurrentAccount.id : MemberUri
            presenceStatus: UtilsAdapter.getContactPresence(CurrentAccount.id, MemberUri)
            showPresenceIndicator: presenceStatus > 0
            mode: CurrentAccount.uri === MemberUri ? Avatar.Mode.Account : Avatar.Mode.Contact

            IconImage {
                id: icon

                anchors.top: parent.top
                anchors.topMargin: -4
                anchors.right: parent.right

                width: JamiTheme.iconButtonSmall
                height: JamiTheme.iconButtonSmall

                visible: MemberRole !== undefined

                source: {
                    switch (MemberRole) {
                    case Member.Role.ADMIN:
                        return JamiResources.moderator_filled_24dp_svg;
                    case Member.Role.BANNED:
                        return JamiResources.disconnect_participant_24dp_svg;
                    case Member.Role.INVITED:
                        return JamiResources.mail_24dp_svg;
                    default:
                        return "";
                    }
                }
                sourceSize.width: JamiTheme.iconButtonSmall
                sourceSize.height: JamiTheme.iconButtonSmall

                color: {
                    switch (MemberRole) {
                    case Member.Role.ADMIN:
                        return "#bf9b30";
                    case Member.Role.BANNED:
                        return JamiTheme.redColor;
                    case Member.Role.INVITED:
                        return JamiTheme.tintedBlue;
                    default:
                        return JamiTheme.transparentColor;
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent

                hoverEnabled: true
                acceptedButtons: Qt.RightButton | Qt.LeftButton

                onClicked: {
                    if (mouse.button === Qt.LeftButton) {
                        if (ConversationsAdapter.dialogId(MemberUri) !== "")
                            ConversationsAdapter.openDialogConversationWith(MemberUri);
                        else
                            ConversationsAdapter.setFilter(MemberUri);
                    } else if (mouse.button === Qt.RightButton) {
                        const position = mapToItem(parent, mouse.x, mouse.y);
                        contextMenu.openMenuAt(position.x, position.y, MemberUri);
                    }
                }
            }

            MaterialToolTip {
                parent: parent

                text: {
                    switch(MemberRole) {
                    case Member.Role.ADMIN:
                        return JamiStrings.administrator;
                    case Member.Role.INVITED:
                        return JamiStrings.invited;
                    case Member.Role.BANNED:
                        return JamiStrings.blocked;
                    default:
                        return "";
                    }
                }

                visible: mouseArea.containsMouse && text.length > 0
                delay: Qt.styleHints.mousePressAndHoldInterval
            }
        }
        ElidedTextLabel {
            id: nameTextEdit

            anchors.horizontalCenter: parent.horizontalCenter

            padding: 0

            width: parent.width
            eText: UtilsAdapter.getContactBestName(CurrentAccount.id, MemberUri)
            maxWidth: width

            font.pointSize: JamiTheme.participantFontSize
            color: JamiTheme.primaryForegroundColor
            opacity: (MemberRole === Member.Role.INVITED || MemberRole
                      === Member.Role.BANNED) ? 0.5 : 1
            font.kerning: true

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                cursorShape: Qt.IBeamCursor
                onClicked: function (mouse) {
                    nameTextEditContextMenu.openMenuAt(mouse);
                }
            }

            LineEditContextMenu {
                id: nameTextEditContextMenu
                lineEditObj: nameTextEdit
                selectOnly: true
            }
        }
    }

    SwarmParticipantContextMenu {
        id: contextMenu
        role: UtilsAdapter.getParticipantRole(CurrentAccount.id,
                                              CurrentConversation.id,
                                              CurrentAccount.uri)

        function openMenuAt(x, y, participantUri) {
            contextMenu.x = x;
            contextMenu.y = y;
            contextMenu.conversationId = CurrentConversation.id;
            contextMenu.participantUri = participantUri;
            openMenu();
        }
    }

    background: null

    Keys.onReturnPressed: {
        const position = mapToItem(parent, width / 2, height / 2);
        contextMenu.openMenuAt(position.x, position.y, MemberUri);
    }

    Accessible.role: Accessible.Button
    Accessible.name: UtilsAdapter.getContactBestName(CurrentAccount.id, MemberUri)
}
